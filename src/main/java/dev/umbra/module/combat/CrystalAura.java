package dev.umbra.module.combat;

import dev.umbra.module.Category;
import dev.umbra.module.Module;
import dev.umbra.setting.BoolSetting;
import dev.umbra.setting.NumberSetting;
import dev.umbra.util.Friends;
import dev.umbra.util.InvUtil;
import dev.umbra.util.Lines;
import dev.umbra.util.WorldUtil;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.boss.enderdragon.EndCrystal;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.Items;
import net.minecraft.world.level.ClipContext;
import net.minecraft.world.level.block.Blocks;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.phys.AABB;
import net.minecraft.world.phys.BlockHitResult;
import net.minecraft.world.phys.HitResult;
import net.minecraft.world.phys.Vec3;

/**
 * Places and detonates end crystals next to enemy players.
 *
 * Damage numbers are estimates: vanilla's explosion formula with a 3-ray exposure check,
 * ignoring armor, enchantments and difficulty. Tune MinDamage/MaxSelf with that in mind.
 */
public class CrystalAura extends Module {
    private final NumberSetting targetRange = number("TargetRange", "How far to look for enemies", 10, 3, 16, 0.5);
    private final NumberSetting placeRange = number("PlaceRange", "Max distance to place crystals", 4.5, 1, 6, 0.1);
    private final NumberSetting breakRange = number("BreakRange", "Max distance to hit crystals", 4.5, 1, 6, 0.1);
    private final NumberSetting minDamage = number("MinDamage", "Minimum estimated damage to the target", 6, 0, 36, 0.5);
    private final NumberSetting maxSelf = number("MaxSelf", "Maximum estimated damage to yourself", 8, 0, 36, 0.5);
    private final BoolSetting antiSuicide = bool("AntiSuicide", "Never place/break if it could kill you", true);
    private final NumberSetting placeDelay = number("PlaceDelay", "Ticks between placements", 1, 0, 10, 1);
    private final NumberSetting breakDelay = number("BreakDelay", "Ticks between hits", 1, 0, 10, 1);
    private final BoolSetting autoSwitch = bool("AutoSwitch", "Switch to crystals in the hotbar", true);
    private final BoolSetting rotate = bool("Rotate", "Send look packets", true);
    private final BoolSetting render = bool("Render", "Outline the chosen placement", true);

    private Player target;
    private BlockPos lastPlace;
    private int placeTimer, breakTimer;

    public CrystalAura() {
        super("CrystalAura", Category.COMBAT, "Automatically places and breaks end crystals on enemies");
    }

    @Override
    public void onDisable() {
        target = null;
        lastPlace = null;
    }

    @Override
    public void onTick() {
        if (placeTimer > 0) placeTimer--;
        if (breakTimer > 0) breakTimer--;

        target = findTarget();
        if (target == null) {
            lastPlace = null;
            return;
        }
        if (breakTimer <= 0 && doBreak()) breakTimer = breakDelay.getInt();
        if (placeTimer <= 0 && doPlace()) placeTimer = placeDelay.getInt();
    }

    private Player findTarget() {
        Player best = null;
        double bestDist = targetRange.get();
        for (Player p : mc.level.players()) {
            if (p == mc.player || !p.isAlive() || p.isSpectator() || p.isCreative() || Friends.isFriend(p)) continue;
            double d = mc.player.distanceTo(p);
            if (d <= bestDist) {
                best = p;
                bestDist = d;
            }
        }
        return best;
    }

    private float selfHealth() {
        return mc.player.getHealth() + mc.player.getAbsorptionAmount();
    }

    private boolean selfSafe(double selfDamage) {
        if (selfDamage > maxSelf.get()) return false;
        return !antiSuicide.get() || selfDamage < selfHealth() - 1;
    }

    private boolean doBreak() {
        EndCrystal best = null;
        double bestDamage = 0;
        Vec3 eyes = mc.player.getEyePosition();
        AABB area = mc.player.getBoundingBox().inflate(breakRange.get() + 2);
        for (Entity e : mc.level.getEntities((Entity) null, area, ent -> ent instanceof EndCrystal && ent.isAlive())) {
            if (eyes.distanceTo(e.position()) > breakRange.get()) continue;
            double self = damage(e.position(), mc.player);
            if (!selfSafe(self)) continue;
            double dmg = damage(e.position(), target);
            if (dmg > bestDamage) {
                bestDamage = dmg;
                best = (EndCrystal) e;
            }
        }
        if (best == null || bestDamage < Math.min(minDamage.get(), 2)) return false;
        if (rotate.get()) WorldUtil.silentLook(best.position());
        mc.gameMode.attack(mc.player, best);
        mc.player.swing(InteractionHand.MAIN_HAND);
        return true;
    }

    private boolean doPlace() {
        InteractionHand hand;
        if (mc.player.getOffhandItem().is(Items.END_CRYSTAL)) hand = InteractionHand.OFF_HAND;
        else if (mc.player.getMainHandItem().is(Items.END_CRYSTAL)) hand = InteractionHand.MAIN_HAND;
        else if (autoSwitch.get()) {
            int slot = InvUtil.findHotbar(s -> s.is(Items.END_CRYSTAL));
            if (slot == -1) return false;
            InvUtil.select(slot);
            hand = InteractionHand.MAIN_HAND;
        } else return false;

        BlockPos best = null;
        double bestDamage = minDamage.get();
        int r = (int) Math.ceil(placeRange.get());
        BlockPos origin = mc.player.blockPosition();
        Vec3 eyes = mc.player.getEyePosition();

        for (int x = -r; x <= r; x++) {
            for (int y = -r; y <= r; y++) {
                for (int z = -r; z <= r; z++) {
                    BlockPos pos = origin.offset(x, y, z);
                    if (eyes.distanceTo(Vec3.atCenterOf(pos)) > placeRange.get()) continue;
                    if (!canPlace(pos)) continue;
                    Vec3 crystal = new Vec3(pos.getX() + 0.5, pos.getY() + 1, pos.getZ() + 0.5);
                    if (target.position().distanceTo(crystal) > 12) continue;
                    double self = damage(crystal, mc.player);
                    if (!selfSafe(self)) continue;
                    double dmg = damage(crystal, target);
                    if (dmg > bestDamage) {
                        bestDamage = dmg;
                        best = pos;
                    }
                }
            }
        }
        lastPlace = best;
        if (best == null) return false;

        Vec3 hitVec = new Vec3(best.getX() + 0.5, best.getY() + 1.0, best.getZ() + 0.5);
        if (rotate.get()) WorldUtil.silentLook(hitVec);
        mc.gameMode.useItemOn(mc.player, hand, new BlockHitResult(hitVec, Direction.UP, best, false));
        mc.player.swing(hand);
        return true;
    }

    private boolean canPlace(BlockPos pos) {
        BlockState base = mc.level.getBlockState(pos);
        if (!base.is(Blocks.OBSIDIAN) && !base.is(Blocks.BEDROCK)) return false;
        BlockPos up = pos.above();
        if (!mc.level.getBlockState(up).isAir()) return false;
        AABB space = new AABB(up.getX(), up.getY(), up.getZ(), up.getX() + 1, up.getY() + 2, up.getZ() + 1);
        return mc.level.getEntities((Entity) null, space, e -> e.isAlive() && !e.isSpectator()).isEmpty();
    }

    /** Vanilla explosion damage (power 6) with a coarse exposure estimate. */
    private double damage(Vec3 crystal, LivingEntity entity) {
        double dist = entity.position().distanceTo(crystal);
        if (dist > 12) return 0;
        double exposure = exposure(crystal, entity);
        double impact = (1 - dist / 12.0) * exposure;
        return (impact * impact + impact) / 2.0 * 7.0 * 12.0 + 1.0;
    }

    private double exposure(Vec3 from, LivingEntity entity) {
        AABB box = entity.getBoundingBox();
        Vec3[] points = {
                new Vec3(box.getCenter().x, box.minY + 0.1, box.getCenter().z),
                box.getCenter(),
                new Vec3(box.getCenter().x, box.maxY - 0.1, box.getCenter().z)
        };
        int visible = 0;
        for (Vec3 p : points) {
            HitResult hit = mc.level.clip(new ClipContext(from, p, ClipContext.Block.COLLIDER, ClipContext.Fluid.NONE, mc.player));
            if (hit.getType() == HitResult.Type.MISS) visible++;
        }
        return visible / (double) points.length;
    }

    @Override
    public void onRenderLines(Lines lines) {
        if (render.get() && lastPlace != null) lines.box(WorldUtil.blockBox(lastPlace), 0xFFE04848);
    }

    @Override
    public String getInfo() {
        return target == null ? null : target.getName().getString();
    }
}

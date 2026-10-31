package dev.umbra.util;

import net.minecraft.client.Minecraft;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.network.protocol.game.ServerboundMovePlayerPacket;
import net.minecraft.util.Mth;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.MobCategory;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.phys.AABB;
import net.minecraft.world.phys.BlockHitResult;
import net.minecraft.world.phys.Vec3;

public final class WorldUtil {
    private WorldUtil() { }

    private static final Minecraft mc = Minecraft.getInstance();

    // ---- rotations --------------------------------------------------------

    /** {yaw, pitch} needed to look from the player's eyes at a point. */
    public static float[] rotationsTo(Vec3 target) {
        Vec3 eyes = mc.player.getEyePosition();
        double dx = target.x - eyes.x, dy = target.y - eyes.y, dz = target.z - eyes.z;
        double horizontal = Math.sqrt(dx * dx + dz * dz);
        float yaw = (float) Math.toDegrees(Math.atan2(dz, dx)) - 90f;
        float pitch = (float) -Math.toDegrees(Math.atan2(dy, horizontal));
        return new float[]{Mth.wrapDegrees(yaw), Mth.clamp(pitch, -90f, 90f)};
    }

    /** Tells the server we look at a point without moving the client camera. */
    public static void silentLook(Vec3 target) {
        float[] rot = rotationsTo(target);
        mc.player.connection.send(new ServerboundMovePlayerPacket.Rot(rot[0], rot[1], mc.player.onGround(), mc.player.horizontalCollision));
    }

    // ---- targets ----------------------------------------------------------

    public static boolean isValidTarget(Entity e, boolean players, boolean hostiles, boolean passives) {
        if (!(e instanceof LivingEntity living) || e == mc.player || !living.isAlive() || living.getHealth() <= 0) return false;
        if (e instanceof Player p) {
            if (!players || Friends.isFriend(p) || p.isSpectator() || p.isCreative()) return false;
            return true;
        }
        MobCategory cat = e.getType().getCategory();
        if (cat == MobCategory.MONSTER) return hostiles;
        return passives && cat != MobCategory.MISC;
    }

    // ---- blocks -----------------------------------------------------------

    public static boolean isReplaceable(BlockPos pos) {
        return mc.level.getBlockState(pos).canBeReplaced();
    }

    /** True if no entity (other than items/xp) occupies the block. */
    public static boolean isFreeOfEntities(BlockPos pos) {
        return mc.level.getEntities((Entity) null, blockBox(pos), ent -> ent.isAlive() && !ent.isSpectator() && ent.isPickable()).isEmpty();
    }

    public static AABB blockBox(BlockPos pos) {
        return new AABB(pos.getX(), pos.getY(), pos.getZ(), pos.getX() + 1, pos.getY() + 1, pos.getZ() + 1);
    }

    /**
     * Places the held block at pos by clicking a solid neighbour. Returns false if there
     * is nothing to click against.
     */
    public static boolean place(BlockPos pos, InteractionHand hand, boolean rotate) {
        if (!isReplaceable(pos)) return false;
        for (Direction dir : Direction.values()) {
            BlockPos neighbour = pos.relative(dir);
            if (mc.level.getBlockState(neighbour).canBeReplaced()) continue;
            Direction face = dir.getOpposite();
            Vec3 hitVec = Vec3.atCenterOf(neighbour).add(face.getStepX() * 0.5, face.getStepY() * 0.5, face.getStepZ() * 0.5);
            if (rotate) silentLook(hitVec);
            BlockHitResult hit = new BlockHitResult(hitVec, face, neighbour, false);
            mc.gameMode.useItemOn(mc.player, hand, hit);
            mc.player.swing(hand);
            return true;
        }
        return false;
    }

    public static double distanceTo(BlockPos pos) {
        return mc.player.getEyePosition().distanceTo(Vec3.atCenterOf(pos));
    }

    /** Interpolated entity position for smooth rendering. */
    public static Vec3 lerpPos(Entity e, float partialTick) {
        return new Vec3(Mth.lerp(partialTick, e.xo, e.getX()), Mth.lerp(partialTick, e.yo, e.getY()), Mth.lerp(partialTick, e.zo, e.getZ()));
    }

    public static AABB lerpBox(Entity e, float partialTick) {
        Vec3 p = lerpPos(e, partialTick);
        return e.getBoundingBox().move(p.x - e.getX(), p.y - e.getY(), p.z - e.getZ());
    }
}

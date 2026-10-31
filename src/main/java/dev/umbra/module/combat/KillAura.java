package dev.umbra.module.combat;

import dev.umbra.module.Category;
import dev.umbra.module.Module;
import dev.umbra.setting.BoolSetting;
import dev.umbra.setting.ModeSetting;
import dev.umbra.setting.NumberSetting;
import dev.umbra.util.WorldUtil;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.LivingEntity;

import java.util.Comparator;

public class KillAura extends Module {
    private final NumberSetting range = number("Range", "Attack reach in blocks", 4.5, 1, 6, 0.1);
    private final BoolSetting players = bool("Players", "Attack players (friends are skipped)", true);
    private final BoolSetting hostiles = bool("Hostiles", "Attack hostile mobs", true);
    private final BoolSetting passives = bool("Passives", "Attack animals and other passive mobs", false);
    private final ModeSetting priority = mode("Priority", "Which target to pick first", "Closest", "Closest", "Health", "Angle");
    private final BoolSetting rotate = bool("Rotate", "Send a look packet at the target before hitting", true);
    private final BoolSetting cooldown = bool("Cooldown", "Wait for a fully charged attack", true);
    private final NumberSetting delay = number("Delay", "Ticks between hits when Cooldown is off", 2, 0, 20, 1);
    private final BoolSetting pauseEating = bool("PauseOnUse", "Don't attack while eating or using an item", true);

    private LivingEntity target;
    private int timer;

    public KillAura() {
        super("KillAura", Category.COMBAT, "Automatically attacks entities around you");
    }

    @Override
    public void onDisable() {
        target = null;
    }

    @Override
    public void onTick() {
        target = null;
        if (pauseEating.get() && mc.player.isUsingItem()) return;
        if (timer > 0) timer--;

        double r = range.get();
        Comparator<LivingEntity> order = switch (priority.get()) {
            case "Health" -> Comparator.comparingDouble(e -> e.getHealth() + e.getAbsorptionAmount());
            case "Angle" -> Comparator.comparingDouble(this::angleTo);
            default -> Comparator.comparingDouble(e -> mc.player.distanceTo(e));
        };

        LivingEntity best = null;
        for (Entity e : mc.level.entitiesForRendering()) {
            if (!WorldUtil.isValidTarget(e, players.get(), hostiles.get(), passives.get())) continue;
            LivingEntity le = (LivingEntity) e;
            if (mc.player.distanceTo(le) > r) continue;
            if (best == null || order.compare(le, best) < 0) best = le;
        }
        target = best;
        if (target == null) return;

        boolean ready = cooldown.get() ? mc.player.getAttackStrengthScale(0.5f) >= 1.0f : timer <= 0;
        if (!ready) return;

        if (rotate.get()) WorldUtil.silentLook(target.getBoundingBox().getCenter());
        mc.gameMode.attack(mc.player, target);
        mc.player.swing(InteractionHand.MAIN_HAND);
        timer = delay.getInt();
    }

    private double angleTo(LivingEntity e) {
        float[] rot = WorldUtil.rotationsTo(e.getBoundingBox().getCenter());
        float diff = Math.abs(net.minecraft.util.Mth.wrapDegrees(rot[0] - mc.player.getYRot()));
        return diff + Math.abs(rot[1] - mc.player.getXRot());
    }

    @Override
    public String getInfo() {
        return target == null ? null : target.getName().getString();
    }
}

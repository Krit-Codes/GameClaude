package dev.umbra.module.movement;

import dev.umbra.module.Category;
import dev.umbra.module.Module;
import dev.umbra.setting.ModeSetting;
import dev.umbra.setting.NumberSetting;

public class Speed extends Module {
    private final ModeSetting mode = mode("Mode", "Strafe: bunny-hop with air control. OnGround: faster walking only.", "Strafe", "Strafe", "OnGround");
    private final NumberSetting speed = number("Speed", "Target horizontal speed (blocks/tick)", 0.32, 0.1, 2, 0.01);

    public Speed() {
        super("Speed", Category.MOVEMENT, "Move faster");
    }

    @Override
    public void onTick() {
        if (mc.player.isFallFlying() || mc.player.getAbilities().flying || mc.player.isInWater() || mc.player.isInLava()) return;
        if (!MoveUtil.isMoving()) return;
        if (mc.player.isShiftKeyDown()) return;

        if (mode.is("Strafe")) {
            if (mc.player.onGround()) mc.player.jumpFromGround();
            double current = Math.hypot(mc.player.getDeltaMovement().x, mc.player.getDeltaMovement().z);
            double s = mc.player.onGround() ? speed.get() : Math.max(current, speed.get() * 0.9);
            double[] xz = MoveUtil.directionalSpeed(s);
            mc.player.setDeltaMovement(xz[0], mc.player.getDeltaMovement().y, xz[1]);
        } else if (mc.player.onGround()) {
            double[] xz = MoveUtil.directionalSpeed(speed.get());
            mc.player.setDeltaMovement(xz[0], mc.player.getDeltaMovement().y, xz[1]);
        }
    }

    @Override
    public String getInfo() {
        return mode.get();
    }
}

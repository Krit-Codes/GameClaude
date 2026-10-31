package dev.umbra.module.movement;

import dev.umbra.module.Category;
import dev.umbra.module.Module;
import dev.umbra.setting.BoolSetting;
import dev.umbra.setting.ModeSetting;
import dev.umbra.setting.NumberSetting;
import net.minecraft.network.protocol.game.ServerboundMovePlayerPacket;

public class Flight extends Module {
    private final ModeSetting mode = mode("Mode", "Velocity sets your motion directly; Abilities uses creative-style flying", "Velocity", "Velocity", "Abilities");
    private final NumberSetting speed = number("Speed", "Horizontal speed (blocks/tick)", 1.0, 0.1, 5, 0.1);
    private final NumberSetting verticalSpeed = number("VerticalSpeed", "Up/down speed (blocks/tick)", 0.5, 0.1, 3, 0.1);
    private final BoolSetting antiKick = bool("AntiKick", "Dip down slightly every few ticks so vanilla's fly check doesn't kick you", true);
    private final BoolSetting noFall = bool("NoFall", "Claim to be on the ground while flying", false);

    private int ticks;

    public Flight() {
        super("Flight", Category.MOVEMENT, "Lets you fly in survival");
    }

    @Override
    public void onTick() {
        ticks++;
        if (noFall.get() && mc.player.fallDistance > 2) {
            mc.player.connection.send(new ServerboundMovePlayerPacket.StatusOnly(true, mc.player.horizontalCollision));
            mc.player.fallDistance = 0;
        }
        if (mode.is("Abilities")) {
            mc.player.getAbilities().flying = true;
            mc.player.getAbilities().setFlyingSpeed(speed.getFloat() / 10f);
            return;
        }
        double[] xz = MoveUtil.directionalSpeed(speed.get());
        double y = 0;
        if (mc.options.keyJump.isDown()) y += verticalSpeed.get();
        if (mc.options.keyShift.isDown()) y -= verticalSpeed.get();
        if (antiKick.get() && ticks % 40 == 0 && y == 0) y = -0.04;
        mc.player.setDeltaMovement(xz[0], y, xz[1]);
    }

    @Override
    public void onDisable() {
        if (!inGame()) return;
        if (mode.is("Abilities")) {
            boolean creative = mc.player.isCreative() || mc.player.isSpectator();
            mc.player.getAbilities().flying = creative && mc.player.getAbilities().flying;
            mc.player.getAbilities().setFlyingSpeed(0.05f);
        }
        mc.player.setDeltaMovement(0, 0, 0);
    }

    @Override
    public String getInfo() {
        return mode.get();
    }
}

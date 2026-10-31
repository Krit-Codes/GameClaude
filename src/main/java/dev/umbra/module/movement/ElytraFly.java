package dev.umbra.module.movement;

import dev.umbra.module.Category;
import dev.umbra.module.Module;
import dev.umbra.setting.BoolSetting;
import dev.umbra.setting.ModeSetting;
import dev.umbra.setting.NumberSetting;
import net.minecraft.network.protocol.game.ServerboundPlayerCommandPacket;
import net.minecraft.world.entity.EquipmentSlot;
import net.minecraft.world.item.Items;
import net.minecraft.world.phys.Vec3;

public class ElytraFly extends Module {
    private final ModeSetting mode = mode("Mode", "Control: fly where you look and hover with no input. Boost: add speed in the look direction.", "Control", "Control", "Boost");
    private final NumberSetting speed = number("Speed", "Horizontal speed (blocks/tick)", 1.8, 0.1, 5, 0.1);
    private final NumberSetting verticalSpeed = number("VerticalSpeed", "Up/down speed in Control mode", 1.0, 0.1, 3, 0.1);
    private final NumberSetting boost = number("BoostAmount", "Acceleration per tick in Boost mode", 0.05, 0.01, 0.3, 0.01);
    private final NumberSetting maxBoost = number("MaxBoost", "Speed cap in Boost mode", 2.5, 0.5, 5, 0.1);
    private final BoolSetting autoStart = bool("AutoStart", "Open the elytra automatically when falling", true);
    private final BoolSetting pitchLock = bool("UsePitch", "Control mode: look up/down to climb/descend", false);

    public ElytraFly() {
        super("ElytraFly", Category.MOVEMENT, "Better elytra flight");
    }

    @Override
    public void onTick() {
        boolean wearing = mc.player.getItemBySlot(EquipmentSlot.CHEST).is(Items.ELYTRA);
        if (!wearing) return;

        if (!mc.player.isFallFlying()) {
            if (autoStart.get() && !mc.player.onGround() && mc.player.getDeltaMovement().y < -0.08 && !mc.player.isInWater()) {
                mc.player.connection.send(new ServerboundPlayerCommandPacket(mc.player, ServerboundPlayerCommandPacket.Action.START_FALL_FLYING));
            }
            return;
        }

        if (mode.is("Boost")) {
            if (!mc.options.keyUp.isDown()) return;
            Vec3 look = Vec3.directionFromRotation(mc.player.getXRot(), mc.player.getYRot());
            Vec3 v = mc.player.getDeltaMovement().add(look.scale(boost.get()));
            double h = Math.sqrt(v.x * v.x + v.z * v.z);
            if (h > maxBoost.get()) v = new Vec3(v.x / h * maxBoost.get(), v.y, v.z / h * maxBoost.get());
            mc.player.setDeltaMovement(v);
            return;
        }

        double[] xz = MoveUtil.directionalSpeed(speed.get());
        double y = 0;
        if (mc.options.keyJump.isDown()) y = verticalSpeed.get();
        else if (mc.options.keyShift.isDown()) y = -verticalSpeed.get();
        else if (pitchLock.get() && MoveUtil.isMoving()) y = -Math.sin(Math.toRadians(mc.player.getXRot())) * speed.get();
        mc.player.setDeltaMovement(xz[0], y, xz[1]);
    }

    @Override
    public String getInfo() {
        return mode.get();
    }
}

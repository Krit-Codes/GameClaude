package dev.umbra.module.render;

import dev.umbra.module.Category;
import dev.umbra.module.Module;
import dev.umbra.setting.NumberSetting;
import net.minecraft.network.protocol.Packet;
import net.minecraft.network.protocol.game.ClientboundPlayerPositionPacket;
import net.minecraft.network.protocol.game.ServerboundMovePlayerPacket;
import net.minecraft.network.protocol.game.ServerboundPlayerCommandPacket;
import net.minecraft.world.phys.Vec3;

/**
 * Packet freecam: your client flies around with no-clip while every movement packet is held
 * back, so the server keeps you where you started. Turning it off snaps you back.
 */
public class Freecam extends Module {
    private final NumberSetting speed = number("Speed", "Fly speed (blocks/tick)", 1.0, 0.1, 5, 0.1);

    private Vec3 startPos;
    private float startYaw, startPitch;
    private boolean startFlying;

    public Freecam() {
        super("Freecam", Category.RENDER, "Fly your camera through walls while your body stays put");
    }

    @Override
    public void onEnable() {
        if (!inGame()) {
            setEnabledSilently(false);
            return;
        }
        startPos = mc.player.position();
        startYaw = mc.player.getYRot();
        startPitch = mc.player.getXRot();
        startFlying = mc.player.getAbilities().flying;
    }

    @Override
    public void onTick() {
        if (startPos == null) {
            setEnabled(false);
            return;
        }
        mc.player.noPhysics = true;
        mc.player.getAbilities().flying = true;
        double s = speed.get();
        double yaw = Math.toRadians(mc.player.getYRot());
        var in = mc.player.input.getMoveVector();
        double fwd = in.y, strafe = in.x;
        double x = (fwd * -Math.sin(yaw) + strafe * Math.cos(yaw)) * s;
        double z = (fwd * Math.cos(yaw) + strafe * Math.sin(yaw)) * s;
        double y = 0;
        if (mc.options.keyJump.isDown()) y += s;
        if (mc.options.keyShift.isDown()) y -= s;
        mc.player.setDeltaMovement(x, y, z);
        mc.player.fallDistance = 0;
    }

    @Override
    public void onDisable() {
        if (mc.player != null && startPos != null) {
            mc.player.noPhysics = false;
            mc.player.getAbilities().flying = startFlying;
            mc.player.setPos(startPos.x, startPos.y, startPos.z);
            mc.player.setYRot(startYaw);
            mc.player.setXRot(startPitch);
            mc.player.setDeltaMovement(0, 0, 0);
        }
        startPos = null;
    }

    @Override
    public void onJoin() {
        // New world: the stored position means nothing here.
        startPos = null;
        setEnabled(false);
    }

    @Override
    public boolean onPacketSend(Packet<?> packet) {
        return startPos != null && (packet instanceof ServerboundMovePlayerPacket || packet instanceof ServerboundPlayerCommandPacket);
    }

    @Override
    public boolean onPacketReceive(Packet<?> packet) {
        // The server moved us (teleport, rubberband). Leave freecam first so the teleport wins.
        if (packet instanceof ClientboundPlayerPositionPacket) mc.execute(() -> setEnabled(false));
        return false;
    }
}

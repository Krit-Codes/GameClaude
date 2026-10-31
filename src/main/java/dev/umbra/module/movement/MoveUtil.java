package dev.umbra.module.movement;

import net.minecraft.client.Minecraft;
import net.minecraft.world.phys.Vec2;

/** Helpers for turning the movement keys into a world-space direction. */
final class MoveUtil {
    private MoveUtil() { }

    private static final Minecraft mc = Minecraft.getInstance();

    static boolean isMoving() {
        Vec2 in = mc.player.input.getMoveVector();
        return in.x != 0 || in.y != 0;
    }

    /** {x, z} velocity of the given speed in the direction the movement keys point, or {0,0}. */
    static double[] directionalSpeed(double speed) {
        Vec2 in = mc.player.input.getMoveVector();
        float forward = in.y, strafe = in.x;
        if (forward == 0 && strafe == 0) return new double[]{0, 0};
        double len = Math.sqrt(forward * forward + strafe * strafe);
        forward /= (float) len;
        strafe /= (float) len;
        double yaw = Math.toRadians(mc.player.getYRot());
        double sin = Math.sin(yaw), cos = Math.cos(yaw);
        double x = forward * -sin + strafe * cos;
        double z = forward * cos + strafe * sin;
        return new double[]{x * speed, z * speed};
    }
}

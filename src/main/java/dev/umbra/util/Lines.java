package dev.umbra.util;

import com.mojang.blaze3d.vertex.PoseStack;
import com.mojang.blaze3d.vertex.VertexConsumer;
import net.minecraft.world.phys.AABB;
import net.minecraft.world.phys.Vec3;

/**
 * Draws world-space lines into the frame's shared line buffer. Callers pass absolute world
 * coordinates; this class subtracts the camera position.
 */
public final class Lines {
    private final PoseStack.Pose pose;
    private final VertexConsumer buffer;
    public final Vec3 camera;
    public final float partialTick;

    public Lines(PoseStack.Pose pose, VertexConsumer buffer, Vec3 camera, float partialTick) {
        this.pose = pose;
        this.buffer = buffer;
        this.camera = camera;
        this.partialTick = partialTick;
    }

    /** Line between two absolute world positions. Color is ARGB. */
    public void line(double ax, double ay, double az, double bx, double by, double bz, int color) {
        rawLine(ax - camera.x, ay - camera.y, az - camera.z, bx - camera.x, by - camera.y, bz - camera.z, color);
    }

    public void line(Vec3 a, Vec3 b, int color) {
        line(a.x, a.y, a.z, b.x, b.y, b.z, color);
    }

    /** Line in camera-relative coordinates (0,0,0 is the eye). */
    public void rawLine(double ax, double ay, double az, double bx, double by, double bz, int color) {
        int a = (color >>> 24) & 0xFF, r = (color >> 16) & 0xFF, g = (color >> 8) & 0xFF, b = color & 0xFF;
        float nx = (float) (bx - ax), ny = (float) (by - ay), nz = (float) (bz - az);
        float len = (float) Math.sqrt(nx * nx + ny * ny + nz * nz);
        if (len > 1.0e-4f) {
            nx /= len;
            ny /= len;
            nz /= len;
        }
        buffer.addVertex(pose, (float) ax, (float) ay, (float) az).setColor(r, g, b, a).setNormal(pose, nx, ny, nz).setLineWidth(1.5f);
        buffer.addVertex(pose, (float) bx, (float) by, (float) bz).setColor(r, g, b, a).setNormal(pose, nx, ny, nz).setLineWidth(1.5f);
    }

    /** Outline of a box given in absolute world coordinates. */
    public void box(AABB w, int color) {
        line(w.minX, w.minY, w.minZ, w.maxX, w.minY, w.minZ, color);
        line(w.maxX, w.minY, w.minZ, w.maxX, w.minY, w.maxZ, color);
        line(w.maxX, w.minY, w.maxZ, w.minX, w.minY, w.maxZ, color);
        line(w.minX, w.minY, w.maxZ, w.minX, w.minY, w.minZ, color);
        line(w.minX, w.maxY, w.minZ, w.maxX, w.maxY, w.minZ, color);
        line(w.maxX, w.maxY, w.minZ, w.maxX, w.maxY, w.maxZ, color);
        line(w.maxX, w.maxY, w.maxZ, w.minX, w.maxY, w.maxZ, color);
        line(w.minX, w.maxY, w.maxZ, w.minX, w.maxY, w.minZ, color);
        line(w.minX, w.minY, w.minZ, w.minX, w.maxY, w.minZ, color);
        line(w.maxX, w.minY, w.minZ, w.maxX, w.maxY, w.minZ, color);
        line(w.maxX, w.minY, w.maxZ, w.maxX, w.maxY, w.maxZ, color);
        line(w.minX, w.minY, w.maxZ, w.minX, w.maxY, w.maxZ, color);
    }
}

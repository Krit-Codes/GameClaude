package dev.umbra.module.render;

import dev.umbra.module.Category;
import dev.umbra.module.Module;
import dev.umbra.setting.BoolSetting;
import dev.umbra.setting.NumberSetting;
import dev.umbra.util.Lines;
import dev.umbra.util.WorldUtil;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.phys.Vec3;

public class Tracers extends Module {
    private final BoolSetting players = bool("Players", "Lines to players", true);
    private final BoolSetting hostiles = bool("Hostiles", "Lines to hostile mobs", false);
    private final BoolSetting passives = bool("Passives", "Lines to passive mobs", false);
    private final BoolSetting items = bool("Items", "Lines to dropped items", false);
    private final BoolSetting crystals = bool("Crystals", "Lines to end crystals", false);
    private final NumberSetting range = number("Range", "Max distance", 512, 16, 1024, 16);

    public Tracers() {
        super("Tracers", Category.RENDER, "Draws lines from your crosshair to entities");
    }

    @Override
    public void onRenderLines(Lines lines) {
        // Start a little in front of the camera so the line converges on the crosshair.
        Vec3 look = mc.player.getViewVector(lines.partialTick);
        double sx = look.x * 0.5, sy = look.y * 0.5, sz = look.z * 0.5;
        double max = range.get() * range.get();
        for (Entity e : mc.level.entitiesForRendering()) {
            if (e == mc.player) continue;
            if (e.distanceToSqr(mc.player) > max) continue;
            int color = EntityColors.of(e, players.get(), hostiles.get(), passives.get(), items.get(), crystals.get());
            if (color == 0) continue;
            Vec3 p = WorldUtil.lerpPos(e, lines.partialTick).add(0, e.getBbHeight() / 2, 0);
            lines.rawLine(sx, sy, sz, p.x - lines.camera.x, p.y - lines.camera.y, p.z - lines.camera.z, color);
        }
    }
}

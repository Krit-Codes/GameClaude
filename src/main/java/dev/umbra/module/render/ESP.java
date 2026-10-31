package dev.umbra.module.render;

import dev.umbra.module.Category;
import dev.umbra.module.Module;
import dev.umbra.setting.BoolSetting;
import dev.umbra.setting.NumberSetting;
import dev.umbra.util.Lines;
import dev.umbra.util.WorldUtil;
import net.minecraft.world.entity.Entity;

public class ESP extends Module {
    private final BoolSetting players = bool("Players", "Show players (friends in green)", true);
    private final BoolSetting hostiles = bool("Hostiles", "Show hostile mobs", true);
    private final BoolSetting passives = bool("Passives", "Show passive mobs", false);
    private final BoolSetting items = bool("Items", "Show dropped items", true);
    private final BoolSetting crystals = bool("Crystals", "Show end crystals", true);
    private final NumberSetting range = number("Range", "Max distance", 256, 16, 512, 16);

    public ESP() {
        super("ESP", Category.RENDER, "Draws boxes around entities through walls");
    }

    @Override
    public void onRenderLines(Lines lines) {
        double max = range.get() * range.get();
        for (Entity e : mc.level.entitiesForRendering()) {
            if (e == mc.player && mc.options.getCameraType().isFirstPerson()) continue;
            if (e.distanceToSqr(mc.player) > max) continue;
            int color = EntityColors.of(e, players.get(), hostiles.get(), passives.get(), items.get(), crystals.get());
            if (color == 0) continue;
            lines.box(WorldUtil.lerpBox(e, lines.partialTick), color);
        }
    }
}

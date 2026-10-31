package dev.umbra.module.player;

import dev.umbra.module.Category;
import dev.umbra.module.Module;
import dev.umbra.setting.BoolSetting;
import dev.umbra.util.ChatUtil;
import net.minecraft.client.gui.screens.DeathScreen;

public class AutoRespawn extends Module {
    private final BoolSetting coords = bool("DeathCoords", "Print where you died in chat", true);

    public AutoRespawn() {
        super("AutoRespawn", Category.PLAYER, "Respawns instantly after death");
    }

    @Override
    public void onTick() {
        if (!(mc.gui.screen() instanceof DeathScreen)) return;
        if (coords.get()) {
            ChatUtil.info("You died at " + mc.player.getBlockX() + " " + mc.player.getBlockY() + " " + mc.player.getBlockZ()
                    + " in " + mc.level.dimension().identifier().getPath());
        }
        mc.player.respawn();
        mc.gui.setScreen(null);
    }
}

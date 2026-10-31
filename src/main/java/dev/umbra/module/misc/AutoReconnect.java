package dev.umbra.module.misc;

import dev.umbra.module.Category;
import dev.umbra.module.Module;
import dev.umbra.setting.NumberSetting;
import net.fabricmc.fabric.api.client.networking.v1.ClientPlayConnectionEvents;
import net.minecraft.client.gui.screens.ConnectScreen;
import net.minecraft.client.gui.screens.DisconnectedScreen;
import net.minecraft.client.gui.screens.TitleScreen;
import net.minecraft.client.multiplayer.ServerData;
import net.minecraft.client.multiplayer.resolver.ServerAddress;

public class AutoReconnect extends Module {
    private final NumberSetting delay = number("Delay", "Seconds to wait before reconnecting", 5, 1, 120, 1);

    private ServerData lastServer;
    private int ticks;

    public AutoReconnect() {
        super("AutoReconnect", Category.MISC, "Reconnects to the server after you get kicked");
        // Remember the server even while the module is off, so turning it on after a kick works.
        ClientPlayConnectionEvents.JOIN.register((handler, sender, client) -> {
            if (client.getCurrentServer() != null) lastServer = client.getCurrentServer();
        });
    }

    @Override
    public void onClientTick() {
        if (!(mc.gui.screen() instanceof DisconnectedScreen) || lastServer == null) {
            ticks = 0;
            return;
        }
        if (++ticks < delay.get() * 20) return;
        ticks = 0;
        ConnectScreen.startConnecting(new TitleScreen(), mc, ServerAddress.parseString(lastServer.ip), lastServer, false, null);
    }

    @Override
    public String getInfo() {
        return delay.getInt() + "s";
    }
}

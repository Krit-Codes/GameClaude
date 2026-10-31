package dev.umbra.module.combat;

import dev.umbra.module.Category;
import dev.umbra.module.Module;
import dev.umbra.setting.BoolSetting;
import dev.umbra.setting.NumberSetting;
import dev.umbra.util.Friends;
import net.minecraft.network.chat.Component;
import net.minecraft.network.protocol.common.ClientboundDisconnectPacket;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.Items;

public class AutoLog extends Module {
    private final NumberSetting health = number("Health", "Disconnect at or below this health (0 = off)", 6, 0, 36, 1);
    private final BoolSetting noTotems = bool("NoTotems", "Disconnect when you run out of totems", false);
    private final BoolSetting players = bool("OnPlayer", "Disconnect when a non-friend player enters render distance", false);
    private final BoolSetting toggleOff = bool("ToggleOff", "Turn AutoLog off after it fires (so AutoReconnect doesn't loop)", true);

    public AutoLog() {
        super("AutoLog", Category.COMBAT, "Disconnects automatically when you are in danger");
    }

    @Override
    public void onTick() {
        float hp = mc.player.getHealth() + mc.player.getAbsorptionAmount();
        if (health.get() > 0 && hp <= health.get()) {
            log("Health was " + Math.round(hp));
            return;
        }
        if (noTotems.get()) {
            boolean any = mc.player.getOffhandItem().is(Items.TOTEM_OF_UNDYING);
            for (int i = 0; i < 36 && !any; i++) any = mc.player.getInventory().getItem(i).is(Items.TOTEM_OF_UNDYING);
            if (!any) {
                log("Out of totems");
                return;
            }
        }
        if (players.get()) {
            for (Player p : mc.level.players()) {
                if (p != mc.player && !Friends.isFriend(p)) {
                    log(p.getName().getString() + " entered render distance");
                    return;
                }
            }
        }
    }

    private void log(String reason) {
        if (toggleOff.get()) setEnabled(false);
        mc.player.connection.handleDisconnect(new ClientboundDisconnectPacket(Component.literal("[AutoLog] " + reason)));
    }
}

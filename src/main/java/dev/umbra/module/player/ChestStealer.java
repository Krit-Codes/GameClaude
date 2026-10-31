package dev.umbra.module.player;

import dev.umbra.module.Category;
import dev.umbra.module.Module;
import dev.umbra.setting.BoolSetting;
import dev.umbra.setting.NumberSetting;
import dev.umbra.util.InvUtil;
import net.minecraft.world.inventory.AbstractContainerMenu;
import net.minecraft.world.inventory.ChestMenu;
import net.minecraft.world.inventory.ContainerInput;
import net.minecraft.world.inventory.ShulkerBoxMenu;

public class ChestStealer extends Module {
    private final NumberSetting delay = number("Delay", "Ticks between item moves", 1, 0, 10, 1);
    private final BoolSetting autoClose = bool("AutoClose", "Close the container when it's empty", true);

    private int timer;

    public ChestStealer() {
        super("ChestStealer", Category.PLAYER, "Takes everything out of chests and shulker boxes you open");
    }

    @Override
    public void onTick() {
        AbstractContainerMenu menu = mc.player.containerMenu;
        if (!(menu instanceof ChestMenu) && !(menu instanceof ShulkerBoxMenu)) return;
        if (timer > 0) {
            timer--;
            return;
        }
        // Container slots come first; the last 36 slots are the player's inventory.
        int containerSlots = menu.slots.size() - 36;
        for (int i = 0; i < containerSlots; i++) {
            if (menu.slots.get(i).getItem().isEmpty()) continue;
            InvUtil.clickContainer(menu.containerId, i, 0, ContainerInput.QUICK_MOVE);
            timer = delay.getInt();
            if (timer > 0) return;
        }
        boolean empty = true;
        for (int i = 0; i < containerSlots; i++) if (!menu.slots.get(i).getItem().isEmpty()) empty = false;
        if (empty && autoClose.get() && mc.gui.screen() != null) mc.gui.screen().onClose();
    }
}

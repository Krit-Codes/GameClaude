package dev.umbra.module.player;

import dev.umbra.module.Category;
import dev.umbra.module.Module;
import dev.umbra.setting.NumberSetting;
import dev.umbra.util.InvUtil;
import net.minecraft.client.gui.screens.inventory.AbstractContainerScreen;
import net.minecraft.client.gui.screens.inventory.InventoryScreen;
import net.minecraft.world.inventory.ContainerInput;
import net.minecraft.world.item.ItemStack;

public class AutoReplenish extends Module {
    private final NumberSetting threshold = number("Threshold", "Refill a hotbar stack at or below this count", 16, 1, 63, 1);
    private final NumberSetting delay = number("Delay", "Ticks between refills", 2, 0, 20, 1);
    private int timer;

    public AutoReplenish() {
        super("AutoReplenish", Category.PLAYER, "Refills hotbar stacks from your inventory");
    }

    @Override
    public void onTick() {
        if (timer > 0) {
            timer--;
            return;
        }
        if (mc.gui.screen() instanceof AbstractContainerScreen<?> && !(mc.gui.screen() instanceof InventoryScreen)) return;
        if (!mc.player.containerMenu.getCarried().isEmpty()) return;

        for (int hot = 0; hot < 9; hot++) {
            ItemStack stack = mc.player.getInventory().getItem(hot);
            if (stack.isEmpty() || !stack.isStackable() || stack.getCount() > threshold.getInt()) continue;
            if (stack.getCount() >= stack.getMaxStackSize()) continue;
            for (int inv = 9; inv < 36; inv++) {
                ItemStack source = mc.player.getInventory().getItem(inv);
                if (source.isEmpty() || !ItemStack.isSameItemSameComponents(stack, source)) continue;
                // Pick up the source stack, drop it onto the hotbar stack (merges), put any rest back.
                InvUtil.click(InvUtil.toMenuSlot(inv), 0, ContainerInput.PICKUP);
                InvUtil.click(InvUtil.toMenuSlot(hot), 0, ContainerInput.PICKUP);
                if (!mc.player.containerMenu.getCarried().isEmpty()) InvUtil.click(InvUtil.toMenuSlot(inv), 0, ContainerInput.PICKUP);
                timer = delay.getInt();
                return;
            }
        }
    }
}

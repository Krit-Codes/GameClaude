package dev.umbra.util;

import net.minecraft.client.Minecraft;
import net.minecraft.world.inventory.ContainerInput;
import net.minecraft.world.item.ItemStack;

import java.util.function.Predicate;

/**
 * Inventory helpers. "Inventory index" means the player's Inventory numbering
 * (0-8 hotbar, 9-35 main). "Menu slot" means the slot id inside the player's
 * inventory menu (36-44 hotbar, 9-35 main, 45 offhand).
 */
public final class InvUtil {
    private InvUtil() { }

    private static final Minecraft mc = Minecraft.getInstance();
    public static final int OFFHAND_BUTTON = 40;

    public static int findHotbar(Predicate<ItemStack> filter) {
        for (int i = 0; i < 9; i++) {
            if (filter.test(mc.player.getInventory().getItem(i))) return i;
        }
        return -1;
    }

    public static int findInventory(Predicate<ItemStack> filter) {
        // Search main inventory first so hotbar items stay where the player put them.
        for (int i = 9; i < 36; i++) {
            if (filter.test(mc.player.getInventory().getItem(i))) return i;
        }
        for (int i = 0; i < 9; i++) {
            if (filter.test(mc.player.getInventory().getItem(i))) return i;
        }
        return -1;
    }

    public static int toMenuSlot(int inventoryIndex) {
        return inventoryIndex < 9 ? 36 + inventoryIndex : inventoryIndex;
    }

    public static int selected() {
        return mc.player.getInventory().getSelectedSlot();
    }

    public static void select(int hotbarSlot) {
        if (hotbarSlot >= 0 && hotbarSlot < 9) mc.player.getInventory().setSelectedSlot(hotbarSlot);
    }

    /** Swaps an inventory item into the offhand using the vanilla "F" swap click. */
    public static void swapToOffhand(int inventoryIndex) {
        click(toMenuSlot(inventoryIndex), OFFHAND_BUTTON, ContainerInput.SWAP);
    }

    /** Swaps an inventory item with a hotbar slot. */
    public static void swapToHotbar(int inventoryIndex, int hotbarSlot) {
        click(toMenuSlot(inventoryIndex), hotbarSlot, ContainerInput.SWAP);
    }

    public static void click(int menuSlot, int button, ContainerInput input) {
        if (mc.gameMode == null || mc.player == null) return;
        mc.gameMode.handleContainerInput(mc.player.inventoryMenu.containerId, menuSlot, button, input, mc.player);
    }

    public static void clickContainer(int containerId, int menuSlot, int button, ContainerInput input) {
        if (mc.gameMode == null || mc.player == null) return;
        mc.gameMode.handleContainerInput(containerId, menuSlot, button, input, mc.player);
    }
}

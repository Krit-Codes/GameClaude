package dev.umbra.module.combat;

import dev.umbra.module.Category;
import dev.umbra.module.Module;
import dev.umbra.setting.BoolSetting;
import dev.umbra.setting.NumberSetting;
import dev.umbra.util.InvUtil;
import net.minecraft.client.gui.screens.inventory.AbstractContainerScreen;
import net.minecraft.client.gui.screens.inventory.InventoryScreen;
import net.minecraft.core.component.DataComponents;
import net.minecraft.tags.ItemTags;
import net.minecraft.world.entity.EquipmentSlot;
import net.minecraft.world.inventory.ContainerInput;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.Items;

public class AutoArmor extends Module {
    private static final EquipmentSlot[] SLOTS = {EquipmentSlot.HEAD, EquipmentSlot.CHEST, EquipmentSlot.LEGS, EquipmentSlot.FEET};

    private final BoolSetting elytra = bool("PreferElytra", "Put an elytra in an empty chest slot instead of a chestplate", false);
    private final NumberSetting delay = number("Delay", "Ticks between equips", 2, 0, 20, 1);
    private int timer;

    public AutoArmor() {
        super("AutoArmor", Category.COMBAT, "Equips armor from your inventory into empty armor slots");
    }

    @Override
    public void onTick() {
        if (timer > 0) {
            timer--;
            return;
        }
        if (mc.gui.screen() instanceof AbstractContainerScreen<?> && !(mc.gui.screen() instanceof InventoryScreen)) return;

        for (EquipmentSlot slot : SLOTS) {
            if (!mc.player.getItemBySlot(slot).isEmpty()) continue;
            int found = InvUtil.findInventory(stack -> fits(stack, slot));
            if (found == -1) continue;
            // Shift-clicking armor in the inventory equips it.
            InvUtil.click(InvUtil.toMenuSlot(found), 0, ContainerInput.QUICK_MOVE);
            timer = delay.getInt();
            return;
        }
    }

    private boolean fits(ItemStack stack, EquipmentSlot slot) {
        if (stack.isEmpty() || !stack.has(DataComponents.EQUIPPABLE)) return false;
        if (stack.get(DataComponents.EQUIPPABLE).slot() != slot) return false;
        return switch (slot) {
            case HEAD -> stack.is(ItemTags.HEAD_ARMOR);
            case CHEST -> elytra.get() ? stack.is(Items.ELYTRA) : stack.is(ItemTags.CHEST_ARMOR);
            case LEGS -> stack.is(ItemTags.LEG_ARMOR);
            case FEET -> stack.is(ItemTags.FOOT_ARMOR);
            default -> false;
        };
    }
}

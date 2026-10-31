package dev.umbra.module.combat;

import dev.umbra.module.Category;
import dev.umbra.module.Module;
import dev.umbra.setting.ModeSetting;
import dev.umbra.setting.NumberSetting;
import dev.umbra.util.InvUtil;
import net.minecraft.client.gui.screens.inventory.AbstractContainerScreen;
import net.minecraft.client.gui.screens.inventory.InventoryScreen;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.Items;

public class AutoTotem extends Module {
    private final ModeSetting mode = mode("Mode", "Strict always keeps a totem; Smart holds a crystal/gapple until health drops", "Strict", "Strict", "Smart");
    private final ModeSetting fallback = mode("Fallback", "Offhand item in Smart mode while health is high", "Crystal", "Crystal", "Gapple");
    private final NumberSetting health = number("Health", "Smart mode: switch to totem at or below this health", 14, 1, 36, 1);
    private final NumberSetting delay = number("Delay", "Ticks between swaps", 0, 0, 10, 1);

    private int timer;

    public AutoTotem() {
        super("AutoTotem", Category.COMBAT, "Keeps a totem of undying in your offhand");
    }

    @Override
    public void onTick() {
        if (timer > 0) {
            timer--;
            return;
        }
        // Clicking while another container is open would click that container instead.
        if (mc.gui.screen() instanceof AbstractContainerScreen<?> && !(mc.gui.screen() instanceof InventoryScreen)) return;

        Item wanted = Items.TOTEM_OF_UNDYING;
        if (mode.is("Smart")) {
            float hp = mc.player.getHealth() + mc.player.getAbsorptionAmount();
            boolean falling = mc.player.fallDistance > 10;
            if (hp > health.get() && !falling) wanted = fallback.is("Gapple") ? Items.ENCHANTED_GOLDEN_APPLE : Items.END_CRYSTAL;
        }

        if (mc.player.getOffhandItem().is(wanted)) return;
        final Item find = wanted;
        int slot = InvUtil.findInventory(s -> s.is(find));
        if (slot == -1 && wanted == Items.ENCHANTED_GOLDEN_APPLE) slot = InvUtil.findInventory(s -> s.is(Items.GOLDEN_APPLE));
        if (slot == -1 && wanted != Items.TOTEM_OF_UNDYING) {
            // Fallback item missing: a totem is still better than nothing.
            if (mc.player.getOffhandItem().is(Items.TOTEM_OF_UNDYING)) return;
            slot = InvUtil.findInventory(s -> s.is(Items.TOTEM_OF_UNDYING));
        }
        if (slot == -1) return;
        InvUtil.swapToOffhand(slot);
        timer = delay.getInt();
    }

    @Override
    public String getInfo() {
        if (!inGame()) return null;
        int count = 0;
        for (int i = 0; i < 36; i++) {
            if (mc.player.getInventory().getItem(i).is(Items.TOTEM_OF_UNDYING)) count += mc.player.getInventory().getItem(i).getCount();
        }
        if (mc.player.getOffhandItem().is(Items.TOTEM_OF_UNDYING)) count++;
        return String.valueOf(count);
    }
}

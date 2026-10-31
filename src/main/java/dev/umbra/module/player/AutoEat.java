package dev.umbra.module.player;

import dev.umbra.module.Category;
import dev.umbra.module.Module;
import dev.umbra.setting.BoolSetting;
import dev.umbra.setting.NumberSetting;
import dev.umbra.util.InvUtil;
import net.minecraft.core.component.DataComponents;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.Items;

public class AutoEat extends Module {
    private final NumberSetting hunger = number("Hunger", "Eat when the food bar is at or below this", 16, 1, 19, 1);
    private final BoolSetting gapples = bool("Gapples", "Eat golden apples when health is low", true);
    private final NumberSetting health = number("Health", "Health at which to eat a golden apple", 10, 1, 19, 1);
    private final BoolSetting pauseAuras = bool("PauseCombat", "Skip eating while KillAura has a target", false);

    private int previousSlot = -1;
    private boolean eating;

    public AutoEat() {
        super("AutoEat", Category.PLAYER, "Eats automatically when hungry or hurt");
    }

    @Override
    public void onDisable() {
        stop();
    }

    @Override
    public void onTick() {
        boolean lowHealth = gapples.get() && mc.player.getHealth() <= health.get();
        boolean hungry = mc.player.getFoodData().getFoodLevel() <= hunger.getInt();

        if (eating) {
            ItemStack held = mc.player.getMainHandItem();
            boolean stillWant = (hungry || lowHealth) && isFood(held, lowHealth);
            if (!stillWant) {
                stop();
                return;
            }
            mc.options.keyUse.setDown(true);
            return;
        }

        if (!hungry && !lowHealth) return;
        if (mc.gui.screen() != null) return;
        if (pauseAuras.get() && dev.umbra.Umbra.MODULES.get(dev.umbra.module.combat.KillAura.class).getInfo() != null) return;

        int slot = -1;
        if (lowHealth) slot = InvUtil.findHotbar(s -> s.is(Items.ENCHANTED_GOLDEN_APPLE) || s.is(Items.GOLDEN_APPLE));
        if (slot == -1 && hungry) slot = InvUtil.findHotbar(s -> isFood(s, false));
        if (slot == -1) return;

        previousSlot = InvUtil.selected();
        InvUtil.select(slot);
        mc.options.keyUse.setDown(true);
        eating = true;
    }

    private boolean isFood(ItemStack s, boolean allowGapple) {
        if (s.isEmpty() || !s.has(DataComponents.FOOD)) return false;
        // Avoid foods with bad side effects (chorus fruit teleports you).
        if (s.is(Items.CHORUS_FRUIT) || s.is(Items.ROTTEN_FLESH) || s.is(Items.SPIDER_EYE) || s.is(Items.POISONOUS_POTATO)
                || s.is(Items.PUFFERFISH) || s.is(Items.SUSPICIOUS_STEW)) return false;
        if (!allowGapple && (s.is(Items.ENCHANTED_GOLDEN_APPLE))) return false;
        return true;
    }

    private void stop() {
        if (eating) {
            mc.options.keyUse.setDown(false);
            if (previousSlot != -1 && mc.player != null) InvUtil.select(previousSlot);
        }
        eating = false;
        previousSlot = -1;
    }

    @Override
    public String getInfo() {
        return eating ? "Eating" : null;
    }
}

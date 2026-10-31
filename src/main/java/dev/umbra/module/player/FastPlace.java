package dev.umbra.module.player;

import dev.umbra.mixin.MinecraftAccessor;
import dev.umbra.module.Category;
import dev.umbra.module.Module;
import dev.umbra.setting.ModeSetting;
import net.minecraft.world.item.BlockItem;
import net.minecraft.world.item.Items;

public class FastPlace extends Module {
    private final ModeSetting items = mode("Items", "Which held items get no use delay", "All", "All", "Blocks", "Crystals", "XP");

    public FastPlace() {
        super("FastPlace", Category.PLAYER, "Removes the delay between right clicks");
    }

    @Override
    public void onTick() {
        var held = mc.player.getMainHandItem();
        boolean apply = switch (items.get()) {
            case "Blocks" -> held.getItem() instanceof BlockItem;
            case "Crystals" -> held.is(Items.END_CRYSTAL) || mc.player.getOffhandItem().is(Items.END_CRYSTAL);
            case "XP" -> held.is(Items.EXPERIENCE_BOTTLE);
            default -> true;
        };
        if (apply) ((MinecraftAccessor) mc).umbra$setRightClickDelay(0);
    }

    @Override
    public String getInfo() {
        return items.get();
    }
}

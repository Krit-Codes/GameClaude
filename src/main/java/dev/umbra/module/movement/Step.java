package dev.umbra.module.movement;

import dev.umbra.module.Category;
import dev.umbra.module.Module;
import dev.umbra.setting.NumberSetting;
import net.minecraft.world.entity.ai.attributes.AttributeInstance;
import net.minecraft.world.entity.ai.attributes.Attributes;

public class Step extends Module {
    private final NumberSetting height = number("Height", "Max step height in blocks", 2, 0.6, 10, 0.5);
    private static final double VANILLA = 0.6;

    public Step() {
        super("Step", Category.MOVEMENT, "Walk straight up full blocks");
    }

    @Override
    public void onTick() {
        AttributeInstance attr = mc.player.getAttribute(Attributes.STEP_HEIGHT);
        if (attr != null && attr.getBaseValue() != height.get()) attr.setBaseValue(height.get());
    }

    @Override
    public void onDisable() {
        if (!inGame()) return;
        AttributeInstance attr = mc.player.getAttribute(Attributes.STEP_HEIGHT);
        if (attr != null) attr.setBaseValue(VANILLA);
    }

    @Override
    public String getInfo() {
        return height.display();
    }
}

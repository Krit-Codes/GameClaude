package dev.umbra.module.movement;

import dev.umbra.module.Category;
import dev.umbra.module.Module;
import dev.umbra.setting.BoolSetting;

public class Sprint extends Module {
    private final BoolSetting omni = bool("AllDirections", "Sprint sideways and backwards too", false);

    public Sprint() {
        super("Sprint", Category.MOVEMENT, "Always sprint");
    }

    @Override
    public void onTick() {
        if (mc.player.isShiftKeyDown() || mc.player.getFoodData().getFoodLevel() <= 6 || mc.player.horizontalCollision) return;
        var in = mc.player.input.getMoveVector();
        boolean moving = omni.get() ? (in.x != 0 || in.y != 0) : in.y > 0;
        if (moving && !mc.player.isSprinting()) mc.player.setSprinting(true);
    }
}

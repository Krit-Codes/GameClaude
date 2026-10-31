package dev.umbra.module.movement;

import dev.umbra.module.Category;
import dev.umbra.module.Module;
import dev.umbra.setting.BoolSetting;
import net.minecraft.core.BlockPos;

public class Jesus extends Module {
    private final BoolSetting lava = bool("Lava", "Also walk on lava", true);

    public Jesus() {
        super("Jesus", Category.MOVEMENT, "Walk on water and lava");
    }

    @Override
    public void onTick() {
        if (mc.player.isShiftKeyDown() || mc.player.getAbilities().flying || mc.player.isFallFlying()) return;
        boolean inFluid = mc.player.isInWater() || (lava.get() && mc.player.isInLava());
        var v = mc.player.getDeltaMovement();
        if (inFluid) {
            // Push up to the surface.
            mc.player.setDeltaMovement(v.x, 0.11, v.z);
            return;
        }
        // Standing just above a fluid surface: cancel the fall so we stay on top.
        BlockPos below = BlockPos.containing(mc.player.getX(), mc.player.getY() - 0.05, mc.player.getZ());
        var fluid = mc.level.getFluidState(below);
        boolean surface = !fluid.isEmpty() && (lava.get() || !fluid.is(net.minecraft.tags.FluidTags.LAVA));
        if (surface && v.y < 0 && mc.player.getY() - below.getY() < 1.15) {
            mc.player.setDeltaMovement(v.x, 0, v.z);
            mc.player.setOnGround(true);
            mc.player.fallDistance = 0;
        }
    }
}

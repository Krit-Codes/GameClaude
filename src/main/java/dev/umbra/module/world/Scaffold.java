package dev.umbra.module.world;

import dev.umbra.module.Category;
import dev.umbra.module.Module;
import dev.umbra.setting.BoolSetting;
import dev.umbra.setting.NumberSetting;
import dev.umbra.util.InvUtil;
import dev.umbra.util.WorldUtil;
import net.minecraft.core.BlockPos;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.item.BlockItem;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.block.FallingBlock;

public class Scaffold extends Module {
    private final BoolSetting tower = bool("Tower", "Hold jump while standing still to pillar up fast", true);
    private final BoolSetting rotate = bool("Rotate", "Send look packets when placing", true);
    private final NumberSetting extend = number("Extend", "Also place this many blocks ahead in your movement direction", 0, 0, 4, 1);
    private final BoolSetting switchBack = bool("SwitchBack", "Return to your previous hotbar slot after placing", true);

    public Scaffold() {
        super("Scaffold", Category.WORLD, "Places blocks under your feet as you walk");
    }

    private static boolean usable(ItemStack s) {
        if (!(s.getItem() instanceof BlockItem bi)) return false;
        // Sand/gravel fall and are useless as a bridge.
        return !(bi.getBlock() instanceof FallingBlock) && bi.getBlock().defaultBlockState().isCollisionShapeFullBlock(mc.level, BlockPos.ZERO);
    }

    @Override
    public void onTick() {
        int slot = InvUtil.findHotbar(Scaffold::usable);
        if (slot == -1) return;
        int prev = InvUtil.selected();

        BlockPos under = BlockPos.containing(mc.player.getX(), mc.player.getY() - 0.5, mc.player.getZ());
        boolean placed = false;
        InvUtil.select(slot);
        if (WorldUtil.isReplaceable(under)) placed = WorldUtil.place(under, InteractionHand.MAIN_HAND, rotate.get());

        var v = mc.player.getDeltaMovement();
        double hSpeed = Math.hypot(v.x, v.z);
        for (int i = 1; i <= extend.getInt() && hSpeed > 0.01; i++) {
            BlockPos ahead = BlockPos.containing(mc.player.getX() + v.x / hSpeed * i, mc.player.getY() - 0.5, mc.player.getZ() + v.z / hSpeed * i);
            if (WorldUtil.isReplaceable(ahead)) WorldUtil.place(ahead, InteractionHand.MAIN_HAND, rotate.get());
        }

        if (tower.get() && mc.options.keyJump.isDown() && hSpeed < 0.05 && placed) {
            mc.player.setDeltaMovement(v.x, 0.42, v.z);
        }
        if (switchBack.get()) InvUtil.select(prev);
    }
}

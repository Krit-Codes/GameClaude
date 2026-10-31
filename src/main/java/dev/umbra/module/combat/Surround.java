package dev.umbra.module.combat;

import dev.umbra.module.Category;
import dev.umbra.module.Module;
import dev.umbra.setting.BoolSetting;
import dev.umbra.setting.NumberSetting;
import dev.umbra.util.ChatUtil;
import dev.umbra.util.InvUtil;
import dev.umbra.util.WorldUtil;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.item.Items;

public class Surround extends Module {
    private final NumberSetting blocksPerTick = number("BlocksPerTick", "Blocks placed per tick", 4, 1, 8, 1);
    private final BoolSetting center = bool("Center", "Snap to the middle of the block when enabled", true);
    private final BoolSetting disableOnJump = bool("DisableOnJump", "Turn off when you move up", true);
    private final BoolSetting rotate = bool("Rotate", "Send look packets when placing", true);

    private double startY;

    public Surround() {
        super("Surround", Category.COMBAT, "Surrounds your feet with obsidian to block crystal damage");
    }

    @Override
    public void onEnable() {
        if (!inGame()) return;
        startY = mc.player.getY();
        if (center.get()) {
            BlockPos p = mc.player.blockPosition();
            mc.player.setPos(p.getX() + 0.5, mc.player.getY(), p.getZ() + 0.5);
            mc.player.setDeltaMovement(0, mc.player.getDeltaMovement().y, 0);
        }
    }

    @Override
    public void onTick() {
        if (disableOnJump.get() && mc.player.getY() > startY + 0.5) {
            setEnabled(false);
            return;
        }
        int slot = InvUtil.findHotbar(s -> s.is(Items.OBSIDIAN) || s.is(Items.CRYING_OBSIDIAN) || s.is(Items.ENDER_CHEST));
        if (slot == -1) {
            ChatUtil.error("Surround: no obsidian in hotbar");
            setEnabled(false);
            return;
        }

        BlockPos feet = BlockPos.containing(mc.player.getX(), mc.player.getY() + 0.2, mc.player.getZ());
        int placed = 0;
        int prev = InvUtil.selected();
        for (Direction dir : Direction.Plane.HORIZONTAL) {
            if (placed >= blocksPerTick.getInt()) break;
            BlockPos pos = feet.relative(dir);
            if (!WorldUtil.isReplaceable(pos)) continue;
            if (!WorldUtil.isFreeOfEntities(pos)) continue;
            // If there's nothing to click on, support it from below first.
            BlockPos below = pos.below();
            InvUtil.select(slot);
            if (WorldUtil.isReplaceable(below) && WorldUtil.place(below, InteractionHand.MAIN_HAND, rotate.get())) placed++;
            if (placed < blocksPerTick.getInt() && WorldUtil.place(pos, InteractionHand.MAIN_HAND, rotate.get())) placed++;
        }
        InvUtil.select(prev);
    }
}

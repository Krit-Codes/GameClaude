package dev.umbra.module.world;

import dev.umbra.module.Category;
import dev.umbra.module.Module;
import dev.umbra.setting.BoolSetting;
import dev.umbra.setting.ModeSetting;
import dev.umbra.setting.NumberSetting;
import dev.umbra.util.Lines;
import dev.umbra.util.WorldUtil;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.level.block.state.BlockState;

public class Nuker extends Module {
    private final ModeSetting mode = mode("Mode", "All: everything in range. Flatten: only at or above your feet. Smash: only instant-break blocks.", "Flatten", "All", "Flatten", "Smash");
    private final NumberSetting range = number("Range", "Reach in blocks", 4.5, 1, 6, 0.5);
    private final NumberSetting perTick = number("PerTick", "Blocks broken per tick in creative / Smash mode", 4, 1, 32, 1);
    private final BoolSetting rotate = bool("Rotate", "Send look packets", false);
    private final BoolSetting render = bool("Render", "Outline the block being mined", true);

    private BlockPos current;

    public Nuker() {
        super("Nuker", Category.WORLD, "Breaks blocks around you");
    }

    @Override
    public void onDisable() {
        current = null;
    }

    @Override
    public void onTick() {
        if (mc.gui.screen() != null) return;
        boolean instant = mc.player.isCreative() || mode.is("Smash");
        int r = (int) Math.ceil(range.get());
        BlockPos feet = mc.player.blockPosition();

        // Keep mining the current block if it's still valid.
        if (!instant && current != null && valid(current, feet)) {
            mine(current);
            return;
        }
        current = null;

        int broken = 0;
        BlockPos best = null;
        double bestDist = Double.MAX_VALUE;
        for (int x = -r; x <= r; x++) {
            for (int y = -r; y <= r; y++) {
                for (int z = -r; z <= r; z++) {
                    BlockPos pos = feet.offset(x, y, z);
                    if (!valid(pos, feet)) continue;
                    double d = WorldUtil.distanceTo(pos);
                    if (instant) {
                        if (mode.is("Smash") && !mc.player.isCreative() && mc.level.getBlockState(pos).getDestroySpeed(mc.level, pos) != 0) continue;
                        if (rotate.get()) WorldUtil.silentLook(net.minecraft.world.phys.Vec3.atCenterOf(pos));
                        mc.gameMode.startDestroyBlock(pos, Direction.UP);
                        mc.player.swing(InteractionHand.MAIN_HAND);
                        if (++broken >= perTick.getInt()) return;
                    } else if (d < bestDist) {
                        bestDist = d;
                        best = pos;
                    }
                }
            }
        }
        if (best != null) {
            current = best.immutable();
            mine(current);
        }
    }

    private boolean valid(BlockPos pos, BlockPos feet) {
        if (WorldUtil.distanceTo(pos) > range.get()) return false;
        if (mode.is("Flatten") && pos.getY() < feet.getY()) return false;
        BlockState state = mc.level.getBlockState(pos);
        if (state.isAir() || !state.getFluidState().isEmpty()) return false;
        return state.getDestroySpeed(mc.level, pos) >= 0;
    }

    private void mine(BlockPos pos) {
        if (rotate.get()) WorldUtil.silentLook(net.minecraft.world.phys.Vec3.atCenterOf(pos));
        mc.gameMode.continueDestroyBlock(pos, Direction.UP);
        mc.player.swing(InteractionHand.MAIN_HAND);
    }

    @Override
    public void onRenderLines(Lines lines) {
        if (render.get() && current != null) lines.box(WorldUtil.blockBox(current), 0xFFFF5050);
    }
}

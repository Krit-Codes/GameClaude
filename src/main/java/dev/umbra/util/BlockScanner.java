package dev.umbra.util;

import net.minecraft.client.Minecraft;
import net.minecraft.core.BlockPos;
import net.minecraft.world.level.block.state.BlockState;

import java.util.HashMap;
import java.util.Map;
import java.util.function.ToIntFunction;

/**
 * Scans a cube around the player a slice at a time so a full scan is spread over many ticks
 * instead of freezing one frame. Results map positions to an ARGB color.
 */
public final class BlockScanner {
    private final Minecraft mc = Minecraft.getInstance();
    private final ToIntFunction<BlockState> colorOf;

    private Map<BlockPos, Integer> results = new HashMap<>();
    private Map<BlockPos, Integer> pending = new HashMap<>();
    private BlockPos center;
    private int sliceX;
    private int radius;

    /** colorOf returns 0 for blocks that should not be shown. */
    public BlockScanner(ToIntFunction<BlockState> colorOf) {
        this.colorOf = colorOf;
    }

    public void reset() {
        results = new HashMap<>();
        pending = new HashMap<>();
        center = null;
    }

    public Map<BlockPos, Integer> results() {
        return results;
    }

    /** Scans `slicesPerTick` x-slices of the cube; call every tick. */
    public void tick(int radius, int vertical, int slicesPerTick) {
        if (mc.player == null || mc.level == null) return;
        if (center == null || radius != this.radius) {
            center = mc.player.blockPosition();
            this.radius = radius;
            sliceX = -radius;
        }
        int minY = Math.max(mc.level.getMinY(), center.getY() - vertical);
        int maxY = Math.min(mc.level.getMinY() + mc.level.getHeight() - 1, center.getY() + vertical);
        BlockPos.MutableBlockPos pos = new BlockPos.MutableBlockPos();

        for (int s = 0; s < slicesPerTick; s++) {
            int x = center.getX() + sliceX;
            for (int z = center.getZ() - radius; z <= center.getZ() + radius; z++) {
                for (int y = minY; y <= maxY; y++) {
                    pos.set(x, y, z);
                    int color = colorOf.applyAsInt(mc.level.getBlockState(pos));
                    if (color != 0) pending.put(pos.immutable(), color);
                }
            }
            sliceX++;
            if (sliceX > radius) {
                // Finished a full pass: publish it and restart around the player's new position.
                results = pending;
                pending = new HashMap<>();
                center = mc.player.blockPosition();
                sliceX = -radius;
                return;
            }
        }
    }
}

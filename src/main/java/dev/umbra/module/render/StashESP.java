package dev.umbra.module.render;

import dev.umbra.module.Category;
import dev.umbra.module.Module;
import dev.umbra.setting.BoolSetting;
import dev.umbra.setting.NumberSetting;
import dev.umbra.util.ChatUtil;
import dev.umbra.util.Lines;
import dev.umbra.util.WorldUtil;
import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientBlockEntityEvents;
import net.fabricmc.fabric.api.client.networking.v1.ClientPlayConnectionEvents;
import net.minecraft.core.BlockPos;
import net.minecraft.world.level.block.ShulkerBoxBlock;
import net.minecraft.world.level.block.Blocks;
import net.minecraft.world.level.block.state.BlockState;

import java.util.HashSet;
import java.util.Set;

/** Outlines storage blocks (chests, shulkers, ender chests, barrels) loaded around you. */
public class StashESP extends Module {
    private final BoolSetting chests = bool("Chests", "Chests and trapped chests", true);
    private final BoolSetting shulkers = bool("Shulkers", "Shulker boxes", true);
    private final BoolSetting enderChests = bool("EnderChests", "Ender chests", true);
    private final BoolSetting barrels = bool("Barrels", "Barrels", true);
    private final BoolSetting other = bool("Other", "Hoppers, dispensers, droppers, furnaces", false);
    private final NumberSetting alert = number("StashAlert", "Chat alert when this many storage blocks are loaded (0 = off)", 30, 0, 500, 5);

    /** Tracked whether or not the module is on, so enabling it shows chunks that were already loaded. */
    private static final Set<BlockPos> STORAGE = new HashSet<>();
    private boolean alerted;

    public StashESP() {
        super("StashESP", Category.RENDER, "Highlights chests, shulkers and other storage; finds stashes");
        ClientBlockEntityEvents.BLOCK_ENTITY_LOAD.register((be, level) -> STORAGE.add(be.getBlockPos().immutable()));
        ClientBlockEntityEvents.BLOCK_ENTITY_UNLOAD.register((be, level) -> STORAGE.remove(be.getBlockPos()));
        ClientPlayConnectionEvents.DISCONNECT.register((handler, client) -> STORAGE.clear());
    }

    @Override
    public void onJoin() {
        alerted = false;
    }

    private int colorOf(BlockState s) {
        if (chests.get() && (s.is(Blocks.CHEST) || s.is(Blocks.TRAPPED_CHEST))) return 0xFFFFA020;
        if (shulkers.get() && s.getBlock() instanceof ShulkerBoxBlock) return 0xFFFF60C0;
        if (enderChests.get() && s.is(Blocks.ENDER_CHEST)) return 0xFF9040FF;
        if (barrels.get() && s.is(Blocks.BARREL)) return 0xFFB07030;
        if (other.get() && (s.is(Blocks.HOPPER) || s.is(Blocks.DISPENSER) || s.is(Blocks.DROPPER) || s.is(Blocks.FURNACE)
                || s.is(Blocks.BLAST_FURNACE) || s.is(Blocks.SMOKER))) return 0xFF909090;
        return 0;
    }

    @Override
    public void onTick() {
        if (alert.getInt() <= 0) return;
        int count = 0;
        for (BlockPos p : STORAGE) if (colorOf(mc.level.getBlockState(p)) != 0) count++;
        if (count >= alert.getInt() && !alerted) {
            alerted = true;
            ChatUtil.success("StashESP: " + count + " storage blocks loaded near " + mc.player.getBlockX() + " " + mc.player.getBlockZ());
        } else if (count < alert.getInt() / 2) {
            alerted = false;
        }
    }

    @Override
    public void onRenderLines(Lines lines) {
        for (BlockPos p : STORAGE) {
            int c = colorOf(mc.level.getBlockState(p));
            if (c != 0) lines.box(WorldUtil.blockBox(p), c);
        }
    }

    @Override
    public String getInfo() {
        return String.valueOf(STORAGE.size());
    }
}

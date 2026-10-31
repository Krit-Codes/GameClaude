package dev.umbra.module.render;

import dev.umbra.module.Category;
import dev.umbra.module.Module;
import dev.umbra.setting.BoolSetting;
import dev.umbra.setting.NumberSetting;
import dev.umbra.util.BlockScanner;
import dev.umbra.util.Lines;
import dev.umbra.util.WorldUtil;
import net.minecraft.core.BlockPos;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.Blocks;
import net.minecraft.world.level.block.state.BlockState;

import java.util.Map;

/**
 * Ore finder: outlines ores through walls. Note: anarchy servers like 2b2t run anti-xray,
 * which hides buried ores from the client, so this mainly finds exposed ores in caves.
 */
public class XRay extends Module {
    private final BoolSetting diamond = bool("Diamond", "Diamond ore", true);
    private final BoolSetting debris = bool("AncientDebris", "Ancient debris", true);
    private final BoolSetting emerald = bool("Emerald", "Emerald ore", false);
    private final BoolSetting gold = bool("Gold", "Gold and nether gold ore", false);
    private final BoolSetting iron = bool("Iron", "Iron ore", false);
    private final BoolSetting redstone = bool("Redstone", "Redstone ore", false);
    private final BoolSetting lapis = bool("Lapis", "Lapis ore", false);
    private final BoolSetting coal = bool("Coal", "Coal ore", false);
    private final BoolSetting spawners = bool("Spawners", "Mob spawners", true);
    private final NumberSetting radius = number("Radius", "Horizontal scan radius", 32, 8, 64, 8);
    private final NumberSetting vertical = number("Vertical", "Vertical scan range above/below you", 32, 8, 128, 8);
    private final NumberSetting speed = number("ScanSpeed", "Slices scanned per tick (higher = faster, heavier)", 2, 1, 16, 1);

    private final BlockScanner scanner = new BlockScanner(this::colorOf);

    public XRay() {
        super("XRay", Category.RENDER, "Highlights ores and spawners through walls");
    }

    private int colorOf(BlockState s) {
        Block b = s.getBlock();
        if (diamond.get() && (b == Blocks.DIAMOND_ORE || b == Blocks.DEEPSLATE_DIAMOND_ORE)) return 0xFF40E0FF;
        if (debris.get() && b == Blocks.ANCIENT_DEBRIS) return 0xFF8B5A2B;
        if (emerald.get() && (b == Blocks.EMERALD_ORE || b == Blocks.DEEPSLATE_EMERALD_ORE)) return 0xFF20E060;
        if (gold.get() && (b == Blocks.GOLD_ORE || b == Blocks.DEEPSLATE_GOLD_ORE || b == Blocks.NETHER_GOLD_ORE)) return 0xFFFFD700;
        if (iron.get() && (b == Blocks.IRON_ORE || b == Blocks.DEEPSLATE_IRON_ORE)) return 0xFFD8AF93;
        if (redstone.get() && (b == Blocks.REDSTONE_ORE || b == Blocks.DEEPSLATE_REDSTONE_ORE)) return 0xFFFF2020;
        if (lapis.get() && (b == Blocks.LAPIS_ORE || b == Blocks.DEEPSLATE_LAPIS_ORE)) return 0xFF2050FF;
        if (coal.get() && (b == Blocks.COAL_ORE || b == Blocks.DEEPSLATE_COAL_ORE)) return 0xFF404040;
        if (spawners.get() && b == Blocks.SPAWNER) return 0xFFFF40FF;
        return 0;
    }

    @Override
    public void onEnable() {
        scanner.reset();
    }

    @Override
    public void onJoin() {
        scanner.reset();
    }

    @Override
    public void onTick() {
        scanner.tick(radius.getInt(), vertical.getInt(), speed.getInt());
    }

    @Override
    public void onRenderLines(Lines lines) {
        for (Map.Entry<BlockPos, Integer> e : scanner.results().entrySet()) {
            // Skip blocks that were mined since the last scan.
            if (colorOf(mc.level.getBlockState(e.getKey())) == 0) continue;
            lines.box(WorldUtil.blockBox(e.getKey()), e.getValue());
        }
    }

    @Override
    public String getInfo() {
        return String.valueOf(scanner.results().size());
    }
}

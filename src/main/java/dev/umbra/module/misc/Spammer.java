package dev.umbra.module.misc;

import dev.umbra.module.Category;
import dev.umbra.module.Module;
import dev.umbra.setting.BoolSetting;
import dev.umbra.setting.NumberSetting;
import dev.umbra.util.ChatUtil;
import net.fabricmc.loader.api.FabricLoader;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ThreadLocalRandom;

/** Sends lines from config/umbra/spammer.txt on a timer. */
public class Spammer extends Module {
    private final NumberSetting delay = number("Delay", "Seconds between messages", 10, 1, 300, 1);
    private final BoolSetting random = bool("Random", "Pick lines at random instead of in order", true);
    private final BoolSetting antiFilter = bool("AntiFilter", "Append a short random suffix so repeat filters don't block it", true);

    private static final Path FILE = FabricLoader.getInstance().getConfigDir().resolve("umbra").resolve("spammer.txt");
    private List<String> lines = new ArrayList<>();
    private int index, ticks;

    public Spammer() {
        super("Spammer", Category.MISC, "Repeats chat messages from config/umbra/spammer.txt");
    }

    @Override
    public void onEnable() {
        try {
            if (!Files.exists(FILE)) {
                Files.createDirectories(FILE.getParent());
                Files.writeString(FILE, "Umbra on top\n", StandardCharsets.UTF_8);
            }
            lines = new ArrayList<>();
            for (String l : Files.readAllLines(FILE, StandardCharsets.UTF_8)) if (!l.isBlank()) lines.add(l.trim());
        } catch (IOException e) {
            ChatUtil.error("Spammer: could not read " + FILE);
        }
        index = 0;
        ticks = 0;
        if (lines.isEmpty()) {
            ChatUtil.error("Spammer: " + FILE + " is empty");
        }
    }

    @Override
    public void onTick() {
        if (lines.isEmpty() || ++ticks < delay.get() * 20) return;
        ticks = 0;
        String line = random.get() ? lines.get(ThreadLocalRandom.current().nextInt(lines.size())) : lines.get(index++ % lines.size());
        if (line.startsWith("/")) {
            mc.player.connection.sendCommand(line.substring(1));
            return;
        }
        if (antiFilter.get()) line += " " + Integer.toHexString(ThreadLocalRandom.current().nextInt(0x1000, 0xFFFF));
        mc.player.connection.sendChat(line);
    }
}

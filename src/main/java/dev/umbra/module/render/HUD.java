package dev.umbra.module.render;

import dev.umbra.Umbra;
import dev.umbra.mixin.MinecraftAccessor;
import dev.umbra.module.Category;
import dev.umbra.module.Module;
import dev.umbra.setting.BoolSetting;
import dev.umbra.setting.ModeSetting;
import net.minecraft.client.gui.Font;
import net.minecraft.client.gui.GuiGraphicsExtractor;
import net.minecraft.client.multiplayer.PlayerInfo;
import net.minecraft.world.entity.EquipmentSlot;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.Items;
import net.minecraft.world.level.Level;

import java.awt.Color;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

public class HUD extends Module {
    private final BoolSetting watermark = bool("Watermark", "Client name in the top left", true);
    private final BoolSetting arrayList = bool("ArrayList", "Enabled modules in the top right", true);
    private final BoolSetting coords = bool("Coords", "Coordinates with nether/overworld conversion", true);
    private final BoolSetting info = bool("Info", "FPS, ping and speed", true);
    private final BoolSetting armor = bool("Armor", "Armor and totem count above the hotbar", true);
    private final ModeSetting color = mode("Color", "Text color style", "Rainbow", "Rainbow", "Purple", "White");

    public HUD() {
        super("HUD", Category.RENDER, "On-screen overlay");
        setEnabledSilently(true);
        drawn.set(false);
    }

    private int color(int offset) {
        return switch (color.get()) {
            case "Purple" -> 0xFF9B5DE5;
            case "White" -> 0xFFFFFFFF;
            default -> {
                float hue = ((System.currentTimeMillis() + offset * 120L) % 4000L) / 4000f;
                yield 0xFF000000 | (Color.HSBtoRGB(hue, 0.55f, 1f) & 0xFFFFFF);
            }
        };
    }

    @Override
    public void onHud(GuiGraphicsExtractor g, float partialTick) {
        if (mc.gui.screen() instanceof dev.umbra.gui.ClickGuiScreen) return;
        Font font = mc.font;
        int w = g.guiWidth(), h = g.guiHeight();

        if (watermark.get()) {
            g.text(font, Umbra.NAME, 3, 3, color(0), true);
            g.text(font, Umbra.VERSION, 5 + font.width(Umbra.NAME), 3, 0xFFAAAAAA, true);
        }

        if (arrayList.get()) {
            List<String[]> entries = new ArrayList<>();
            for (Module m : Umbra.MODULES.enabled()) {
                if (!m.drawn.get()) continue;
                String inf = m.getInfo();
                entries.add(new String[]{m.name, inf == null ? "" : " " + inf});
            }
            entries.sort((a, b) -> Integer.compare(font.width(b[0] + b[1]), font.width(a[0] + a[1])));
            int y = 3, i = 0;
            for (String[] e : entries) {
                int tw = font.width(e[0] + e[1]);
                int x = w - tw - 3;
                g.fill(x - 2, y - 1, w, y + font.lineHeight, 0x70000000);
                g.text(font, e[0], x, y, color(i), true);
                if (!e[1].isEmpty()) g.text(font, e[1], x + font.width(e[0]), y, 0xFFAAAAAA, true);
                y += font.lineHeight + 1;
                i++;
            }
        }

        int bottom = h - 3 - font.lineHeight;
        if (mc.gui.screen() instanceof net.minecraft.client.gui.screens.ChatScreen) bottom -= 14;

        if (coords.get()) {
            double x = mc.player.getX(), y = mc.player.getY(), z = mc.player.getZ();
            boolean nether = mc.level.dimension() == Level.NETHER;
            double ox = nether ? x * 8 : x / 8, oz = nether ? z * 8 : z / 8;
            String main = String.format(Locale.ROOT, "XYZ %.1f %.1f %.1f", x, y, z);
            String other = String.format(Locale.ROOT, " [%s %.1f %.1f]", nether ? "OW" : "Nether", ox, oz);
            g.text(font, main, 3, bottom, 0xFFFFFFFF, true);
            g.text(font, other, 3 + font.width(main), bottom, 0xFFAAAAAA, true);
            bottom -= font.lineHeight + 1;
        }

        if (info.get()) {
            int ping = 0;
            if (mc.getConnection() != null) {
                PlayerInfo pi = mc.getConnection().getPlayerInfo(mc.player.getUUID());
                if (pi != null) ping = pi.getLatency();
            }
            double bps = Math.hypot(mc.player.getX() - mc.player.xo, mc.player.getZ() - mc.player.zo) * 20;
            String line = String.format(Locale.ROOT, "FPS %d  Ping %dms  Speed %.1f b/s", MinecraftAccessor.umbra$getFps(), ping, bps);
            g.text(font, line, 3, bottom, 0xFFFFFFFF, true);
        }

        if (armor.get() && !mc.player.isCreative() && !mc.player.isSpectator()) {
            int x = w / 2 + 8;
            int y = h - 56;
            if (mc.player.isUnderWater() || mc.player.getAirSupply() < mc.player.getMaxAirSupply()) y -= 10;
            EquipmentSlot[] slots = {EquipmentSlot.HEAD, EquipmentSlot.CHEST, EquipmentSlot.LEGS, EquipmentSlot.FEET};
            for (EquipmentSlot slot : slots) {
                ItemStack stack = mc.player.getItemBySlot(slot);
                if (!stack.isEmpty()) {
                    g.item(stack, x, y);
                    g.itemDecorations(font, stack, x, y);
                }
                x += 18;
            }
            int totems = 0;
            for (int i = 0; i < 36; i++) {
                ItemStack s = mc.player.getInventory().getItem(i);
                if (s.is(Items.TOTEM_OF_UNDYING)) totems += s.getCount();
            }
            if (mc.player.getOffhandItem().is(Items.TOTEM_OF_UNDYING)) totems++;
            if (totems > 0) {
                ItemStack t = new ItemStack(Items.TOTEM_OF_UNDYING, Math.min(totems, 99));
                g.item(t, x + 4, y);
                g.itemDecorations(font, t, x + 4, y);
            }
        }
    }
}

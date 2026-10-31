package dev.umbra.gui;

import dev.umbra.Umbra;
import dev.umbra.command.CommandManager;
import dev.umbra.module.Category;
import dev.umbra.module.Module;
import dev.umbra.setting.BoolSetting;
import dev.umbra.setting.ModeSetting;
import dev.umbra.setting.NumberSetting;
import dev.umbra.setting.Setting;
import dev.umbra.util.Config;
import net.minecraft.client.gui.Font;
import net.minecraft.client.gui.GuiGraphicsExtractor;
import net.minecraft.client.gui.screens.Screen;
import net.minecraft.client.input.KeyEvent;
import net.minecraft.client.input.MouseButtonEvent;
import net.minecraft.network.chat.Component;

import java.util.ArrayList;
import java.util.EnumMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Panel-style ClickGUI.
 * Left click a module: toggle. Right click: expand settings. Middle click: start binding.
 * Drag a panel header to move it, right click a header to collapse it. Scroll to move all panels.
 */
public class ClickGuiScreen extends Screen {
    private static final int PANEL_W = 112;
    private static final int HEADER_H = 15;
    private static final int ROW_H = 13;
    private static final int SET_H = 12;

    private static final int BG = 0xE0141418;
    private static final int ROW_BG = 0xC81C1C22;
    private static final int SET_BG = 0xC8101014;
    private static final int TEXT = 0xFFE6E6E6;
    private static final int DIM = 0xFF8A8A96;
    private static final int ACCENT = 0xFF9B5DE5;

    /** Panel positions persist between openings for the session. */
    private static final Map<Category, int[]> PANEL_POS = new EnumMap<>(Category.class);
    private static final Set<Category> COLLAPSED = new HashSet<>();
    private static final Set<Module> EXPANDED = new HashSet<>();

    private final List<Row> rows = new ArrayList<>();
    private Category draggingPanel;
    private int dragOffX, dragOffY;
    private NumberSetting draggingSlider;
    private int sliderX, sliderW;
    private Module binding;
    private String hoverDescription;

    private record Row(int x, int y, int w, int h, Category header, Module module, Setting<?> setting, boolean bindRow) {
        boolean contains(double mx, double my) {
            return mx >= x && mx < x + w && my >= y && my < y + h;
        }
    }

    public ClickGuiScreen() {
        super(Component.literal("Umbra ClickGUI"));
        int x = 10;
        for (Category c : Category.values()) {
            PANEL_POS.putIfAbsent(c, new int[]{x, 10});
            x += PANEL_W + 8;
        }
    }

    @Override
    public boolean isPauseScreen() {
        return false;
    }

    @Override
    public void onClose() {
        Config.save();
        super.onClose();
    }

    @Override
    public void extractBackground(GuiGraphicsExtractor g, int mouseX, int mouseY, float delta) {
        g.fill(0, 0, this.width, this.height, 0x60000000);
    }

    @Override
    public void extractRenderState(GuiGraphicsExtractor g, int mouseX, int mouseY, float delta) {
        super.extractRenderState(g, mouseX, mouseY, delta);
        Font font = this.font;
        rows.clear();
        hoverDescription = null;

        if (draggingPanel != null) {
            int[] pos = PANEL_POS.get(draggingPanel);
            pos[0] = mouseX - dragOffX;
            pos[1] = mouseY - dragOffY;
        }
        if (draggingSlider != null) {
            double frac = Math.max(0, Math.min(1, (mouseX - sliderX) / (double) sliderW));
            draggingSlider.set(draggingSlider.min + frac * (draggingSlider.max - draggingSlider.min));
        }

        for (Category cat : Category.values()) {
            int[] pos = PANEL_POS.get(cat);
            int x = pos[0], y = pos[1];
            List<Module> modules = Umbra.MODULES.byCategory(cat);

            // Header
            g.fill(x, y, x + PANEL_W, y + HEADER_H, cat.color);
            g.text(font, cat.displayName, x + 5, y + 4, 0xFFFFFFFF, true);
            String count = COLLAPSED.contains(cat) ? "+" : String.valueOf(modules.size());
            g.text(font, count, x + PANEL_W - 5 - font.width(count), y + 4, 0xFFFFFFFF, true);
            rows.add(new Row(x, y, PANEL_W, HEADER_H, cat, null, null, false));
            y += HEADER_H;
            if (COLLAPSED.contains(cat)) continue;

            for (Module m : modules) {
                boolean hover = mouseX >= x && mouseX < x + PANEL_W && mouseY >= y && mouseY < y + ROW_H;
                g.fill(x, y, x + PANEL_W, y + ROW_H, hover ? 0xD0262630 : ROW_BG);
                if (m.isEnabled()) g.fill(x, y, x + 2, y + ROW_H, ACCENT);
                g.text(font, m.name, x + 5, y + 3, m.isEnabled() ? ACCENT | 0xFF000000 : TEXT, true);
                String mark = EXPANDED.contains(m) ? "-" : "...";
                g.text(font, mark, x + PANEL_W - 4 - font.width(mark), y + 3, DIM, false);
                rows.add(new Row(x, y, PANEL_W, ROW_H, null, m, null, false));
                if (hover) hoverDescription = m.description;
                y += ROW_H;

                if (EXPANDED.contains(m)) {
                    for (Setting<?> s : m.allSettings()) {
                        if (!s.isVisible()) continue;
                        y = drawSetting(g, font, s, m, x, y, mouseX, mouseY);
                    }
                    // Bind row
                    g.fill(x, y, x + PANEL_W, y + SET_H, SET_BG);
                    String bindText = binding == m ? "Press a key... (Esc = none)" : "Bind: " + CommandManager.keyName(m.getKey());
                    g.text(font, bindText, x + 8, y + 2, binding == m ? 0xFFFFD050 : DIM, false);
                    rows.add(new Row(x, y, PANEL_W, SET_H, null, m, null, true));
                    y += SET_H;
                }
            }
            g.fill(x, y, x + PANEL_W, y + 2, cat.color);
        }

        // Footer: description of hovered module and a hint line.
        String hint = "LMB toggle  |  RMB settings  |  MMB bind  |  " + CommandManager.prefix + "help in chat";
        g.text(font, hint, 4, this.height - 12, DIM, true);
        if (hoverDescription != null) g.text(font, hoverDescription, 4, this.height - 24, TEXT, true);
        String brand = Umbra.NAME + " " + Umbra.VERSION;
        g.text(font, brand, this.width - font.width(brand) - 4, this.height - 12, ACCENT, true);
    }

    private int drawSetting(GuiGraphicsExtractor g, Font font, Setting<?> s, Module m, int x, int y, int mouseX, int mouseY) {
        g.fill(x, y, x + PANEL_W, y + SET_H, SET_BG);
        boolean hover = mouseX >= x && mouseX < x + PANEL_W && mouseY >= y && mouseY < y + SET_H;
        if (hover) hoverDescription = s.description;

        if (s instanceof BoolSetting b) {
            g.text(font, s.name, x + 8, y + 2, TEXT, false);
            int bx = x + PANEL_W - 14;
            g.fill(bx, y + 2, bx + 9, y + 10, 0xFF2A2A33);
            if (b.get()) g.fill(bx + 1, y + 3, bx + 8, y + 9, ACCENT);
        } else if (s instanceof NumberSetting n) {
            int sx = x + 6, sw = PANEL_W - 12;
            g.fill(sx, y + SET_H - 3, sx + sw, y + SET_H - 1, 0xFF2A2A33);
            g.fill(sx, y + SET_H - 3, sx + (int) (sw * n.fraction()), y + SET_H - 1, ACCENT);
            g.text(font, s.name, x + 8, y + 1, TEXT, false);
            String v = n.display();
            g.text(font, v, x + PANEL_W - 6 - font.width(v), y + 1, DIM, false);
        } else if (s instanceof ModeSetting md) {
            g.text(font, s.name, x + 8, y + 2, TEXT, false);
            String v = md.get();
            g.text(font, v, x + PANEL_W - 6 - font.width(v), y + 2, ACCENT, false);
        }
        rows.add(new Row(x, y, PANEL_W, SET_H, null, m, s, false));
        return y + SET_H;
    }

    @Override
    public boolean mouseClicked(MouseButtonEvent event, boolean doubleClick) {
        double mx = event.x(), my = event.y();
        int button = event.button();
        // Iterate in reverse so the panel drawn last (on top) wins overlaps.
        for (int i = rows.size() - 1; i >= 0; i--) {
            Row r = rows.get(i);
            if (!r.contains(mx, my)) continue;

            if (r.header() != null) {
                if (button == 0) {
                    int[] pos = PANEL_POS.get(r.header());
                    draggingPanel = r.header();
                    dragOffX = (int) mx - pos[0];
                    dragOffY = (int) my - pos[1];
                } else if (button == 1) {
                    if (!COLLAPSED.remove(r.header())) COLLAPSED.add(r.header());
                }
                return true;
            }

            if (r.bindRow()) {
                binding = binding == r.module() ? null : r.module();
                return true;
            }

            if (r.setting() != null) {
                Setting<?> s = r.setting();
                if (s instanceof BoolSetting b) b.toggle();
                else if (s instanceof ModeSetting md) md.cycle(button != 1);
                else if (s instanceof NumberSetting n) {
                    draggingSlider = n;
                    sliderX = r.x() + 6;
                    sliderW = PANEL_W - 12;
                }
                return true;
            }

            Module m = r.module();
            if (button == 0) m.toggle();
            else if (button == 1) {
                if (!EXPANDED.remove(m)) EXPANDED.add(m);
            } else if (button == 2) binding = m;
            return true;
        }
        return super.mouseClicked(event, doubleClick);
    }

    @Override
    public boolean mouseReleased(MouseButtonEvent event) {
        draggingPanel = null;
        draggingSlider = null;
        return super.mouseReleased(event);
    }

    @Override
    public boolean mouseScrolled(double mouseX, double mouseY, double horizontal, double vertical) {
        for (int[] pos : PANEL_POS.values()) pos[1] += (int) (vertical * 12);
        return true;
    }

    @Override
    public boolean keyPressed(KeyEvent event) {
        if (binding != null) {
            int key = event.key();
            // Escape, Backspace and Delete clear the bind.
            binding.setKey(key == 256 || key == 259 || key == 261 ? -1 : key);
            binding = null;
            return true;
        }
        return super.keyPressed(event);
    }
}

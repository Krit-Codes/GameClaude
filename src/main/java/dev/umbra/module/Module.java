package dev.umbra.module;

import dev.umbra.setting.BoolSetting;
import dev.umbra.setting.ModeSetting;
import dev.umbra.setting.NumberSetting;
import dev.umbra.setting.Setting;
import dev.umbra.util.ChatUtil;
import dev.umbra.util.Lines;
import net.fabricmc.fabric.api.client.rendering.v1.level.LevelRenderContext;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.GuiGraphicsExtractor;
import net.minecraft.network.protocol.Packet;
import net.minecraft.world.phys.Vec3;

import java.util.ArrayList;
import java.util.List;

public abstract class Module {
    protected static final Minecraft mc = Minecraft.getInstance();

    public final String name;
    public final String description;
    public final Category category;
    public final List<Setting<?>> settings = new ArrayList<>();

    private boolean enabled;
    private int key = -1;
    /** Hidden modules are not listed in the HUD array list. */
    public final BoolSetting drawn;

    protected Module(String name, Category category, String description) {
        this.name = name;
        this.category = category;
        this.description = description;
        this.drawn = new BoolSetting("Drawn", "Show this module in the HUD list", true);
    }

    // ---- settings helpers -------------------------------------------------

    protected BoolSetting bool(String name, String desc, boolean def) {
        BoolSetting s = new BoolSetting(name, desc, def);
        settings.add(s);
        return s;
    }

    protected NumberSetting number(String name, String desc, double def, double min, double max, double step) {
        NumberSetting s = new NumberSetting(name, desc, def, min, max, step);
        settings.add(s);
        return s;
    }

    protected ModeSetting mode(String name, String desc, String def, String... modes) {
        ModeSetting s = new ModeSetting(name, desc, def, modes);
        settings.add(s);
        return s;
    }

    public Setting<?> getSetting(String name) {
        for (Setting<?> s : allSettings()) if (s.name.equalsIgnoreCase(name)) return s;
        return null;
    }

    /** Module settings plus the shared "Drawn" toggle, in display order. */
    public List<Setting<?>> allSettings() {
        List<Setting<?>> all = new ArrayList<>(settings);
        all.add(drawn);
        return all;
    }

    // ---- state ------------------------------------------------------------

    public boolean isEnabled() {
        return enabled;
    }

    public void toggle() {
        setEnabled(!enabled);
    }

    public void setEnabled(boolean enabled) {
        if (this.enabled == enabled) return;
        this.enabled = enabled;
        try {
            if (enabled) onEnable();
            else onDisable();
        } catch (Throwable t) {
            ChatUtil.error(name + " failed to " + (enabled ? "enable" : "disable") + ": " + t);
        }
    }

    /** Sets state without firing callbacks, used when loading config before a world exists. */
    public void setEnabledSilently(boolean enabled) {
        this.enabled = enabled;
    }

    public int getKey() {
        return key;
    }

    public void setKey(int key) {
        this.key = key;
    }

    protected boolean inGame() {
        return mc.player != null && mc.level != null;
    }

    // ---- hooks (override what you need) -----------------------------------

    public void onEnable() { }

    public void onDisable() { }

    /** Called every client tick while enabled and in a world. */
    public void onTick() { }

    /** Called every client tick while enabled, even on menus (no world, mc.player may be null). */
    public void onClientTick() { }

    /** Called on world join (after a disconnect or dimension change the player object is new). */
    public void onJoin() { }

    /** World-space text labels. Use ctx.submitNodeCollector(). */
    public void onRenderLabels(LevelRenderContext ctx, Vec3 camera) { }

    /** World-space lines (boxes, tracers). Coordinates in Lines are absolute world coordinates. */
    public void onRenderLines(Lines lines) { }

    /** Screen-space HUD drawing. */
    public void onHud(GuiGraphicsExtractor g, float partialTick) { }

    /** Return true to cancel an outgoing packet. Runs on the thread that sent it (usually the client thread). */
    public boolean onPacketSend(Packet<?> packet) {
        return false;
    }

    /** Return true to drop an incoming packet. Runs on the NETTY thread, keep it cheap. */
    public boolean onPacketReceive(Packet<?> packet) {
        return false;
    }

    /** Short status shown next to the module name in the HUD list, or null. */
    public String getInfo() {
        return null;
    }
}

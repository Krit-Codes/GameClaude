package dev.umbra.module.render;

import dev.umbra.gui.ClickGuiScreen;
import dev.umbra.module.Category;
import dev.umbra.module.Module;

/** Bindable entry for the GUI. Enabling it opens the screen and immediately turns it back off. */
public class ClickGUI extends Module {
    public ClickGUI() {
        super("ClickGUI", Category.RENDER, "Opens this menu (default key: Right Shift)");
        drawn.set(false);
    }

    @Override
    public void onEnable() {
        if (mc.gui.screen() == null) mc.gui.setScreen(new ClickGuiScreen());
        setEnabledSilently(false);
    }
}

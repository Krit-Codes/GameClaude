package dev.umbra.module;

public enum Category {
    COMBAT("Combat", 0xFFE04848),
    MOVEMENT("Movement", 0xFF48A8E0),
    RENDER("Render", 0xFFB060E0),
    PLAYER("Player", 0xFF60D070),
    WORLD("World", 0xFFE0A040),
    MISC("Misc", 0xFF909090);

    public final String displayName;
    public final int color;

    Category(String displayName, int color) {
        this.displayName = displayName;
        this.color = color;
    }
}

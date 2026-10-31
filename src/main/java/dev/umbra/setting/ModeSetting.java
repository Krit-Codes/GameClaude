package dev.umbra.setting;

import com.google.gson.JsonElement;
import com.google.gson.JsonPrimitive;

import java.util.List;

public class ModeSetting extends Setting<String> {
    public final List<String> modes;

    public ModeSetting(String name, String description, String defaultValue, String... modes) {
        super(name, description, defaultValue);
        this.modes = List.of(modes);
    }

    public boolean is(String mode) {
        return value.equalsIgnoreCase(mode);
    }

    public void cycle(boolean forward) {
        int i = modes.indexOf(value);
        int n = modes.size();
        value = modes.get(((forward ? i + 1 : i - 1) % n + n) % n);
    }

    @Override
    public boolean parse(String input) {
        for (String mode : modes) {
            if (mode.equalsIgnoreCase(input)) {
                value = mode;
                return true;
            }
        }
        return false;
    }

    @Override
    public String display() {
        return value;
    }

    @Override
    public JsonElement toJson() {
        return new JsonPrimitive(value);
    }

    @Override
    public void fromJson(JsonElement element) {
        if (element.isJsonPrimitive()) parse(element.getAsString());
    }
}

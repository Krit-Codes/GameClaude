package dev.umbra.setting;

import com.google.gson.JsonElement;
import com.google.gson.JsonPrimitive;

public class NumberSetting extends Setting<Double> {
    public final double min;
    public final double max;
    public final double step;

    public NumberSetting(String name, String description, double defaultValue, double min, double max, double step) {
        super(name, description, defaultValue);
        this.min = min;
        this.max = max;
        this.step = step;
    }

    @Override
    public void set(Double v) {
        double clamped = Math.max(min, Math.min(max, v));
        if (step > 0) clamped = Math.round(clamped / step) * step;
        // Round off float noise like 0.30000000000000004.
        value = Math.round(clamped * 1000.0) / 1000.0;
    }

    public int getInt() {
        return (int) Math.round(value);
    }

    public float getFloat() {
        return value.floatValue();
    }

    /** 0..1 position of the current value inside [min, max], for drawing sliders. */
    public double fraction() {
        return (value - min) / (max - min);
    }

    @Override
    public boolean parse(String input) {
        try {
            set(Double.parseDouble(input));
            return true;
        } catch (NumberFormatException e) {
            return false;
        }
    }

    @Override
    public String display() {
        if (step >= 1 && value == Math.floor(value)) return String.valueOf(value.longValue());
        return String.format(java.util.Locale.ROOT, "%.2f", value);
    }

    @Override
    public JsonElement toJson() {
        return new JsonPrimitive(value);
    }

    @Override
    public void fromJson(JsonElement element) {
        if (element.isJsonPrimitive()) set(element.getAsDouble());
    }
}

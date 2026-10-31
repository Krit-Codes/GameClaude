package dev.umbra.setting;

import com.google.gson.JsonElement;

import java.util.function.BooleanSupplier;

public abstract class Setting<T> {
    public final String name;
    public final String description;
    protected T value;
    protected final T defaultValue;
    private BooleanSupplier visible = () -> true;

    protected Setting(String name, String description, T defaultValue) {
        this.name = name;
        this.description = description;
        this.value = defaultValue;
        this.defaultValue = defaultValue;
    }

    public T get() {
        return value;
    }

    public void set(T value) {
        this.value = value;
    }

    public void reset() {
        this.value = defaultValue;
    }

    /** Hide this setting in the GUI unless the condition holds (e.g. only show for a certain mode). */
    public Setting<T> visibleWhen(BooleanSupplier condition) {
        this.visible = condition;
        return this;
    }

    public boolean isVisible() {
        return visible.getAsBoolean();
    }

    /** Parses a value typed in chat (".set Module setting value"). Returns false on bad input. */
    public abstract boolean parse(String input);

    public abstract String display();

    public abstract JsonElement toJson();

    public abstract void fromJson(JsonElement element);
}

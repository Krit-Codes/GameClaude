package dev.umbra.util;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import dev.umbra.Umbra;
import dev.umbra.command.CommandManager;
import dev.umbra.module.Module;
import dev.umbra.setting.Setting;
import net.fabricmc.loader.api.FabricLoader;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

/** Saves modules, binds, settings, friends and the command prefix to config/umbra/<profile>.json. */
public final class Config {
    private Config() { }

    private static final Gson GSON = new GsonBuilder().setPrettyPrinting().create();
    private static final Path DIR = FabricLoader.getInstance().getConfigDir().resolve("umbra");

    public static Path file(String profile) {
        return DIR.resolve(profile.replaceAll("[^A-Za-z0-9_-]", "_") + ".json");
    }

    public static void save() {
        save("default");
    }

    public static void save(String profile) {
        try {
            JsonObject root = new JsonObject();
            root.addProperty("prefix", CommandManager.prefix);

            JsonArray friends = new JsonArray();
            for (String f : Friends.all()) friends.add(f);
            root.add("friends", friends);

            JsonObject modules = new JsonObject();
            for (Module m : Umbra.MODULES.all()) {
                JsonObject obj = new JsonObject();
                obj.addProperty("enabled", m.isEnabled());
                obj.addProperty("key", m.getKey());
                JsonObject settings = new JsonObject();
                for (Setting<?> s : m.allSettings()) settings.add(s.name, s.toJson());
                obj.add("settings", settings);
                modules.add(m.name, obj);
            }
            root.add("modules", modules);

            Files.createDirectories(DIR);
            Files.writeString(file(profile), GSON.toJson(root), StandardCharsets.UTF_8);
        } catch (IOException e) {
            Umbra.LOG.error("Could not save config", e);
        }
    }

    public static boolean load() {
        return load("default");
    }

    public static boolean load(String profile) {
        Path path = file(profile);
        if (!Files.exists(path)) return false;
        try {
            JsonObject root = JsonParser.parseString(Files.readString(path, StandardCharsets.UTF_8)).getAsJsonObject();
            if (root.has("prefix")) CommandManager.prefix = root.get("prefix").getAsString();

            if (root.has("friends")) {
                Friends.clear();
                for (JsonElement e : root.getAsJsonArray("friends")) Friends.add(e.getAsString());
            }

            JsonObject modules = root.has("modules") ? root.getAsJsonObject("modules") : new JsonObject();
            for (Module m : Umbra.MODULES.all()) {
                if (!modules.has(m.name)) continue;
                JsonObject obj = modules.getAsJsonObject(m.name);
                if (obj.has("key")) m.setKey(obj.get("key").getAsInt());
                if (obj.has("settings")) {
                    JsonObject settings = obj.getAsJsonObject("settings");
                    for (Setting<?> s : m.allSettings()) {
                        if (settings.has(s.name)) {
                            try {
                                s.fromJson(settings.get(s.name));
                            } catch (RuntimeException ignored) {
                                // Keep the default for a value that no longer parses.
                            }
                        }
                    }
                }
                boolean enabled = obj.has("enabled") && obj.get("enabled").getAsBoolean();
                // At startup there is no world yet: set the flag only; modules re-sync on join.
                var client = net.minecraft.client.Minecraft.getInstance();
                if (client != null && client.player != null) m.setEnabled(enabled);
                else m.setEnabledSilently(enabled);
            }
            return true;
        } catch (Exception e) {
            Umbra.LOG.error("Could not load config {}", path, e);
            return false;
        }
    }
}

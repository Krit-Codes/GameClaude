package dev.umbra.util;

import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.player.Player;

import java.util.Locale;
import java.util.Set;
import java.util.TreeSet;

public final class Friends {
    private Friends() { }

    private static final Set<String> NAMES = new TreeSet<>();

    public static boolean add(String name) {
        return NAMES.add(name.toLowerCase(Locale.ROOT));
    }

    public static boolean remove(String name) {
        return NAMES.remove(name.toLowerCase(Locale.ROOT));
    }

    public static boolean isFriend(String name) {
        return NAMES.contains(name.toLowerCase(Locale.ROOT));
    }

    public static boolean isFriend(Entity entity) {
        return entity instanceof Player p && isFriend(p.getName().getString());
    }

    public static Set<String> all() {
        return NAMES;
    }

    public static void clear() {
        NAMES.clear();
    }
}

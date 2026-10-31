package dev.umbra.command;

import com.mojang.blaze3d.platform.InputConstants;
import dev.umbra.Umbra;
import dev.umbra.module.Module;
import dev.umbra.setting.Setting;
import dev.umbra.util.ChatUtil;
import dev.umbra.util.Config;
import dev.umbra.util.Friends;
import net.minecraft.client.Minecraft;
import net.minecraft.world.phys.Vec3;

import java.util.Arrays;
import java.util.Locale;
import java.util.StringJoiner;

/**
 * Chat commands. Anything typed starting with the prefix (default ".") is handled locally
 * and never sent to the server.
 */
public final class CommandManager {
    public static String prefix = ".";

    /** @return true if the message was a client command and must not be sent. */
    public boolean handle(String message) {
        if (!message.startsWith(prefix)) return false;
        String[] parts = message.substring(prefix.length()).trim().split("\\s+");
        if (parts.length == 0 || parts[0].isEmpty()) return true;
        String cmd = parts[0].toLowerCase(Locale.ROOT);
        String[] args = Arrays.copyOfRange(parts, 1, parts.length);

        Minecraft.getInstance().gui.hud.getChat().addRecentChat(message);
        try {
            switch (cmd) {
                case "help", "h" -> help();
                case "toggle", "t" -> toggle(args);
                case "bind", "b" -> bind(args);
                case "unbind" -> unbind(args);
                case "binds" -> binds();
                case "set", "s" -> set(args);
                case "settings" -> settings(args);
                case "modules", "list" -> modules();
                case "friend", "f" -> friend(args);
                case "prefix" -> setPrefix(args);
                case "config", "cfg" -> config(args);
                case "vclip" -> vclip(args);
                case "hclip" -> hclip(args);
                case "coords" -> coords();
                default -> {
                    Module m = Umbra.MODULES.get(cmd);
                    if (m != null) {
                        m.toggle();
                        ChatUtil.info(m.name + (m.isEnabled() ? " §aenabled" : " §cdisabled"));
                    } else {
                        ChatUtil.error("Unknown command. Try " + prefix + "help");
                    }
                }
            }
        } catch (Exception e) {
            ChatUtil.error("Command failed: " + e.getMessage());
        }
        return true;
    }

    private Module requireModule(String name) {
        Module m = Umbra.MODULES.get(name);
        if (m == null) throw new IllegalArgumentException("No module named " + name);
        return m;
    }

    private void help() {
        String p = prefix;
        ChatUtil.info("Commands:");
        ChatUtil.info(p + "toggle <module>  |  " + p + "<module>   toggle a module");
        ChatUtil.info(p + "bind <module> <key>  |  " + p + "unbind <module>  |  " + p + "binds");
        ChatUtil.info(p + "set <module> <setting> <value>  |  " + p + "settings <module>");
        ChatUtil.info(p + "modules  |  " + p + "friend add/del/list <name>");
        ChatUtil.info(p + "config save/load [name]  |  " + p + "prefix <char>");
        ChatUtil.info(p + "vclip <blocks>  |  " + p + "hclip <blocks>  |  " + p + "coords");
        ChatUtil.info("Open the ClickGUI with Right Shift.");
    }

    private void toggle(String[] args) {
        if (args.length < 1) throw new IllegalArgumentException("Usage: toggle <module>");
        Module m = requireModule(args[0]);
        m.toggle();
        ChatUtil.info(m.name + (m.isEnabled() ? " §aenabled" : " §cdisabled"));
    }

    private void bind(String[] args) {
        if (args.length < 2) throw new IllegalArgumentException("Usage: bind <module> <key>  (e.g. bind KillAura r)");
        Module m = requireModule(args[0]);
        int key = parseKey(args[1]);
        if (key < 0) throw new IllegalArgumentException("Unknown key " + args[1]);
        m.setKey(key);
        ChatUtil.success("Bound " + m.name + " to " + keyName(key));
        Config.save();
    }

    private void unbind(String[] args) {
        if (args.length < 1) throw new IllegalArgumentException("Usage: unbind <module>");
        Module m = requireModule(args[0]);
        m.setKey(-1);
        ChatUtil.success("Unbound " + m.name);
        Config.save();
    }

    private void binds() {
        for (Module m : Umbra.MODULES.all()) {
            if (m.getKey() > 0) ChatUtil.info(m.name + ": " + keyName(m.getKey()));
        }
    }

    private void set(String[] args) {
        if (args.length < 3) throw new IllegalArgumentException("Usage: set <module> <setting> <value>");
        Module m = requireModule(args[0]);
        Setting<?> s = m.getSetting(args[1]);
        if (s == null) throw new IllegalArgumentException(m.name + " has no setting " + args[1]);
        String value = String.join(" ", Arrays.copyOfRange(args, 2, args.length));
        if (!s.parse(value)) throw new IllegalArgumentException("Bad value for " + s.name + ": " + value);
        ChatUtil.success(m.name + " " + s.name + " = " + s.display());
    }

    private void settings(String[] args) {
        if (args.length < 1) throw new IllegalArgumentException("Usage: settings <module>");
        Module m = requireModule(args[0]);
        ChatUtil.info(m.name + ": " + m.description);
        for (Setting<?> s : m.allSettings()) ChatUtil.info("  " + s.name + " = " + s.display() + "  §8" + s.description);
    }

    private void modules() {
        StringJoiner j = new StringJoiner(", ");
        for (Module m : Umbra.MODULES.all()) j.add((m.isEnabled() ? "§a" : "§7") + m.name);
        ChatUtil.info(j.toString());
    }

    private void friend(String[] args) {
        if (args.length < 1) throw new IllegalArgumentException("Usage: friend add/del/list <name>");
        switch (args[0].toLowerCase(Locale.ROOT)) {
            case "add" -> {
                if (args.length < 2) throw new IllegalArgumentException("Usage: friend add <name>");
                Friends.add(args[1]);
                ChatUtil.success("Added friend " + args[1]);
            }
            case "del", "remove" -> {
                if (args.length < 2) throw new IllegalArgumentException("Usage: friend del <name>");
                ChatUtil.info(Friends.remove(args[1]) ? "Removed " + args[1] : args[1] + " was not a friend");
            }
            case "list" -> ChatUtil.info("Friends: " + (Friends.all().isEmpty() ? "none" : String.join(", ", Friends.all())));
            default -> throw new IllegalArgumentException("Usage: friend add/del/list <name>");
        }
        Config.save();
    }

    private void setPrefix(String[] args) {
        if (args.length < 1 || args[0].isEmpty() || args[0].startsWith("/")) throw new IllegalArgumentException("Usage: prefix <char> (not /)");
        prefix = args[0];
        ChatUtil.success("Prefix set to " + prefix);
        Config.save();
    }

    private void config(String[] args) {
        if (args.length < 1) throw new IllegalArgumentException("Usage: config save/load [name]");
        String name = args.length > 1 ? args[1] : "default";
        switch (args[0].toLowerCase(Locale.ROOT)) {
            case "save" -> {
                Config.save(name);
                ChatUtil.success("Saved config " + name);
            }
            case "load" -> ChatUtil.info(Config.load(name) ? "Loaded config " + name : "No config named " + name);
            default -> throw new IllegalArgumentException("Usage: config save/load [name]");
        }
    }

    private void vclip(String[] args) {
        if (args.length < 1) throw new IllegalArgumentException("Usage: vclip <blocks>");
        var p = Minecraft.getInstance().player;
        if (p == null) return;
        p.setPos(p.getX(), p.getY() + Double.parseDouble(args[0]), p.getZ());
    }

    private void hclip(String[] args) {
        if (args.length < 1) throw new IllegalArgumentException("Usage: hclip <blocks>");
        var p = Minecraft.getInstance().player;
        if (p == null) return;
        double d = Double.parseDouble(args[0]);
        Vec3 dir = Vec3.directionFromRotation(0, p.getYRot());
        p.setPos(p.getX() + dir.x * d, p.getY(), p.getZ() + dir.z * d);
    }

    private void coords() {
        var p = Minecraft.getInstance().player;
        if (p == null) return;
        String text = String.format(Locale.ROOT, "%d %d %d", p.getBlockX(), p.getBlockY(), p.getBlockZ());
        Minecraft.getInstance().keyboardHandler.setClipboard(text);
        ChatUtil.info("Copied " + text);
    }

    // ---- key names ----------------------------------------------------------

    public static int parseKey(String name) {
        String n = name.toLowerCase(Locale.ROOT);
        switch (n) {
            case "none": return -1;
            case "rshift": return 344;
            case "lshift": return 340;
            case "rctrl": return 345;
            case "lctrl": return 341;
            case "ralt": return 346;
            case "lalt": return 342;
            case "tab": return 258;
            case "capslock", "caps": return 280;
            case "space": return 32;
            case "insert": return 260;
            case "delete": return 261;
            case "home": return 268;
            case "end": return 269;
            case "pageup": return 266;
            case "pagedown": return 267;
            case "up": return 265;
            case "down": return 264;
            case "left": return 263;
            case "right": return 262;
            default: break;
        }
        if (n.length() == 1) {
            char c = Character.toUpperCase(n.charAt(0));
            if ((c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')) return c;
        }
        if (n.matches("f([1-9]|1[0-9]|2[0-5])")) return 290 + Integer.parseInt(n.substring(1)) - 1;
        if (n.matches("kp[0-9]")) return 320 + (n.charAt(2) - '0');
        try {
            return InputConstants.getKey("key.keyboard." + n).getValue();
        } catch (Exception e) {
            return -1;
        }
    }

    public static String keyName(int key) {
        if (key <= 0) return "None";
        try {
            return InputConstants.Type.KEYSYM.getOrCreate(key).getDisplayName().getString();
        } catch (Exception e) {
            return "Key " + key;
        }
    }
}

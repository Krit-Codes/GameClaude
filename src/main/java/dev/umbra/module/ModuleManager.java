package dev.umbra.module;

import dev.umbra.module.combat.*;
import dev.umbra.module.misc.*;
import dev.umbra.module.movement.*;
import dev.umbra.module.player.*;
import dev.umbra.module.render.*;
import dev.umbra.module.world.*;
import dev.umbra.util.ChatUtil;
import net.minecraft.network.protocol.Packet;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

public final class ModuleManager {
    private final List<Module> modules = new ArrayList<>();
    /** Snapshot of enabled modules, safe to iterate from the netty thread. */
    private final List<Module> enabledSnapshot = new CopyOnWriteArrayList<>();

    public ModuleManager() {
        // Combat
        add(new KillAura());
        add(new CrystalAura());
        add(new AutoTotem());
        add(new Surround());
        add(new Criticals());
        add(new Velocity());
        add(new AutoArmor());
        add(new AutoLog());
        // Movement
        add(new Flight());
        add(new ElytraFly());
        add(new Speed());
        add(new NoFall());
        add(new Step());
        add(new Jesus());
        add(new Sprint());
        // Render
        add(new HUD());
        add(new ClickGUI());
        add(new ESP());
        add(new Tracers());
        add(new Nametags());
        add(new Fullbright());
        add(new Freecam());
        add(new XRay());
        add(new StashESP());
        // Player
        add(new AutoEat());
        add(new FastPlace());
        add(new AutoRespawn());
        add(new ChestStealer());
        add(new AutoReplenish());
        // World
        add(new Scaffold());
        add(new Nuker());
        // Misc
        add(new AutoReconnect());
        add(new Spammer());
        modules.sort((a, b) -> a.name.compareToIgnoreCase(b.name));
    }

    private void add(Module module) {
        modules.add(module);
    }

    public List<Module> all() {
        return Collections.unmodifiableList(modules);
    }

    public List<Module> byCategory(Category category) {
        List<Module> list = new ArrayList<>();
        for (Module m : modules) if (m.category == category) list.add(m);
        return list;
    }

    public Module get(String name) {
        for (Module m : modules) if (m.name.equalsIgnoreCase(name)) return m;
        return null;
    }

    @SuppressWarnings("unchecked")
    public <T extends Module> T get(Class<T> type) {
        for (Module m : modules) if (m.getClass() == type) return (T) m;
        throw new IllegalArgumentException("No module " + type.getSimpleName());
    }

    public List<Module> enabled() {
        return enabledSnapshot;
    }

    /** Rebuilds the thread-safe enabled list; call once per tick. */
    public void refreshSnapshot() {
        List<Module> now = new ArrayList<>();
        for (Module m : modules) if (m.isEnabled()) now.add(m);
        if (!now.equals(enabledSnapshot)) {
            enabledSnapshot.clear();
            enabledSnapshot.addAll(now);
        }
    }

    public void tick(boolean inGame) {
        refreshSnapshot();
        for (Module m : enabledSnapshot) {
            try {
                m.onClientTick();
                if (inGame && m.isEnabled()) m.onTick();
            } catch (Throwable t) {
                ChatUtil.error(m.name + " crashed and was disabled: " + t);
                t.printStackTrace();
                m.setEnabled(false);
            }
        }
    }

    public boolean onPacketSend(Packet<?> packet) {
        boolean cancel = false;
        for (Module m : enabledSnapshot) {
            try {
                if (m.onPacketSend(packet)) cancel = true;
            } catch (Throwable t) {
                t.printStackTrace();
            }
        }
        return cancel;
    }

    public boolean onPacketReceive(Packet<?> packet) {
        boolean cancel = false;
        for (Module m : enabledSnapshot) {
            try {
                if (m.onPacketReceive(packet)) cancel = true;
            } catch (Throwable t) {
                t.printStackTrace();
            }
        }
        return cancel;
    }
}

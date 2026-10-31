package dev.umbra;

import com.mojang.blaze3d.platform.InputConstants;
import dev.umbra.command.CommandManager;
import dev.umbra.gui.ClickGuiScreen;
import dev.umbra.module.Module;
import dev.umbra.module.ModuleManager;
import dev.umbra.module.render.ClickGUI;
import dev.umbra.util.Config;
import dev.umbra.util.Lines;
import net.fabricmc.api.ClientModInitializer;
import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientLifecycleEvents;
import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientTickEvents;
import net.fabricmc.fabric.api.client.keymapping.v1.KeyMappingHelper;
import net.fabricmc.fabric.api.client.message.v1.ClientSendMessageEvents;
import net.fabricmc.fabric.api.client.networking.v1.ClientPlayConnectionEvents;
import net.fabricmc.fabric.api.client.rendering.v1.hud.HudElementRegistry;
import net.fabricmc.fabric.api.client.rendering.v1.level.LevelRenderEvents;
import net.minecraft.client.KeyMapping;
import net.minecraft.client.Minecraft;
import net.minecraft.client.renderer.rendertype.RenderTypes;
import net.minecraft.resources.Identifier;
import net.minecraft.world.phys.Vec3;
import org.lwjgl.glfw.GLFW;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class Umbra implements ClientModInitializer {
    public static final String MOD_ID = "umbra";
    public static final String NAME = "Umbra";
    public static final String VERSION = "1.0.0";
    public static final Logger LOG = LoggerFactory.getLogger(NAME);

    public static ModuleManager MODULES;
    public static CommandManager COMMANDS;

    private static KeyMapping guiKey;
    private static final Map<Integer, Boolean> keyStates = new HashMap<>();
    private static int saveTimer;

    @Override
    public void onInitializeClient() {
        MODULES = new ModuleManager();
        COMMANDS = new CommandManager();
        Config.load();

        KeyMapping.Category category = KeyMapping.Category.register(Identifier.fromNamespaceAndPath(MOD_ID, "main"));
        guiKey = KeyMappingHelper.registerKeyMapping(new KeyMapping("key.umbra.clickgui", InputConstants.Type.KEYSYM, GLFW.GLFW_KEY_RIGHT_SHIFT, category));

        ClientTickEvents.END_CLIENT_TICK.register(Umbra::onTick);
        ClientLifecycleEvents.CLIENT_STOPPING.register(client -> Config.save());

        ClientPlayConnectionEvents.JOIN.register((handler, sender, client) -> {
            for (Module m : MODULES.all()) {
                if (m.isEnabled()) {
                    try {
                        m.onJoin();
                    } catch (Throwable t) {
                        LOG.error("{} onJoin failed", m.name, t);
                    }
                }
            }
        });

        ClientSendMessageEvents.ALLOW_CHAT.register(message -> !COMMANDS.handle(message));

        HudElementRegistry.addLast(Identifier.fromNamespaceAndPath(MOD_ID, "hud"), (graphics, delta) -> {
            Minecraft mc = Minecraft.getInstance();
            if (mc.player == null) return;
            float pt = delta.getGameTimeDeltaPartialTick(true);
            for (Module m : MODULES.enabled()) {
                try {
                    m.onHud(graphics, pt);
                } catch (Throwable t) {
                    LOG.error("{} HUD render failed", m.name, t);
                }
            }
        });

        LevelRenderEvents.COLLECT_SUBMITS.register(ctx -> {
            Minecraft mc = Minecraft.getInstance();
            if (mc.player == null || mc.level == null) return;
            List<Module> active = MODULES.enabled();
            if (active.isEmpty()) return;
            Vec3 camera = ctx.levelState().cameraRenderState.pos;
            float pt = mc.getDeltaTracker().getGameTimeDeltaPartialTick(true);

            for (Module m : active) {
                try {
                    m.onRenderLabels(ctx, camera);
                } catch (Throwable t) {
                    LOG.error("{} label render failed", m.name, t);
                }
            }

            var level = mc.level;
            ctx.submitNodeCollector().submitCustomGeometry(ctx.poseStack(), RenderTypes.lines(), (pose, buffer) -> {
                if (mc.level != level || mc.player == null) return;
                Lines lines = new Lines(pose, buffer, camera, pt);
                for (Module m : active) {
                    try {
                        m.onRenderLines(lines);
                    } catch (Throwable t) {
                        LOG.error("{} line render failed", m.name, t);
                    }
                }
            });
        });

        LOG.info("{} {} loaded with {} modules", NAME, VERSION, MODULES.all().size());
    }

    private static void onTick(Minecraft mc) {
        boolean inGame = mc.player != null && mc.level != null;

        // ClickGUI key (rebindable in vanilla Controls, or via the ClickGUI module bind).
        while (guiKey.consumeClick()) {
            if (inGame && mc.gui.screen() == null) MODULES.get(ClickGUI.class).toggle();
        }

        // Module keybinds: only while no screen is open so typing in chat never toggles anything.
        if (inGame && mc.gui.screen() == null) {
            for (Module m : MODULES.all()) {
                int key = m.getKey();
                if (key <= 0) continue;
                boolean down = InputConstants.isKeyDown(mc.getWindow(), key);
                boolean was = keyStates.getOrDefault(key, false);
                if (down && !was) m.toggle();
            }
        }
        keyStates.clear();
        for (Module m : MODULES.all()) {
            int key = m.getKey();
            if (key > 0) keyStates.put(key, InputConstants.isKeyDown(mc.getWindow(), key));
        }

        MODULES.tick(inGame);

        if (++saveTimer >= 20 * 60) {
            saveTimer = 0;
            Config.save();
        }
    }
}

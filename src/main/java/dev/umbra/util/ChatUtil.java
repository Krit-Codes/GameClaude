package dev.umbra.util;

import net.minecraft.ChatFormatting;
import net.minecraft.client.Minecraft;
import net.minecraft.network.chat.Component;

public final class ChatUtil {
    private ChatUtil() { }

    private static void send(Component body) {
        Minecraft mc = Minecraft.getInstance();
        if (mc.player == null) return;
        Component prefix = Component.literal("[Umbra] ").withStyle(ChatFormatting.DARK_PURPLE);
        mc.player.sendSystemMessage(Component.empty().append(prefix).append(body));
    }

    public static void info(String message) {
        send(Component.literal(message).withStyle(ChatFormatting.GRAY));
    }

    public static void success(String message) {
        send(Component.literal(message).withStyle(ChatFormatting.GREEN));
    }

    public static void error(String message) {
        send(Component.literal(message).withStyle(ChatFormatting.RED));
    }
}

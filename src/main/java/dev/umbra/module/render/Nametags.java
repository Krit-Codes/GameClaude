package dev.umbra.module.render;

import com.mojang.blaze3d.vertex.PoseStack;
import dev.umbra.module.Category;
import dev.umbra.module.Module;
import dev.umbra.setting.BoolSetting;
import dev.umbra.util.Friends;
import dev.umbra.util.WorldUtil;
import net.fabricmc.fabric.api.client.rendering.v1.level.LevelRenderContext;
import net.minecraft.ChatFormatting;
import net.minecraft.network.chat.Component;
import net.minecraft.network.chat.MutableComponent;
import net.minecraft.util.LightCoordsUtil;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.phys.Vec3;

public class Nametags extends Module {
    private final BoolSetting health = bool("Health", "Show health", true);
    private final BoolSetting distance = bool("Distance", "Show distance", true);
    private final BoolSetting ping = bool("Ping", "Show ping", true);
    private final BoolSetting heldItem = bool("HeldItem", "Show the item in their main hand", true);

    public Nametags() {
        super("Nametags", Category.RENDER, "Bigger, more informative player nametags visible through walls");
    }

    @Override
    public void onRenderLabels(LevelRenderContext ctx, Vec3 camera) {
        float pt = mc.getDeltaTracker().getGameTimeDeltaPartialTick(true);
        PoseStack stack = ctx.poseStack();
        for (Player p : mc.level.players()) {
            if (p == mc.player || !p.isAlive()) continue;
            MutableComponent text = Component.literal(p.getName().getString())
                    .withStyle(Friends.isFriend(p) ? ChatFormatting.GREEN : ChatFormatting.WHITE);
            if (ping.get() && mc.getConnection() != null) {
                var info = mc.getConnection().getPlayerInfo(p.getUUID());
                if (info != null) text.append(Component.literal(" " + info.getLatency() + "ms").withStyle(ChatFormatting.GRAY));
            }
            if (health.get()) {
                float hp = p.getHealth() + p.getAbsorptionAmount();
                ChatFormatting c = hp > 15 ? ChatFormatting.GREEN : hp > 8 ? ChatFormatting.YELLOW : ChatFormatting.RED;
                text.append(Component.literal(" " + Math.round(hp)).withStyle(c));
            }
            if (distance.get()) {
                text.append(Component.literal(" " + Math.round(mc.player.distanceTo(p)) + "m").withStyle(ChatFormatting.AQUA));
            }
            if (heldItem.get()) {
                ItemStack held = p.getMainHandItem();
                if (!held.isEmpty()) text.append(Component.literal(" [" + held.getHoverName().getString() + "]").withStyle(ChatFormatting.GOLD));
            }

            Vec3 pos = WorldUtil.lerpPos(p, pt);
            stack.pushPose();
            try {
                stack.translate(pos.x - camera.x, pos.y + p.getBbHeight() - camera.y, pos.z - camera.z);
                ctx.submitNodeCollector().submitNameTag(stack, new Vec3(0.0, 0.75, 0.0), 0, text,
                        true, LightCoordsUtil.FULL_BRIGHT, ctx.levelState().cameraRenderState);
            } finally {
                stack.popPose();
            }
        }
    }
}

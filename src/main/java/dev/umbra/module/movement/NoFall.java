package dev.umbra.module.movement;

import dev.umbra.module.Category;
import dev.umbra.module.Module;
import dev.umbra.setting.ModeSetting;
import net.minecraft.network.protocol.game.ServerboundMovePlayerPacket;
import net.minecraft.world.phys.AABB;

public class NoFall extends Module {
    private final ModeSetting mode = mode("Mode", "Packet: claim ground every tick while falling. Landing: one packet just before you land.", "Packet", "Packet", "Landing");

    public NoFall() {
        super("NoFall", Category.MOVEMENT, "Prevents fall damage");
    }

    @Override
    public void onTick() {
        if (mc.player.isFallFlying() || mc.player.getAbilities().flying) return;
        if (mc.player.fallDistance < 2.5) return;
        if (mode.is("Packet") || landingNextTick()) {
            mc.player.connection.send(new ServerboundMovePlayerPacket.StatusOnly(true, mc.player.horizontalCollision));
            if (mode.is("Packet")) mc.player.fallDistance = 0;
        }
    }

    private boolean landingNextTick() {
        var v = mc.player.getDeltaMovement();
        if (v.y >= 0) return false;
        AABB box = mc.player.getBoundingBox();
        return mc.level.getBlockCollisions(mc.player, box.expandTowards(0, v.y - 0.5, 0)).iterator().hasNext();
    }

    @Override
    public String getInfo() {
        return mode.get();
    }
}

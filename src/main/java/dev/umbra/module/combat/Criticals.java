package dev.umbra.module.combat;

import dev.umbra.module.Category;
import dev.umbra.module.Module;
import dev.umbra.setting.ModeSetting;
import net.minecraft.network.protocol.Packet;
import net.minecraft.network.protocol.game.ServerboundAttackPacket;
import net.minecraft.network.protocol.game.ServerboundMovePlayerPacket;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.boss.enderdragon.EndCrystal;

public class Criticals extends Module {
    private final ModeSetting mode = mode("Mode", "Packet fakes a tiny hop; Strict uses smaller offsets some anticheats accept", "Packet", "Packet", "Strict");

    public Criticals() {
        super("Criticals", Category.COMBAT, "Makes melee hits critical");
    }

    @Override
    public boolean onPacketSend(Packet<?> packet) {
        if (!(packet instanceof ServerboundAttackPacket(int entityId))) return false;
        if (!inGame() || !mc.player.onGround() || mc.player.isInWater() || mc.player.isInLava() || mc.player.onClimbable()) return false;
        Entity target = mc.level.getEntity(entityId);
        if (!(target instanceof LivingEntity) || target instanceof EndCrystal) return false;

        double x = mc.player.getX(), y = mc.player.getY(), z = mc.player.getZ();
        if (mode.is("Packet")) {
            mc.player.connection.send(new ServerboundMovePlayerPacket.Pos(x, y + 0.0625, z, false, mc.player.horizontalCollision));
            mc.player.connection.send(new ServerboundMovePlayerPacket.Pos(x, y, z, false, mc.player.horizontalCollision));
        } else {
            mc.player.connection.send(new ServerboundMovePlayerPacket.Pos(x, y + 0.11, z, false, mc.player.horizontalCollision));
            mc.player.connection.send(new ServerboundMovePlayerPacket.Pos(x, y + 0.1100013579, z, false, mc.player.horizontalCollision));
            mc.player.connection.send(new ServerboundMovePlayerPacket.Pos(x, y + 0.0000013579, z, false, mc.player.horizontalCollision));
        }
        return false;
    }

    @Override
    public String getInfo() {
        return mode.get();
    }
}

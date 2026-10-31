package dev.umbra.module.combat;

import dev.umbra.module.Category;
import dev.umbra.module.Module;
import dev.umbra.setting.BoolSetting;
import dev.umbra.setting.NumberSetting;
import net.minecraft.network.protocol.Packet;
import net.minecraft.network.protocol.game.ClientboundExplodePacket;
import net.minecraft.network.protocol.game.ClientboundSetEntityMotionPacket;
import net.minecraft.world.phys.Vec3;

public class Velocity extends Module {
    private final NumberSetting horizontal = number("Horizontal", "Percent of horizontal knockback kept", 0, 0, 100, 1);
    private final NumberSetting vertical = number("Vertical", "Percent of vertical knockback kept", 0, 0, 100, 1);
    private final BoolSetting explosions = bool("Explosions", "Also drop explosion knockback (loses explosion particles/sound)", true);

    public Velocity() {
        super("Velocity", Category.COMBAT, "Reduces or removes knockback");
    }

    @Override
    public boolean onPacketReceive(Packet<?> packet) {
        var player = mc.player;
        if (player == null) return false;

        if (packet instanceof ClientboundSetEntityMotionPacket motion && motion.id() == player.getId()) {
            double h = horizontal.get() / 100.0, v = vertical.get() / 100.0;
            if (h == 0 && v == 0) return true;
            var m = motion.movement();
            // Apply the scaled push ourselves on the client thread and drop the original.
            mc.execute(() -> {
                if (mc.player == null) return;
                Vec3 cur = mc.player.getDeltaMovement();
                mc.player.setDeltaMovement(
                        cur.x + (m.x() - cur.x) * h,
                        cur.y + (m.y() - cur.y) * v,
                        cur.z + (m.z() - cur.z) * h);
            });
            return true;
        }
        return explosions.get() && packet instanceof ClientboundExplodePacket;
    }

    @Override
    public String getInfo() {
        return horizontal.getInt() + "%/" + vertical.getInt() + "%";
    }
}

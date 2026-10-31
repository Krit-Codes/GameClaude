package dev.umbra.module.render;

import dev.umbra.util.Friends;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.MobCategory;
import net.minecraft.world.entity.boss.enderdragon.EndCrystal;
import net.minecraft.world.entity.item.ItemEntity;
import net.minecraft.world.entity.player.Player;

final class EntityColors {
    private EntityColors() { }

    static final int PLAYER = 0xFFFF4040;
    static final int FRIEND = 0xFF40FF80;
    static final int HOSTILE = 0xFFFF9020;
    static final int PASSIVE = 0xFF60D0FF;
    static final int ITEM = 0xFFE0E0E0;
    static final int CRYSTAL = 0xFFC060FF;

    /** Returns 0 when the entity type is switched off. */
    static int of(Entity e, boolean players, boolean hostiles, boolean passives, boolean items, boolean crystals) {
        if (e instanceof Player) return players ? (Friends.isFriend(e) ? FRIEND : PLAYER) : 0;
        if (e instanceof ItemEntity) return items ? ITEM : 0;
        if (e instanceof EndCrystal) return crystals ? CRYSTAL : 0;
        MobCategory cat = e.getType().getCategory();
        if (cat == MobCategory.MONSTER) return hostiles ? HOSTILE : 0;
        if (cat == MobCategory.MISC) return 0;
        return passives ? PASSIVE : 0;
    }
}

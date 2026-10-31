package dev.umbra.module.render;

import dev.umbra.module.Category;
import dev.umbra.module.Module;
import net.minecraft.world.effect.MobEffectInstance;
import net.minecraft.world.effect.MobEffects;

/** Client-side night vision. The server never sees it. */
public class Fullbright extends Module {
    public Fullbright() {
        super("Fullbright", Category.RENDER, "See in the dark");
    }

    @Override
    public void onTick() {
        var current = mc.player.getEffect(MobEffects.NIGHT_VISION);
        if (current == null || current.getDuration() < 400 && !current.isInfiniteDuration()) {
            mc.player.addEffect(new MobEffectInstance(MobEffects.NIGHT_VISION, MobEffectInstance.INFINITE_DURATION, 0, false, false, false));
        }
    }

    @Override
    public void onDisable() {
        if (!inGame()) return;
        var current = mc.player.getEffect(MobEffects.NIGHT_VISION);
        if (current != null && current.isInfiniteDuration()) mc.player.removeEffect(MobEffects.NIGHT_VISION);
    }
}

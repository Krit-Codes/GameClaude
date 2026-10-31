package dev.umbra.mixin;

import dev.umbra.Umbra;
import dev.umbra.module.render.Freecam;
import net.minecraft.client.player.LocalPlayer;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(LocalPlayer.class)
public abstract class LocalPlayerMixin {
    /**
     * Player.tick() resets noPhysics to isSpectator() every tick before movement runs,
     * so Freecam has to re-apply it here, right before the player moves.
     */
    @Inject(method = "aiStep", at = @At("HEAD"))
    private void umbra$beforeAiStep(CallbackInfo ci) {
        if (Umbra.MODULES != null && Umbra.MODULES.get(Freecam.class).isEnabled()) {
            ((LocalPlayer) (Object) this).noPhysics = true;
        }
    }
}

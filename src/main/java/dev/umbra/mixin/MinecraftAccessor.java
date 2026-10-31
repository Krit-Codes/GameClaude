package dev.umbra.mixin;

import net.minecraft.client.Minecraft;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.gen.Accessor;

@Mixin(Minecraft.class)
public interface MinecraftAccessor {
    @Accessor("rightClickDelay")
    int umbra$getRightClickDelay();

    @Accessor("rightClickDelay")
    void umbra$setRightClickDelay(int delay);

    @Accessor("fps")
    static int umbra$getFps() {
        throw new AssertionError();
    }
}

package dev.umbra.mixin;

import dev.umbra.Umbra;
import io.netty.channel.ChannelFutureListener;
import io.netty.channel.ChannelHandlerContext;
import net.minecraft.network.Connection;
import net.minecraft.network.protocol.Packet;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

/**
 * The only packet hook the client needs. Incoming packets are seen on the netty thread before
 * vanilla handles them; outgoing packets are seen on the three-argument send, which every other
 * send overload funnels into in 26.2.
 */
@Mixin(Connection.class)
public abstract class ConnectionMixin {
    @Inject(method = "channelRead0(Lio/netty/channel/ChannelHandlerContext;Lnet/minecraft/network/protocol/Packet;)V",
            at = @At("HEAD"), cancellable = true)
    private void umbra$onReceive(ChannelHandlerContext context, Packet<?> packet, CallbackInfo ci) {
        if (Umbra.MODULES != null && Umbra.MODULES.onPacketReceive(packet)) ci.cancel();
    }

    @Inject(method = "send(Lnet/minecraft/network/protocol/Packet;Lio/netty/channel/ChannelFutureListener;Z)V",
            at = @At("HEAD"), cancellable = true)
    private void umbra$onSend(Packet<?> packet, ChannelFutureListener listener, boolean flush, CallbackInfo ci) {
        if (Umbra.MODULES != null && Umbra.MODULES.onPacketSend(packet)) ci.cancel();
    }
}

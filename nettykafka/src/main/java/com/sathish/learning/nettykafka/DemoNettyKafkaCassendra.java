package com.sathish.learning.nettykafka;

import io.netty.bootstrap.ServerBootstrap;
import io.netty.buffer.PooledByteBufAllocator;
import io.netty.channel.ChannelFuture;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.ChannelOption;
import io.netty.channel.ChannelPipeline;
import io.netty.channel.EventLoopGroup;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioServerSocketChannel;
import io.netty.handler.codec.http.HttpRequestDecoder;
import io.netty.handler.codec.http.HttpResponseEncoder;

public class DemoNettyKafkaCassendra {
	public static void main(String[] args) throws InterruptedException {

		EventLoopGroup bossGroup = new NioEventLoopGroup(1);
		EventLoopGroup workerGroup = new NioEventLoopGroup();

		try {
			ServerBootstrap bootstrap = new ServerBootstrap();
			bootstrap
					.group(bossGroup, workerGroup)
					.channel(NioServerSocketChannel.class)
					.option(ChannelOption.SO_BACKLOG, 200)
					.childOption(ChannelOption.ALLOCATOR,
							PooledByteBufAllocator.DEFAULT)
					.childHandler(new ChannelInitializer<SocketChannel>() {
						@Override
						public void initChannel(SocketChannel ch)
								throws Exception {
							ChannelPipeline p = ch.pipeline();
							p.addLast(new HttpRequestDecoder());
							p.addLast(new HttpResponseEncoder());
							p.addLast(new MySuperHttpHandler());
						}
					});

			ChannelFuture future = bootstrap.bind(8000).sync();

			future.channel().closeFuture().sync();

		} finally {
			bossGroup.shutdownGracefully();
			workerGroup.shutdownGracefully();

			bossGroup.terminationFuture().sync();
			workerGroup.terminationFuture().sync();
		}

	}
}

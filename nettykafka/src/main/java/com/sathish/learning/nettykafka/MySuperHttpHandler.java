package com.sathish.learning.nettykafka;

import java.io.IOException;

import io.netty.buffer.ByteBuf;
import io.netty.buffer.Unpooled;
import io.netty.channel.ChannelFutureListener;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.SimpleChannelInboundHandler;
import io.netty.handler.codec.http.DefaultFullHttpResponse;
import io.netty.handler.codec.http.FullHttpResponse;
import io.netty.handler.codec.http.HttpHeaders;
import io.netty.handler.codec.http.HttpRequest;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.handler.codec.http.HttpVersion;
import io.netty.util.CharsetUtil;

public class MySuperHttpHandler extends SimpleChannelInboundHandler<Object> {
	private static byte[] CONTENT = "You request has been registerted with us"
			.getBytes();

	@Override
	public void channelReadComplete(ChannelHandlerContext ctx) {

		ctx.flush();
	}

	@Override
	public void channelRead0(ChannelHandlerContext ctx, Object msg) throws IOException {

		if (msg instanceof HttpRequest) {
			HttpRequest req = (HttpRequest) msg;

			String reqUrl = req.getUri();
			String cont = req.getUri().split("/")[1];
System.out.println(reqUrl);
			if (cont.equals("request")) {
				KafkaProducer kp = new KafkaProducer(req);
				kp.process();
				CONTENT = "Success: You request has been registerted with us"
						.getBytes();
				Browser[] browsersData = null;
				respond(ctx, "request", req, browsersData);
			} else if (cont.equals("report")) {
				Browser[] browsersData = showReportingUI();
				respond(ctx, "report", req, browsersData);
			} else {
				System.out.println("exit here for the unsupported request.");
				CONTENT = "Exception: You request hasn't been accepted"
						.getBytes();
				Browser[] browsersData = null;
				respond(ctx, "exception", req, browsersData);
			}

		}
	}

	@SuppressWarnings("null")
	private void respond(ChannelHandlerContext ctx, String repondType,
			HttpRequest req, Browser[] browsersData) {
		// this is the response part
		if (HttpHeaders.is100ContinueExpected(req)) {
			ctx.write(new DefaultFullHttpResponse(HttpVersion.HTTP_1_1,
					HttpResponseStatus.CONTINUE));
		}
		boolean keepAlive = HttpHeaders.isKeepAlive(req);

		StringBuilder buf = null;
		FullHttpResponse response;
		if (repondType == "report") {
			buf = new StringBuilder()
					.append("<html><head>"
							+ " <script type=\"text/javascript\" src=\"https://www.google.com/jsapi\"></script>"
							+ "<script type=\"text/javascript\">google.load(\"visualization\", \"1\", {packages:[\"corechart\"]});"
							+ "google.setOnLoadCallback(drawChart);"
							+ "function drawChart() {"
							+ "        var data = google.visualization.arrayToDataTable(["
							+ "          [\"Browser Name\", \"Hits\"],");
			for (int i = 0; i < browsersData.length; i++) {
				String brw_name = browsersData[i].BrowserName;
				long hits = browsersData[i].hits;
				buf.append("          [\"" + brw_name + "\",     " + hits
						+ "],");
			}
			buf.append("]);"
					+ "        var options = {"
					+ "          title: \"Various Browsers Hits\""
					+ "        };"
					+ "        var chart = new google.visualization.PieChart(document.getElementById(\"piechart\"));"
					+ "       chart.draw(data, options);"
					+ "     }"
					+ "   </script>"
					+ " </head><body><div id=\"piechart\" style=\"width: 900px; height: 500px;\"></div></body></html>");
			ByteBuf buffer = Unpooled.copiedBuffer(buf, CharsetUtil.UTF_8);

			response = new DefaultFullHttpResponse(HttpVersion.HTTP_1_1,
					HttpResponseStatus.OK);

			response.content().writeBytes(buffer);
		} else {
			response = new DefaultFullHttpResponse(HttpVersion.HTTP_1_1,
					HttpResponseStatus.OK, Unpooled.wrappedBuffer(CONTENT));
		}

		response.headers().set(HttpHeaders.Names.CONTENT_TYPE,
				"text/html; charset=UTF-8");
		response.headers().set(HttpHeaders.Names.CONTENT_LENGTH,
				response.content().readableBytes());

		if (!keepAlive) {
			ctx.write(response).addListener(ChannelFutureListener.CLOSE);
		} else {
			response.headers().set(HttpHeaders.Names.CONNECTION,
					HttpHeaders.Values.KEEP_ALIVE);

			ctx.write(response);
		}

	}

	@SuppressWarnings("null")
	public Browser[] showReportingUI() {
		// Load into Cassendra
		CassandraLoader cl = null;
		try {
			cl = new CassandraLoader();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		Browser[] browsers = cl.readAll();

		cl.closeclientConnection();
		return browsers;
	}

	@Override
	public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) {
		ctx.close();
	}
}
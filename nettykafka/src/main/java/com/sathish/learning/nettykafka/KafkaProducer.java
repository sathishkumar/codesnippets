package com.sathish.learning.nettykafka;

import io.netty.handler.codec.http.HttpRequest;

import java.util.Properties;

import kafka.producer.KeyedMessage;
import kafka.producer.ProducerConfig;

public class KafkaProducer {
	HttpRequest request;
	Properties props;
	kafka.javaapi.producer.Producer<String, String> producer = null;

	KafkaProducer(HttpRequest req) {
		request = req;
		props = new Properties();
		props.put("metadata.broker.list", "localhost:9092");
		props.put("zk.connect", "localhost:2181");
		props.put("serializer.class", "kafka.serializer.StringEncoder");
		props.put("partitioner.class",
				"com.sathish.learning.nettykafka.SimplePartitioner");
		props.put("request.required.acks", "1");
		props.put("auto.commit.interval.ms", "1000");

		try {
			ProducerConfig config = new ProducerConfig(props);
			producer = new kafka.javaapi.producer.Producer<String, String>(
					config);
		} catch (Throwable t) {
			t.printStackTrace();
		}
	}

	public void process() {
//		System.out.println("test here..." + request.headers().entries());// .get("User-Agent").toString());
		String ua = request.headers().get("User-Agent");
		try {
			KeyedMessage<String, String> data = new KeyedMessage<String, String>(
					"User-Agents", ua);
			producer.send(data);
			System.out.println(data);
		} catch (Throwable t) {
			t.printStackTrace();
		}
		producer.close();
	}
}
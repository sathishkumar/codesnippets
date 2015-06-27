package com.sathish.learning.nettykafka;

import io.netty.handler.codec.http.HttpRequest;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

import kafka.producer.KeyedMessage;
import kafka.producer.ProducerConfig;

public class KafkaProducer {
	HttpRequest request;
	Properties props;

	String broker_list = "", zk_connect = "", serializer_class = "",
			partitioner_class = "", req_required_acks = "",
			auto_commit_interval_in_ms = "", group_id = "", topic_name = "";

	// CONSTANTS
	String BROKERLIST = "metadata.broker.list";
	String ZK_CONNECT = "zk.connect";
	String SERIALIZER_CLASS = "serializer.class";
	String PARTITIONER_CLASS = "partitioner.class";
	String REQ_REQUIRED_ACKS = "request.required.acks";
	String AUTO_COMMIT_INTERVAL_IN_MS = "auto.commit.interval.ms";
	String GROUP_ID = "group.id";

	kafka.javaapi.producer.Producer<String, String> producer = null;

	public void getPropValues() throws IOException {

		Properties prop = new Properties();
		String propFileName = "kafka.properties";

		InputStream inputStream = getClass().getClassLoader()
				.getResourceAsStream(propFileName);

		if (inputStream != null) {
			prop.load(inputStream);
		} else {
			throw new FileNotFoundException("property file '" + propFileName
					+ "' not found in the classpath");
		}

		// get the property value and print it out
		broker_list = prop.getProperty("broker.list");
		zk_connect = prop.getProperty("zk.connect");
		serializer_class = prop.getProperty("serializer.class");
		partitioner_class = prop.getProperty("partitioner.class");
		req_required_acks = prop.getProperty("request.required.acks");
		auto_commit_interval_in_ms = prop
				.getProperty("auto.commit.interval.ms");
		group_id = prop
				.getProperty("group.id");
		topic_name = prop.getProperty("topic.name");

	}

	KafkaProducer(HttpRequest req) throws IOException {
		request = req;
		getPropValues();
		props = new Properties();
		props.put(BROKERLIST, broker_list);
		props.put(ZK_CONNECT, zk_connect);
		props.put(SERIALIZER_CLASS, serializer_class);
		props.put(PARTITIONER_CLASS, partitioner_class);
		props.put(REQ_REQUIRED_ACKS, req_required_acks);
		props.put(AUTO_COMMIT_INTERVAL_IN_MS, auto_commit_interval_in_ms);
		props.put("GROUP_ID", group_id);

		try {
			ProducerConfig config = new ProducerConfig(props);
			producer = new kafka.javaapi.producer.Producer<String, String>(
					config);
		} catch (Throwable t) {
			t.printStackTrace();
		}
	}

	public void process() {
		// System.out.println("test here..." + request.headers().entries());//
		// .get("User-Agent").toString());
		String ua = request.headers().get("User-Agent");
		try {
			KeyedMessage<String, String> data = new KeyedMessage<String, String>(
					topic_name, ua);
			producer.send(data);
			System.out.println(data);
		} catch (Throwable t) {
			t.printStackTrace();
		}
		producer.close();
	}
}
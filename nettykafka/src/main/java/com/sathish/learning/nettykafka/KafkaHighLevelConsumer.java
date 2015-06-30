package com.sathish.learning.nettykafka;

import java.io.File;
import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import kafka.consumer.ConsumerConfig;
import kafka.consumer.KafkaStream;
import kafka.javaapi.consumer.ConsumerConnector;

public class KafkaHighLevelConsumer {

	private final ConsumerConnector consumer;
	private final String topic;
	private ExecutorService executor;
	static File file = new File("/tmp/consumer.lock");
	
	public KafkaHighLevelConsumer(String a_zookeeper, String a_groupId,
			String a_topic) {
		consumer = kafka.consumer.Consumer
				.createJavaConsumerConnector(createConsumerConfig(a_zookeeper,
						a_groupId));
		this.topic = a_topic;
	}

	public void shutdown() {
		 if (consumer != null)
		 consumer.shutdown();
		 if (executor != null)
		 executor.shutdown();
		try {
			if (!executor.awaitTermination(5000, TimeUnit.MILLISECONDS)) {
				System.out
						.println("Timed out waiting for consumer threads to shut down, exiting uncleanly");
			}
		} catch (InterruptedException e) {
			System.out
					.println("Interrupted during shutdown, exiting uncleanly");
		}
	}

	public void run(int a_numThreads) throws IOException {
		Map<String, Integer> topicCountMap = new HashMap<String, Integer>();
		topicCountMap.put(topic, new Integer(a_numThreads));
		Map<String, List<KafkaStream<byte[], byte[]>>> consumerMap = consumer
				.createMessageStreams(topicCountMap);
		List<KafkaStream<byte[], byte[]>> streams = consumerMap.get(topic);
		CassandraLoader cl = new CassandraLoader();
		// now launch all the threads
		//
		executor = Executors.newFixedThreadPool(a_numThreads);
		// now create an object to consume the messages
		//
		System.out.println(streams.size());
		int threadNumber = 0;
		for (final KafkaStream stream : streams) {
			executor.submit(new ConsumerWrite(stream, threadNumber, cl));
			threadNumber++;
		}
	}

	private static ConsumerConfig createConsumerConfig(String a_zookeeper,
			String a_groupId) {
		Properties props = new Properties();
		props.put("zookeeper.connect", a_zookeeper);
		props.put("group.id", a_groupId);
		props.put("zookeeper.session.timeout.ms", "400");
		props.put("zookeeper.sync.time.ms", "200");
		props.put("auto.commit.interval.ms", "1000");
		props.put("auto.commit.enabled", "true");
		return new ConsumerConfig(props);
	}

	public static void main(String[] args) throws IOException {
		String zooKeeper = args[0];
		String groupId = args[1];
		String topic = args[2];
		int threads = Integer.parseInt(args[3]);
		KafkaHighLevelConsumer example = new KafkaHighLevelConsumer(zooKeeper,
				groupId, topic);
		if (file.createNewFile()){
	        System.out.println("Consumer Lock File is created!");
	        example.run(threads);
	      }else{
	        System.out.println("Consumer Lock File already exists.");
	        return;
	      }		

		 try {
		 Thread.sleep(20000);
		 } catch (InterruptedException ie) {
		
		 }
		 example.shutdown();

	}
}
package com.sathish.learning.nettykafka;

import java.io.IOException;
import java.io.UnsupportedEncodingException;

import kafka.consumer.ConsumerIterator;
import kafka.consumer.KafkaStream;
import kafka.message.MessageAndMetadata;

public class ConsumerWrite implements Runnable {
	private KafkaStream m_stream;
	private int m_threadNumber;
	CassandraLoader cl = null;

	public ConsumerWrite(KafkaStream a_stream, int a_threadNumber,
			CassandraLoader cl1) throws IOException {
		m_threadNumber = a_threadNumber;
		m_stream = a_stream;
		cl = cl1;
	}

	public void run() {
		ConsumerIterator<byte[], byte[]> it = m_stream.iterator();
		String msg = null;
		long offset = 0;

		while (it.hasNext()) {
			MessageAndMetadata<byte[], byte[]> row = it.next();
			try {
				msg = new String(row.message(), "UTF-8");
			} catch (UnsupportedEncodingException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			offset = row.offset();
			System.out.println("Thread " + m_threadNumber + ": " + msg
					+ "offset:" + offset);
			// Find Browser name from User Agent
			BrowserFinder bn = new BrowserFinder(msg);
			// Write into Cassendra
			cl.write(bn.findBrowserName());
			System.out.println("Shutting down Thread: " + m_threadNumber);
		}
	}
}
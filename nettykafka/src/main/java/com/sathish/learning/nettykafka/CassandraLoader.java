package com.sathish.learning.nettykafka;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.util.Date;
import java.util.List;
import java.util.Properties;

import com.datastax.driver.core.ResultSet;
import com.datastax.driver.core.Row;

public class CassandraLoader {

	int count = 0;
	String browserLoaded = new String();
	CassandraConnector client;
	String ipAddress = "127.0.0.1";
	int port = 0;

	public void getPropValues() throws IOException {

		Properties prop = new Properties();
		String propFileName = "cassandra.properties";

		InputStream inputStream = getClass().getClassLoader()
				.getResourceAsStream(propFileName);

		if (inputStream != null) {
			prop.load(inputStream);
		} else {
			throw new FileNotFoundException("property file '" + propFileName
					+ "' not found in the classpath");
		}

		// get the property value and print it out
		ipAddress = prop.getProperty("node");
		port = Integer.parseInt(prop.getProperty("port"));

	}

	public CassandraLoader() throws IOException {
		getPropValues();
		init(ipAddress, port);
	}

	public static void main(String args[]) throws IOException {
		CassandraLoader cl = new CassandraLoader();
		cl.readAll();
	}

	public void init(String node, int portnum) {
		client = new CassandraConnector();
		client.connect(ipAddress, port);

	}

	public Browser[] readAll() {
		String query = "SELECT * FROM mykeyspace.Browsers";

		// Use select to get the user we just entered
		ResultSet results = client.getSession().execute(query);
		List<Row> rowsList = results.all();
		Browser[] browserArray = new Browser[rowsList.size()];

		try {
			// for (Row row : results) {
			for (int i = 0; i < rowsList.size(); i++) {
				String brw_name = rowsList.get(i).getString("browser_name");
				long count = rowsList.get(i).getLong("count");
				System.out.format("%s %d\n", brw_name, count);
				browserArray[i] = new Browser(brw_name, count);
			}
		} catch (Throwable t) {
			t.printStackTrace();
		}

		closeclientConnection();
		return browserArray;
	}

	public void write(String browser_name) {
		System.out.println("comes here to write into Cassandra..........");
		client.getSession().execute(
				"UPDATE mykeyspace.Browsers SET count = count + 1 WHERE browser_name='"
						+ browser_name + "';");
	}

	public void closeclientConnection() {
		// Clean up the connection by closing it
		client.close();
	}
}
package com.sathish.learning.nettykafka;

import java.util.List;

import com.datastax.driver.core.ResultSet;
import com.datastax.driver.core.Row;

public class CassandraLoader {

	int count = 0;
	String browserLoaded = new String();
	CassandraConnector client;

	public CassandraLoader() {
		init("127.0.0.1", 9042);
	}

	public static void main(String args[]) {
		CassandraLoader cl = new CassandraLoader();
		cl.readAll();
	}

	public void init(String node, int portnum) {
		client = new CassandraConnector();
		final String ipAddress = node != "" ? node : "localhost";
		final int port = (portnum == 9042) ? portnum : 9042;
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
		client.getSession().execute(
				"UPDATE mykeyspace.Browsers SET count = count + 1 WHERE browser_name='"
						+ browser_name + "';");
	}

	public void closeclientConnection() {
		// Clean up the connection by closing it
		client.close();

	}
}
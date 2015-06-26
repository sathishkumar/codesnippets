package com.sathish.learning.nettykafka;

import com.datastax.driver.core.Cluster;
import com.datastax.driver.core.ResultSet;
import com.datastax.driver.core.Row;
import com.datastax.driver.core.Session;

public class GettingStarted {

    public static void main(String[] args) {
    	Cluster cluster;
    	Session session;
    	// Connect to the cluster and keyspace "demo"
    	cluster = Cluster.builder().addContactPoint("127.0.0.1").build();
    	session = cluster.connect("mykeyspace");
    	System.out.println("here it comes out....");
    	    	// Use select to get the user we just entered
    	ResultSet results = session.execute("SELECT * FROM users WHERE lname='smith'");
    	for (Row row : results) {
    	System.out.format("%s %d\n", row.getString("fname"), row.getInt("user_id"));
    	}
    	
    	CassandraLoader cl = new CassandraLoader();
    	cl.readAll();
    }
   
}    

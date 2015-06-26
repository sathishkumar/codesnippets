package com.sathish.learning.nettykafka;

public class Browser {

	String BrowserName = "";
	long hits = 0;

	public Browser(String browser_name, long count) {
		BrowserName = browser_name;
		hits = count;
	}
}

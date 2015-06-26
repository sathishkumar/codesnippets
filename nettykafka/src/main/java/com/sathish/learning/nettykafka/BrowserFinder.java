package com.sathish.learning.nettykafka;


public class BrowserFinder {
	String UserAgent = "";
	
	public BrowserFinder(String ua){
		UserAgent = ua;
	}
	
	public String findBrowserName(){
    	String browserName = "";
    	// In Opera 15+, the true version is after "OPR/" 
    	if ((UserAgent.indexOf("OPR/"))!=-1) {
    	 browserName = "Opera";
    	}
    	// In older Opera, the true version is after "Opera" or after "Version"
    	else if ((UserAgent.indexOf("Opera"))!=-1) {
    	 browserName = "Opera";
    	}
    	// In MSIE, the true version is after "MSIE" in userAgent
    	else if ((UserAgent.indexOf("MSIE"))!=-1) {
    	 browserName = "Microsoft Internet Explorer";
    	}
    	// In Chrome, the true version is after "Chrome" 
    	else if ((UserAgent.indexOf("Chrome"))!=-1) {
    	 browserName = "Chrome";
    	}
    	// In Safari, the true version is after "Safari" or after "Version" 
    	else if ((UserAgent.indexOf("Safari"))!=-1) {
    	 browserName = "Safari";
    	}
    	// In Firefox, the true version is after "Firefox" 
    	else if ((UserAgent.indexOf("Firefox"))!=-1) {
    	 browserName = "Firefox";
    	}
    	else {
    		browserName = "Others";
    	}
    	return browserName;
    }
   
}    

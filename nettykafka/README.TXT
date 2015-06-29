## This is new project created for solve below question:

Question:
Complete the code test in next 2 days

1.HTTP AdServer 
This should contain a netty server web end point to receive request. On receiving a web request it should write to kafka.
Let's say you have an endpoint
http://localhost/request
So when we fire this url from a browser, you need to identify the browser and write data to kafka. 
Consume the data from kafka and write into cassandra.
Later you can read the data back from cassandra to show reports.

2.Reports Page
As a user i should be able to see a pie chart for number of times the request came from a particular browser.

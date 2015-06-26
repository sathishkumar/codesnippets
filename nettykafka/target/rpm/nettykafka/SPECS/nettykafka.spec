%define _unpackaged_files_terminate_build 0
Name: nettykafka
Version: 0.1
Release: 1
Summary: nettykafka
License: sathish-learning
Distribution: sathish-learning
Group: utilties
Packager: learning
Provides: nettykafka
autoprov: yes
autoreq: yes
BuildRoot: /home/km/KMRepo/Workspace/Atom-Prime-UI/nettykafka/target/rpm/nettykafka/buildroot

%description

%files

%attr(775,root,root) /opt/nettykafka/bin
%attr(775,root,root) /opt/nettykafka/lib/nettykafka-0.1.jar
%attr(775,root,root) /opt/nettykafka/lib/cassandra-driver-core-2.0.2.jar
%attr(775,root,root) /opt/nettykafka/lib/log4j-1.2.15.jar
%attr(775,root,root) /opt/nettykafka/lib/scala-library-2.9.2.jar
%attr(775,root,root) /opt/nettykafka/lib/snappy-java-1.0.5.jar
%attr(775,root,root) /opt/nettykafka/lib/metrics-core-2.2.0.jar
%attr(775,root,root) /opt/nettykafka/lib/kafka_2.9.2-0.8.1.1.jar
%attr(775,root,root) /opt/nettykafka/lib/netty-all-4.0.29.Final.jar
%attr(775,root,root) /opt/nettykafka/lib/zkclient-0.3.jar
%attr(775,root,root) /opt/nettykafka/lib/netty-3.9.0.Final.jar
%attr(775,root,root) /opt/nettykafka/lib/metrics-core-3.0.2.jar
%attr(775,root,root) /opt/nettykafka/lib/mail-1.4.jar
%attr(775,root,root) /opt/nettykafka/lib/jopt-simple-3.2.jar
%attr(775,root,root) /opt/nettykafka/lib/activation-1.1.jar
%attr(775,root,root) /opt/nettykafka/lib/jline-0.9.94.jar
%attr(775,root,root) /opt/nettykafka/lib/slf4j-api-1.7.5.jar
%attr(775,root,root) /opt/nettykafka/lib/zookeeper-3.3.4.jar
%attr(775,root,root) /opt/nettykafka/lib/guava-16.0.1.jar
%dir %attr(775,root,root) /opt/nettykafka/logs

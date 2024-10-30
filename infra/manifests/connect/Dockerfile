FROM quay.io/debezium/connect:latest

RUN mkdir /kafka/etc && cd /kafka/etc &&\
    curl -so jmx_prometheus_javaagent.jar \
    https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.15.0/jmx_prometheus_javaagent-0.15.0.jar

COPY ./config.yml /kafka/etc/config.yml
COPY ./debezium-connector-oracle /kafka/connect


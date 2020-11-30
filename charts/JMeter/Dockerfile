FROM openjdk:8-jdk-slim
		
ARG JMETER_VERSION=5.3
		
RUN apt-get clean && \
apt-get update && \
apt-get -qy install \
wget curl \
unzip

RUN   mkdir /jmeter \
&& cd /jmeter/ \
&& wget https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-$JMETER_VERSION.tgz \
&& tar -xzf apache-jmeter-$JMETER_VERSION.tgz \
&& rm apache-jmeter-$JMETER_VERSION.tgz

ENV JMETER_HOME /jmeter/apache-jmeter-$JMETER_VERSION/
		
ENV PATH $JMETER_HOME/bin:$PATH

# https://jmeter-plugins.org/wiki/TestPlanCheckTool/
ENV PLAN_CHECK_PLUGIN_VERSION=2.4
RUN wget https://jmeter-plugins.org/files/packages/jpgc-plancheck-${PLAN_CHECK_PLUGIN_VERSION}.zip \
&& unzip -o jpgc-plancheck-${PLAN_CHECK_PLUGIN_VERSION}.zip -d ${JMETER_HOME} \
&& rm jpgc-plancheck-${PLAN_CHECK_PLUGIN_VERSION}.zip
RUN cd /jmeter/apache-jmeter-$JMETER_VERSION/ && wget -q -O /tmp/JMeterPlugins-Standard-1.4.0.zip https://jmeter-plugins.org/downloads/file/JMeterPlugins-Standard-1.4.0.zip && unzip -n /tmp/JMeterPlugins-Standard-1.4.0.zip && rm /tmp/JMeterPlugins-Standard-1.4.0.zip

ENV BZM_PARALLEL_PLUGIN_VERSION=0.9
RUN cd /jmeter/apache-jmeter-$JMETER_VERSION/ \
&& wget -q -O /tmp/bzm-parallel-${BZM_PARALLEL_PLUGIN_VERSION}.zip https://jmeter-plugins.org/files/packages/bzm-parallel-${BZM_PARALLEL_PLUGIN_VERSION}.zip \
&& unzip -n /tmp/bzm-parallel-${BZM_PARALLEL_PLUGIN_VERSION}.zip \
&& rm /tmp/bzm-parallel-${BZM_PARALLEL_PLUGIN_VERSION}.zip

COPY docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 60000 1099 50000

ENTRYPOINT ["/entrypoint.sh"]
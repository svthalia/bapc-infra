FROM debian:stretch as build

ENV CDS_ZIP_URL https://pc2.ecs.csus.edu/pc2projects/build/CDS/dist/wlp.CDS-2.1.2100.zip

ENV CDS_VERSION 2.1.2100

ENV BUILDDEPS "unzip ca-certificates curl"

RUN export DEBIAN_FRONTEND=noninteractive && \
	apt-get update && apt-get install -y --no-install-recommends $BUILDDEPS && \
	curl -k -L -o /opt/wlp.CDS-${CDS_VERSION}.zip ${CDS_ZIP_URL} && \
	unzip /opt/wlp.CDS-${CDS_VERSION}.zip -d /opt && \
	mkdir /contest

FROM debian:stretch

COPY --from=build /opt/wlp /opt/wlp
COPY --from=build /contest /contest

ENV RUNDEPS "openjdk-8-jdk-headless"

RUN export DEBIAN_FRONTEND=noninteractive && \
	apt-get update && apt-get install -y --no-install-recommends $RUNDEPS && \
	apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY server.xml /opt/wlp/usr/servers/cds/server.xml
COPY users.xml /opt/wlp/usr/servers/cds/users.xml

EXPOSE 80

COPY ["./start.sh", "/scripts/start.sh"]

RUN chmod 755 /scripts/start.sh

ENTRYPOINT ["/scripts/start.sh"]
CMD /opt/wlp/bin/server run cds

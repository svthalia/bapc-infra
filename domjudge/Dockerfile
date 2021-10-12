FROM domjudge/domserver:latest
MAINTAINER Study Association Thalia BAPCie <bapc@thalia.nu>


ENV CUPS_SERVER=localhost

# Install required packages for CUPS
RUN apt-get update \
        && apt-get install --no-install-recommends --no-install-suggests -y \
        cups-client cups-bsd \
        && rm -rf /var/lib/apt/lists/*

COPY ["./start.sh", "/scripts/start.sh"]

RUN chmod 755 /scripts/start.sh

CMD ["/scripts/start.sh"]

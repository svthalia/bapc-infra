FROM domjudge/domserver:9.0.0
MAINTAINER Study Association Thalia BAPCie <bapc@thalia.nu>

ARG MAX_MEM=4G
ARG MAX_UPLOAD=2G

ENV CUPS_SERVER=localhost

# Install required packages for CUPS
RUN apt-get update \
        && apt-get install --no-install-recommends --no-install-suggests -y \
        cups-client cups-bsd \
        && rm -rf /var/lib/apt/lists/*

# Set the max uploads for ini
RUN sed -ri -e "s/(php_admin_value\[memory_limit\] =).*/\1 ${MAX_MEM}/" /opt/domjudge/domserver/etc/domjudge-fpm.conf
RUN sed -ri -e "s/(php_admin_value\[upload_max_filesize\] =).*/\1 ${MAX_UPLOAD}/" /opt/domjudge/domserver/etc/domjudge-fpm.conf
RUN sed -ri -e "s/(php_admin_value\[post_max_size\] =).*/\1 ${MAX_UPLOAD}/" /opt/domjudge/domserver/etc/domjudge-fpm.conf

COPY ["./cups.sh", "/scripts/start.d/20-cups.sh"]

RUN chmod 755 /scripts/start.d/20-cups.sh

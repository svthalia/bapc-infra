#!/bin/bash

useradd \
  --groups=sudo,lp,lpadmin \
  --create-home \
  --home-dir=/home/${PRINT_USER} \
  --shell=/bin/bash \
  --password=$(mkpasswd ${PRINT_PASSWORD}) \
  ${PRINT_USER} \

exec /usr/sbin/cupsd -f



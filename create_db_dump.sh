#!/bin/bash

docker-compose exec dj-mariadb mysqldump \
  --all-databases --user=root \
  --password=$(grep "MYSQL_ROOT_PASSWORD" < database.env | sed 's/^MYSQL_ROOT_PASSWORD=//') \
  > database_dumps/dump_`date +%d-%m-%Y"_"%H_%M_%S`.sql


#!/bin/bash

docker-compose exec -T dj-mariadb mysql --user=root --password=$(grep "MYSQL_ROOT_PASSWORD" < database.env | sed 's/^MYSQL_ROOT_PASSWORD=//') < $1

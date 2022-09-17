#!/bin/sh -eu

DOCKER_GATEWAY_IP=$(/sbin/ip route|awk '/default/ { print $3 }')

# Add the Docker gateway as a trusted proxy
if grep -q TRUSTED_PROXIES /opt/domjudge/domserver/webapp/.env.local > /dev/null 2>&1
then
	sed -i "s|TRUSTED_PROXIES=.*|TRUSTED_PROXIES=${DOCKER_GATEWAY_IP}/24|" /opt/domjudge/domserver/webapp/.env.local
else
	echo "TRUSTED_PROXIES=${DOCKER_GATEWAY_IP}/24" >> /opt/domjudge/domserver/webapp/.env.local
fi


#!/usr/bin/env bash
set -e

: "${ADMIN_CDS_PW:=adm1n}"
: "${PRESADMIN_CDS_PW:=presadm1n}"
: "${BALLOON_CDS_PW:=balloonPr1nter}"
: "${BLUE_CDS_PW:=blu3}"
: "${PUBLIC_CDS_PW:=publ1c}"
: "${PRESENTATION_CDS_PW:=presentat1on}"
: "${MYICPC_CDS_PW:=my1cpc}"
: "${LIVE_CDS_PW:=l1ve}"

sed -i "s/password=\"admin_pw\"/password=\"${ADMIN_CDS_PW}\"/" /opt/wlp/usr/servers/cds/users.xml
sed -i "s/password=\"presadmin_pw\"/password=\"${PRESADMIN_CDS_PW}\"/" /opt/wlp/usr/servers/cds/users.xml
sed -i "s/password=\"balloon_pw\"/password=\"${BALLOON_CDS_PW}\"/" /opt/wlp/usr/servers/cds/users.xml
sed -i "s/password=\"blue_pw\"/password=\"${BLUE_CDS_PW}\"/" /opt/wlp/usr/servers/cds/users.xml
sed -i "s/password=\"public_pw\"/password=\"${PUBLIC_CDS_PW}\"/" /opt/wlp/usr/servers/cds/users.xml
sed -i "s/password=\"icpc_pw\"/password=\"${MYICPC_CDS_PW}\"/" /opt/wlp/usr/servers/cds/users.xml
sed -i "s/password=\"live_pw\"/password=\"${LIVE_CDS_PW}\"/" /opt/wlp/usr/servers/cds/users.xml
sed -i "s/password=\"presentation_pw\"/password=\"${PRESENTATION_CDS_PW}\"/" /opt/wlp/usr/servers/cds/users.xml

exec "$@"


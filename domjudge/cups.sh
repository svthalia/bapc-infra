#!/bin/sh -eu

echo "[..] Changing CUPS settings"
mkdir -p /etc/cups
echo "ServerName ${CUPS_SERVER}" > /etc/cups/client.conf
echo "[ok] Remote CUPS server set to: ${CUPS_SERVER}"; echo

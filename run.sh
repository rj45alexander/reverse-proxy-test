#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run with sudo."
    exit 1
fi

cleanup() {
    if [[ "$CLEANED" == "1" ]]; then return; fi
    CLEANED=1

    trap '' INT TERM # prevent ctrl+c during cleanup
    
    echo -e "\nKilling remote port..."
    ssh -i auth/id_rsa root@$VPS_IP "fuser -k 5555/tcp || true" >/dev/null 2>&1 
    echo "Done."
}

trap cleanup INT TERM EXIT

> logs/socks.log

source config.env
# VPS_IP
# REMOTE_TUNNEL_PORT
# PROXY_PORT

# get interface
ROUTE_INFO=$(ip route get 1.1.1.1)
EXT_IFACE=$(awk '{print $5; exit}' <<< "$ROUTE_INFO")

sed -e "s|{{PROXY_PORT}}|$PROXY_PORT|" \
    -e "s|{{EXT_IFACE}}|$EXT_IFACE|" \
    danted.template.conf > danted.conf
    

echo "Interface: $EXT_IFACE"
echo -e "IP: $(dig +short myip.opendns.com @resolver1.opendns.com echo || 'Failed')\n"

echo "Starting Dante..."
/usr/sbin/danted -f danted.conf &

echo "Waiting for Dante..."
for ((i = 0; i<10; i++)); do
    if ss -ltn | grep -q "127.0.0.1:$PROXY_PORT"; then
        DANTE_READY=1
        break
    fi
    sleep 1
done

if [[ "$DANTE_READY" -ne 1 ]]; then
    echo "Dante did not start in time."
    exit 1
fi

echo -e "Opening tunnel to $VPS_IP\n"
exec autossh -M 0 -N \
    -i auth/id_rsa \
    -R 0.0.0.0:$REMOTE_TUNNEL_PORT:127.0.0.1:$PROXY_PORT \
    -R localhost:2222:localhost:22 \
    root@$VPS_IP \
    >/dev/null 2>&1 &
tail -F temp/socks.log

#!/bin/bash
set -e

CHROOT_DIR=$1
ENABLED=$2
PORTS=$3

if [ -z "$CHROOT_DIR" ] || [ -z "$ENABLED" ]; then
    exit 1
fi

echo "Configuring firewall..."

chroot "$CHROOT_DIR" bash -c "DEBIAN_FRONTEND=noninteractive apt-get update"
chroot "$CHROOT_DIR" bash -c "DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ufw"

if [ "$ENABLED" = "true" ]; then
    echo "Enabling firewall with default deny policy"

    chroot "$CHROOT_DIR" ufw --force reset

    chroot "$CHROOT_DIR" ufw default deny incoming
    chroot "$CHROOT_DIR" ufw default allow outgoing

    if [ -n "$PORTS" ]; then
        IFS=',' read -ra PORT_ARRAY <<< "$PORTS"
        for PORT in "${PORT_ARRAY[@]}"; do
            echo "Allowing port $PORT"
            chroot "$CHROOT_DIR" ufw allow "$PORT/tcp"
        done
    fi

    chroot "$CHROOT_DIR" ufw --force enable

    if [ -x "$CHROOT_DIR/bin/systemctl" ] || [ -x "$CHROOT_DIR/usr/bin/systemctl" ]; then
        chroot "$CHROOT_DIR" systemctl enable ufw
    fi
    
    echo "Firewall enabled and configured"
else
    echo "Disabling firewall"

    chroot "$CHROOT_DIR" ufw --force disable

    if [ -x "$CHROOT_DIR/bin/systemctl" ] || [ -x "$CHROOT_DIR/usr/bin/systemctl" ]; then
        chroot "$CHROOT_DIR" systemctl disable ufw || true
    fi
    
    echo "Firewall disabled"
fi

exit 0

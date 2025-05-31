#!/bin/bash
set -e

CHROOT_DIR=$1
HOSTNAME=$2

if [ -z "$CHROOT_DIR" ] || [ -z "$HOSTNAME" ]; then
    exit 1
fi

echo "Setting hostname to $HOSTNAME"
echo "$HOSTNAME" > "$CHROOT_DIR/etc/hostname"

if [ -f "$CHROOT_DIR/etc/hosts" ]; then
    if ! grep -q " $HOSTNAME" "$CHROOT_DIR/etc/hosts"; then
        if grep -q "127.0.0.1" "$CHROOT_DIR/etc/hosts"; then
            sed -i "s/127.0.0.1\(.*\)/127.0.0.1\1 $HOSTNAME/" "$CHROOT_DIR/etc/hosts"
        else
            echo "127.0.0.1 localhost $HOSTNAME" >> "$CHROOT_DIR/etc/hosts"
        fi
        
        if grep -q "::1" "$CHROOT_DIR/etc/hosts"; then
            sed -i "s/::1\(.*\)/::1\1 $HOSTNAME/" "$CHROOT_DIR/etc/hosts"
        else
            echo "::1 localhost $HOSTNAME" >> "$CHROOT_DIR/etc/hosts"
        fi
    fi
else
    cat > "$CHROOT_DIR/etc/hosts" << EOF
127.0.0.1 localhost $HOSTNAME
::1 localhost $HOSTNAME
EOF
fi

echo "Hostname configured successfully"
exit 0

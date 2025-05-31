#!/bin/bash
set -e

CHROOT_DIR=$1
ENABLED=$2
ALLOW_ROOT_LOGIN=$3
PASSWORD_AUTHENTICATION=$4

if [ -z "$CHROOT_DIR" ] || [ -z "$ENABLED" ]; then
    exit 1
fi

echo "Configuring SSH..."

chroot "$CHROOT_DIR" bash -c "DEBIAN_FRONTEND=noninteractive apt-get update"
chroot "$CHROOT_DIR" bash -c "DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends openssh-server"

SSH_CONFIG="$CHROOT_DIR/etc/ssh/sshd_config"

if [ -f "$SSH_CONFIG" ]; then
    cp "$SSH_CONFIG" "${SSH_CONFIG}.bak"

    if [ "$ALLOW_ROOT_LOGIN" = "true" ]; then
        echo "Allowing root login via SSH"
        sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' "$SSH_CONFIG"
    else
        echo "Disabling root login via SSH"
        sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' "$SSH_CONFIG"
    fi

    if [ "$PASSWORD_AUTHENTICATION" = "true" ]; then
        echo "Enabling password authentication for SSH"
        sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' "$SSH_CONFIG"
    else
        echo "Disabling password authentication for SSH"
        sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' "$SSH_CONFIG"
    fi

    if ! grep -q "^PermitRootLogin" "$SSH_CONFIG"; then
        if [ "$ALLOW_ROOT_LOGIN" = "true" ]; then
            echo "PermitRootLogin yes" >> "$SSH_CONFIG"
        else
            echo "PermitRootLogin no" >> "$SSH_CONFIG"
        fi
    fi
    
    if ! grep -q "^PasswordAuthentication" "$SSH_CONFIG"; then
        if [ "$PASSWORD_AUTHENTICATION" = "true" ]; then
            echo "PasswordAuthentication yes" >> "$SSH_CONFIG"
        else
            echo "PasswordAuthentication no" >> "$SSH_CONFIG"
        fi
    fi
fi

if [ "$ENABLED" = "true" ]; then
    echo "Enabling SSH service"
    if [ -x "$CHROOT_DIR/bin/systemctl" ] || [ -x "$CHROOT_DIR/usr/bin/systemctl" ]; then
        chroot "$CHROOT_DIR" systemctl enable ssh
    fi
else
    echo "Disabling SSH service"
    if [ -x "$CHROOT_DIR/bin/systemctl" ] || [ -x "$CHROOT_DIR/usr/bin/systemctl" ]; then
        chroot "$CHROOT_DIR" systemctl disable ssh || true
    fi
fi

echo "SSH configuration completed"
exit 0

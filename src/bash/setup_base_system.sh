#!/bin/bash
set -e

BUILD_DIR=$1

echo "Setting up base system in $BUILD_DIR"

CHROOT_DIR="$BUILD_DIR/chroot"
mkdir -p "$CHROOT_DIR"

if ! command -v debootstrap &> /dev/null; then
    apt-get update
    apt-get install -y debootstrap
fi

echo "Running debootstrap..."
debootstrap --arch=amd64 bullseye "$CHROOT_DIR" http://deb.debian.org/debian/

echo "Setting up basic configuration..."

mkdir -p "$CHROOT_DIR/etc/apt/sources.list.d"
mkdir -p "$CHROOT_DIR/etc/systemd/system"

cp /etc/resolv.conf "$CHROOT_DIR/etc/resolv.conf"

cat > "$CHROOT_DIR/etc/apt/sources.list" << EOF
deb http://deb.debian.org/debian bullseye main contrib non-free
deb http://security.debian.org/debian-security bullseye-security main contrib non-free
EOF

echo "Updating package lists in chroot..."
chroot "$CHROOT_DIR" apt-get update

echo "Installing base packages..."
chroot "$CHROOT_DIR" bash -c "DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    linux-image-amd64 \
    live-boot \
    systemd-sysv \
    openbox \
    network-manager \
    xorg \
    xserver-xorg-input-all \
    xserver-xorg-video-all \
    lightdm \
    lightdm-gtk-greeter \
    python3 \
    python3-pip \
    sudo \
    curl \
    ca-certificates \
    gnupg2 \
    apt-transport-https \
    wget \
    x11-xserver-utils \
    unclutter \
    passwd \
    adduser \
    whois \
    procps"

mkdir -p "$CHROOT_DIR/tmp"
chmod 1777 "$CHROOT_DIR/tmp"

echo "Base system setup completed"
exit 0

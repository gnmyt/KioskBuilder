#!/bin/bash
set -e

CHROOT_DIR=$1
LANGUAGE=$2
KEYBOARD=$3
TIMEZONE=$4

if [ -z "$CHROOT_DIR" ] || [ -z "$LANGUAGE" ] || [ -z "$KEYBOARD" ] || [ -z "$TIMEZONE" ]; then
    exit 1
fi

echo "Configuring locale settings:"
echo "  Language: $LANGUAGE"
echo "  Keyboard: $KEYBOARD"
echo "  Timezone: $TIMEZONE"

echo "Installing locale packages..."
chroot "$CHROOT_DIR" bash -c "DEBIAN_FRONTEND=noninteractive apt-get update"
chroot "$CHROOT_DIR" bash -c "DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends locales console-setup tzdata"

echo "Configuring locale..."
if ! grep -q "^$LANGUAGE " "$CHROOT_DIR/etc/locale.gen"; then
    if [ -f "$CHROOT_DIR/etc/locale.gen" ]; then
        sed -i "s/# $LANGUAGE/$LANGUAGE/" "$CHROOT_DIR/etc/locale.gen" || true
    fi

    if ! grep -q "^$LANGUAGE " "$CHROOT_DIR/etc/locale.gen"; then
        echo "$LANGUAGE UTF-8" >> "$CHROOT_DIR/etc/locale.gen"
    fi

    chroot "$CHROOT_DIR" locale-gen "$LANGUAGE" || echo "Warning: Failed to generate locale"
fi

echo "LANG=$LANGUAGE" > "$CHROOT_DIR/etc/default/locale"
echo "LC_ALL=$LANGUAGE" >> "$CHROOT_DIR/etc/default/locale"

echo "Configuring keyboard..."
cat > "$CHROOT_DIR/etc/default/keyboard" << EOF
XKBMODEL="pc105"
XKBLAYOUT="$KEYBOARD"
XKBVARIANT=""
XKBOPTIONS=""
BACKSPACE="guess"
EOF

echo "Configuring timezone..."
echo "$TIMEZONE" > "$CHROOT_DIR/etc/timezone"
chroot "$CHROOT_DIR" ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime || echo "Warning: Failed to set timezone"

chroot "$CHROOT_DIR" bash -c "echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections"
chroot "$CHROOT_DIR" bash -c "echo 'locales locales/default_environment_locale select $LANGUAGE' | debconf-set-selections"
chroot "$CHROOT_DIR" bash -c "echo 'keyboard-configuration keyboard-configuration/layoutcode string $KEYBOARD' | debconf-set-selections"
chroot "$CHROOT_DIR" bash -c "echo 'tzdata tzdata/Areas select $(echo $TIMEZONE | cut -d'/' -f1)' | debconf-set-selections"
chroot "$CHROOT_DIR" bash -c "echo 'tzdata tzdata/Zones/$(echo $TIMEZONE | cut -d'/' -f1) select $(echo $TIMEZONE | cut -d'/' -f2)' | debconf-set-selections"

if [ -x "$CHROOT_DIR/usr/sbin/dpkg-reconfigure" ]; then
    chroot "$CHROOT_DIR" dpkg-reconfigure -f noninteractive keyboard-configuration || echo "Warning: Failed to reconfigure keyboard"
fi

echo "Locale settings configuration completed successfully"
exit 0

#!/bin/bash
set -e

CHROOT_DIR=$1
SCRIPT_TYPE=$2

if [ -z "$CHROOT_DIR" ] || [ -z "$SCRIPT_TYPE" ]; then
    exit 1
fi

echo "Setting up startup service for $SCRIPT_TYPE scripts in $CHROOT_DIR"

mkdir -p "$CHROOT_DIR/etc/systemd/system"

cat > "$CHROOT_DIR/etc/systemd/system/kiosk-startup.service" << EOF
[Unit]
Description=Kiosk Startup Scripts
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'for script in /etc/kiosk/startup/*; do if [ -x "\$script" ]; then "\$script"; fi; done'
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

if [ -x "$CHROOT_DIR/bin/systemctl" ] || [ -x "$CHROOT_DIR/usr/bin/systemctl" ]; then
    chroot "$CHROOT_DIR" systemctl enable kiosk-startup.service
else
    echo "Warning: systemctl not found in chroot, cannot enable kiosk-startup service"
    mkdir -p "$CHROOT_DIR/etc/systemd/system.d"
    echo "# This service would be enabled on a real system" > "$CHROOT_DIR/etc/systemd/system.d/kiosk-startup.service.info"
fi
echo "Startup service enabled"

exit 0

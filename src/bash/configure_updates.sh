#!/bin/bash
set -e

CHROOT_DIR=$1
AUTOMATIC=$2
SCHEDULE=$3

if [ -z "$CHROOT_DIR" ] || [ -z "$AUTOMATIC" ]; then
    exit 1
fi

echo "Installing update packages..."
chroot "$CHROOT_DIR" bash -c "DEBIAN_FRONTEND=noninteractive apt-get update"
chroot "$CHROOT_DIR" bash -c "DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends unattended-upgrades apt-config-auto-update cron"

if [ "$AUTOMATIC" = "true" ]; then
    if [ -z "$SCHEDULE" ]; then
        echo "Error: Automatic updates require a schedule in cron format"
        exit 1
    fi
    
    echo "Enabling automatic updates with schedule: $SCHEDULE"

    cat > "$CHROOT_DIR/etc/apt/apt.conf.d/20auto-upgrades" << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

    cat > "$CHROOT_DIR/etc/apt/apt.conf.d/50unattended-upgrades" << EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}";
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}ESMApps:\${distro_codename}-apps-security";
    "\${distro_id}ESM:\${distro_codename}-infra-security";
    "\${distro_id}:\${distro_codename}-updates";
};

Unattended-Upgrade::Package-Blacklist {
};

Unattended-Upgrade::Automatic-Reboot "false";
EOF

    USER="root"
    COMMAND="/usr/bin/unattended-upgrade"
    SCHEDULE_PARTS=($SCHEDULE)
    
    if [ ${#SCHEDULE_PARTS[@]} -eq 5 ]; then
        MINUTE=${SCHEDULE_PARTS[0]}
        HOUR=${SCHEDULE_PARTS[1]}
        DOM=${SCHEDULE_PARTS[2]}
        MONTH=${SCHEDULE_PARTS[3]}
        DOW=${SCHEDULE_PARTS[4]}
        
        CRON_LINE="$MINUTE $HOUR $DOM $MONTH $DOW $USER $COMMAND"
        echo "$CRON_LINE" > "$CHROOT_DIR/etc/cron.d/auto-updates"
        chmod 644 "$CHROOT_DIR/etc/cron.d/auto-updates"
    else
        echo "Error: Invalid cron schedule format. Expected 5 space-separated values."
        exit 1
    fi

    if [ -x "$CHROOT_DIR/bin/systemctl" ] || [ -x "$CHROOT_DIR/usr/bin/systemctl" ]; then
        chroot "$CHROOT_DIR" systemctl enable cron
    fi
else
    echo "Automatic updates disabled"

    cat > "$CHROOT_DIR/etc/apt/apt.conf.d/20auto-upgrades" << EOF
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Unattended-Upgrade "0";
EOF

    if [ -f "$CHROOT_DIR/etc/cron.d/auto-updates" ]; then
        rm -f "$CHROOT_DIR/etc/cron.d/auto-updates"
    fi
fi

echo "Update configuration completed successfully"
exit 0

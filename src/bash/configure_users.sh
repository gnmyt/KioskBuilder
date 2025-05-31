#!/bin/bash
set -e

CHROOT_DIR=$1
USERNAME=$2
PASSWORD=$3
GROUPS=$4
SUDO=$5
AUTOLOGIN=$6

if [ -z "$CHROOT_DIR" ]; then
    exit 1
fi

PASSWORD=${PASSWORD:-"changeme"}
GROUPS=${GROUPS:-""}
SUDO=${SUDO:-"false"}
AUTOLOGIN=${AUTOLOGIN:-"false"}

echo "Setting up user $USERNAME in chroot $CHROOT_DIR"

ensure_packages() {
    echo "Ensuring required packages are installed..."
    chroot "$CHROOT_DIR" bash -c "DEBIAN_FRONTEND=noninteractive apt-get update"
    chroot "$CHROOT_DIR" bash -c "DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends passwd sudo adduser"
}

create_user() {
    local username=$1
    local password=$2

    if [[ "$username" == -* ]] || ! [[ "$username" =~ ^[a-zA-Z0-9]+$ ]]; then
        echo "Skipping invalid username: $username"
        return 1
    fi

    if chroot "$CHROOT_DIR" id -u "$username" &>/dev/null; then
        echo "User $username already exists in chroot"
    else
        echo "Creating user $username in chroot"

        if ! chroot "$CHROOT_DIR" useradd -m -s /bin/bash "$username"; then
            echo "useradd failed, trying adduser for $username"
            if ! chroot "$CHROOT_DIR" adduser --disabled-password --gecos '""' "$username"; then
                echo "Failed to create user $username with any method"
                return 1
            fi
        fi

        chroot "$CHROOT_DIR" mkdir -p "/home/$username" || echo "Warning: Could not create home directory"
    fi

    if ! echo "$username:$password" | chroot "$CHROOT_DIR" chpasswd; then
        echo "chpasswd failed, trying direct passwd command for $username"
        if ! chroot "$CHROOT_DIR" bash -c "echo '$password' | passwd $username"; then
            echo "Failed to set password for $username"
        fi
    fi

    chroot "$CHROOT_DIR" groupadd -f "$username" || echo "Warning: Failed to create group $username"

    if ! chroot "$CHROOT_DIR" chown -R "$username:$username" "/home/$username"; then
        echo "chown -R failed, trying without -R for $username"
        chroot "$CHROOT_DIR" chown "$username:$username" "/home/$username" || echo "Warning: Failed to set ownership on /home/$username"
    fi

    return 0
}

add_to_groups() {
    local username=$1
    local groups=$2
    local sudo_flag=$3

    if [ -n "$groups" ] && [ "$groups" != "null" ]; then
        echo "Adding user $username to groups: $groups"
        chroot "$CHROOT_DIR" usermod -a -G "$groups" "$username" || \
            echo "Warning: Failed to add $username to groups $groups"
    fi

    if [ "$sudo_flag" = "true" ]; then
        echo "Adding user $username to sudo group"
        chroot "$CHROOT_DIR" usermod -a -G sudo "$username" || \
            echo "Warning: Failed to add $username to sudo group"
    fi
}

setup_autologin() {
    local username=$1
    
    echo "Configuring autologin for user $username"

    chroot "$CHROOT_DIR" bash -c "DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends lightdm" || \
        echo "Warning: Failed to install lightdm"

    mkdir -p "$CHROOT_DIR/etc/lightdm"

    cat > "$CHROOT_DIR/etc/lightdm/lightdm.conf" << EOF
[Seat:*]
autologin-user=$username
autologin-user-timeout=0
user-session=openbox
greeter-session=lightdm-gtk-greeter
EOF

    if [ -d "$CHROOT_DIR/etc/systemd/system" ]; then
        mkdir -p "$CHROOT_DIR/etc/systemd/system/getty@tty1.service.d"
        
        cat > "$CHROOT_DIR/etc/systemd/system/getty@tty1.service.d/override.conf" << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $username --noclear %I \$TERM
EOF
    fi
}

ensure_packages

if create_user "$USERNAME" "$PASSWORD"; then
    add_to_groups "$USERNAME" "$GROUPS" "$SUDO"
    
    if [ "$AUTOLOGIN" = "true" ]; then
        setup_autologin "$USERNAME"
    fi
    
    echo "User $USERNAME setup completed successfully"
    exit 0
else
    echo "Failed to setup user $USERNAME"
    exit 1
fi

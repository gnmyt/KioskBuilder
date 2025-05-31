#!/bin/bash
set -e

CHROOT_DIR=$1

if [ -z "$CHROOT_DIR" ]; then
    exit 1
fi

echo "Installing UI packages in $CHROOT_DIR"

DEBIAN_FRONTEND=noninteractive chroot "$CHROOT_DIR" apt-get install -y --no-install-recommends openbox lightdm unclutter x11-xserver-utils || {
    echo "Warning: Failed standard install of UI packages, trying individual installs"

    DEBIAN_FRONTEND=noninteractive chroot "$CHROOT_DIR" apt-get install -y --no-install-recommends openbox || {
        echo "Warning: Failed to install openbox package"
    }
    
    DEBIAN_FRONTEND=noninteractive chroot "$CHROOT_DIR" apt-get install -y --no-install-recommends lightdm || {
        echo "Warning: Failed to install lightdm package"
    }
    
    DEBIAN_FRONTEND=noninteractive chroot "$CHROOT_DIR" apt-get install -y --no-install-recommends unclutter || {
        echo "Warning: Failed to install unclutter package"
    }
    
    DEBIAN_FRONTEND=noninteractive chroot "$CHROOT_DIR" apt-get install -y --no-install-recommends x11-xserver-utils || {
        echo "Warning: Failed to install x11-xserver-utils package"
    }
}

echo "UI packages installed successfully"
exit 0

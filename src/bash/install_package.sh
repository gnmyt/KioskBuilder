#!/bin/bash
set -e

CHROOT_DIR=$1
PACKAGE_NAME=$2
PACKAGE_VERSION=$3

if [ -z "$CHROOT_DIR" ] || [ -z "$PACKAGE_NAME" ]; then
    exit 1
fi

if [ "$PACKAGE_VERSION" != "null" ] && [ -n "$PACKAGE_VERSION" ]; then
    echo "Installing package: $PACKAGE_NAME=$PACKAGE_VERSION"
    DEBIAN_FRONTEND=noninteractive chroot "$CHROOT_DIR" apt-get install -y --no-install-recommends "$PACKAGE_NAME=$PACKAGE_VERSION" || {
        echo "Warning: Failed to install $PACKAGE_NAME=$PACKAGE_VERSION, continuing anyway"
        exit 1
    }
else
    echo "Installing package: $PACKAGE_NAME (latest)"
    DEBIAN_FRONTEND=noninteractive chroot "$CHROOT_DIR" apt-get install -y --no-install-recommends "$PACKAGE_NAME" || {
        echo "Warning: Failed to install $PACKAGE_NAME, continuing anyway"
        exit 1
    }
fi

echo "Package $PACKAGE_NAME installed successfully"
exit 0

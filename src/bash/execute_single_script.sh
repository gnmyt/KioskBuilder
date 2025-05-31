#!/bin/bash
set -e

CHROOT_DIR=$1
SCRIPT_NAME=$2
SCRIPT_CONTENT=$3
SCRIPT_TYPE=$4
INSTALL_ONLY=$5

if [ -z "$CHROOT_DIR" ] || [ -z "$SCRIPT_NAME" ] || [ -z "$SCRIPT_CONTENT" ] || [ -z "$SCRIPT_TYPE" ]; then
    exit 1
fi

if [ "$INSTALL_ONLY" = "install_only" ]; then
    echo "Installing script: $SCRIPT_NAME"
else
    echo "Executing script: $SCRIPT_NAME"
fi

SCRIPTS_DIR="$CHROOT_DIR/tmp/kiosk_scripts/$SCRIPT_TYPE"
mkdir -p "$SCRIPTS_DIR"

SCRIPT_PATH="$SCRIPTS_DIR/$SCRIPT_NAME"
echo "$SCRIPT_CONTENT" > "$SCRIPT_PATH"
chmod +x "$SCRIPT_PATH"

if [ "$SCRIPT_TYPE" = "startup" ]; then
    mkdir -p "$CHROOT_DIR/etc/kiosk/startup"
    cp "$SCRIPT_PATH" "$CHROOT_DIR/etc/kiosk/startup/"
    chmod +x "$CHROOT_DIR/etc/kiosk/startup/$SCRIPT_NAME"
    echo "Startup script $SCRIPT_NAME installed to /etc/kiosk/startup/"
else
    if [ "$INSTALL_ONLY" != "install_only" ]; then
        echo "Running: $SCRIPT_NAME"

        chroot "$CHROOT_DIR" "/tmp/kiosk_scripts/$SCRIPT_TYPE/$SCRIPT_NAME" || {
            echo "Script execution failed: $SCRIPT_NAME"
            echo "Continuing anyway to prevent build failure"
            exit 0
        }
        echo "Script $SCRIPT_NAME completed"
    else
        echo "Script $SCRIPT_NAME installed (not executed)"
    fi
fi

exit 0

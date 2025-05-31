#!/bin/bash
set -e

CHROOT_DIR=$1
REPO_NAME=$2
REPO_URL=$3
REPO_KEY=$4

if [ -z "$CHROOT_DIR" ] || [ -z "$REPO_NAME" ] || [ -z "$REPO_URL" ]; then
    exit 1
fi

echo "Adding repository: $REPO_NAME - $REPO_URL"

if [ "$REPO_KEY" != "null" ] && [ -n "$REPO_KEY" ]; then
    KEY_FILE="/tmp/${REPO_NAME}.key"
    wget -qO "$KEY_FILE" "$REPO_KEY"
    mkdir -p "$CHROOT_DIR/etc/apt/trusted.gpg.d"
    cp "$KEY_FILE" "$CHROOT_DIR/etc/apt/trusted.gpg.d/${REPO_NAME}.asc"
fi

mkdir -p "$CHROOT_DIR/etc/apt/sources.list.d"
echo "deb $REPO_URL stable main" > "$CHROOT_DIR/etc/apt/sources.list.d/$REPO_NAME.list"

echo "Repository $REPO_NAME added successfully"
exit 0

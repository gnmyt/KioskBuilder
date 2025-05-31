#!/bin/bash
set -e

CHROOT_DIR=$1
PATH_TO_MODIFY=$2
OWNER=$3
GROUP=$4
MODE=$5

if [ -z "$CHROOT_DIR" ] || [ -z "$PATH_TO_MODIFY" ] || [ -z "$OWNER" ] || [ -z "$GROUP" ] || [ -z "$MODE" ]; then
    exit 1
fi

echo "Setting permissions for $PATH_TO_MODIFY"

RELATIVE_PATH="${PATH_TO_MODIFY#/}"
FULL_PATH="$CHROOT_DIR/$RELATIVE_PATH"

if [ ! -e "$FULL_PATH" ]; then
    echo "Warning: Path $PATH_TO_MODIFY does not exist in the chroot"

    PARENT_DIR=$(dirname "$FULL_PATH")
    if [ ! -d "$PARENT_DIR" ]; then
        echo "Creating parent directories for $PATH_TO_MODIFY"
        mkdir -p "$PARENT_DIR"
    fi

    if [[ "$PATH_TO_MODIFY" == */ ]]; then
        echo "Creating directory $PATH_TO_MODIFY"
        mkdir -p "$FULL_PATH"
    else
        echo "Creating empty file $PATH_TO_MODIFY"
        touch "$FULL_PATH"
    fi
fi

echo "Setting owner:group to $OWNER:$GROUP"
chroot "$CHROOT_DIR" chown "$OWNER:$GROUP" "/$RELATIVE_PATH"

echo "Setting mode to $MODE"
chroot "$CHROOT_DIR" chmod "$MODE" "/$RELATIVE_PATH"

echo "Permissions set successfully"
exit 0

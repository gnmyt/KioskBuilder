#!/bin/bash
set -e

CHROOT_DIR=$1
KIOSK_APP=$2
RESOLUTION=$3
ORIENTATION=$4

if [ -z "$CHROOT_DIR" ] || [ -z "$KIOSK_APP" ]; then
    exit 1
fi

echo "Configuring kiosk mode with application: $KIOSK_APP"
echo "Resolution: $RESOLUTION (if specified)"
echo "Orientation: $ORIENTATION (if specified)"

mkdir -p "$CHROOT_DIR/etc/xdg/openbox"
cat > "$CHROOT_DIR/etc/xdg/openbox/autostart" << EOF
#!/bin/bash

if [ "$RESOLUTION" != "null" ] && [ -n "$RESOLUTION" ]; then
  DISPLAY_NAME=\$(xrandr | grep -w connected | head -n 1 | cut -d' ' -f1)
  if [ -n "\$DISPLAY_NAME" ]; then
    xrandr --output "\$DISPLAY_NAME" --mode $RESOLUTION
  fi
fi

if [ "$ORIENTATION" != "null" ] && [ "$ORIENTATION" != "0" ]; then
  DISPLAY_NAME=\$(xrandr | grep -w connected | head -n 1 | cut -d' ' -f1)
  if [ -n "\$DISPLAY_NAME" ]; then
    case "$ORIENTATION" in
      "90") xrandr --output "\$DISPLAY_NAME" --rotate right ;;
      "180") xrandr --output "\$DISPLAY_NAME" --rotate inverted ;;
      "270") xrandr --output "\$DISPLAY_NAME" --rotate left ;;
    esac
  fi
fi

unclutter -idle 5 -root &

$KIOSK_APP &
EOF

chmod +x "$CHROOT_DIR/etc/xdg/openbox/autostart"

echo "Kiosk mode configured successfully"
exit 0

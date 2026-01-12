#!/bin/bash
## This is an example for copying entire folders from one LXC Container to another.

cd /tmp
TEMP_DIR=$(mktemp -d)
pushd "$TEMP_DIR"

CTID_FROM=101
CTID_TO=100

pct stop "$CTID_TO"

echo Mounting source
CTID_FROM_PATH=$(pct mount "$CTID_FROM" | sed -n "s/.*'\(.*\)'/\1/p")
FROM_PATH=/opt/dockge
[ -d "${CTID_FROM_PATH}${FROM_PATH}" ] ||   echo "Source folder in '$CTID_FROM' not found."

echo Mounting target
CTID_TO_PATH=$(pct mount "$CTID_TO" | sed -n "s/.*'\(.*\)'/\1/p")
TO_PATH=/opt
[ -d "${CTID_TO_PATH}${TO_PATH}" ] ||   echo "Target folder in '$CTID_TO' not found."

echo Copiyng...
rsync --archive   --hard-links   --sparse   --xattrs   --no-inc-recursive   --info=progress2 \
    "${CTID_FROM_PATH}"${FROM_PATH} "${CTID_TO_PATH}"${TO_PATH}

echo Cleaning...
[ -d "${CTID_FROM_PATH:-}" ] && pct unmount "$CTID_FROM"
[ -d "${CTID_TO_PATH:-}" ] && pct unmount "$CTID_TO"
popd
rm -rf "$TEMP_DIR"

echo Done!
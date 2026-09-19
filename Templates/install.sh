#!/bin/sh
# Symlinks this repo's Xcode templates into ~/Library/Developer/Xcode/Templates/
# so they show up in Xcode's File > New > Project sheet. Re-run after pulling
# changes is not needed -- the symlink keeps them live.

set -e

SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)/SwiftQiskit"
DEST_DIR="$HOME/Library/Developer/Xcode/Templates"
DEST_LINK="$DEST_DIR/SwiftQiskit"

mkdir -p "$DEST_DIR"

if [ -L "$DEST_LINK" ] || [ -e "$DEST_LINK" ]; then
    echo "Removing existing $DEST_LINK"
    rm -rf "$DEST_LINK"
fi

ln -s "$SOURCE_DIR" "$DEST_LINK"
echo "Installed: $DEST_LINK -> $SOURCE_DIR"
echo "Restart Xcode, then look for \"SwiftQiskit\" under File > New > Project."

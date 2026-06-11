#!/usr/bin/env bash

set -e

INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="xcclean"

echo "Installing $SCRIPT_NAME..."

curl -fsSL \
  https://raw.githubusercontent.com/Mohamed-Khaterr/xcclean/main/xcclean.sh \
  -o "$INSTALL_DIR/$SCRIPT_NAME"

chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

echo "✅ Installed!"
echo "Run: xcclean"
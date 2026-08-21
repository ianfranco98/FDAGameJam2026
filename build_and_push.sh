#!/bin/bash

# --- CONFIGURATION ---
EXPORT_PRESET_WIN="Windows Desktop"
EXPORT_PRESET_WEB="Web"
GODOT_VERSION="Godot_v4.7.1-stable_win64"

BUILD_DIR="./builds"
WIN_DIR="$BUILD_DIR/windows"
WEB_DIR="$BUILD_DIR/web"

ITCH_USERNAME="alvaropd"
ITCH_GAME_ID="bancando-la-parrilla"
# ---------------------

echo "🧼 Cleaning up old builds..."
rm -rf "$BUILD_DIR"
mkdir -p "$WIN_DIR"
mkdir -p "$WEB_DIR"

echo "🖥️ Building for Windows..."
$GODOT_VERSION --headless --export-release "$EXPORT_PRESET_WIN" "$WIN_DIR/$ITCH_GAME_ID.exe"

echo "🌐 Building for Web..."
# Web export main file must be named index.html for itch.io
$GODOT_VERSION --headless --export-release "$EXPORT_PRESET_WEB" "$WEB_DIR/index.html"

echo "🚀 Pushing Web build to itch.io..."
butler push "$WEB_DIR" "$ITCH_USERNAME/$ITCH_GAME_ID:web"

echo "🚀 Pushing Windows build to itch.io..."
butler push "$WIN_DIR" "$ITCH_USERNAME/$ITCH_GAME_ID:windows"

echo "✅ All builds exported and pushed successfully!"

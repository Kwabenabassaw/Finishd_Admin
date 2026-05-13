#!/bin/bash

# Install Flutter
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter..."
  git clone --depth 1 https://github.com/flutter/flutter.git -b stable
fi

# Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Enable Web
flutter config --enable-web

# Build for Web
echo "Building Flutter Web..."
flutter build web --release --base-href /

# Move output to the root of the build directory if needed
# Vercel expects files in the directory specified as 'Output Directory'
# If we set Output Directory to 'build/web' in Vercel settings, we don't need to move anything.

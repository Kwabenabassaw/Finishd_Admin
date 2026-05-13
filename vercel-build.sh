#!/bin/bash

# Exit on any error
set -e

# Add Flutter to PATH
export PATH="$PATH:$(pwd)/flutter/bin"

echo "--- Build Environment Check ---"
echo "Directory: $(pwd)"

# 1. Install Flutter
if [ ! -d "flutter" ]; then
  echo "--- Cloning Flutter SDK ---"
  git clone --depth 1 https://github.com/flutter/flutter.git -b stable
else
  echo "--- Flutter SDK already exists ---"
fi

# 2. Setup Flutter
echo "--- Configuring Flutter ---"
flutter config --no-analytics
flutter config --enable-web

# 3. Download Artifacts
echo "--- Downloading Web Artifacts ---"
flutter precache --web

# 4. Get Packages
echo "--- Running pub get ---"
flutter pub get

# 5. Build
echo "--- Starting Flutter Build Web ---"
flutter build web --release --base-href /

echo "--- Build Finished Successfully ---"

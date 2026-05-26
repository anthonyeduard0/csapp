#!/bin/bash
set -e

# 1. Clean up any existing flutter directory from previous builds/caches
if [ -d "flutter" ]; then
  echo "Existing flutter directory found. Removing it for a clean clone..."
  rm -rf flutter
fi

# 2. Clone the exact Flutter version matching your local environment (3.32.7) with depth 1
echo "Cloning Flutter 3.32.7 (shallow clone)..."
git clone https://github.com/flutter/flutter.git -b 3.32.7 --depth 1

# 3. Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# 4. Clean local cache first
echo "Cleaning Flutter project..."
flutter clean

# 5. Pre-download web development binaries
echo "Downloading web development binaries..."
flutter precache --web

# 6. Run build with verbose output to diagnose any compilation failures in detail
echo "Compiling Flutter Web application..."
flutter build web --release --verbose
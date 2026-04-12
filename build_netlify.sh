#!/bin/bash
set -e

FLUTTER_HOME="$HOME/flutter"

# Install Flutter if not already cached
if [ ! -d "$FLUTTER_HOME" ]; then
  echo "Installing Flutter..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_HOME"
fi

export PATH="$PATH:$FLUTTER_HOME/bin"

flutter --version
flutter config --enable-web
flutter pub get
flutter build web --release --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY"

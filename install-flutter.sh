#!/bin/bash
# Baixa o Flutter
git clone https://github.com/flutter/flutter.git -b stable
# Adiciona ao PATH
export PATH="$PATH:`pwd`/flutter/bin"
# Executa o build
flutter build web --release
#!/bin/zsh
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
swiftc -parse-as-library \
  "$root/scripts/IconDrawing/FruitIcon.swift" \
  "$root/scripts/IconDrawing/AppleIcon.swift" \
  "$root/scripts/IconDrawing/PineappleIcon.swift" \
  "$root/scripts/GenerateIcons.swift" \
  -o /tmp/mouse-mover-generate-icons \
  -framework AppKit
/tmp/mouse-mover-generate-icons

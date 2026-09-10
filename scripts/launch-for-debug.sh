#!/bin/zsh
set -euo pipefail

# Launch Services start (same as Finder / close to Xcode). Direct lldb spawn
# of Contents/MacOS/Mouse Mover does not get the app's Accessibility identity.
app="${1:-}"
if [[ -z "$app" ]]; then
  echo "usage: $0 /path/to/Mouse Mover.app" >&2
  exit 1
fi

if [[ ! -d "$app" ]]; then
  echo "App not found: $app" >&2
  exit 1
fi

killall "Mouse Mover" 2>/dev/null || true
sleep 0.3

open --env OS_ACTIVITY_DT_MODE=1 --env OS_ACTIVITY_MODE=debug -n "$app"
sleep 0.8

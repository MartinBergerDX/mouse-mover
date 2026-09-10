# Mouse Mover

A native macOS menu-bar app that nudges the pointer on a schedule so the Mac does not look idle. It lives in the menu bar (no Dock icon) and only synthesizes movement after the pointer has been still.

Requires **macOS 15** and **Accessibility** permission.

## Features

- Start / stop from the menu bar extra
- Movement patterns: horizontal, vertical, diagonal, circle, figure-eight, random direction
- Interval, distance, duration, smoothness, and jitter
- Optional restore to the original pointer position
- Pause while you use the pointer; the idle countdown resets on real movement
- Daily schedule with independent start/stop times, weekdays, and a random threshold
- Launch at login

## Permissions

Mouse Mover must be allowed under **System Settings → Privacy & Security → Accessibility**. macOS ties that grant to the signed app identity. Use a Development team in Xcode (not “Sign to Run Locally”); ad-hoc signatures change every rebuild and the grant will not stick.

## Build and run

Open `MouseMover.xcodeproj` in Xcode and run the **Mouse Mover** scheme.

From Cursor, use the **Mouse Mover** debug configuration (F5). That builds the signed `.app`, starts it with Launch Services (`open`), then attaches the debugger — the same TCC identity you get from Xcode. The **Mouse Mover (lldb spawn)** configuration launches the inner executable directly and typically will not receive Accessibility.

```bash
xcodebuild \
  -project MouseMover.xcodeproj \
  -scheme "Mouse Mover" \
  -configuration Debug \
  -destination "platform=macOS,arch=arm64" \
  -derivedDataPath DerivedData \
  build
```

The built app is `DerivedData/Build/Products/Debug/Mouse Mover.app` (gitignored).

# Mouse Mover

A native macOS menu-bar app that nudges the pointer on a schedule so the Mac does not look idle. It lives in the menu bar (no Dock icon) and only synthesizes movement after the Mac has been idle.

Requires **macOS 15** and **Accessibility** permission.

## Features

- Start / stop from the menu bar extra
- Movement patterns: horizontal, vertical, diagonal, circle, figure-eight, random direction
- Interval, distance, duration, smoothness, and jitter
- Optional restore to the original pointer position
- Pause while you use the Mac; mouse, keyboard, clicks, and scroll reset the idle countdown
- Daily schedule with independent start/stop times, weekdays, and a random threshold
- Launch at login
- Panic quit: hold **⌃⌥⌘Q** from any app (including during a screenshare). Hold duration is set in Settings → General (0.1–5 s, default 0.6 s)

## Permissions

Mouse Mover must be allowed under **System Settings → Privacy & Security → Accessibility**. macOS ties that grant to the signed app identity. Use a Development team in Xcode (not “Sign to Run Locally”); ad-hoc signatures change every rebuild and the grant will not stick.

## Build and run

Open `MouseMover.xcodeproj` in Xcode and run the **Mouse Mover** scheme.

From Cursor, pick a configuration and press F5:

- **Mouse Mover (Debug)** — builds Debug, starts the signed `.app` with Launch Services (`open`), then attaches the debugger (same TCC identity as Xcode)
- **Mouse Mover (Release)** — same launch path, output in `DerivedData/Build/Products/Release/`
- **Mouse Mover (Debug, lldb spawn)** — launches the inner executable directly and typically will not receive Accessibility

```bash
xcodebuild \
  -project MouseMover.xcodeproj \
  -scheme "Mouse Mover" \
  -configuration Debug \
  -destination "platform=macOS,arch=arm64" \
  -derivedDataPath DerivedData \
  build
```

Built apps are `DerivedData/Build/Products/Debug/Mouse Mover.app` and `DerivedData/Build/Products/Release/Mouse Mover.app` (gitignored).

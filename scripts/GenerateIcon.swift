import AppKit

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
    NSColor.clear.setFill()
    rect.fill()

    let inset = NSRect(x: 64, y: 64, width: size - 128, height: size - 128)
    let rounded = NSBezierPath(roundedRect: inset, xRadius: 220, yRadius: 220)
    NSColor(calibratedRed: 0.20, green: 0.48, blue: 0.42, alpha: 1).setFill()
    rounded.fill()

    let pointer = NSBezierPath()
    pointer.move(to: CGPoint(x: 340, y: 720))
    pointer.line(to: CGPoint(x: 340, y: 280))
    pointer.line(to: CGPoint(x: 430, y: 370))
    pointer.line(to: CGPoint(x: 510, y: 330))
    pointer.close()
    NSColor.white.setFill()
    pointer.fill()

    let arc = NSBezierPath()
    arc.appendArc(
        withCenter: CGPoint(x: 640, y: 430),
        radius: 150,
        startAngle: -20,
        endAngle: 210,
        clockwise: false
    )
    arc.lineWidth = 42
    arc.lineCapStyle = .round
    NSColor.white.withAlphaComponent(0.92).setStroke()
    arc.stroke()

    let head = NSBezierPath()
    head.move(to: CGPoint(x: 740, y: 560))
    head.line(to: CGPoint(x: 810, y: 500))
    head.line(to: CGPoint(x: 700, y: 490))
    head.close()
    NSColor.white.setFill()
    head.fill()
    return true
}

let representations: [(Int, String)] = [
    (16, "icon_16x16"),
    (32, "icon_16x16@2x"),
    (32, "icon_32x32"),
    (64, "icon_32x32@2x"),
    (128, "icon_128x128"),
    (256, "icon_128x128@2x"),
    (256, "icon_256x256"),
    (512, "icon_256x256@2x"),
    (512, "icon_512x512"),
    (1024, "icon_512x512@2x"),
]

let folder = URL(fileURLWithPath: "/Users/martinberger/Dev/Mouse Mover/MouseMover/Assets.xcassets/AppIcon.appiconset")

guard let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff) else {
    fatalError("Could not rasterize icon")
}

for (pixels, name) in representations {
    let scaled = NSImage(size: NSSize(width: pixels, height: pixels))
    scaled.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    image.draw(
        in: NSRect(origin: .zero, size: NSSize(width: pixels, height: pixels)),
        from: .zero,
        operation: .copy,
        fraction: 1
    )
    scaled.unlockFocus()
    guard let scaledTiff = scaled.tiffRepresentation,
          let scaledRep = NSBitmapImageRep(data: scaledTiff),
          let png = scaledRep.representation(using: .png, properties: [:]) else {
        continue
    }
    try png.write(to: folder.appendingPathComponent("\(name).png"))
}

print("Wrote app icons")

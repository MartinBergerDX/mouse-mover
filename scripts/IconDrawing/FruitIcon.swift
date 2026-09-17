import AppKit
import Foundation

protocol FruitIcon {
    var name: String { get }
    func drawColor(in rect: NSRect)
    func drawTemplate(in rect: NSRect, filled: Bool)
}

enum IconOutput {
    static let assets = URL(
        fileURLWithPath: "/Users/martinberger/Dev/Mouse Mover/MouseMover/Assets.xcassets"
    )

    static func makeBitmap(size: CGFloat) -> NSBitmapImageRep {
        let pixels = Int(size.rounded())
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixels,
            pixelsHigh: pixels,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            fatalError("Could not create bitmap")
        }
        return rep
    }

    static func withBitmap(size: CGFloat, draw: (NSRect) -> Void) -> NSBitmapImageRep {
        let rep = makeBitmap(size: size)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current?.imageInterpolation = .high
        NSColor.clear.setFill()
        let rect = NSRect(x: 0, y: 0, width: size, height: size)
        rect.fill()
        draw(rect)
        NSGraphicsContext.restoreGraphicsState()
        return rep
    }

    static func writePNG(_ rep: NSBitmapImageRep, to url: URL) throws {
        guard let png = rep.representation(using: .png, properties: [:]) else {
            fatalError("Could not encode PNG for \(url.lastPathComponent)")
        }
        try png.write(to: url)
    }
}

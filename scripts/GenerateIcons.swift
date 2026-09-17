import AppKit
import Foundation

/// Switch fruit here, then run `scripts/generate-icons.sh`.
@main
enum GenerateIcons {
    static let activeFruit: any FruitIcon = PineappleIcon()
    // static let activeFruit: any FruitIcon = AppleIcon()

    static func main() {
        do {
            try writeAppIcon(activeFruit)
            try writeMenuBarIcons(activeFruit)
            print("Wrote \(activeFruit.name) app and menu bar icons")
        } catch {
            fputs("\(error)\n", stderr)
            exit(1)
        }
    }

    private static func writeAppIcon(_ fruit: any FruitIcon) throws {
        let size: CGFloat = 1024
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            NSColor.clear.setFill()
            rect.fill()
            fruit.drawColor(in: rect)
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

        let folder = IconOutput.assets.appendingPathComponent("AppIcon.appiconset")
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
            guard let tiff = scaled.tiffRepresentation,
                  let rep = NSBitmapImageRep(data: tiff),
                  let png = rep.representation(using: .png, properties: [:]) else {
                continue
            }
            try png.write(to: folder.appendingPathComponent("\(name).png"))
        }
    }

    private static func writeMenuBarIcons(_ fruit: any FruitIcon) throws {
        try writeMenuBarImageset(name: "MenuBarFruit", fruit: fruit, filled: false)
        try writeMenuBarImageset(name: "MenuBarFruitFill", fruit: fruit, filled: true)
    }

    private static func writeMenuBarImageset(name: String, fruit: any FruitIcon, filled: Bool) throws {
        let set = IconOutput.assets.appendingPathComponent("\(name).imageset")
        try FileManager.default.createDirectory(at: set, withIntermediateDirectories: true)
        for (pixels, filename) in [(16, "icon.png"), (32, "icon@2x.png")] as [(CGFloat, String)] {
            let rep = IconOutput.withBitmap(size: pixels) { rect in
                fruit.drawTemplate(
                    in: rect.insetBy(dx: pixels * 0.08, dy: pixels * 0.08),
                    filled: filled
                )
            }
            try IconOutput.writePNG(rep, to: set.appendingPathComponent(filename))
        }
        let contents = """
        {
          "images" : [
            { "filename" : "icon.png", "idiom" : "universal", "scale" : "1x" },
            { "filename" : "icon@2x.png", "idiom" : "universal", "scale" : "2x" }
          ],
          "info" : { "author" : "xcode", "version" : 1 },
          "properties" : { "template-rendering-intent" : "template" }
        }
        """
        try contents.write(to: set.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
    }
}


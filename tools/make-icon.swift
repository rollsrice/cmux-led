#!/usr/bin/env swift
import AppKit
import CoreGraphics

let outDir = CommandLine.arguments.dropFirst().first ?? "build/AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

func makePNG(size: CGFloat) -> Data {
    let pixelSize = Int(size)
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 32
    ) else { fatalError("bitmap alloc") }
    rep.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext

    let cornerR = size * 0.22
    let bgRect = CGRect(x: 0, y: 0, width: size, height: size)
    let bgPath = CGPath(roundedRect: bgRect, cornerWidth: cornerR, cornerHeight: cornerR, transform: nil)
    ctx.addPath(bgPath)
    ctx.setFillColor(CGColor(red: 0.13, green: 0.13, blue: 0.15, alpha: 1.0))
    ctx.fillPath()

    let dotR = size * 0.18
    let gap = size * 0.10
    let cy = size * 0.5
    let leftCx = size * 0.5 - dotR - gap / 2
    let rightCx = size * 0.5 + dotR + gap / 2

    func dot(cx: CGFloat, color: CGColor, glow: CGColor) {
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: dotR * 0.6, color: glow)
        ctx.setFillColor(color)
        ctx.fillEllipse(in: CGRect(x: cx - dotR, y: cy - dotR, width: dotR * 2, height: dotR * 2))
        ctx.restoreGState()
    }

    let green = CGColor(red: 0.30, green: 0.85, blue: 0.45, alpha: 1.0)
    let red = CGColor(red: 0.95, green: 0.30, blue: 0.30, alpha: 1.0)
    let greenGlow = CGColor(red: 0.30, green: 0.85, blue: 0.45, alpha: 0.7)
    let redGlow = CGColor(red: 0.95, green: 0.30, blue: 0.30, alpha: 0.7)

    dot(cx: leftCx, color: green, glow: greenGlow)
    dot(cx: rightCx, color: red, glow: redGlow)

    NSGraphicsContext.restoreGraphicsState()

    guard let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("png encode")
    }
    return data
}

let sizes: [(String, Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]

for (name, px) in sizes {
    let data = makePNG(size: CGFloat(px))
    let path = "\(outDir)/\(name).png"
    try data.write(to: URL(fileURLWithPath: path))
}
print("wrote \(sizes.count) icons to \(outDir)")

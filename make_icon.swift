#!/usr/bin/swift
import AppKit

let canvas = 1024
let size = CGSize(width: canvas, height: canvas)

let image = NSImage(size: size, flipped: false) { rect in
    guard let ctx = NSGraphicsContext.current?.cgContext else { return false }

    // --- Background: dark charcoal, full rounded rect ---
    let bg = CGPath(roundedRect: rect.insetBy(dx: 0, dy: 0),
                    cornerWidth: 224, cornerHeight: 224, transform: nil)
    ctx.addPath(bg)
    ctx.clip()

    // Gradient: dark slate top → slightly lighter bottom
    let space = CGColorSpaceCreateDeviceRGB()
    let colors = [
        CGColor(red: 0.13, green: 0.13, blue: 0.15, alpha: 1),
        CGColor(red: 0.17, green: 0.17, blue: 0.20, alpha: 1)
    ] as CFArray
    let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0, 1])!
    ctx.drawLinearGradient(gradient,
        start: CGPoint(x: 0, y: rect.height),
        end: CGPoint(x: 0, y: 0),
        options: [])

    // --- Panel: white frosted rectangle on the right ---
    let panelX  = CGFloat(canvas) * 0.30
    let panelW  = CGFloat(canvas) * 0.62
    let panelH  = CGFloat(canvas) * 0.72
    let panelY  = (CGFloat(canvas) - panelH) / 2
    let panelR: CGFloat = 60
    let panelRect = CGRect(x: panelX, y: panelY, width: panelW, height: panelH)

    ctx.resetClip()
    // Panel shadow
    ctx.setShadow(offset: CGSize(width: -8, height: -12), blur: 40,
                  color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.5))
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.12))
    let panelPath = CGPath(roundedRect: panelRect,
                           cornerWidth: panelR, cornerHeight: panelR, transform: nil)
    ctx.addPath(panelPath)
    ctx.fillPath()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)

    // Panel border
    ctx.addPath(panelPath)
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.18))
    ctx.setLineWidth(3)
    ctx.strokePath()

    // --- Left edge accent line (the drag handle) ---
    let handleX = panelX + 6
    let handleH = panelH * 0.35
    let handleY = panelY + (panelH - handleH) / 2
    let handlePath = CGPath(roundedRect: CGRect(x: handleX, y: handleY, width: 7, height: handleH),
                            cornerWidth: 4, cornerHeight: 4, transform: nil)
    ctx.addPath(handlePath)
    ctx.setFillColor(CGColor(red: 1, green: 0.84, blue: 0, alpha: 0.85))  // yellow
    ctx.fillPath()

    // --- Reminder rows inside the panel ---
    let rowStartX = panelX + 56
    let rowWidth  = panelW - 80
    let rowStartY = panelY + panelH - 130
    let rowGap: CGFloat = 100

    for i in 0..<4 {
        let ry = rowStartY - CGFloat(i) * rowGap

        // Circle checkbox
        let circleR: CGFloat = 22
        let circleRect = CGRect(x: rowStartX, y: ry - circleR,
                                width: circleR * 2, height: circleR * 2)
        ctx.addEllipse(in: circleRect)
        if i == 0 {
            // First row: filled (completed) with yellow
            ctx.setFillColor(CGColor(red: 1, green: 0.84, blue: 0, alpha: 0.9))
            ctx.fillPath()
            // Checkmark
            ctx.setStrokeColor(CGColor(red: 0.13, green: 0.13, blue: 0.15, alpha: 1))
            ctx.setLineWidth(5)
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)
            let cx = rowStartX + circleR
            let cy = ry
            ctx.move(to: CGPoint(x: cx - 10, y: cy))
            ctx.addLine(to: CGPoint(x: cx - 2, y: cy - 9))
            ctx.addLine(to: CGPoint(x: cx + 12, y: cy + 8))
            ctx.strokePath()
        } else {
            ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.35))
            ctx.setLineWidth(3)
            ctx.strokePath()
        }

        // Text line next to circle
        let lineX = rowStartX + circleR * 2 + 18
        let lineW = rowWidth - circleR * 2 - 18 - (i == 1 ? 60 : 0)
        let lineH: CGFloat = 14
        let lineRect = CGRect(x: lineX, y: ry - lineH / 2, width: lineW, height: lineH)
        let lineAlpha: CGFloat = i == 0 ? 0.3 : (i == 1 ? 0.7 : 0.5)
        let linePath = CGPath(roundedRect: lineRect, cornerWidth: 7, cornerHeight: 7, transform: nil)
        ctx.addPath(linePath)
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: lineAlpha))
        ctx.fillPath()

        // Shorter sub-line (date/note) for some rows
        if i == 1 || i == 2 {
            let subW = lineW * 0.45
            let subRect = CGRect(x: lineX, y: ry - lineH / 2 - 22, width: subW, height: 10)
            let subPath = CGPath(roundedRect: subRect, cornerWidth: 5, cornerHeight: 5, transform: nil)
            ctx.addPath(subPath)
            ctx.setFillColor(CGColor(red: 1, green: 0.4, blue: 0.4, alpha: 0.6))  // red = overdue
            ctx.fillPath()
        }
    }

    // --- Arrow pointing right (pop-out indicator) on the left ---
    let arrowCX: CGFloat = 148
    let arrowCY: CGFloat = CGFloat(canvas) / 2
    let aw: CGFloat = 52
    let ah: CGFloat = 44

    ctx.setFillColor(CGColor(red: 1, green: 0.84, blue: 0, alpha: 0.75))
    ctx.move(to: CGPoint(x: arrowCX - aw / 2, y: arrowCY - ah / 2))
    ctx.addLine(to: CGPoint(x: arrowCX + aw / 2, y: arrowCY))
    ctx.addLine(to: CGPoint(x: arrowCX - aw / 2, y: arrowCY + ah / 2))
    ctx.closePath()
    ctx.fillPath()

    return true
}

// Save as 1024x1024 PNG
let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: canvas, pixelsHigh: canvas,
    bitsPerSample: 8, samplesPerPixel: 4,
    hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0, bitsPerPixel: 0
)!
rep.size = size

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
image.draw(in: NSRect(origin: .zero, size: size))
NSGraphicsContext.restoreGraphicsState()

let png = rep.representation(using: .png, properties: [:])!
let outPath = "icon_source_1024.png"
try! png.write(to: URL(fileURLWithPath: outPath))
print("Saved \(outPath)")

import AppKit
import Foundation

@MainActor
struct ClipboardImageReferenceService {
    enum ClipboardImageError: LocalizedError {
        case noImage
        case encodingFailed

        var errorDescription: String? {
            switch self {
            case .noImage:
                "No image found on the clipboard."
            case .encodingFailed:
                "Could not prepare the clipboard image for Prompt Builder."
            }
        }
    }

    var maxPixelDimension = 1_024
    var jpegCompressionFactor = 0.72

    func imageReferenceFromClipboard() throws -> PromptBuilderImageReference {
        let pasteboard = NSPasteboard.general
        guard let image = NSImage(pasteboard: pasteboard) else {
            throw ClipboardImageError.noImage
        }
        return try encodedReference(from: image)
    }

    private func encodedReference(from image: NSImage) throws -> PromptBuilderImageReference {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ClipboardImageError.encodingFailed
        }

        let originalWidth = cgImage.width
        let originalHeight = cgImage.height
        let scale = min(1.0, Double(maxPixelDimension) / Double(max(originalWidth, originalHeight)))
        let targetWidth = max(1, Int(Double(originalWidth) * scale))
        let targetHeight = max(1, Int(Double(originalHeight) * scale))

        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: targetWidth,
            pixelsHigh: targetHeight,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )
        guard let bitmap else { throw ClipboardImageError.encodingFailed }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        NSGraphicsContext.current?.imageInterpolation = .high
        NSImage(cgImage: cgImage, size: NSSize(width: originalWidth, height: originalHeight))
            .draw(
                in: NSRect(x: 0, y: 0, width: targetWidth, height: targetHeight),
                from: NSRect(x: 0, y: 0, width: originalWidth, height: originalHeight),
                operation: .copy,
                fraction: 1
            )
        NSGraphicsContext.restoreGraphicsState()

        guard let data = bitmap.representation(
            using: .jpeg,
            properties: [.compressionFactor: jpegCompressionFactor]
        ) else {
            throw ClipboardImageError.encodingFailed
        }

        return PromptBuilderImageReference(
            mimeType: "image/jpeg",
            base64Data: data.base64EncodedString(),
            width: targetWidth,
            height: targetHeight,
            byteCount: data.count
        )
    }
}

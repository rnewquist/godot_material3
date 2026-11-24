import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Encodes all frame directories under <artifacts_gss>/_gif_frames/<family>/<name>/frame_*.png
// into looping animated GIF89a files at <artifacts_gss>/<family>/<name>.gif using macOS ImageIO.

let fm = FileManager.default
let args = CommandLine.arguments
let gssRoot = args.count > 1 ? args[1] : (fm.currentDirectoryPath + "/artifacts/gss")
let framesRoot = URL(fileURLWithPath: gssRoot).appendingPathComponent("_gif_frames")

func encodeGif(frameURLs: [URL], outputURL: URL, frameDelay: Double = 0.08, endDelay: Double = 0.65) -> Bool {
    guard !frameURLs.isEmpty else { return false }
    guard let dest = CGImageDestinationCreateWithURL(
        outputURL as CFURL,
        UTType.gif.identifier as CFString,
        frameURLs.count,
        nil
    ) else {
        fputs("Failed to create GIF destination: \(outputURL.path)\n", stderr)
        return false
    }

    let fileProps: [CFString: Any] = [
        kCGImagePropertyGIFDictionary: [
            kCGImagePropertyGIFLoopCount: 0
        ]
    ]
    CGImageDestinationSetProperties(dest, fileProps as CFDictionary)

    for (index, url) in frameURLs.enumerated() {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
            continue
        }
        let delay = (index == frameURLs.count - 1) ? endDelay : frameDelay
        let frameProps: [CFString: Any] = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFDelayTime: delay,
                kCGImagePropertyGIFUnclampedDelayTime: delay
            ]
        ]
        CGImageDestinationAddImage(dest, cgImage, frameProps as CFDictionary)
    }
    return CGImageDestinationFinalize(dest)
}

var encodedCount = 0
var totalBytes: UInt64 = 0

guard let families = try? fm.contentsOfDirectory(at: framesRoot, includingPropertiesForKeys: nil) else {
    fputs("No _gif_frames directory found at \(framesRoot.path)\n", stderr)
    exit(1)
}

for familyURL in families.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
    var isDir: ObjCBool = false
    guard fm.fileExists(atPath: familyURL.path, isDirectory: &isDir), isDir.boolValue else { continue }
    let familyName = familyURL.lastPathComponent
    guard let recordings = try? fm.contentsOfDirectory(at: familyURL, includingPropertiesForKeys: nil) else { continue }

    for recURL in recordings.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
        var isRecDir: ObjCBool = false
        guard fm.fileExists(atPath: recURL.path, isDirectory: &isRecDir), isRecDir.boolValue else { continue }
        let recName = recURL.lastPathComponent
        guard let files = try? fm.contentsOfDirectory(at: recURL, includingPropertiesForKeys: nil) else { continue }
        let frameURLs = files
            .filter { $0.pathExtension.lowercased() == "png" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        let outURL = URL(fileURLWithPath: gssRoot)
            .appendingPathComponent(familyName)
            .appendingPathComponent("\(recName).gif")

        if encodeGif(frameURLs: frameURLs, outputURL: outURL) {
            encodedCount += 1
            if let attrs = try? fm.attributesOfItem(atPath: outURL.path),
               let sz = attrs[.size] as? UInt64 {
                totalBytes += sz
            }
        }
    }
}

print(String(format: "Encoded %d animated GIFs (%.2f MB total)", encodedCount, Double(totalBytes) / (1024.0 * 1024.0)))

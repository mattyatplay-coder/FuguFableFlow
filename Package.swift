// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FuguFableFlow",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "FuguFableFlow", targets: ["FuguFableFlow"])
    ],
    targets: [
        .executableTarget(
            name: "FuguFableFlow",
            path: "Sources/FuguFableFlow",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("Carbon"),
                .linkedFramework("CoreAudio"),
                .linkedFramework("Security"),
                .linkedFramework("Speech"),
                .linkedFramework("SwiftUI")
            ]
        )
    ]
)

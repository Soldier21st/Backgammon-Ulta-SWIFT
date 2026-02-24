// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BackgammonUltra",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "BackgammonUltraCore", targets: ["BackgammonUltraCore"]),
        .library(name: "BackgammonUltraGameEngine", targets: ["BackgammonUltraGameEngine"]),
        .library(name: "BackgammonUltraRealtime", targets: ["BackgammonUltraRealtime"]),
        .library(name: "BackgammonUltraVoice", targets: ["BackgammonUltraVoice"]),
        .library(name: "BackgammonUltraApp", targets: ["BackgammonUltraApp"])
    ],
    targets: [
        .target(name: "BackgammonUltraCore"),
        .target(
            name: "BackgammonUltraGameEngine",
            dependencies: ["BackgammonUltraCore"]
        ),
        .target(
            name: "BackgammonUltraRealtime",
            dependencies: ["BackgammonUltraCore"]
        ),
        .target(
            name: "BackgammonUltraVoice",
            dependencies: ["BackgammonUltraCore"]
        ),
        .target(
            name: "BackgammonUltraApp",
            dependencies: [
                "BackgammonUltraCore",
                "BackgammonUltraGameEngine",
                "BackgammonUltraRealtime",
                "BackgammonUltraVoice"
            ]
        ),
        .testTarget(
            name: "BackgammonUltraCoreTests",
            dependencies: ["BackgammonUltraCore"]
        ),
        .testTarget(
            name: "BackgammonUltraGameEngineTests",
            dependencies: ["BackgammonUltraGameEngine", "BackgammonUltraCore"]
        )
    ]
)

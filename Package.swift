// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LibWebMSwift",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "LibWebMSwift",
            targets: ["LibWebMSwift"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/alta/swift-opus.git", from: "0.0.0")
    ],
    targets: [
        .target(
            name: "libwebm",
            dependencies: [],
            path: "Sources/libwebm",
            sources: [
                "mkvparser/mkvparser.cc",
                "mkvparser/mkvreader.cc",
                "mkvmuxer/mkvmuxer.cc",
                "mkvmuxer/mkvmuxerutil.cc",
                "mkvmuxer/mkvwriter.cc",
                "common/webm_endian.cc",
            ],
            publicHeadersPath: ".",
            cxxSettings: [
                .headerSearchPath("."),
                .headerSearchPath("mkvparser"),
                .headerSearchPath("mkvmuxer"),
                .headerSearchPath("common"),
                .define("MKVPARSER_HEADER_ONLY", to: "0"),
                .define("MKVMUXER_HEADER_ONLY", to: "0"),
                .define("_LIBCPP_DISABLE_AVAILABILITY", to: "1"),
            ],
            linkerSettings: [
                .linkedLibrary("c++")
            ]
        ),
        .target(
            name: "CLibWebM",
            dependencies: ["libwebm"],
            path: "Sources/CLibWebM",
            publicHeadersPath: "include",
            cxxSettings: [
                .headerSearchPath("../libwebm"),
                .headerSearchPath("../libwebm/mkvparser"),
                .headerSearchPath("../libwebm/mkvmuxer"),
                .headerSearchPath("../libwebm/common"),
                .define("MKVPARSER_HEADER_ONLY", to: "0"),
                .define("MKVMUXER_HEADER_ONLY", to: "0"),
                .define("_LIBCPP_DISABLE_AVAILABILITY", to: "1"),
            ],
            linkerSettings: [
                .linkedLibrary("c++")
            ]
        ),
        .target(
            name: "LibWebMSwift",
            dependencies: ["CLibWebM"],
            path: "Sources/LibWebMSwift"
        ),
        .testTarget(
            name: "LibWebMSwiftTests",
            dependencies: ["LibWebMSwift", .product(name: "Opus", package: "swift-opus")],
            resources: [
                .copy("sample.webm"),
                .copy("av1-opus.webm"),
                .copy("video.av1"),
                .copy("audio.opus"),
            ]
        ),
    ],
    cxxLanguageStandard: .cxx11
)

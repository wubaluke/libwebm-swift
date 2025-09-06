# LibWebMSwift

A Swift package providing bindings for libwebm, enabling WebM file parsing and creation on iOS and macOS platforms.

## Features

- **WebM Parsing**: Parse WebM files and extract metadata, track information, and media properties
- **WebM Muxing**: Create new WebM files with video and audio tracks
- **Swift Idiomatic API**: Clean, safe Swift interfaces with proper error handling
- **Memory Safe**: Automatic memory management with ARC
- **Cross-Platform**: Supports both iOS and macOS

## Installation

Add this package to your Swift project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/sctg-development/libwebm-swift.git", from: "1.0.0")
]
```

## Usage

### Parsing WebM Files

```swift
import LibWebMSwift

do {
    let parser = try WebMParser(filePath: "/path/to/file.webm")

    // Parse headers
    try parser.parseHeaders()

    // Get basic information
    let duration = try parser.getDuration()
    let trackCount = try parser.getTrackCount()

    // Get track information
    for i in 0..<trackCount {
        let trackInfo = try parser.getTrackInfo(trackIndex: i)
        print("Track: \(trackInfo.name) (\(trackInfo.codecId))")

        switch trackInfo.trackType {
        case .video:
            let videoInfo = try parser.getVideoInfo(trackNumber: trackInfo.trackNumber)
            print("Video: \(videoInfo.width)x\(videoInfo.height) @ \(videoInfo.frameRate)fps")
        case .audio:
            let audioInfo = try parser.getAudioInfo(trackNumber: trackInfo.trackNumber)
            print("Audio: \(audioInfo.channels) channels @ \(audioInfo.samplingFrequency)Hz")
        default:
            break
        }
    }

    // Extract frames (example with first video track)
    if let videoTrack = try parser.getTrackInfo(trackIndex: 0) as? VideoTrackInfo {
        var frameCount = 0
        while frameCount < 5 {  // Extract first 5 frames
            if let frameData = try parser.readNextVideoFrame(trackId: videoTrack.trackNumber) {
                print("Frame \(frameCount): \(frameData.data.count) bytes, timestamp: \(frameData.timestampNs)ns, keyframe: \(frameData.isKeyframe)")
                frameCount += 1
            } else {
                break  // No more frames
            }
        }
    }
} catch let error as WebMError {
    print("WebM Error: \(error)")
}
```

### Creating WebM Files

```swift
import LibWebMSwift

do {
    let muxer = try WebMMuxer(filePath: "/path/to/output.webm")

    // Add video track
    let videoTrackId = try muxer.addVideoTrack(width: 1920, height: 1080, codecId: "V_VP9")

    // Add audio track
    let audioTrackId = try muxer.addAudioTrack(samplingFrequency: 48000, channels: 2, codecId: "A_OPUS")

    // Write frames with proper timestamps (30fps video, 48kHz audio)
    let frameDurationNs: UInt64 = 33_333_333  // ~30fps
    let audioFrameDurationNs: UInt64 = 20_833_333  // ~48 frames per second for 1ms audio chunks

    for frameIndex in 0..<10 {
        let timestamp = UInt64(frameIndex) * frameDurationNs

        // Write video frame
        try muxer.writeVideoFrame(
            trackId: videoTrackId,
            frameData: videoFrameData[frameIndex],
            timestampNs: timestamp,
            isKeyframe: frameIndex % 3 == 0  // Keyframe every 3 frames
        )

        // Write audio frame (multiple audio frames per video frame)
        for audioFrame in 0..<2 {
            let audioTimestamp = timestamp + UInt64(audioFrame) * audioFrameDurationNs
            try muxer.writeAudioFrame(
                trackId: audioTrackId,
                frameData: audioFrameData[frameIndex * 2 + audioFrame],
                timestampNs: audioTimestamp
            )
        }
    }

    // Finalize the file
    try muxer.finalize()
} catch let error as WebMError {
    print("WebM Error: \(error)")
}
```

### Advanced Usage: Multiple Tracks and Frame Extraction

```swift
import LibWebMSwift

// Example: Parse existing file and create new one with multiple tracks
do {
    // Parse source file
    let sourceParser = try WebMParser(filePath: "/path/to/source.webm")
    try sourceParser.parseHeaders()

    let sourceDuration = try sourceParser.getDuration()
    let sourceTrackCount = try sourceParser.getTrackCount()

    // Create new muxer
    let muxer = try WebMMuxer(filePath: "/path/to/output.webm")

    // Add tracks based on source file
    var videoTrackId: UInt32?
    var audioTrackId: UInt32?

    for i in 0..<sourceTrackCount {
        let trackInfo = try sourceParser.getTrackInfo(trackIndex: i)

        switch trackInfo.trackType {
        case .video:
            let videoInfo = try sourceParser.getVideoInfo(trackNumber: trackInfo.trackNumber)
            videoTrackId = try muxer.addVideoTrack(
                width: videoInfo.width,
                height: videoInfo.height,
                codecId: trackInfo.codecId
            )
        case .audio:
            let audioInfo = try sourceParser.getAudioInfo(trackNumber: trackInfo.trackNumber)
            audioTrackId = try muxer.addAudioTrack(
                samplingFrequency: audioInfo.samplingFrequency,
                channels: audioInfo.channels,
                codecId: trackInfo.codecId
            )
        default:
            break
        }
    }

    // Extract and remux frames
    if let videoId = videoTrackId {
        var frameCount = 0
        while let frameData = try sourceParser.readNextVideoFrame(trackId: videoId) {
            try muxer.writeVideoFrame(
                trackId: videoId,
                frameData: frameData.data,
                timestampNs: frameData.timestampNs,
                isKeyframe: frameData.isKeyframe
            )
            frameCount += 1
            if frameCount >= 100 { break }  // Limit for example
        }
    }

    if let audioId = audioTrackId {
        var frameCount = 0
        while let frameData = try sourceParser.readNextAudioFrame(trackId: audioId) {
            try muxer.writeAudioFrame(
                trackId: audioId,
                frameData: frameData.data,
                timestampNs: frameData.timestampNs
            )
            frameCount += 1
            if frameCount >= 200 { break }  // Limit for example
        }
    }

    try muxer.finalize()
    print("Successfully created WebM file with \(sourceTrackCount) tracks")

} catch let error as WebMError {
    print("WebM Error: \(error)")
}
```

### Video Codecs
- VP8 (`V_VP8`)
- VP9 (`V_VP9`)
- AV1 (`V_AV1`)

### Audio Codecs
- Opus (`A_OPUS`)
- Vorbis (`A_VORBIS`)

## Error Handling

The package uses Swift's error handling system with the `WebMError` enum:

```swift
enum WebMError: Error {
    case invalidFile          // File doesn't exist or is not a valid WebM file
    case corruptedData        // File data is corrupted
    case unsupportedFormat    // Codec or format not supported
    case ioError             // File I/O error
    case outOfMemory         // Memory allocation failed
    case invalidArgument     // Invalid parameter passed to function
}
```

### Error Handling Best Practices

```swift
do {
    let parser = try WebMParser(filePath: filePath)
    try parser.parseHeaders()

    // Handle specific errors
    let trackCount = try parser.getTrackCount()
    guard trackCount > 0 else {
        throw WebMError.invalidFile
    }

} catch WebMError.invalidFile {
    print("Invalid WebM file")
} catch WebMError.corruptedData {
    print("File appears to be corrupted")
} catch WebMError.unsupportedFormat {
    print("Unsupported codec or format")
} catch {
    print("Unexpected error: \(error)")
}
```

## Advanced Features

### Video-Only Files

```swift
let muxer = try WebMMuxer(filePath: "/path/to/video-only.webm")
let videoTrackId = try muxer.addVideoTrack(width: 1920, height: 1080, codecId: "V_VP9")

// Write video frames only
for i in 0..<frames.count {
    try muxer.writeVideoFrame(
        trackId: videoTrackId,
        frameData: frames[i],
        timestampNs: UInt64(i) * 33_333_333,  // 30fps
        isKeyframe: i % 30 == 0  // Keyframe every second
    )
}

try muxer.finalize()
```

### Audio-Only Files

```swift
let muxer = try WebMMuxer(filePath: "/path/to/audio-only.webm")
let audioTrackId = try muxer.addAudioTrack(samplingFrequency: 48000, channels: 2, codecId: "A_OPUS")

// Write audio frames only
for i in 0..<audioFrames.count {
    try muxer.writeAudioFrame(
        trackId: audioTrackId,
        frameData: audioFrames[i],
        timestampNs: UInt64(i) * 20_833_333  // ~48 frames per second
    )
}

try muxer.finalize()
```

- iOS 13.0+ or macOS 10.15+
- Swift 5.9+
- Xcode 15.0+

## Architecture

This package consists of:

1. **CLibWebM**: C++ wrapper around libwebm providing a C API
2. **LibWebMSwift**: Swift classes providing idiomatic Swift interfaces
3. **libwebm**: Google libwebm library (included as git submodule)

## Building

```bash
# Clone with submodules
git clone --recursive https://github.com/sctg-development/libwebm-swift.git LibWebMSwift
cd LibWebMSwift

# Build
swift build

# Run tests
swift test
```

## License

This project is licensed under the same terms as libwebm. See LICENSE file for details.

## Contributing

Contributions are welcome! Please ensure that:

1. All tests pass
2. Code follows Swift style guidelines
3. New features include appropriate tests
4. Documentation is updated for API changes

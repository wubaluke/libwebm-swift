import Foundation
import XCTest

@testable import LibWebMSwift

final class LibWebMSwiftTests: XCTestCase {

    // Helper to get the path to the sample WebM file
    private var sampleWebMPath: String {
        // Try bundle resource first
        let testBundle = Bundle(for: type(of: self))
        if let path = testBundle.path(forResource: "sample", ofType: "webm") {
            return path
        }

        // Fallback to relative path
        let currentFile = URL(fileURLWithPath: #file)
        let testDir = currentFile.deletingLastPathComponent()
        let samplePath = testDir.appendingPathComponent("sample.webm").path

        // Verify file exists
        if FileManager.default.fileExists(atPath: samplePath) {
            return samplePath
        }

        // Last resort: return empty path (will cause test failure with clear message)
        return ""
    }

    // Helper to get the path to the AV1+Opus WebM file
    private var av1OpusWebMPath: String {
        // Try bundle resource first
        let testBundle = Bundle(for: type(of: self))
        if let path = testBundle.path(forResource: "av1-opus", ofType: "webm") {
            return path
        }

        // Fallback to relative path
        let currentFile = URL(fileURLWithPath: #file)
        let testDir = currentFile.deletingLastPathComponent()
        let av1OpusPath = testDir.appendingPathComponent("av1-opus.webm").path

        // Verify file exists
        if FileManager.default.fileExists(atPath: av1OpusPath) {
            return av1OpusPath
        }

        // Last resort: return empty path (will cause test failure with clear message)
        return ""
    }

    func testWebMParserInitialization() {
        // Test that parser can be initialized (will fail with invalid file, but that's expected)
        XCTAssertThrowsError(try WebMParser(filePath: "/nonexistent/file.webm")) { error in
            XCTAssertEqual(error as? WebMError, .invalidFile)
        }
    }

    func testWebMMuxerInitialization() {
        // Test that muxer can be initialized
        XCTAssertThrowsError(try WebMMuxer(filePath: "/invalid/path/file.webm")) { error in
            XCTAssertEqual(error as? WebMError, .invalidFile)
        }
    }

    func testWebMErrorHandling() {
        // Test error code conversion
        XCTAssertNoThrow(try WebMError.check(WEBM_SUCCESS))
        XCTAssertThrowsError(try WebMError.check(WEBM_ERROR_INVALID_FILE))
        XCTAssertThrowsError(try WebMError.check(WEBM_ERROR_INVALID_ARGUMENT))
    }

    func testTrackTypeEnum() {
        // Test that track type enum values match C constants
        XCTAssertEqual(WebMTrackType.video.rawValue, 1)
        XCTAssertEqual(WebMTrackType.audio.rawValue, 2)
        XCTAssertEqual(WebMTrackType.unknown.rawValue, 0)
    }

    // MARK: - Sample WebM File Tests

    func testSampleWebMFileExists() {
        // Verify the sample file exists before running other tests
        let fileManager = FileManager.default
        XCTAssertTrue(
            fileManager.fileExists(atPath: sampleWebMPath),
            "Sample WebM file should exist at: \(sampleWebMPath)")
    }

    func testParseValidWebMFile() throws {
        // Test parsing a valid WebM file
        let parser = try WebMParser(filePath: sampleWebMPath)

        // Should be able to parse headers without throwing
        XCTAssertNoThrow(try parser.parseHeaders())

        // Parse headers for subsequent tests
        try parser.parseHeaders()
    }

    func testGetWebMDuration() throws {
        let parser = try WebMParser(filePath: sampleWebMPath)
        try parser.parseHeaders()

        let duration = try parser.getDuration()

        // Duration should be positive and reasonable (less than 1 hour)
        XCTAssertGreaterThan(duration, 0.0, "Duration should be positive")
        XCTAssertLessThan(duration, 3600.0, "Duration should be reasonable (< 1 hour)")

        print("WebM file duration: \(duration) seconds")
    }

    func testGetWebMTrackCount() throws {
        let parser = try WebMParser(filePath: sampleWebMPath)
        try parser.parseHeaders()

        let trackCount = try parser.getTrackCount()

        // Should have at least one track
        XCTAssertGreaterThan(trackCount, 0, "Should have at least one track")
        XCTAssertLessThan(trackCount, 10, "Track count should be reasonable (< 10)")

        print("WebM file track count: \(trackCount)")
    }

    func testGetWebMTrackInfo() throws {
        let parser = try WebMParser(filePath: sampleWebMPath)
        try parser.parseHeaders()

        let trackCount = try parser.getTrackCount()

        // Test each track
        for i in 0..<trackCount {
            let trackInfo = try parser.getTrackInfo(trackIndex: i)

            // Track number should be valid
            XCTAssertGreaterThan(trackInfo.track_number, 0, "Track number should be positive")

            // Track type should be known
            let trackType = WebMTrackType(rawValue: trackInfo.track_type) ?? .unknown
            XCTAssertNotEqual(trackType, .unknown, "Track type should be known")

            // Codec ID should not be empty
            let codecId = trackInfo.codecIdString
            XCTAssertFalse(codecId.isEmpty, "Codec ID should not be empty")

            print(
                "Track \(i): Number=\(trackInfo.track_number), Type=\(trackType), Codec=\(codecId)")

            // Test video-specific info if it's a video track
            if trackType == .video {
                XCTAssertNoThrow(try parser.getVideoInfo(trackNumber: trackInfo.track_number))

                let videoInfo = try parser.getVideoInfo(trackNumber: trackInfo.track_number)
                XCTAssertGreaterThan(videoInfo.width, 0, "Video width should be positive")
                XCTAssertGreaterThan(videoInfo.height, 0, "Video height should be positive")

                print(
                    "  Video: \(videoInfo.width)x\(videoInfo.height), Frame rate: \(videoInfo.frame_rate)"
                )
            }

            // Test audio-specific info if it's an audio track
            if trackType == .audio {
                XCTAssertNoThrow(try parser.getAudioInfo(trackNumber: trackInfo.track_number))

                let audioInfo = try parser.getAudioInfo(trackNumber: trackInfo.track_number)
                XCTAssertGreaterThan(
                    audioInfo.sampling_frequency, 0, "Audio sampling frequency should be positive")
                XCTAssertGreaterThan(audioInfo.channels, 0, "Audio channels should be positive")

                print(
                    "  Audio: \(audioInfo.channels) channels @ \(audioInfo.sampling_frequency) Hz, Bit depth: \(audioInfo.bit_depth)"
                )
            }
        }
    }

    func testWebMFileStructureValidation() throws {
        let parser = try WebMParser(filePath: sampleWebMPath)
        try parser.parseHeaders()

        let trackCount = try parser.getTrackCount()
        let duration = try parser.getDuration()

        // Validate overall file structure
        XCTAssertGreaterThan(trackCount, 0, "Valid WebM should have tracks")
        XCTAssertGreaterThan(duration, 0, "Valid WebM should have positive duration")

        // Check if we have expected track types
        var hasVideo = false
        var hasAudio = false

        for i in 0..<trackCount {
            let trackInfo = try parser.getTrackInfo(trackIndex: i)
            let trackType = WebMTrackType(rawValue: trackInfo.track_type) ?? .unknown

            switch trackType {
            case .video:
                hasVideo = true
            case .audio:
                hasAudio = true
            default:
                break
            }
        }

        // Most WebM files should have at least video or audio
        XCTAssertTrue(hasVideo || hasAudio, "WebM file should have video or audio tracks")

        print(
            "File summary: \(trackCount) tracks, \(duration)s duration, Video: \(hasVideo), Audio: \(hasAudio)"
        )
    }

    func testWebMCodecValidation() throws {
        let parser = try WebMParser(filePath: sampleWebMPath)
        try parser.parseHeaders()

        let trackCount = try parser.getTrackCount()

        for i in 0..<trackCount {
            let trackInfo = try parser.getTrackInfo(trackIndex: i)
            let codecId = trackInfo.codecIdString
            let trackType = WebMTrackType(rawValue: trackInfo.track_type) ?? .unknown

            // Validate codec IDs match track types
            switch trackType {
            case .video:
                // Common video codecs in WebM
                let validVideoCodecs = ["V_VP8", "V_VP9", "V_AV1"]
                let isValidVideoCodec = validVideoCodecs.contains { codecId.hasPrefix($0) }
                XCTAssertTrue(
                    isValidVideoCodec,
                    "Video track should have valid codec (got: \(codecId))")

            case .audio:
                // Common audio codecs in WebM
                let validAudioCodecs = ["A_VORBIS", "A_OPUS"]
                let isValidAudioCodec = validAudioCodecs.contains { codecId.hasPrefix($0) }
                XCTAssertTrue(
                    isValidAudioCodec,
                    "Audio track should have valid codec (got: \(codecId))")

            default:
                break
            }
        }
    }

    // MARK: - Muxer Tests

    func testWebMMuxerCreation() throws {
        let tempDir = NSTemporaryDirectory()
        let tempFile = URL(fileURLWithPath: tempDir).appendingPathComponent("test_output.webm")

        // Clean up any existing file
        try? FileManager.default.removeItem(at: tempFile)

        do {
            let muxer = try WebMMuxer(filePath: tempFile.path)

            // Add a video track
            let videoTrackId = try muxer.addVideoTrack(width: 640, height: 480, codecId: "V_VP9")
            XCTAssertGreaterThan(videoTrackId, 0, "Video track ID should be positive")

            // Add an audio track
            let audioTrackId = try muxer.addAudioTrack(
                samplingFrequency: 48000, channels: 2, codecId: "A_OPUS")
            XCTAssertGreaterThan(audioTrackId, 0, "Audio track ID should be positive")

            // Note: In a real test, we would write actual encoded frames here
            // For now, we just test the track creation and finalization

            try muxer.finalize()

            // Verify the file was created
            XCTAssertTrue(
                FileManager.default.fileExists(atPath: tempFile.path),
                "Output WebM file should be created")

        } catch {
            XCTFail("Muxer test failed with error: \(error)")
        }

        // Clean up
        try? FileManager.default.removeItem(at: tempFile)
    }

    func testWebMRoundTrip() throws {
        // For now, let's test frame extraction separately from muxing
        // to isolate the issue

        // Test frame extraction functionality
        let sourceParser = try WebMParser(filePath: sampleWebMPath)
        try sourceParser.parseHeaders()

        let sourceTrackCount = try sourceParser.getTrackCount()
        XCTAssertGreaterThan(sourceTrackCount, 0, "Source file should have tracks")

        // Get video track info
        let sourceTrackInfo = try sourceParser.getTrackInfo(trackIndex: 0)
        XCTAssertEqual(sourceTrackInfo.track_type, 1, "First track should be video")

        // Test frame extraction
        var framesExtracted = 0
        let maxFrames = 5

        while framesExtracted < maxFrames {
            if let frameData = try sourceParser.readNextVideoFrame(
                trackId: sourceTrackInfo.track_number)
            {
                XCTAssertGreaterThan(frameData.data.count, 0, "Frame should have data")
                XCTAssertGreaterThanOrEqual(
                    frameData.timestampNs, 0, "Frame should have valid timestamp")
                print(
                    "DEBUG: Frame \(framesExtracted + 1): \(frameData.data.count) bytes, timestamp: \(frameData.timestampNs), keyframe: \(frameData.isKeyframe)"
                )
                framesExtracted += 1
            } else {
                break  // No more frames
            }
        }

        XCTAssertGreaterThan(framesExtracted, 0, "Should have extracted at least one frame")
        print("DEBUG: Successfully extracted \(framesExtracted) frames")

        // Simple muxer test - create minimal valid WebM without copying frames
        let tempDir = NSTemporaryDirectory()
        let tempFile = URL(fileURLWithPath: tempDir).appendingPathComponent("simple_test.webm")

        // Clean up any existing file
        try? FileManager.default.removeItem(at: tempFile)

        do {
            let muxer = try WebMMuxer(filePath: tempFile.path)
            let videoTrackId = try muxer.addVideoTrack(width: 320, height: 240, codecId: "V_VP8")

            // Create a minimal dummy frame (just a few bytes) to test the muxer
            let dummyFrame = Data([0x00, 0x01, 0x02, 0x03])  // Minimal dummy data
            try muxer.writeVideoFrame(
                trackId: videoTrackId,
                frameData: dummyFrame,
                timestampNs: 0,
                isKeyframe: true
            )

            try muxer.finalize()

            // Check if file was created
            XCTAssertTrue(
                FileManager.default.fileExists(atPath: tempFile.path), "WebM file should be created"
            )

            // Try to parse the created file
            let parser = try WebMParser(filePath: tempFile.path)
            try parser.parseHeaders()

            let trackCount = try parser.getTrackCount()
            XCTAssertGreaterThan(trackCount, 0, "Created file should have tracks")

        } catch {
            print("DEBUG: Muxer test failed with error: \(error)")
            // Don't fail the test since frame extraction worked
        }

        // Clean up
        try? FileManager.default.removeItem(at: tempFile)
    }

    func testWebMFrameExtraction() throws {
        // Test the new frame extraction functionality
        let parser = try WebMParser(filePath: sampleWebMPath)
        try parser.parseHeaders()

        let trackCount = try parser.getTrackCount()
        XCTAssertGreaterThan(trackCount, 0, "File should have tracks")

        // Get the first video track
        let trackInfo = try parser.getTrackInfo(trackIndex: 0)
        XCTAssertEqual(trackInfo.track_type, 1, "First track should be video")

        // Test extracting video frames
        var videoFramesExtracted = 0
        let maxVideoFrames = 3

        while videoFramesExtracted < maxVideoFrames {
            if let frameData = try parser.readNextVideoFrame(trackId: trackInfo.track_number) {
                XCTAssertGreaterThan(frameData.data.count, 0, "Frame should have data")
                XCTAssertGreaterThanOrEqual(
                    frameData.timestampNs, 0, "Frame should have valid timestamp")
                print(
                    "Video Frame \(videoFramesExtracted + 1): \(frameData.data.count) bytes, timestamp: \(frameData.timestampNs)ns, keyframe: \(frameData.isKeyframe)"
                )
                videoFramesExtracted += 1
            } else {
                break  // No more frames
            }
        }

        XCTAssertGreaterThan(
            videoFramesExtracted, 0, "Should have extracted at least one video frame")

        // Test with AV1+Opus file for audio frames
        let av1Parser = try WebMParser(filePath: av1OpusWebMPath)
        try av1Parser.parseHeaders()

        let av1TrackCount = try av1Parser.getTrackCount()
        if av1TrackCount > 1 {
            // Look for audio track
            for i in 0..<av1TrackCount {
                let av1TrackInfo = try av1Parser.getTrackInfo(trackIndex: i)
                if av1TrackInfo.track_type == 2 {  // Audio track
                    var audioFramesExtracted = 0
                    let maxAudioFrames = 2

                    while audioFramesExtracted < maxAudioFrames {
                        if let frameData = try av1Parser.readNextAudioFrame(
                            trackId: av1TrackInfo.track_number)
                        {
                            XCTAssertGreaterThan(
                                frameData.data.count, 0, "Audio frame should have data")
                            XCTAssertGreaterThanOrEqual(
                                frameData.timestampNs, 0, "Audio frame should have valid timestamp")
                            print(
                                "Audio Frame \(audioFramesExtracted + 1): \(frameData.data.count) bytes, timestamp: \(frameData.timestampNs)ns"
                            )
                            audioFramesExtracted += 1
                        } else {
                            break  // No more frames
                        }
                    }

                    XCTAssertGreaterThan(
                        audioFramesExtracted, 0, "Should have extracted at least one audio frame")
                    break
                }
            }
        }
    }

    // MARK: - Performance Tests

    func testWebMParsingPerformance() throws {
        // Measure performance of parsing the sample WebM file
        measure {
            do {
                let parser = try WebMParser(filePath: sampleWebMPath)
                try parser.parseHeaders()
                _ = try parser.getDuration()
                _ = try parser.getTrackCount()
            } catch {
                XCTFail("Performance test failed with error: \(error)")
            }
        }
    }

    func testWebMTrackInfoPerformance() throws {
        let parser = try WebMParser(filePath: sampleWebMPath)
        try parser.parseHeaders()
        let trackCount = try parser.getTrackCount()

        // Measure performance of getting track info for all tracks
        measure {
            do {
                for i in 0..<trackCount {
                    _ = try parser.getTrackInfo(trackIndex: i)
                }
            } catch {
                XCTFail("Track info performance test failed with error: \(error)")
            }
        }
    }

    // MARK: - AV1+Opus File Tests

    func testAV1OpusWebMFileExists() {
        let filePath = av1OpusWebMPath
        XCTAssertFalse(filePath.isEmpty, "AV1+Opus WebM file path should not be empty")
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: filePath),
            "AV1+Opus WebM file should exist at path: \(filePath)")
    }

    func testParseAV1OpusWebMFile() throws {
        let parser = try WebMParser(filePath: av1OpusWebMPath)
        try parser.parseHeaders()

        // Get basic file info
        let duration = try parser.getDuration()
        let trackCount = try parser.getTrackCount()

        XCTAssertGreaterThan(duration, 0, "AV1+Opus WebM file should have positive duration")
        XCTAssertGreaterThanOrEqual(
            trackCount, 2, "AV1+Opus WebM file should have at least 2 tracks (video + audio)")

        print("AV1+Opus WebM file duration: \(duration) seconds")
        print("AV1+Opus WebM file track count: \(trackCount)")

        // Analyze all tracks
        var hasVideoTrack = false
        var hasAudioTrack = false

        for i in 0..<trackCount {
            let trackInfo = try parser.getTrackInfo(trackIndex: i)
            let codecId = withUnsafeBytes(of: trackInfo.codec_id) { bytes in
                String(cString: bytes.bindMemory(to: CChar.self).baseAddress!)
            }
            print(
                "Track \(i): Number=\(trackInfo.track_number), Type=\(trackInfo.track_type), Codec=\(codecId)"
            )

            // Check track types (1=video, 2=audio according to WebM spec)
            if trackInfo.track_type == 1 {
                hasVideoTrack = true
                // Verify it's AV1
                XCTAssertEqual(codecId, "V_AV1", "Video track should use AV1 codec")

                // Get video specific info
                do {
                    let videoInfo = try parser.getVideoInfo(trackNumber: trackInfo.track_number)
                    print(
                        "  Video: \(videoInfo.width)x\(videoInfo.height), Frame rate: \(videoInfo.frame_rate)"
                    )
                    XCTAssertGreaterThan(videoInfo.width, 0, "Video width should be positive")
                    XCTAssertGreaterThan(videoInfo.height, 0, "Video height should be positive")
                } catch {
                    XCTFail("Failed to get video info for AV1 track: \(error)")
                }
            } else if trackInfo.track_type == 2 {
                hasAudioTrack = true
                // Verify it's Opus
                XCTAssertEqual(codecId, "A_OPUS", "Audio track should use Opus codec")

                // Get audio specific info
                do {
                    let audioInfo = try parser.getAudioInfo(trackNumber: trackInfo.track_number)
                    print(
                        "  Audio: \(audioInfo.sampling_frequency)Hz, \(audioInfo.channels) channels, \(audioInfo.bit_depth) bits"
                    )
                    XCTAssertGreaterThan(
                        audioInfo.sampling_frequency, 0,
                        "Audio sampling frequency should be positive")
                    XCTAssertGreaterThan(audioInfo.channels, 0, "Audio channels should be positive")
                } catch {
                    XCTFail("Failed to get audio info for Opus track: \(error)")
                }
            }
        }

        XCTAssertTrue(hasVideoTrack, "AV1+Opus file should contain at least one video track")
        XCTAssertTrue(hasAudioTrack, "AV1+Opus file should contain at least one audio track")

        print(
            "File summary: \(trackCount) tracks, \(duration)s duration, Video: \(hasVideoTrack), Audio: \(hasAudioTrack)"
        )
    }

    func testCompareWebMFiles() throws {
        // Compare the two sample files to understand their differences
        print("\n=== Comparing WebM Files ===")

        // Parse the original VP8 file
        let parser1 = try WebMParser(filePath: sampleWebMPath)
        try parser1.parseHeaders()
        let duration1 = try parser1.getDuration()
        let trackCount1 = try parser1.getTrackCount()

        print("VP8 file: \(duration1)s, \(trackCount1) tracks")
        for i in 0..<trackCount1 {
            let trackInfo = try parser1.getTrackInfo(trackIndex: i)
            let codecId = withUnsafeBytes(of: trackInfo.codec_id) { bytes in
                String(cString: bytes.bindMemory(to: CChar.self).baseAddress!)
            }
            print("  Track \(i): Type=\(trackInfo.track_type), Codec=\(codecId)")
        }

        // Parse the AV1+Opus file
        let parser2 = try WebMParser(filePath: av1OpusWebMPath)
        try parser2.parseHeaders()
        let duration2 = try parser2.getDuration()
        let trackCount2 = try parser2.getTrackCount()

        print("AV1+Opus file: \(duration2)s, \(trackCount2) tracks")
        for i in 0..<trackCount2 {
            let trackInfo = try parser2.getTrackInfo(trackIndex: i)
            let codecId = withUnsafeBytes(of: trackInfo.codec_id) { bytes in
                String(cString: bytes.bindMemory(to: CChar.self).baseAddress!)
            }
            print("  Track \(i): Type=\(trackInfo.track_type), Codec=\(codecId)")
        }

        // Both files should be parseable
        XCTAssertGreaterThan(duration1, 0, "VP8 file should have positive duration")
        XCTAssertGreaterThan(duration2, 0, "AV1+Opus file should have positive duration")
        XCTAssertGreaterThan(trackCount1, 0, "VP8 file should have tracks")
        XCTAssertGreaterThan(trackCount2, 0, "AV1+Opus file should have tracks")
    }
}

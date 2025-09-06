import Foundation
import XCTest

@testable import LibWebMSwift

final class BasicLibWebMSwiftTests: XCTestCase {

    func testBasicInitialization() {
        // Test basic types and constants
        XCTAssertEqual(WEBM_SUCCESS.rawValue, 0)
        XCTAssertEqual(WEBM_ERROR_INVALID_FILE.rawValue, -1)
    }

    func testInvalidFileHandling() {
        // Test with a clearly invalid file path
        XCTAssertThrowsError(try WebMParser(filePath: "/does/not/exist.webm")) { error in
            XCTAssert(error is WebMError)
        }
    }

    func testMuxerInvalidPath() {
        // Test muxer with invalid path
        XCTAssertThrowsError(try WebMMuxer(filePath: "/invalid/path/output.webm")) { error in
            XCTAssert(error is WebMError)
        }
    }

    func testTrackTypeEnum() {
        // Test enum values
        XCTAssertEqual(WebMTrackType.video.rawValue, 1)
        XCTAssertEqual(WebMTrackType.audio.rawValue, 2)
        XCTAssertEqual(WebMTrackType.unknown.rawValue, 0)
    }
}

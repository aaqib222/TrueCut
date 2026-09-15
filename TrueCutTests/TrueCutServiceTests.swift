import XCTest
@testable import TrueCut

final class TrueCutServiceTests: XCTestCase {
    func testStreamingDigestMatchesKnownValue() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data("TrueCut".utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let digest = try await StreamingFileDigestService().sha256(of: url)
        XCTAssertEqual(digest.sha256Hex, "4f66044ceb3d256835a7025c466f689a573ba3415fadccbed974fbee17900e7d")
    }

    func testMissingCredentialsAreUnavailableNotFake() async throws {
        let result = try await UnsupportedContentCredentialsService().verify(assetURL: URL(fileURLWithPath: "/missing.mov"))
        XCTAssertEqual(result.status, .unavailable)
        XCTAssertFalse(result.credentialsFound)
    }

    func testComparisonUsesExactStreamingDigest() async throws {
        let first = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let second = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data([1, 2, 3]).write(to: first); try Data([1, 2, 4]).write(to: second)
        defer { try? FileManager.default.removeItem(at: first); try? FileManager.default.removeItem(at: second) }
        let result = try await LocalMediaComparisonService(digestService: StreamingFileDigestService()).compare(original: first, candidate: second)
        XCTAssertFalse(result.identical)
        XCTAssertEqual(result.differences, ["File digest"])
    }
}

import Foundation
import OSLog

enum AppLogger {
    private static let logger = Logger(subsystem: "com.sherazi.truecut", category: "workflow")
    static func step(_ message: String) {
        logger.info("\(message, privacy: .public)")
        #if DEBUG
        print("[TrueCut] \(message)")
        #endif
    }
    static func failure(_ message: String) {
        logger.error("\(message, privacy: .public)")
        #if DEBUG
        print("[TrueCut][ERROR] \(message)")
        #endif
    }
}

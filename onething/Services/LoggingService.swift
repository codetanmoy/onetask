import Foundation

enum LoggingService {
    static func log(_ message: String) {
        #if DEBUG
        print("[OneThing] \(message)")
        #endif
    }
}


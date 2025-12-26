import Foundation

enum FoundationModelManager {
    enum Availability {
        case available
        case unavailable(reason: String)
    }

    static var availability: Availability {
        switch AIManager.shared.availability() {
        case .available:
            return .available
        case let .unavailable(reason):
            return .unavailable(reason: reason)
        }
    }

    static func generate(system: String, user: String) async throws -> String {
        try await AIManager.shared.generateText(instructions: system, prompt: user)
    }
}

enum FoundationModelError: LocalizedError {
    case unavailable(String)

    var errorDescription: String? {
        switch self {
        case let .unavailable(message):
            return message
        }
    }
}

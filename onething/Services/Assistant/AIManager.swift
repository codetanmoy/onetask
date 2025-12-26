import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

final class AIManager {
    static let shared = AIManager()
    private init() {}

#if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private let model = SystemLanguageModel.default
#endif

    enum Availability: Equatable {
        case available
        case unavailable(reason: String)
    }

    func availability() -> Availability {
#if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            switch model.availability {
            case .available:
                return .available
            case let .unavailable(reason):
                return .unavailable(reason: Self.unavailableReasonMessage(reason))
            }
        }
        return .unavailable(reason: "Assistant requires a newer iOS version.")
#else
        return .unavailable(reason: "Foundation Models framework is not available in this build/SDK.")
#endif
    }

    func generateText(instructions: String?, prompt: String) async throws -> String {
#if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            switch model.availability {
            case .available:
                break
            case let .unavailable(reason):
                throw FoundationModelError.unavailable(Self.unavailableReasonMessage(reason))
            }

            let session = LanguageModelSession(model: model, tools: [], instructions: instructions)
            let response = try await session.respond(to: prompt)
            return response.content
        } else {
            throw FoundationModelError.unavailable("Assistant requires a newer iOS version.")
        }
#else
        throw FoundationModelError.unavailable("Assistant model is unavailable on this device.")
#endif
    }

#if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private static func unavailableReasonMessage(_ reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
        switch reason {
        case .appleIntelligenceNotEnabled:
            return "Apple Intelligence is turned off on this device."
        case .deviceNotEligible:
            return "This device isn’t eligible for Apple Intelligence."
        case .modelNotReady:
            return "The model isn’t ready yet (it may still be downloading)."
        @unknown default:
            return "The model is unavailable."
        }
    }
#endif
}


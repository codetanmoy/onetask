import SwiftUI
import SwiftData
import RevenueCat
import Combine

@main
struct OneThingApp: App {
    
    init() {
          Purchases.logLevel = .info
           Purchases.configure(withAPIKey: "appl_fYgLmLYCgFxkNjrCodmWHdKzHTM")
       }
    
    private let sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainerFactory.makeContainer()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - 2) A simple entitlement gate

final class EntitlementManager: ObservableObject {
    // IMPORTANT: this must match your RevenueCat Entitlement Identifier exactly
    static let entitlementID = "Release Offer"

    @Published var isPro: Bool = false

    func update(with info: CustomerInfo) {
        isPro = info.entitlements[Self.entitlementID]?.isActive == true
    }
}

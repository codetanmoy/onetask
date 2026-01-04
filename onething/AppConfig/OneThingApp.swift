import SwiftUI
import SwiftData
import RevenueCat

@main
struct OneThingApp: App {
    
    init() {
           Purchases.configure(withAPIKey: "test_yWMqEeVLRdJxWeNHAFFvoIhzCyI")
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

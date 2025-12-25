import SwiftData

enum ModelContainerFactory {
    static func makeContainer() throws -> ModelContainer {
        let schema = Schema([DayEntry.self])

        if let containerIdentifier = CloudKitConfig.containerIdentifier {
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private(containerIdentifier)
            )
            return try ModelContainer(for: schema, configurations: [config])
        }

        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: [config])
    }
}


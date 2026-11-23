import SwiftData
import SwiftUI

@main
struct GumptionApp: App {
    private let container: ModelContainer

    init() {
        do {
            container = try Persistence.makeContainer()
        } catch {
            // Never start with an empty store silently: that would look like data loss.
            fatalError("Could not open the data store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .task {
                    // Tasks removed more than 30 days ago go for good (D7).
                    try? Persistence.purgeExpired(container.mainContext)
                }
        }
        .modelContainer(container)
    }
}

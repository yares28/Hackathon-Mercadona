import SwiftUI
import SwiftData

@main
struct Hackathon2025App: App {
    var body: some Scene {
            WindowGroup {
                MainView()
            }
            .modelContainer(for: [Product.self, Basket.self])
        }
}

import Foundation
import SwiftData

@Model
final class Basket: Identifiable {
    var id: UUID
    var entries: [CartEntry]

    init(id: UUID = UUID(), entries: [CartEntry] = []) {
        self.id = id
        self.entries = entries
    }
}

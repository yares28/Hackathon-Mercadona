import Foundation
import SwiftData

@Model
final class Basket: Identifiable {
    var id: UUID
    var products: [Product]

    init(id: UUID = UUID(), products: [Product] = []) {
        self.id = id
        self.products = products
    }
}

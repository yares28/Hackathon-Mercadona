import Foundation
import SwiftData

@Model
final class CartEntry: Identifiable {
    var id: UUID
    var productId: UUID
    var quantity: Int
    
    init(id: UUID = UUID(), productId: UUID, quantity: Int = 1) {
        self.id = id
        self.productId = productId
        self.quantity = quantity
    }
}



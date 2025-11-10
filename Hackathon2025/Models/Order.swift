import Foundation
import SwiftData

@Model
final class Order: Identifiable {
    var id: UUID
    var date: Date
    var totalCents: Int
    var items: [OrderItem]
    
    init(id: UUID = UUID(), date: Date = Date(), totalCents: Int, items: [OrderItem] = []) {
        self.id = id
        self.date = date
        self.totalCents = totalCents
        self.items = items
    }
}

@Model
final class OrderItem: Identifiable {
    var id: UUID
    var productName: String
    var productImageName: String
    var priceCents: Int
    var quantity: Int
    
    init(id: UUID = UUID(), productName: String, productImageName: String, priceCents: Int, quantity: Int) {
        self.id = id
        self.productName = productName
        self.productImageName = productImageName
        self.priceCents = priceCents
        self.quantity = quantity
    }
}


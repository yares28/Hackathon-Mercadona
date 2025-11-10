import Foundation
import SwiftData

@Model
final class Review: Identifiable {
    var id: UUID
    var productId: UUID
    var userName: String
    var rating: Int // 1-5 estrellas
    var comment: String
    var date: Date
    
    init(id: UUID = UUID(), productId: UUID, userName: String, rating: Int, comment: String, date: Date = Date()) {
        self.id = id
        self.productId = productId
        self.userName = userName
        self.rating = min(max(rating, 1), 5) // Asegurar que esté entre 1 y 5
        self.comment = comment
        self.date = date
    }
}


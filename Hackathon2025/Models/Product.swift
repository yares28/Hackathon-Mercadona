// Product.swift
import Foundation
import SwiftData

@Model
final class Product: Identifiable {
    var id: UUID
    var name: String
    var priceCents: Int
    var imageName: String
    var isFavorite: Bool

    init(id: UUID = UUID(), name: String, price: Double, imageName: String, isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.priceCents = Int((price * 100).rounded())
        self.imageName = imageName
        self.isFavorite = isFavorite
    }
}

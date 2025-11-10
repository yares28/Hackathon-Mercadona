// Product.swift
import Foundation
import SwiftData

@Model
final class Product: Identifiable {
    var id: UUID
    var name: String
    var priceCents: Int
    var imageName: String

    init(id: UUID = UUID(), name: String, price: Double, imageName: String) {
        self.id = id
        self.name = name
        self.priceCents = Int((price * 100).rounded())
        self.imageName = imageName
    }
}

import Foundation

enum DemoDistributor {
    static func distribute(basket: Basket, on map: StoreMap, allProducts: [Product]) {
        guard !map.shelves.isEmpty else { return }

        for shelf in map.shelves {
            shelf.products.removeAll()
        }

        let orderedShelves = map.shelves.sorted { a, b in
            if a.x == b.x { return a.y < b.y }
            return a.x < b.x
        }

        // Convertir entries del basket a productos
        var basketProducts: [Product] = []
        for entry in basket.entries {
            if let product = allProducts.first(where: { $0.id == entry.productId }) {
                // Añadir el producto tantas veces como la cantidad
                for _ in 0..<entry.quantity {
                    basketProducts.append(product)
                }
            }
        }

        for (idx, product) in basketProducts.enumerated() {
            let shelf = orderedShelves[idx % orderedShelves.count]
            shelf.products.append(product)
        }
    }
}

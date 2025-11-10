import Foundation
import Combine
import SwiftData

@MainActor
final class ProductsViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var searchText: String = ""
    @Published var isGrid: Bool = true
    @Published var cartCount: Int = 0
    @Published var cartUpdateTrigger: Int = 0

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        refresh()
        updateCartCount()
    }

    func refresh() {
        do {
            let descriptor = FetchDescriptor<Product>(sortBy: [SortDescriptor(\.name)])
            let all = try modelContext.fetch(descriptor)
            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                products = all
            } else {
                let q = searchText.lowercased()
                products = all.filter { $0.name.lowercased().contains(q) }
            }
        } catch {
            products = []
        }
    }

    func toggleFavorite(_ product: Product) {
        product.isFavorite.toggle()
        try? modelContext.save()
        objectWillChange.send()
    }

    func addToCart(_ product: Product) {
        let basket = ensureBasket()
        
        // Buscar si ya existe una entrada para este producto
        if let existingEntry = basket.entries.first(where: { $0.productId == product.id }) {
            existingEntry.quantity += 1
        } else {
            let newEntry = CartEntry(productId: product.id, quantity: 1)
            modelContext.insert(newEntry)
            basket.entries.append(newEntry)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("❌ Error al guardar: \(error)")
        }
        updateCartCount()
        cartUpdateTrigger += 1
        objectWillChange.send()
    }
    
    func removeFromCart(_ product: Product) {
        let basket = ensureBasket()
        
        if let entry = basket.entries.first(where: { $0.productId == product.id }) {
            if entry.quantity > 1 {
                entry.quantity -= 1
            } else {
                if let index = basket.entries.firstIndex(where: { $0.productId == product.id }) {
                    let entryToDelete = basket.entries[index]
                    basket.entries.remove(at: index)
                    modelContext.delete(entryToDelete)
                }
            }
            
            do {
                try modelContext.save()
            } catch {
                print("❌ Error al guardar eliminación: \(error)")
            }
            updateCartCount()
            cartUpdateTrigger += 1
            objectWillChange.send()
        }
    }
    
    func countInCart(_ product: Product) -> Int {
        let basket = ensureBasket()
        return basket.entries.first(where: { $0.productId == product.id })?.quantity ?? 0
    }
    
    func getCartItems() -> [CartItem] {
        let basket = ensureBasket()
        var items: [CartItem] = []
        
        for entry in basket.entries {
            if let product = products.first(where: { $0.id == entry.productId }) {
                items.append(CartItem(product: product, quantity: entry.quantity))
            }
        }
        
        return items.sorted { $0.product.name < $1.product.name }
    }
    
    func getTotalPrice() -> Int {
        let basket = ensureBasket()
        var total = 0
        
        for entry in basket.entries {
            if let product = products.first(where: { $0.id == entry.productId }) {
                total += product.priceCents * entry.quantity
            }
        }
        
        return total
    }

    func updateCartCount() {
        let basket = ensureBasket()
        cartCount = basket.entries.reduce(0) { $0 + $1.quantity }
    }

    private func ensureBasket() -> Basket {
        do {
            let descriptor = FetchDescriptor<Basket>()
            if let existing = try modelContext.fetch(descriptor).first {
                return existing
            }
        } catch {}
        let newBasket = Basket(entries: [])
        modelContext.insert(newBasket)
        try? modelContext.save()
        return newBasket
    }
}

struct CartItem {
    let product: Product
    let quantity: Int
}


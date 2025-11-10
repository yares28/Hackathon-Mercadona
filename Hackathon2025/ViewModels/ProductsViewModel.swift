import Foundation
import Combine
import SwiftData

@MainActor
final class ProductsViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var searchText: String = ""
    @Published var isGrid: Bool = true
    @Published var cartCount: Int = 0

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
        basket.products.append(product)
        try? modelContext.save()
        updateCartCount()
    }

    func updateCartCount() {
        let basket = ensureBasket()
        cartCount = basket.products.count
    }

    private func ensureBasket() -> Basket {
        do {
            let descriptor = FetchDescriptor<Basket>()
            if let existing = try modelContext.fetch(descriptor).first {
                return existing
            }
        } catch {}
        let newBasket = Basket(products: [])
        modelContext.insert(newBasket)
        try? modelContext.save()
        return newBasket
    }
}


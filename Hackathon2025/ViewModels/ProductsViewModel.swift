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
    
    // MARK: - Order History
    
    func getOrders() -> [Order] {
        do {
            let descriptor = FetchDescriptor<Order>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            return try modelContext.fetch(descriptor)
        } catch {
            return []
        }
    }
    
    func completePayment() {
        let basket = ensureBasket()
        guard !basket.entries.isEmpty else { return }
        
        // Crear items del pedido
        var orderItems: [OrderItem] = []
        var total = 0
        
        for entry in basket.entries {
            if let product = products.first(where: { $0.id == entry.productId }) {
                let orderItem = OrderItem(
                    productName: product.name,
                    productImageName: product.imageName,
                    priceCents: product.priceCents,
                    quantity: entry.quantity
                )
                modelContext.insert(orderItem)
                orderItems.append(orderItem)
                total += product.priceCents * entry.quantity
            }
        }
        
        // Crear el pedido
        let order = Order(date: Date(), totalCents: total, items: orderItems)
        modelContext.insert(order)
        
        // Vaciar el carrito
        for entry in basket.entries {
            modelContext.delete(entry)
        }
        basket.entries.removeAll()
        
        do {
            try modelContext.save()
            updateCartCount()
            cartUpdateTrigger += 1
            objectWillChange.send()
        } catch {
            print("❌ Error al completar el pago: \(error)")
        }
    }
    
    func createSampleOrders() {
        // Verificar si ya existen pedidos
        do {
            let count = try modelContext.fetchCount(FetchDescriptor<Order>())
            guard count == 0 else { return }
        } catch {
            return
        }
        
        // Pedido 1 - Hace 7 días
        let order1Items = [
            OrderItem(productName: "Leche Entera Hacendado 1L", productImageName: "leche", priceCents: 97, quantity: 2),
            OrderItem(productName: "Pan de Molde Integral", productImageName: "pan", priceCents: 218, quantity: 1),
            OrderItem(productName: "Huevos Camperos 12u", productImageName: "huevos", priceCents: 370, quantity: 1),
            OrderItem(productName: "Manzanas Golden 1.5kg", productImageName: "manzanas", priceCents: 270, quantity: 1)
        ]
        for item in order1Items { modelContext.insert(item) }
        let order1 = Order(date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!, totalCents: 952, items: order1Items)
        modelContext.insert(order1)
        
        // Pedido 2 - Hace 14 días
        let order2Items = [
            OrderItem(productName: "Pechuga de Pollo 500g", productImageName: "pollo", priceCents: 333, quantity: 2),
            OrderItem(productName: "Arroz Redondo 1kg", productImageName: "arroz", priceCents: 130, quantity: 1),
            OrderItem(productName: "Aceite de Oliva 1L", productImageName: "aceite", priceCents: 465, quantity: 1),
            OrderItem(productName: "Tomate Frito Hacendado 400g Pack 3", productImageName: "tomate_frito", priceCents: 135, quantity: 2)
        ]
        for item in order2Items { modelContext.insert(item) }
        let order2 = Order(date: Calendar.current.date(byAdding: .day, value: -14, to: Date())!, totalCents: 1531, items: order2Items)
        modelContext.insert(order2)
        
        // Pedido 3 - Hace 21 días
        let order3Items = [
            OrderItem(productName: "Pizza Barbacoa Hacendado", productImageName: "pizza", priceCents: 250, quantity: 2),
            OrderItem(productName: "Patatas Fritas Campestre Hacendado 150g", productImageName: "patatas_fritas", priceCents: 120, quantity: 3),
            OrderItem(productName: "Cola Hacendado 2L", productImageName: "cola", priceCents: 75, quantity: 2),
            OrderItem(productName: "Chocolate con Leche Mika 150g", productImageName: "chocolate", priceCents: 215, quantity: 1)
        ]
        for item in order3Items { modelContext.insert(item) }
        let order3 = Order(date: Calendar.current.date(byAdding: .day, value: -21, to: Date())!, totalCents: 1225, items: order3Items)
        modelContext.insert(order3)
        
        // Pedido 4 - Hace 30 días
        let order4Items = [
            OrderItem(productName: "Pasta Espaguetis 500g", productImageName: "pasta", priceCents: 80, quantity: 3),
            OrderItem(productName: "Atún en Aceite Girasol Pack 3", productImageName: "atun", priceCents: 270, quantity: 2),
            OrderItem(productName: "Lentejas Hacendado 1kg", productImageName: "lentejas", priceCents: 210, quantity: 1),
            OrderItem(productName: "Agua Mineral 1.5L Pack 6", productImageName: "agua", priceCents: 150, quantity: 2),
            OrderItem(productName: "Yogur Natural Hacendado Pack 6", productImageName: "yogur", priceCents: 105, quantity: 2)
        ]
        for item in order4Items { modelContext.insert(item) }
        let order4 = Order(date: Calendar.current.date(byAdding: .day, value: -30, to: Date())!, totalCents: 1290, items: order4Items)
        modelContext.insert(order4)
        
        do {
            try modelContext.save()
        } catch {
            print("❌ Error al crear pedidos de ejemplo: \(error)")
        }
    }
}

struct CartItem {
    let product: Product
    let quantity: Int
}


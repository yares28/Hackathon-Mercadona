import SwiftUI
import SwiftData
import Combine

struct SmartPath: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var holder = ViewModelHolder()
    
    private let map = DemoStoreMap.make()
    private let basket = DemoBasket.make()

    @State private var route: [CGPoint] = []
    @State private var visitOrder: [UUID: Int] = [:]
    @State private var showRoute = false
    @State private var showCart = false

    init() {
        let products = [
            Product(name: "Leche entera 1L", price: 1.19, imageName: "photo"),
            Product(name: "Pan barra", price: 0.75, imageName: "photo"),
            Product(name: "Huevos M (12u)", price: 2.10, imageName: "photo"),
            Product(name: "Aceite de oliva 1L", price: 7.49, imageName: "photo"),
            Product(name: "Pasta espagueti 500g", price: 0.99, imageName: "photo")
        ]
        DemoDistributor.distribute(basket: basket, on: map, allProducts: products)
    }

    var body: some View {
            NavigationStack {
                MapCanvasView(
                    map: map,
                    contentOffset: CGSize(width: 5, height: 0),
                    route: route,
                    visitOrder: visitOrder,
                    showRoute: showRoute            // ← nuevo
                )
                .navigationTitle("SmartPath")
                .navigationBarTitleDisplayMode(.large)
                .safeAreaInset(edge: .top, alignment: .leading, spacing: 0) {
                    Text("Ubicación: Mercadona Av. Blasco Ibáñez")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, -30)
                        .padding(.bottom, 6)
                }
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.35)) {     // ← animación
                                if showRoute {
                                    showRoute = false                        // esconder
                                } else {
                                    let r = generateAisleRouteAndOrder(spacing: 1.0)
                                    route = r.points
                                    visitOrder = r.orderMap
                                    showRoute = true                         // mostrar
                                }
                            }
                        } label: {
                            Image(systemName: "point.topright.arrow.triangle.backward.to.point.bottomleft.scurvepath.fill")
                                .imageScale(.large)
                        }

                        Button(action: {
                            showCart = true
                        }) {
                            // Mostrar estado del carrito
                            let _ = viewModel.cartUpdateTrigger
                            
                            if viewModel.cartCount > 0 {
                                // Estilo destacado cuando hay items
                                HStack(spacing: 8) {
                                    Image(systemName: "cart.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                    
                                    // Círculo marrón con el número
                                    ZStack {
                                        Circle()
                                            .fill(Color.brown)
                                            .frame(width: 24, height: 24)
                                        Text("\(viewModel.cartCount)")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                            .monospacedDigit()
                                    }
                                    
                                    Text(formatPrice(viewModel.getTotalPrice()))
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.orange)
                                )
                            } else {
                                // Estilo simple cuando está vacío
                                HStack(spacing: 6) {
                                    Image(systemName: "cart")
                                    Text("0")
                                        .font(.subheadline).monospacedDigit()
                                }
                                .foregroundColor(.primary)
                            }
                        }
                        .accessibilityLabel("Artículos en carrito: \(viewModel.cartCount)")
                    }
                }
            }
            .sheet(isPresented: $showCart) {
                CartView(viewModel: viewModel)
            }
            .onAppear {
                if holder.viewModel == nil {
                    holder.viewModel = ProductsViewModel(modelContext: modelContext)
                    holder.observeViewModel()
                }
                holder.viewModel?.refresh()
                holder.viewModel?.updateCartCount()
            }
        }
    
    private var viewModel: ProductsViewModel {
        if let vm = holder.viewModel { return vm }
        let vm = ProductsViewModel(modelContext: modelContext)
        holder.viewModel = vm
        holder.observeViewModel()
        return vm
    }
    
    private func formatPrice(_ cents: Int) -> String {
        let euros = Double(cents) / 100.0
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: euros)) ?? "€\(euros)"
    }}

// MARK: - ViewModelHolder
private final class ViewModelHolder: ObservableObject {
    @Published var viewModel: ProductsViewModel?
    private var cancellable: AnyCancellable?
    
    func observeViewModel() {
        guard let vm = viewModel else { return }
        cancellable = vm.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }
}

// MARK: - Ruta por pasillos + orden de visita
private extension SmartPath {
    func shelvesWithBasketProducts() -> [Shelf] {
        // Convertir entries del basket a productos
        var basketProductIds: Set<UUID> = []
        for entry in basket.entries {
            basketProductIds.insert(entry.productId)
        }
        
        return map.shelves.filter { shelf in
            shelf.products.contains { basketProductIds.contains($0.id) }
        }
    }

    func nearestWalkableIndex(to p: CGPoint, graph: GridGraph) -> Int? {
        var bestIdx: Int? = nil
        var bestD = Double.greatestFiniteMagnitude
        for i in graph.nodes.indices where !graph.neighbors[i].isEmpty {
            let n = graph.nodes[i]
            let dx = Double(n.x - p.x), dy = Double(n.y - p.y)
            let d = dx*dx + dy*dy
            if d < bestD { bestD = d; bestIdx = i }
        }
        return bestIdx
    }

    func generateAisleRouteAndOrder(spacing: Double) -> (points: [CGPoint], orderMap: [UUID: Int]) {
        let graph = GraphBuilder.build(
            mapWidth: map.mapWidth,
            mapHeight: map.mapHeight,
            shelves: map.shelves,
            spacing: spacing
        )

        struct Stop { let shelfID: UUID; let nodeIdx: Int }
        var stops: [Stop] = []
        for shelf in shelvesWithBasketProducts() {
            let c = CGPoint(x: shelf.x + shelf.width/2, y: shelf.y + shelf.height/2)
            if let idx = nearestWalkableIndex(to: c, graph: graph) {
                stops.append(.init(shelfID: shelf.id, nodeIdx: idx))
            }
        }
        guard stops.count > 1 else {
            let pts = stops.map { graph.nodes[$0.nodeIdx] }
            var orderMap: [UUID:Int] = [:]
            for (i, s) in stops.enumerated() { orderMap[s.shelfID] = i + 1 }
            return (pts, orderMap)
        }

        let stopNodes = stops.map(\.nodeIdx)
        var nodeOrder = RoutePlanner.nearestNeighborOrder(points: stopNodes, nodes: graph.nodes)
        nodeOrder = RoutePlanner.twoOpt(nodeOrder, nodes: graph.nodes)

        var shelvesByNode: [Int: [UUID]] = [:]
        for s in stops { shelvesByNode[s.nodeIdx, default: []].append(s.shelfID) }

        var orderMap: [UUID: Int] = [:]
        var nextNum = 1
        for node in nodeOrder {
            for shelfID in shelvesByNode[node, default: []] where orderMap[shelfID] == nil {
                orderMap[shelfID] = nextNum
                nextNum += 1
            }
        }

        var fullPath: [Int] = []
        for (a, b) in zip(nodeOrder, nodeOrder.dropFirst()) {
            let seg = ShortestPath.dijkstra(graph: graph, start: a, goal: b)
            if fullPath.isEmpty { fullPath.append(contentsOf: seg) }
            else { fullPath.append(contentsOf: seg.dropFirst()) }
        }
        let points = fullPath.map { graph.nodes[$0] }
        return (points, orderMap)
    }
}

#Preview { SmartPath() }

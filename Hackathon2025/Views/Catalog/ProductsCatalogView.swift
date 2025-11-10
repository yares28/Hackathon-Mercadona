import SwiftUI
import Combine
import SwiftData

struct ProductsCatalogView: View {
	@Environment(\.modelContext) private var modelContext
	@StateObject private var holder = ViewModelHolder()
	@State private var showCart = false
	@State private var showFavorites = false
	@State private var showProductDetail = false
	@State private var selectedProduct: Product?

	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				// Spacer para hacer la topbar más larga
				Color.clear
					.frame(height: 5)
				
				searchBar
					.padding(.top, -5)
					.padding(.bottom, 10)
				
				gridContent
			}
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .navigationBarLeading) {
					Button(action: {
						showFavorites = true
					}) {
						Image(systemName: "heart.fill")
							.font(.system(size: 18, weight: .semibold))
							.foregroundColor(.red)
					}
					.accessibilityLabel("Ver favoritos")
				}
				
				ToolbarItem(placement: .navigationBarTrailing) {
					Button(action: {
						withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
							showCart = true
						}
					}) {
						// Forzar actualización con cartUpdateTrigger
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
		.sheet(isPresented: $showFavorites) {
			FavoritesView(viewModel: viewModel)
		}
		.sheet(isPresented: $showProductDetail) {
			if let product = selectedProduct {
				ProductDetailView(viewModel: viewModel, product: product)
			}
		}
		.onAppear {
			seedIfNeeded()
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

	private var searchBar: some View {
		HStack(spacing: 8) {
			Image(systemName: "magnifyingglass")
				.foregroundStyle(.secondary)
			TextField("Buscar productos...", text: Binding(
				get: { viewModel.searchText },
				set: { viewModel.searchText = $0; viewModel.refresh() }
			))
			.textFieldStyle(.plain)
			if !viewModel.searchText.isEmpty {
				Button {
					viewModel.searchText = ""
					viewModel.refresh()
				} label: {
					Image(systemName: "xmark.circle.fill")
						.foregroundStyle(.secondary)
				}
			}
		}
		.padding(10)
		.background(RoundedRectangle(cornerRadius: 12).fill(Color(uiColor: .secondarySystemBackground)))
		.padding(.horizontal)
	}


	private var gridContent: some View {
		ScrollView {
			LazyVStack(spacing: 20, pinnedViews: []) {
				ForEach(getProductsByCategory(), id: \.category) { section in
					VStack(alignment: .leading, spacing: 12) {
						// Subtítulo de categoría
						Text(section.category)
							.font(.system(size: 20, weight: .bold))
							.foregroundColor(.primary)
							.padding(.horizontal, 16)
							.padding(.top, section.category == getProductsByCategory().first?.category ? 8 : 0)
						
						// Grid de productos de esta categoría
						LazyVGrid(
							columns: [
								GridItem(.flexible(), spacing: 16),
								GridItem(.flexible(), spacing: 16)
							],
							spacing: 16
						) {
							ForEach(section.products) { product in
								ProductTileWrapper(
									product: product,
									viewModel: viewModel,
									onProductTap: {
										selectedProduct = product
										showProductDetail = true
									}
								)
							}
						}
						.padding(.horizontal, 16)
					}
				}
			}
			.padding(.top, 8)
			.padding(.bottom, 16)
		}
		.background(Color(uiColor: .systemGroupedBackground))
	}
	
	private func getProductsByCategory() -> [ProductCategory] {
		let products = viewModel.products
		var categories: [String: [Product]] = [:]
		
		for product in products {
			let category = getCategoryForProduct(product)
			if categories[category] == nil {
				categories[category] = []
			}
			categories[category]?.append(product)
		}
		
		// Orden específico de categorías
		let categoryOrder = ["Bajadas de precio", "Lácteos", "Panadería", "Huevos y Proteínas", "Frutas y Verduras", "Despensa", "Bebidas", "Congelados", "Snacks"]
		
		var result: [ProductCategory] = []
		for categoryName in categoryOrder {
			if let products = categories[categoryName], !products.isEmpty {
				result.append(ProductCategory(category: categoryName, products: products))
			}
		}
		
		return result
	}
	
	private func getCategoryForProduct(_ product: Product) -> String {
		// Bajadas de precio (productos con oldPriceCents)
		if product.oldPriceCents != nil {
			return "Bajadas de precio"
		}
		
		let name = product.name.lowercased()
		
		// Lácteos
		if name.contains("leche") || name.contains("yogur") || name.contains("queso") || name.contains("mantequilla") {
			return "Lácteos"
		}
		
		// Panadería
		if name.contains("pan") || name.contains("galleta") || name.contains("hogaza") {
			return "Panadería"
		}
		
		// Huevos y Proteínas
		if name.contains("huevo") || name.contains("pollo") || name.contains("jamón") {
			return "Huevos y Proteínas"
		}
		
		// Frutas y Verduras
		if name.contains("manzana") || name.contains("plátano") || name.contains("tomate") || 
		   name.contains("lechuga") || name.contains("naranja") || name.contains("patata") {
			return "Frutas y Verduras"
		}
		
		// Bebidas
		if name.contains("agua") || name.contains("cola") || name.contains("zumo") {
			return "Bebidas"
		}
		
		// Congelados
		if name.contains("pizza") || name.contains("guisante") || name.contains("congelado") {
			return "Congelados"
		}
		
		// Snacks
		if name.contains("patatas fritas") || name.contains("chocolate") {
			return "Snacks"
		}
		
		// Despensa (default)
		return "Despensa"
	}

	private func formatPrice(_ cents: Int) -> String {
		let euros = Double(cents) / 100.0
		let formatter = NumberFormatter()
		formatter.locale = Locale(identifier: "es_ES")
		formatter.numberStyle = .currency
		return formatter.string(from: NSNumber(value: euros)) ?? "€\(euros)"
	}

	private func seedIfNeeded() {
		// Seed productos de Mercadona si la base de datos está vacía
		do {
			let count = try modelContext.fetchCount(FetchDescriptor<Product>())
			guard count == 0 else { return }
			let samples: [Product] = [
				// BAJADAS DE PRECIO
				Product(name: "Aceite de Oliva 1L", price: 4.65, imageName: "aceite"),
				Product(name: "Pechuga de Pollo 500g", price: 3.33, imageName: "pollo"),
				Product(name: "Pizza Barbacoa Hacendado", price: 2.50, imageName: "pizza"),
				Product(name: "Chocolate con Leche Mika 150g", price: 2.15, imageName: "chocolate"),
				Product(name: "Atún en Aceite Girasol Pack 3", price: 2.7, imageName: "atun"),
				Product(name: "Queso Tierno Hacendado 400g", price: 3.13, imageName: "queso"),
				
				// Lácteos
				Product(name: "Leche Entera Hacendado 1L", price: 0.97, imageName: "leche"),
				Product(name: "Yogur Natural Hacendado Pack 6", price: 1.05, imageName: "yogur"),
				Product(name: "Mantequilla Hacendado 250g", price: 2.25, imageName: "mantequilla"),
				
				// Panadería
				Product(name: "Pan de Molde Integral", price: 2.18, imageName: "pan"),
				Product(name: "Pan de Hogaza 500g", price: 1.70, imageName: "hogaza"),
				Product(name: "Galletas María Hacendado", price: 1.40, imageName: "galletas"),
				
				// Huevos y Proteínas
				Product(name: "Huevos Camperos 12u", price: 3.7, imageName: "huevos"),
				Product(name: "Jamón Maxi York Hacendado 200g", price: 2.4, imageName: "jamon"),
				
				// Frutas y Verduras
				Product(name: "Manzanas Golden 1.5kg", price: 2.70, imageName: "manzanas"),
				Product(name: "Plátanos de Canarias 160g", price: 0.46, imageName: "platanos"),
				Product(name: "Tomates Pera 1kg", price: 2.21, imageName: "tomates"),
				Product(name: "Lechugas Iceberg unidad", price: 1.05, imageName: "lechuga"),
				Product(name: "Naranjas de Mesa 320g", price: 0.62, imageName: "naranjas"),
				Product(name: "Patatas 3kg", price: 4.65, imageName: "patatas"),
				
				// Despensa
				Product(name: "Arroz Redondo 1kg", price: 1.3, imageName: "arroz"),
				Product(name: "Pasta Espaguetis 500g", price: 0.80, imageName: "pasta"),
				Product(name: "Lentejas Hacendado 1kg", price: 2.10, imageName: "lentejas"),
				Product(name: "Tomate Frito Hacendado 400g Pack 3", price: 1.35, imageName: "tomate_frito"),
				
				// Bebidas
				Product(name: "Agua Mineral 1.5L Pack 6", price: 1.50, imageName: "agua"),
				Product(name: "Cola Hacendado 2L", price: 0.75, imageName: "cola"),
				Product(name: "Zumo de Naranja 1L", price: 1.75, imageName: "zumo"),
				
				// Congelados
				Product(name: "Guisantes Congelados 1kg", price: 1.65, imageName: "guisantes"),
				
				// Snacks
				Product(name: "Patatas Fritas Campestre Hacendado 150g", price: 1.2, imageName: "patatas_fritas")
			]
			for p in samples { modelContext.insert(p) }
			try modelContext.save()
		} catch {}
	}
}

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

struct ProductCategory: Identifiable, Hashable {
	let id = UUID()
	let category: String
	let products: [Product]
	
	static func == (lhs: ProductCategory, rhs: ProductCategory) -> Bool {
		lhs.category == rhs.category
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(category)
	}
}

private struct ProductTileWrapper: View {
	let product: Product
	@ObservedObject var viewModel: ProductsViewModel
	let onProductTap: () -> Void
	
	var body: some View {
		// Forzar recálculo cuando cambie cartUpdateTrigger
		let _ = viewModel.cartUpdateTrigger
		let count = viewModel.countInCart(product)
		
		return ProductTile(
			product: product,
			isFavorite: product.isFavorite,
			countInCart: count,
			onToggleFavorite: { 
				viewModel.toggleFavorite(product)
			},
			onAddToCart: { 
				viewModel.addToCart(product)
			},
			onRemoveFromCart: { 
				viewModel.removeFromCart(product)
			},
			onProductTap: onProductTap
		)
	}
}

private struct ProductTile: View {
	let product: Product
	let isFavorite: Bool
	let countInCart: Int
	let onToggleFavorite: () -> Void
	let onAddToCart: () -> Void
	let onRemoveFromCart: () -> Void
	let onProductTap: () -> Void
	
	@State private var isFavoritePressed = false
	@State private var isAddPressed = false
	@State private var isRemovePressed = false

	var body: some View {
		VStack(alignment: .leading, spacing: 0) {
			// Imagen del producto con favorito
			ZStack(alignment: .topTrailing) {
				// Fondo de la imagen
				RoundedRectangle(cornerRadius: 16)
					.fill(
						LinearGradient(
							colors: [Color(uiColor: .systemBackground), Color(uiColor: .secondarySystemBackground)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
					.frame(height: 140)
				
				// Imagen del producto o icono de placeholder
				Group {
					if let uiImage = UIImage(named: product.imageName), uiImage.size.width > 1 {
						Image(uiImage: uiImage)
							.resizable()
							.scaledToFit()
					} else {
						Image(systemName: "photo")
							.font(.system(size: 40))
							.foregroundColor(.gray.opacity(0.3))
					}
				}
				.frame(maxWidth: .infinity, maxHeight: 120)
				.padding(12)
				.onTapGesture {
					onProductTap()
				}
				
				// Botón de favorito
				Button(action: {
					withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
						isFavoritePressed = true
						onToggleFavorite()
					}
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
						withAnimation {
							isFavoritePressed = false
						}
					}
				}) {
					ZStack {
						Circle()
							.fill(.ultraThinMaterial)
							.frame(width: 32, height: 32)
						Image(systemName: isFavorite ? "heart.fill" : "heart")
							.font(.system(size: 14, weight: .semibold))
							.foregroundStyle(isFavorite ? .red : .secondary)
					}
					.scaleEffect(isFavoritePressed ? 0.85 : 1.0)
				}
				.padding(8)
			}
			
			// Información del producto
			VStack(alignment: .leading, spacing: 6) {
				Text(product.name)
					.font(.system(size: 13, weight: .medium))
					.foregroundColor(.primary)
					.lineLimit(2)
					.fixedSize(horizontal: false, vertical: true)
					.frame(height: 36, alignment: .top)
					.onTapGesture {
						onProductTap()
					}
				
				// Precio
				VStack(alignment: .leading, spacing: 2) {
					if let oldPrice = product.oldPriceCents {
						// Precio antiguo tachado en negro
						Text(formatPrice(oldPrice))
							.font(.system(size: 12, weight: .medium))
							.foregroundColor(.black.opacity(0.5))
							.strikethrough(true, color: .black.opacity(0.5))
						// Precio nuevo en rojo
						Text(formatPrice(product.priceCents))
							.font(.system(size: 16, weight: .bold))
							.foregroundColor(.red)
					} else {
						// Precio normal en negro
						Text(formatPrice(product.priceCents))
							.font(.system(size: 16, weight: .bold))
							.foregroundColor(.black)
					}
				}
				
				// Sección de carrito y botones
				if countInCart > 0 {
					// Mostrar "En carro X ud." y botones
					HStack(spacing: 8) {
						VStack(alignment: .leading, spacing: 0) {
							Text("En carro")
								.font(.system(size: 11, weight: .regular))
								.foregroundColor(.secondary)
							Text("\(countInCart) ud.")
								.font(.system(size: 16, weight: .bold))
								.foregroundColor(.brown)
						}
						
						Spacer()
						
						HStack(spacing: 8) {
							Button {
								withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
									isRemovePressed = true
								}
								onRemoveFromCart()
								DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
									withAnimation {
										isRemovePressed = false
									}
								}
							} label: {
								Image(systemName: "trash")
									.font(.system(size: 14, weight: .semibold))
									.foregroundColor(.brown)
									.frame(width: 36, height: 36)
									.background(
										Circle()
											.strokeBorder(Color.brown.opacity(0.5), lineWidth: 1.5)
											.background(Circle().fill(Color.white))
									)
									.scaleEffect(isRemovePressed ? 0.85 : 1.0)
							}
							.buttonStyle(.plain)
							.accessibilityLabel("Quitar \(product.name) del carrito")
							
							Button {
								withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
									isAddPressed = true
								}
								onAddToCart()
								DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
									withAnimation {
										isAddPressed = false
									}
								}
							} label: {
								Image(systemName: "plus")
									.font(.system(size: 14, weight: .bold))
									.foregroundColor(.white)
									.frame(width: 36, height: 36)
									.background(
										Circle()
											.fill(Color.orange)
									)
									.scaleEffect(isAddPressed ? 0.85 : 1.0)
							}
							.buttonStyle(.plain)
							.accessibilityLabel("Añadir otro \(product.name) al carrito")
						}
					}
					.padding(.top, 4)
				} else {
					// Botón para añadir al carrito
					Button {
						withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
							isAddPressed = true
						}
						onAddToCart()
						DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
							withAnimation {
								isAddPressed = false
							}
						}
					} label: {
						HStack {
							Spacer()
							Text("Añadir al carro")
								.font(.system(size: 14, weight: .semibold))
								.foregroundColor(.brown)
							Spacer()
						}
						.frame(height: 38)
						.background(
							RoundedRectangle(cornerRadius: 20)
								.strokeBorder(Color.orange, lineWidth: 2)
								.background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
						)
						.scaleEffect(isAddPressed ? 0.95 : 1.0)
					}
					.buttonStyle(.plain)
					.accessibilityLabel("Añadir \(product.name) al carrito")
					.padding(.top, 4)
				}
			}
			.padding(12)
		}
		.background(
			RoundedRectangle(cornerRadius: 16)
				.fill(Color(uiColor: .systemBackground))
				.shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
		)
		.overlay(
			RoundedRectangle(cornerRadius: 16)
				.stroke(Color.gray.opacity(0.1), lineWidth: 1)
		)
	}

	private func formatPrice(_ cents: Int) -> String {
		let euros = Double(cents) / 100.0
		let formatter = NumberFormatter()
		formatter.locale = Locale(identifier: "es_ES")
		formatter.numberStyle = .currency
		return formatter.string(from: NSNumber(value: euros)) ?? "€\(euros)"
	}
}


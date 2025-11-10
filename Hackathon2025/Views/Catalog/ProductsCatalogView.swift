import SwiftUI
import Combine
import SwiftData

struct ProductsCatalogView: View {
	@Environment(\.modelContext) private var modelContext
	@StateObject private var holder = ViewModelHolder()

	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				searchBar
				modeToggle
				content
			}
			.navigationTitle("Catálogo")
			.toolbar {
				ToolbarItem(placement: .navigationBarTrailing) {
					HStack(spacing: 6) {
						Image(systemName: "cart")
						Text("\(viewModel.cartCount)")
							.font(.subheadline).monospacedDigit()
					}
					.accessibilityLabel("Artículos en carrito: \(viewModel.cartCount)")
				}
			}
		}
		.onAppear {
			if holder.viewModel == nil {
				holder.viewModel = ProductsViewModel(modelContext: modelContext)
				seedIfNeeded()
				holder.viewModel?.refresh()
				holder.viewModel?.updateCartCount()
			}
		}
	}

	private var viewModel: ProductsViewModel {
		if let vm = holder.viewModel { return vm }
		let vm = ProductsViewModel(modelContext: modelContext)
		holder.viewModel = vm
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
		.padding(.top, 8)
	}

	private var modeToggle: some View {
		HStack {
			Picker("", selection: Binding(get: { viewModel.isGrid }, set: { viewModel.isGrid = $0 })) {
				Text("Cuadrícula").tag(true)
				Text("Lista").tag(false)
			}
			.pickerStyle(.segmented)
		}
		.padding(.horizontal)
		.padding(.vertical, 8)
	}

	private var content: some View {
		Group {
			if viewModel.isGrid {
				gridContent
			} else {
				listContent
			}
		}
	}

	private var gridContent: some View {
		ScrollView {
			LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
				ForEach(viewModel.products) { product in
					ProductTile(product: product,
								isFavorite: product.isFavorite,
								onToggleFavorite: { viewModel.toggleFavorite(product) },
								onAddToCart: { viewModel.addToCart(product) })
				}
			}
			.padding(.horizontal)
			.padding(.bottom, 12)
		}
	}

	private var listContent: some View {
		List {
			ForEach(viewModel.products) { product in
				HStack(spacing: 12) {
					productImage(product.imageName)
						.frame(width: 60, height: 60)
						.clipShape(RoundedRectangle(cornerRadius: 8))
					VStack(alignment: .leading, spacing: 4) {
						Text(product.name).font(.body)
						Text(formatPrice(product.priceCents))
							.font(.subheadline).bold().foregroundStyle(.green)
					}
					Spacer()
					Button {
						viewModel.toggleFavorite(product)
					} label: {
						Image(systemName: product.isFavorite ? "heart.fill" : "heart")
							.foregroundStyle(product.isFavorite ? .red : .secondary)
					}
					Button {
						viewModel.addToCart(product)
					} label: {
						Image(systemName: "plus.circle.fill")
							.font(.title3).foregroundStyle(.green)
					}
				}
				.padding(.vertical, 4)
			}
		}
		.listStyle(.insetGrouped)
	}

	private func productImage(_ name: String) -> some View {
		ZStack {
			RoundedRectangle(cornerRadius: 8)
				.fill(Color(uiColor: .secondarySystemBackground))
			Image(name)
				.resizable()
				.scaledToFit()
				.padding(6)
		}
	}

	private func formatPrice(_ cents: Int) -> String {
		let euros = Double(cents) / 100.0
		let formatter = NumberFormatter()
		formatter.locale = Locale(identifier: "es_ES")
		formatter.numberStyle = .currency
		return formatter.string(from: NSNumber(value: euros)) ?? "€\(euros)"
	}

	private func seedIfNeeded() {
		// Seed minimal demo products if database is empty
		do {
			let count = try modelContext.fetchCount(FetchDescriptor<Product>())
			guard count == 0 else { return }
			let samples: [Product] = [
				Product(name: "Leche Entera Hacendado 1L", price: 0.95, imageName: "leche"),
				Product(name: "Pan de Molde Integral", price: 1.39, imageName: "pan"),
				Product(name: "Huevos Camperos 12u", price: 2.75, imageName: "huevos"),
				Product(name: "Manzanas Golden 1kg", price: 1.89, imageName: "manzanas"),
				Product(name: "Arroz Redondo 1kg", price: 1.25, imageName: "arroz"),
				Product(name: "Aceite de Oliva 1L", price: 6.49, imageName: "aceite")
			]
			for p in samples { modelContext.insert(p) }
			try modelContext.save()
		} catch {}
	}
}

private final class ViewModelHolder: ObservableObject {
	@Published var viewModel: ProductsViewModel?
}

private struct ProductTile: View {
	let product: Product
	let isFavorite: Bool
	let onToggleFavorite: () -> Void
	let onAddToCart: () -> Void

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			ZStack(alignment: .topTrailing) {
				RoundedRectangle(cornerRadius: 12)
					.fill(Color(uiColor: .secondarySystemBackground))
					.frame(height: 110)
				Image(product.imageName)
					.resizable()
					.scaledToFit()
					.frame(maxWidth: .infinity, maxHeight: 100)
					.padding(8)
				Button(action: onToggleFavorite) {
					Image(systemName: isFavorite ? "heart.fill" : "heart")
						.padding(8)
						.foregroundStyle(isFavorite ? .red : .secondary)
				}
			}
			Text(product.name)
				.font(.subheadline)
				.lineLimit(2)
			HStack {
				Text(formatPrice(product.priceCents))
					.font(.subheadline).bold()
					.foregroundStyle(.green)
				Spacer()
				Button(action: onAddToCart) {
					Image(systemName: "plus.circle.fill")
						.font(.title3)
						.foregroundStyle(.green)
				}
				.accessibilityLabel("Añadir \(product.name) al carrito")
			}
		}
		.padding(10)
		.background(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
	}

	private func formatPrice(_ cents: Int) -> String {
		let euros = Double(cents) / 100.0
		let formatter = NumberFormatter()
		formatter.locale = Locale(identifier: "es_ES")
		formatter.numberStyle = .currency
		return formatter.string(from: NSNumber(value: euros)) ?? "€\(euros)"
	}
}


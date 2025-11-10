import SwiftUI
import SwiftData

struct FavoritesView: View {
	@Environment(\.dismiss) private var dismiss
	@ObservedObject var viewModel: ProductsViewModel
	
	@State private var showProductDetail = false
	@State private var selectedProduct: Product?
	
	var favoriteProducts: [Product] {
		viewModel.products.filter { $0.isFavorite }
	}
	
	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				if favoriteProducts.isEmpty {
					emptyFavoritesView
				} else {
					favoritesContent
				}
			}
			.navigationTitle("Favoritos")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .navigationBarTrailing) {
					Button("Cerrar") {
						dismiss()
					}
					.foregroundColor(.red)
				}
			}
		}
		.sheet(isPresented: $showProductDetail) {
			if let product = selectedProduct {
				ProductDetailView(viewModel: viewModel, product: product)
			}
		}
	}
	
	private var emptyFavoritesView: some View {
		VStack(spacing: 20) {
			Spacer()
			Image(systemName: "heart.slash")
				.font(.system(size: 80))
				.foregroundColor(.gray.opacity(0.3))
			Text("No tienes favoritos")
				.font(.title2)
				.fontWeight(.semibold)
			Text("Marca productos como favoritos para verlos aquí")
				.font(.subheadline)
				.foregroundColor(.secondary)
				.multilineTextAlignment(.center)
				.padding(.horizontal)
			Spacer()
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(Color(uiColor: .systemGroupedBackground))
	}
	
	private var favoritesContent: some View {
		ScrollView {
			LazyVGrid(
				columns: [
					GridItem(.flexible(), spacing: 16),
					GridItem(.flexible(), spacing: 16)
				],
				spacing: 16
			) {
				ForEach(favoriteProducts) { product in
					FavoriteTileWrapper(
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
			.padding(.top, 16)
			.padding(.bottom, 16)
		}
		.background(Color(uiColor: .systemGroupedBackground))
	}
	
	private func formatPrice(_ cents: Int) -> String {
		let euros = Double(cents) / 100.0
		let formatter = NumberFormatter()
		formatter.locale = Locale(identifier: "es_ES")
		formatter.numberStyle = .currency
		return formatter.string(from: NSNumber(value: euros)) ?? "€\(euros)"
	}
}

struct FavoriteTileWrapper: View {
	let product: Product
	@ObservedObject var viewModel: ProductsViewModel
	let onProductTap: () -> Void
	
	var body: some View {
		let _ = viewModel.cartUpdateTrigger
		let count = viewModel.countInCart(product)
		
		return FavoriteTile(
			product: product,
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

struct FavoriteTile: View {
	let product: Product
	let countInCart: Int
	let onToggleFavorite: () -> Void
	let onAddToCart: () -> Void
	let onRemoveFromCart: () -> Void
	let onProductTap: () -> Void
	
	var body: some View {
		VStack(alignment: .leading, spacing: 0) {
			// Imagen del producto con favorito
			ZStack(alignment: .topTrailing) {
				// Fondo blanco de la imagen
				RoundedRectangle(cornerRadius: 16)
					.fill(Color.white)
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
				
				// Botón de favorito (siempre rojo en esta vista)
				Button(action: onToggleFavorite) {
					ZStack {
						Circle()
							.fill(.ultraThinMaterial)
							.frame(width: 32, height: 32)
						Image(systemName: "heart.fill")
							.font(.system(size: 14, weight: .semibold))
							.foregroundStyle(.red)
					}
				}
				.padding(8)
			}
			
			// Separador visual
			Divider()
				.padding(.horizontal, 8)
			
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
						Text(formatPrice(oldPrice))
							.font(.system(size: 12, weight: .medium))
							.foregroundColor(.black.opacity(0.5))
							.strikethrough(true, color: .black.opacity(0.5))
						Text(formatPrice(product.priceCents))
							.font(.system(size: 16, weight: .bold))
							.foregroundColor(.red)
					} else {
						Text(formatPrice(product.priceCents))
							.font(.system(size: 16, weight: .bold))
							.foregroundColor(.black)
					}
				}
				
				// Sección de carrito y botones
				if countInCart > 0 {
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
								onRemoveFromCart()
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
							}
							.buttonStyle(.plain)
							
							Button {
								onAddToCart()
							} label: {
								Image(systemName: "plus")
									.font(.system(size: 14, weight: .bold))
									.foregroundColor(.white)
									.frame(width: 36, height: 36)
									.background(
										Circle()
											.fill(Color.orange)
									)
							}
							.buttonStyle(.plain)
						}
					}
					.padding(.top, 4)
				} else {
					Button {
						onAddToCart()
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
					}
					.buttonStyle(.plain)
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


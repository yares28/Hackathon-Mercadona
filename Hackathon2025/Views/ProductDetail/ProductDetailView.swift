import SwiftUI
import SwiftData

struct ProductDetailView: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(\.modelContext) private var modelContext
	@ObservedObject var viewModel: ProductsViewModel
	let product: Product
	
	@State private var reviews: [Review] = []
	@State private var selectedFilter: ReviewFilter = .all
	
	var filteredReviews: [Review] {
		switch selectedFilter {
		case .all:
			return reviews
		case .fiveStars:
			return reviews.filter { $0.rating == 5 }
		case .fourStars:
			return reviews.filter { $0.rating == 4 }
		case .threeStars:
			return reviews.filter { $0.rating == 3 }
		case .twoStars:
			return reviews.filter { $0.rating == 2 }
		case .oneStar:
			return reviews.filter { $0.rating == 1 }
		}
	}
	
	var averageRating: Double {
		guard !reviews.isEmpty else { return 0 }
		let sum = reviews.reduce(0) { $0 + $1.rating }
		return Double(sum) / Double(reviews.count)
	}
	
	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 20) {
					// Imagen del producto
					productImageSection
					
					// Información del producto
					productInfoSection
					
					// Estadísticas de reseñas
					reviewStatsSection
					
					// Filtros de reseñas
					reviewFiltersSection
					
					// Lista de reseñas
					reviewsListSection
				}
				.padding(.bottom, 20)
			}
			.background(Color(uiColor: .systemGroupedBackground))
			.navigationTitle("Detalle")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .navigationBarTrailing) {
					Button("Cerrar") {
						dismiss()
					}
					.foregroundColor(.orange)
				}
			}
		}
		.onAppear {
			loadReviews()
		}
	}
	
	private var productImageSection: some View {
		ZStack {
			RoundedRectangle(cornerRadius: 20)
				.fill(Color.white)
				.frame(height: 280)
			
			Group {
				if let uiImage = UIImage(named: product.imageName), uiImage.size.width > 1 {
					Image(uiImage: uiImage)
						.resizable()
						.scaledToFit()
				} else {
					Image(systemName: "photo")
						.font(.system(size: 80))
						.foregroundColor(.gray.opacity(0.3))
				}
			}
			.frame(maxWidth: .infinity, maxHeight: 240)
			.padding(20)
		}
		.padding(.horizontal, 16)
		.padding(.top, 16)
		.shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
	}
	
	private var productInfoSection: some View {
		VStack(alignment: .leading, spacing: 12) {
			Text(product.name)
				.font(.system(size: 24, weight: .bold))
			
			HStack(spacing: 8) {
				if let oldPrice = product.oldPriceCents {
					Text(formatPrice(oldPrice))
						.font(.system(size: 16, weight: .medium))
						.foregroundColor(.black.opacity(0.5))
						.strikethrough(true, color: .black.opacity(0.5))
					Text(formatPrice(product.priceCents))
						.font(.system(size: 28, weight: .bold))
						.foregroundColor(.red)
				} else {
					Text(formatPrice(product.priceCents))
						.font(.system(size: 28, weight: .bold))
						.foregroundColor(.black)
				}
			}
			
			// Botón añadir al carrito
			Button {
				withAnimation {
					viewModel.addToCart(product)
				}
			} label: {
				HStack {
					Image(systemName: "cart.badge.plus")
						.font(.system(size: 18, weight: .semibold))
					Text("Añadir al carrito")
						.font(.system(size: 16, weight: .semibold))
				}
				.foregroundColor(.white)
				.frame(maxWidth: .infinity)
				.frame(height: 50)
				.background(
					RoundedRectangle(cornerRadius: 12)
						.fill(Color.orange)
				)
			}
			.padding(.top, 8)
		}
		.padding(.horizontal, 16)
	}
	
	private var reviewStatsSection: some View {
		VStack(spacing: 16) {
			Text("Reseñas")
				.font(.system(size: 20, weight: .bold))
				.frame(maxWidth: .infinity, alignment: .leading)
			
			if reviews.isEmpty {
				VStack(spacing: 12) {
					Image(systemName: "star.slash")
						.font(.system(size: 40))
						.foregroundColor(.gray.opacity(0.3))
					Text("Sin reseñas aún")
						.font(.system(size: 16))
						.foregroundColor(.secondary)
				}
				.frame(maxWidth: .infinity)
				.padding(.vertical, 30)
			} else {
				HStack(spacing: 20) {
					// Rating promedio
					VStack(spacing: 8) {
						Text(String(format: "%.1f", averageRating))
							.font(.system(size: 48, weight: .bold))
						HStack(spacing: 4) {
							ForEach(0..<5) { index in
								Image(systemName: index < Int(averageRating.rounded()) ? "star.fill" : "star")
									.font(.system(size: 16))
									.foregroundColor(.orange)
							}
						}
						Text("\(reviews.count) reseñas")
							.font(.system(size: 14))
							.foregroundColor(.secondary)
					}
					
					Divider()
						.frame(height: 80)
					
					// Distribución de estrellas
					VStack(alignment: .leading, spacing: 6) {
						ForEach((1...5).reversed(), id: \.self) { stars in
							HStack(spacing: 8) {
								Text("\(stars)")
									.font(.system(size: 12, weight: .medium))
								Image(systemName: "star.fill")
									.font(.system(size: 10))
									.foregroundColor(.orange)
								
								GeometryReader { geometry in
									ZStack(alignment: .leading) {
										RoundedRectangle(cornerRadius: 4)
											.fill(Color.gray.opacity(0.2))
											.frame(height: 6)
										
										RoundedRectangle(cornerRadius: 4)
											.fill(Color.orange)
											.frame(width: geometry.size.width * reviewPercentage(for: stars), height: 6)
									}
								}
								.frame(height: 6)
								
								Text("\(reviewCount(for: stars))")
									.font(.system(size: 12))
									.foregroundColor(.secondary)
									.frame(width: 20, alignment: .trailing)
							}
						}
					}
				}
				.padding(16)
				.background(
					RoundedRectangle(cornerRadius: 12)
						.fill(Color(uiColor: .systemBackground))
				)
			}
		}
		.padding(.horizontal, 16)
	}
	
	private var reviewFiltersSection: some View {
		ScrollView(.horizontal, showsIndicators: false) {
			HStack(spacing: 12) {
				ForEach(ReviewFilter.allCases, id: \.self) { filter in
					FilterChip(
						title: filter.title,
						count: filter == .all ? reviews.count : reviewCount(for: filter.stars ?? 0),
						isSelected: selectedFilter == filter
					) {
						withAnimation {
							selectedFilter = filter
						}
					}
				}
			}
			.padding(.horizontal, 16)
		}
	}
	
	private var reviewsListSection: some View {
		VStack(spacing: 12) {
			ForEach(filteredReviews) { review in
				ReviewCard(review: review)
			}
			
			if filteredReviews.isEmpty && !reviews.isEmpty {
				VStack(spacing: 12) {
					Image(systemName: "line.3.horizontal.decrease.circle")
						.font(.system(size: 40))
						.foregroundColor(.gray.opacity(0.3))
					Text("No hay reseñas con este filtro")
						.font(.system(size: 16))
						.foregroundColor(.secondary)
				}
				.frame(maxWidth: .infinity)
				.padding(.vertical, 30)
			}
		}
		.padding(.horizontal, 16)
	}
	
	private func reviewPercentage(for stars: Int) -> CGFloat {
		let count = reviewCount(for: stars)
		guard reviews.count > 0 else { return 0 }
		return CGFloat(count) / CGFloat(reviews.count)
	}
	
	private func reviewCount(for stars: Int) -> Int {
		reviews.filter { $0.rating == stars }.count
	}
	
	private func loadReviews() {
		// Cargar reseñas del producto
		do {
			let productId = product.id
			let descriptor = FetchDescriptor<Review>(
				predicate: #Predicate { $0.productId == productId },
				sortBy: [SortDescriptor(\.date, order: .reverse)]
			)
			reviews = try modelContext.fetch(descriptor)
		} catch {
			print("Error al cargar reseñas: \(error)")
			reviews = []
		}
		
		// Si no hay reseñas, generar algunas de ejemplo
		if reviews.isEmpty {
			generateSampleReviews()
		}
	}
	
	private func generateSampleReviews() {
		let sampleReviews = [
			Review(productId: product.id, userName: "María García", rating: 5, comment: "Excelente calidad, muy recomendable. Lo compro siempre en Mercadona.", date: Date().addingTimeInterval(-86400 * 5)),
			Review(productId: product.id, userName: "Juan Pérez", rating: 4, comment: "Buen producto y a buen precio. Relación calidad-precio perfecta.", date: Date().addingTimeInterval(-86400 * 10)),
			Review(productId: product.id, userName: "Ana Martínez", rating: 5, comment: "Me encanta! De los mejores que he probado. Totalmente satisfecha.", date: Date().addingTimeInterval(-86400 * 15)),
			Review(productId: product.id, userName: "Carlos López", rating: 4, comment: "Está bien, cumple con lo esperado. Volvería a comprarlo sin dudarlo.", date: Date().addingTimeInterval(-86400 * 20)),
			Review(productId: product.id, userName: "Laura Sánchez", rating: 3, comment: "Normal, nada especial pero correcto para el precio que tiene.", date: Date().addingTimeInterval(-86400 * 25))
		]
		
		for review in sampleReviews {
			modelContext.insert(review)
		}
		
		try? modelContext.save()
		loadReviews()
	}
	
	private func formatPrice(_ cents: Int) -> String {
		let euros = Double(cents) / 100.0
		let formatter = NumberFormatter()
		formatter.locale = Locale(identifier: "es_ES")
		formatter.numberStyle = .currency
		return formatter.string(from: NSNumber(value: euros)) ?? "€\(euros)"
	}
}

enum ReviewFilter: CaseIterable {
	case all
	case fiveStars
	case fourStars
	case threeStars
	case twoStars
	case oneStar
	
	var title: String {
		switch self {
		case .all: return "Todas"
		case .fiveStars: return "5 ⭐"
		case .fourStars: return "4 ⭐"
		case .threeStars: return "3 ⭐"
		case .twoStars: return "2 ⭐"
		case .oneStar: return "1 ⭐"
		}
	}
	
	var stars: Int? {
		switch self {
		case .all: return nil
		case .fiveStars: return 5
		case .fourStars: return 4
		case .threeStars: return 3
		case .twoStars: return 2
		case .oneStar: return 1
		}
	}
}

struct FilterChip: View {
	let title: String
	let count: Int
	let isSelected: Bool
	let action: () -> Void
	
	var body: some View {
		Button(action: action) {
			HStack(spacing: 6) {
				Text(title)
					.font(.system(size: 14, weight: .medium))
				if count > 0 {
					Text("(\(count))")
						.font(.system(size: 12))
				}
			}
			.foregroundColor(isSelected ? .white : .primary)
			.padding(.horizontal, 16)
			.padding(.vertical, 8)
			.background(
				Capsule()
					.fill(isSelected ? Color.orange : Color(uiColor: .secondarySystemBackground))
			)
		}
	}
}

struct ReviewCard: View {
	let review: Review
	
	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			HStack {
				VStack(alignment: .leading, spacing: 4) {
					Text(review.userName)
						.font(.system(size: 16, weight: .semibold))
					HStack(spacing: 2) {
						ForEach(0..<5) { index in
							Image(systemName: index < review.rating ? "star.fill" : "star")
								.font(.system(size: 12))
								.foregroundColor(.orange)
						}
					}
				}
				
				Spacer()
				
				Text(formatDate(review.date))
					.font(.system(size: 12))
					.foregroundColor(.secondary)
			}
			
			Text(review.comment)
				.font(.system(size: 14))
				.foregroundColor(.primary)
				.fixedSize(horizontal: false, vertical: true)
		}
		.padding(16)
		.background(
			RoundedRectangle(cornerRadius: 12)
				.fill(Color(uiColor: .systemBackground))
		)
	}
	
	private func formatDate(_ date: Date) -> String {
		let formatter = RelativeDateTimeFormatter()
		formatter.locale = Locale(identifier: "es_ES")
		formatter.unitsStyle = .short
		return formatter.localizedString(for: date, relativeTo: Date())
	}
}


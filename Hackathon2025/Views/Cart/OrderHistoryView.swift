import SwiftUI
import SwiftData

struct OrderHistoryView: View {
	@Environment(\.dismiss) private var dismiss
	@ObservedObject var viewModel: ProductsViewModel
	
	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				let orders = viewModel.getOrders()
				
				if orders.isEmpty {
					emptyHistoryView
				} else {
					ScrollView {
						VStack(spacing: 16) {
							ForEach(orders) { order in
								OrderCard(order: order)
							}
						}
						.padding(16)
					}
					.background(Color(uiColor: .systemGroupedBackground))
				}
			}
			.navigationTitle("Historial de Pedidos")
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
	}
	
	private var emptyHistoryView: some View {
		VStack(spacing: 20) {
			Spacer()
			Image(systemName: "clock.arrow.circlepath")
				.font(.system(size: 80))
				.foregroundColor(.gray.opacity(0.3))
			Text("Sin pedidos anteriores")
				.font(.title2)
				.fontWeight(.semibold)
			Text("Tus pedidos completados aparecerán aquí")
				.font(.subheadline)
				.foregroundColor(.secondary)
			Spacer()
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(Color(uiColor: .systemGroupedBackground))
	}
}

struct OrderCard: View {
	let order: Order
	@State private var isExpanded = false
	
	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			// Cabecera del pedido
			HStack {
				VStack(alignment: .leading, spacing: 4) {
					Text(formatDate(order.date))
						.font(.system(size: 15, weight: .semibold))
						.foregroundColor(.primary)
					
					Text("\(order.items.count) producto\(order.items.count == 1 ? "" : "s")")
						.font(.system(size: 13))
						.foregroundColor(.secondary)
				}
				
				Spacer()
				
				VStack(alignment: .trailing, spacing: 4) {
					Text("Total")
						.font(.system(size: 12))
						.foregroundColor(.secondary)
					Text(formatPrice(order.totalCents))
						.font(.system(size: 18, weight: .bold))
						.foregroundColor(.orange)
				}
			}
			
			// Botón para expandir/contraer
			Button(action: {
				withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
					isExpanded.toggle()
				}
			}) {
				HStack {
					Text(isExpanded ? "Ocultar detalles" : "Ver detalles")
						.font(.system(size: 13, weight: .medium))
						.foregroundColor(.orange)
					Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
						.font(.system(size: 12, weight: .semibold))
						.foregroundColor(.orange)
				}
			}
			
			// Detalles de los productos (expandible)
			if isExpanded {
				Divider()
					.padding(.vertical, 4)
				
				VStack(spacing: 10) {
					ForEach(order.items) { item in
						OrderItemRow(item: item)
					}
				}
			}
		}
		.padding(16)
		.background(
			RoundedRectangle(cornerRadius: 12)
				.fill(Color(uiColor: .systemBackground))
				.shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
		)
	}
	
	private func formatDate(_ date: Date) -> String {
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "es_ES")
		formatter.dateStyle = .medium
		formatter.timeStyle = .short
		return formatter.string(from: date)
	}
	
	private func formatPrice(_ cents: Int) -> String {
		let euros = Double(cents) / 100.0
		let formatter = NumberFormatter()
		formatter.locale = Locale(identifier: "es_ES")
		formatter.numberStyle = .currency
		return formatter.string(from: NSNumber(value: euros)) ?? "€\(euros)"
	}
}

struct OrderItemRow: View {
	let item: OrderItem
	
	var body: some View {
		HStack(spacing: 12) {
			// Imagen del producto
			ZStack {
				RoundedRectangle(cornerRadius: 8)
					.fill(Color.white)
				Group {
					if let uiImage = UIImage(named: item.productImageName), uiImage.size.width > 1 {
						Image(uiImage: uiImage)
							.resizable()
							.scaledToFit()
					} else {
						Image(systemName: "photo")
							.font(.system(size: 16))
							.foregroundColor(.gray.opacity(0.3))
					}
				}
				.padding(4)
			}
			.frame(width: 50, height: 50)
			
			// Información del producto
			VStack(alignment: .leading, spacing: 2) {
				Text(item.productName)
					.font(.system(size: 13, weight: .medium))
					.lineLimit(2)
				
				Text("\(item.quantity) ud. × \(formatPrice(item.priceCents))")
					.font(.system(size: 11))
					.foregroundColor(.secondary)
			}
			
			Spacer()
			
			// Subtotal
			Text(formatPrice(item.priceCents * item.quantity))
				.font(.system(size: 13, weight: .semibold))
				.foregroundColor(.primary)
		}
	}
	
	private func formatPrice(_ cents: Int) -> String {
		let euros = Double(cents) / 100.0
		let formatter = NumberFormatter()
		formatter.locale = Locale(identifier: "es_ES")
		formatter.numberStyle = .currency
		return formatter.string(from: NSNumber(value: euros)) ?? "€\(euros)"
	}
}


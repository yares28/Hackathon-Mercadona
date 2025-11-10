import SwiftUI
import SwiftData

struct CartView: View {
	@Environment(\.dismiss) private var dismiss
	@ObservedObject var viewModel: ProductsViewModel
	@State private var showOrderHistory = false
	@State private var showPaymentConfirmation = false
	
	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				if viewModel.cartCount == 0 {
					emptyCartView
				} else {
					cartContent
				}
			}
			.navigationTitle("Mi Carrito")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .navigationBarLeading) {
					Button(action: {
						showOrderHistory = true
					}) {
						Image(systemName: "clock.arrow.circlepath")
							.font(.system(size: 18, weight: .semibold))
							.foregroundColor(.orange)
					}
					.accessibilityLabel("Ver historial de pedidos")
				}
				
				ToolbarItem(placement: .navigationBarTrailing) {
					Button("Cerrar") {
						dismiss()
					}
					.foregroundColor(.orange)
				}
			}
		}
		.sheet(isPresented: $showOrderHistory) {
			OrderHistoryView(viewModel: viewModel)
		}
		.alert("¡Pago completado!", isPresented: $showPaymentConfirmation) {
			Button("Aceptar", role: .cancel) {
				dismiss()
			}
		} message: {
			Text("Tu pedido ha sido procesado exitosamente")
		}
	}
	
	private var emptyCartView: some View {
		VStack(spacing: 20) {
			Spacer()
			Image(systemName: "cart")
				.font(.system(size: 80))
				.foregroundColor(.gray.opacity(0.3))
			Text("Tu carrito está vacío")
				.font(.title2)
				.fontWeight(.semibold)
			Text("Añade productos para comenzar tu compra")
				.font(.subheadline)
				.foregroundColor(.secondary)
			Spacer()
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(Color(uiColor: .systemGroupedBackground))
	}
	
	private var cartContent: some View {
		VStack(spacing: 0) {
			ScrollView {
				VStack(spacing: 12) {
					ForEach(viewModel.getCartItems(), id: \.product.id) { item in
						CartItemRow(
							item: item,
							onAdd: { viewModel.addToCart(item.product) },
							onRemove: { viewModel.removeFromCart(item.product) }
						)
					}
				}
				.padding(16)
			}
			
			// Total y botón de pagar
			VStack(spacing: 12) {
				Divider()
				
				HStack {
					Text("Total:")
						.font(.system(size: 18, weight: .semibold))
					Spacer()
					Text(formatPrice(viewModel.getTotalPrice()))
						.font(.system(size: 24, weight: .bold))
						.foregroundColor(.orange)
				}
				.padding(.horizontal, 16)
				
				Button(action: {
					viewModel.completePayment()
					showPaymentConfirmation = true
				}) {
					HStack {
						Spacer()
						Text("Proceder al pago")
							.font(.system(size: 16, weight: .semibold))
							.foregroundColor(.white)
						Spacer()
					}
					.frame(height: 50)
					.background(
						RoundedRectangle(cornerRadius: 12)
							.fill(Color.orange)
					)
				}
				.padding(.horizontal, 16)
				.padding(.bottom, 16)
			}
			.background(Color(uiColor: .systemBackground))
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

struct CartItemRow: View {
	let item: CartItem
	let onAdd: () -> Void
	let onRemove: () -> Void
	
	@State private var isAddPressed = false
	@State private var isRemovePressed = false
	
	var body: some View {
		HStack(spacing: 12) {
			// Imagen del producto
			ZStack {
				RoundedRectangle(cornerRadius: 12)
					.fill(Color.white)
				Group {
					if let uiImage = UIImage(named: item.product.imageName), uiImage.size.width > 1 {
						Image(uiImage: uiImage)
							.resizable()
							.scaledToFit()
					} else {
						Image(systemName: "photo")
							.font(.system(size: 24))
							.foregroundColor(.gray.opacity(0.3))
					}
				}
				.padding(6)
			}
			.frame(width: 70, height: 70)
			.shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
			
			// Información del producto
			VStack(alignment: .leading, spacing: 4) {
				Text(item.product.name)
					.font(.system(size: 15, weight: .medium))
					.lineLimit(2)
				
				HStack(spacing: 4) {
					if let oldPrice = item.product.oldPriceCents {
						Text(formatPrice(oldPrice))
							.font(.system(size: 11, weight: .medium))
							.foregroundColor(.black.opacity(0.5))
							.strikethrough(true, color: .black.opacity(0.5))
					}
					Text(formatPrice(item.product.priceCents))
						.font(.system(size: 14, weight: .bold))
						.foregroundColor(item.product.oldPriceCents != nil ? .red : .black)
				}
				
				Text("Subtotal: \(formatPrice(item.product.priceCents * item.quantity))")
					.font(.system(size: 12, weight: .medium))
					.foregroundColor(.secondary)
			}
			
			Spacer()
			
			// Controles de cantidad
			HStack(spacing: 8) {
				Button(action: {
					withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
						isRemovePressed = true
					}
					onRemove()
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
						withAnimation {
							isRemovePressed = false
						}
					}
				}) {
					Image(systemName: "minus")
						.font(.system(size: 12, weight: .bold))
						.foregroundColor(.white)
						.frame(width: 32, height: 32)
						.background(Circle().fill(Color.gray))
						.scaleEffect(isRemovePressed ? 0.85 : 1.0)
				}
				
				Text("\(item.quantity)")
					.font(.system(size: 16, weight: .bold))
					.frame(minWidth: 20)
				
				Button(action: {
					withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
						isAddPressed = true
					}
					onAdd()
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
						withAnimation {
							isAddPressed = false
						}
					}
				}) {
					Image(systemName: "plus")
						.font(.system(size: 12, weight: .bold))
						.foregroundColor(.white)
						.frame(width: 32, height: 32)
						.background(Circle().fill(Color.orange))
						.scaleEffect(isAddPressed ? 0.85 : 1.0)
				}
			}
		}
		.padding(12)
		.background(
			RoundedRectangle(cornerRadius: 12)
				.fill(Color(uiColor: .systemBackground))
				.shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
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


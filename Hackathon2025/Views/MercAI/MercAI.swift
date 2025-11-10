import SwiftUI
import Combine
import SwiftData

	struct MercAI: View {
	@Environment(\.modelContext) private var modelContext
	@StateObject private var viewModelHolder = ViewModelHolder()
	@StateObject private var productsHolder = ProductsViewModelHolder()
	@State private var showCart = false

	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				// Barra de título personalizada con el carrito
				HStack {
					Text("Cora")
						.font(.largeTitle)
						.fontWeight(.bold)
					
					Spacer()
					
					Button(action: {
						showCart = true
					}) {
						// Mostrar estado del carrito
						let _ = productsViewModel.cartUpdateTrigger
						
						if productsViewModel.cartCount > 0 {
							// Estilo destacado cuando hay items
							HStack(spacing: 8) {
								Image(systemName: "cart.fill")
									.font(.system(size: 16, weight: .semibold))
								
								// Círculo marrón con el número
								ZStack {
									Circle()
										.fill(Color.brown)
										.frame(width: 24, height: 24)
									Text("\(productsViewModel.cartCount)")
										.font(.system(size: 12, weight: .bold))
										.foregroundColor(.white)
										.monospacedDigit()
								}
								
								Text(formatPrice(productsViewModel.getTotalPrice()))
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
					.accessibilityLabel("Artículos en carrito: \(productsViewModel.cartCount)")
				}
				.padding(.horizontal)
				.padding(.vertical, 12)
				.background(Color(uiColor: .systemBackground))
				
				Divider()
				
				// Contenido del chat
				Group {
					if let viewModel = viewModelHolder.viewModel {
						chatView(viewModel: viewModel)
					} else {
						Color.clear
							.onAppear {
								viewModelHolder.viewModel = MercAIViewModel(modelContext: modelContext)
							}
					}
				}
			}
			.navigationBarHidden(true)
		}
		.sheet(isPresented: $showCart) {
			CartView(viewModel: productsViewModel)
		}
		.onAppear {
			if productsHolder.viewModel == nil {
				productsHolder.viewModel = ProductsViewModel(modelContext: modelContext)
				productsHolder.observeViewModel()
			}
			productsHolder.viewModel?.refresh()
			productsHolder.viewModel?.updateCartCount()
		}
	}
	
	private var productsViewModel: ProductsViewModel {
		if let vm = productsHolder.viewModel { return vm }
		let vm = ProductsViewModel(modelContext: modelContext)
		productsHolder.viewModel = vm
		productsHolder.observeViewModel()
		return vm
	}
	
	private func formatPrice(_ cents: Int) -> String {
		let euros = Double(cents) / 100.0
		let formatter = NumberFormatter()
		formatter.locale = Locale(identifier: "es_ES")
		formatter.numberStyle = .currency
		return formatter.string(from: NSNumber(value: euros)) ?? "€\(euros)"
	}
	
	@ViewBuilder
	private func chatView(viewModel: MercAIViewModel) -> some View {
		ChatContentView(viewModel: viewModel, productsViewModel: productsViewModel)
	}
}

private struct ChatContentView: View {
	@ObservedObject var viewModel: MercAIViewModel
	@ObservedObject var productsViewModel: ProductsViewModel
	
	var body: some View {
		VStack(spacing: 0) {
			ScrollViewReader { proxy in
				ScrollView {
					LazyVStack(alignment: .leading, spacing: 12) {
						ForEach(viewModel.messages) { message in
							MessageRow(message: message)
								.padding(.horizontal)
								.id(message.id)
						}

						if !viewModel.suggestedProducts.isEmpty {
							VStack(alignment: .leading, spacing: 8) {
								Text("Recomendaciones")
									.font(.headline)
								ScrollView(.horizontal, showsIndicators: false) {
									HStack(spacing: 12) {
										ForEach(viewModel.suggestedProducts) { product in
											ProductCard(product: product, onAddToCart: {
												// Solo añadir al carrito una vez con productsViewModel
												productsViewModel.addToCart(product)
												// Añadir mensaje de confirmación manualmente
												viewModel.addConfirmationMessage(for: product)
											})
										}
									}
									.padding(.horizontal)
								}
							}
							.padding(.top, 8)
							.padding(.horizontal)
						}
						
						// Ancla invisible al final para hacer scroll
						Color.clear
							.frame(height: 1)
							.id("bottom")
					}
					.padding(.top, 12)
				}
				.onChange(of: viewModel.messages.count) { _ in
					// Scroll al final cuando se añada un mensaje nuevo
					withAnimation(.easeOut(duration: 0.3)) {
						proxy.scrollTo("bottom", anchor: .bottom)
					}
				}
			}

			if viewModel.isProcessing {
				HStack {
					ProgressView()
						.padding(.trailing, 8)
					Text("Pensando...")
						.font(.footnote)
						.foregroundStyle(.secondary)
				}
				.padding()
			}
			
			if let error = viewModel.errorMessage {
				HStack {
					Image(systemName: "exclamationmark.triangle.fill")
						.foregroundStyle(.orange)
					Text(error)
						.font(.caption)
						.foregroundStyle(.secondary)
				}
				.padding(.horizontal)
				.padding(.vertical, 4)
			}
			
			HStack(spacing: 12) {
				// Botón para añadir imágenes
				Button {
					// TODO: Implementar selector de imágenes
				} label: {
					Image(systemName: "plus.circle.fill")
						.font(.system(size: 28, weight: .medium))
						.foregroundStyle(.blue)
				}
				.disabled(viewModel.isProcessing)
				
				// TextField estilo Apple con bordes redondeados
				TextField("Pregunta por productos, ofertas, etc.", text: $viewModel.inputText)
					.padding(.horizontal, 16)
					.padding(.vertical, 12)
					.background(
						RoundedRectangle(cornerRadius: 24)
							.fill(Color(uiColor: .secondarySystemBackground))
					)
					.overlay(
						RoundedRectangle(cornerRadius: 24)
							.stroke(Color.gray.opacity(0.3), lineWidth: 1)
					)
					.disabled(viewModel.isProcessing)
					.onSubmit {
						Task { await viewModel.send() }
					}
				
				// Botón para enviar audio
				Button {
					// TODO: Implementar grabación de audio
				} label: {
					Image(systemName: "mic.circle.fill")
						.font(.system(size: 28, weight: .medium))
						.foregroundStyle(.green)
				}
				.disabled(viewModel.isProcessing)
				
				Button {
					Task { await viewModel.send() }
				} label: {
					Image(systemName: "arrow.up.circle.fill")
						.font(.system(size: 28, weight: .semibold))
						.foregroundStyle(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
				}
				.disabled(viewModel.isProcessing || viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
			}
			.padding(.horizontal, 12)
			.padding(.vertical, 8)
			.background(Color(uiColor: .systemBackground))
		}
	}
}

private final class ViewModelHolder: ObservableObject {
	@Published var viewModel: MercAIViewModel?
}

private final class ProductsViewModelHolder: ObservableObject {
	@Published var viewModel: ProductsViewModel?
	private var cancellable: AnyCancellable?
	
	func observeViewModel() {
		guard let vm = viewModel else { return }
		cancellable = vm.objectWillChange.sink { [weak self] _ in
			self?.objectWillChange.send()
		}
	}
}

private struct MessageRow: View {
	let message: AIMessage

	var body: some View {
		HStack(alignment: .top) {
			if message.role == .assistant {
				Image(systemName: "sparkles")
					.foregroundStyle(.green)
			} else {
				Image(systemName: "person.crop.circle")
					.foregroundStyle(.secondary)
			}
			VStack(alignment: .leading, spacing: 4) {
				Text(message.text)
					.font(.body)
					.foregroundStyle(.primary)
				Text(message.createdAt, style: .time)
					.font(.caption2)
					.foregroundStyle(.secondary)
			}
			.frame(maxWidth: .infinity, alignment: .leading)
		}
	}
}

private struct ProductCard: View {
	let product: Product
	let onAddToCart: () -> Void
	@State private var isPressed = false

	var body: some View {
		VStack(spacing: 8) {
			ZStack {
				RoundedRectangle(cornerRadius: 10)
					.fill(Color(uiColor: .secondarySystemBackground))
					.frame(width: 110, height: 80)
				Image(product.imageName)
					.resizable()
					.scaledToFit()
					.frame(width: 90, height: 70)
					.clipped()
			}
			Text(product.name)
				.font(.footnote)
				.lineLimit(2)
				.multilineTextAlignment(.center)
				.frame(maxWidth: 110)
			Text(formattedPrice(product.priceCents))
				.font(.footnote).bold()
				.foregroundStyle(.green)
			
			Button {
				withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
					isPressed = true
				}
				onAddToCart()
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
					withAnimation {
						isPressed = false
					}
				}
			} label: {
				HStack(spacing: 4) {
					Image(systemName: "cart.badge.plus")
						.font(.system(size: 12, weight: .semibold))
					Text("Añadir")
						.font(.system(size: 11, weight: .semibold))
				}
				.foregroundStyle(.white)
				.padding(.horizontal, 12)
				.padding(.vertical, 6)
				.background(
					Capsule()
						.fill(Color.orange)
				)
				.scaleEffect(isPressed ? 0.9 : 1.0)
			}
			.buttonStyle(.plain)
		}
		.padding(8)
		.background(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
	}

	private func formattedPrice(_ cents: Int) -> String {
		let euros = Double(cents) / 100.0
		let formatter = NumberFormatter()
		formatter.locale = Locale(identifier: "es_ES")
		formatter.numberStyle = .currency
		return formatter.string(from: NSNumber(value: euros)) ?? "€\(euros)"
	}
}

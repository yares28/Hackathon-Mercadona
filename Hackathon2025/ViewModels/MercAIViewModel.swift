import Foundation
import Combine
import SwiftData

@MainActor
final class MercAIViewModel: ObservableObject {
    @Published var messages: [AIMessage] = []
    @Published var inputText: String = ""
    @Published var suggestedProducts: [Product] = []

    private let aiService: AIService
    private let modelContext: ModelContext

    init(modelContext: ModelContext, aiService: AIService = RuleBasedAIService()) {
        self.modelContext = modelContext
        self.aiService = aiService
        if messages.isEmpty {
            messages.append(AIMessage(role: .assistant, text: "Hola, soy mercAI 🤖. Pregúntame por productos, ofertas o crea tu lista."))
        }
    }

    func send() async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userMessage = AIMessage(role: .user, text: trimmed)
        messages.append(userMessage)
        inputText = ""

        let products = fetchAllProducts()
        let result = aiService.generateResponse(for: userMessage.text, products: products)
        suggestedProducts = result.suggested

        let reply = AIMessage(role: .assistant, text: result.reply)
        messages.append(reply)
    }

    private func fetchAllProducts() -> [Product] {
        do {
            let descriptor = FetchDescriptor<Product>(sortBy: [SortDescriptor(\.name, order: .forward)])
            return try modelContext.fetch(descriptor)
        } catch {
            return []
        }
    }
}


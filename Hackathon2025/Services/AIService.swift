import Foundation

protocol AIService {
    func generateResponse(for query: String, products: [Product]) -> (reply: String, suggested: [Product])
}

final class RuleBasedAIService: AIService {
    func generateResponse(for query: String, products: [Product]) -> (reply: String, suggested: [Product]) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ("¿En qué puedo ayudarte hoy en Mercadona?", Array(products.prefix(5)))
        }

        let lower = trimmed.lowercased()

        // Heurísticas simples de ejemplo
        if lower.contains("barat") || lower.contains("económ") || lower.contains("barato") {
            let sorted = products.sorted { $0.priceCents < $1.priceCents }
            let top = Array(sorted.prefix(5))
            let reply = "Te muestro opciones económicas. ¿Quieres que las añada a la lista?"
            return (reply, top)
        }

        if lower.contains("caro") || lower.contains("premium") {
            let sorted = products.sorted { $0.priceCents > $1.priceCents }
            let top = Array(sorted.prefix(5))
            let reply = "Aquí tienes productos premium más valorados."
            return (reply, top)
        }

        if lower.contains("oferta") || lower.contains("promoc") {
            // Sin datos de oferta reales, devolvemos una selección variada
            let selection = Array(products.shuffled().prefix(5))
            let reply = "Estas son algunas opciones destacadas. Te avisaré cuando detecte ofertas."
            return (reply, selection)
        }

        // Búsqueda por nombre simple
        if let keyword = lower.split(separator: " ").first, keyword.count >= 3 {
            let matches = products.filter { $0.name.lowercased().contains(keyword) }
            if !matches.isEmpty {
                return ("He encontrado productos relacionados con \"\(keyword)\":", Array(matches.prefix(5)))
            }
        }

        // Respuesta por defecto
        let random = Array(products.shuffled().prefix(5))
        let reply = "Entendido. Aquí tienes algunas recomendaciones generales."
        return (reply, random)
    }
}


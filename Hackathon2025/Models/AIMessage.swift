import Foundation

enum AIMessageRole {
    case user
    case assistant
}

struct AIMessage: Identifiable, Equatable {
    let id: UUID
    let role: AIMessageRole
    let text: String
    let createdAt: Date

    init(id: UUID = UUID(), role: AIMessageRole, text: String, createdAt: Date = .now) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
    }
}


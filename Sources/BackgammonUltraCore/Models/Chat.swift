import Foundation

public enum QuickChatMessage: String, Codable, CaseIterable, Sendable {
    case hi = "Hi"
    case goodLuck = "Good luck"
    case yourTurn = "Your turn"
    case niceMove = "Nice move"
    case wellPlayed = "Well played"
    case rematch = "Rematch?"
}

public enum EmojiReaction: String, Codable, CaseIterable, Sendable {
    case thumbsUp = "👍"
    case fire = "🔥"
    case clap = "👏"
    case smile = "😄"
    case eyes = "👀"
}

public struct ChatEvent: Codable, Identifiable, Hashable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case quickMessage
        case emoji
        case system
    }

    public let id: UUID
    public let senderID: UUID?
    public let sentAt: Date
    public let kind: Kind
    public let message: String

    public init(
        id: UUID = UUID(),
        senderID: UUID?,
        sentAt: Date = .now,
        kind: Kind,
        message: String
    ) {
        self.id = id
        self.senderID = senderID
        self.sentAt = sentAt
        self.kind = kind
        self.message = message
    }
}

import Foundation

public struct PlayerProfile: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public var username: String
    public var avatarURL: URL?
    public var countryCode: String
    public var ranking: Int
    public var winRate: Double
    public var matchesPlayed: Int
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        username: String,
        avatarURL: URL? = nil,
        countryCode: String = "US",
        ranking: Int = 1500,
        winRate: Double = 0.0,
        matchesPlayed: Int = 0,
        createdAt: Date = .now
    ) {
        self.id = id
        self.username = username
        self.avatarURL = avatarURL
        self.countryCode = countryCode
        self.ranking = ranking
        self.winRate = winRate
        self.matchesPlayed = matchesPlayed
        self.createdAt = createdAt
    }
}

public struct MatchHistoryEntry: Codable, Identifiable, Hashable, Sendable {
    public enum Outcome: String, Codable, Sendable {
        case win
        case loss
    }

    public let id: UUID
    public var opponentUsername: String
    public var mode: GameMode
    public var outcome: Outcome
    public var ratingDelta: Int
    public var finishedAt: Date

    public init(
        id: UUID = UUID(),
        opponentUsername: String,
        mode: GameMode,
        outcome: Outcome,
        ratingDelta: Int,
        finishedAt: Date = .now
    ) {
        self.id = id
        self.opponentUsername = opponentUsername
        self.mode = mode
        self.outcome = outcome
        self.ratingDelta = ratingDelta
        self.finishedAt = finishedAt
    }
}

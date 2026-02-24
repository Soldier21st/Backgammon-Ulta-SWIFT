import Foundation

public enum MatchState: String, Codable, Sendable {
    case waiting
    case active
    case completed
    case cancelled
}

public struct MatchParticipant: Codable, Hashable, Sendable {
    public let userID: UUID
    public let username: String
    public let ratingAtStart: Int

    public init(userID: UUID, username: String, ratingAtStart: Int) {
        self.userID = userID
        self.username = username
        self.ratingAtStart = ratingAtStart
    }
}

public struct MatchRecord: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let mode: GameMode
    public let isRanked: Bool
    public var matchLength: MatchLength
    public var state: MatchState
    public let createdAt: Date
    public var startedAt: Date?
    public var finishedAt: Date?
    public var participants: [MatchParticipant]
    public var winnerID: UUID?

    public init(
        id: UUID = UUID(),
        mode: GameMode,
        isRanked: Bool,
        matchLength: MatchLength,
        state: MatchState = .waiting,
        createdAt: Date = .now,
        startedAt: Date? = nil,
        finishedAt: Date? = nil,
        participants: [MatchParticipant] = [],
        winnerID: UUID? = nil
    ) {
        self.id = id
        self.mode = mode
        self.isRanked = isRanked
        self.matchLength = matchLength
        self.state = state
        self.createdAt = createdAt
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.participants = participants
        self.winnerID = winnerID
    }
}

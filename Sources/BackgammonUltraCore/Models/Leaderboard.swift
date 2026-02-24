import Foundation

public struct Season: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var startsAt: Date
    public var endsAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        startsAt: Date,
        endsAt: Date
    ) {
        self.id = id
        self.name = name
        self.startsAt = startsAt
        self.endsAt = endsAt
    }
}

public struct SeasonLeaderboardEntry: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public var seasonID: UUID
    public var playerID: UUID
    public var rank: Int
    public var rating: Int
    public var wins: Int
    public var losses: Int

    public init(
        id: UUID = UUID(),
        seasonID: UUID,
        playerID: UUID,
        rank: Int,
        rating: Int,
        wins: Int,
        losses: Int
    ) {
        self.id = id
        self.seasonID = seasonID
        self.playerID = playerID
        self.rank = rank
        self.rating = rating
        self.wins = wins
        self.losses = losses
    }
}

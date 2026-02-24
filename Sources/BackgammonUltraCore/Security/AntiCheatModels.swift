import Foundation

public enum FairPlayFlagType: String, Codable, Sendable {
    case impossibleMove
    case suspiciousResignPattern
    case collusionPattern
    case abnormalLatency
}

public struct FairPlayFlag: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public var userID: UUID
    public var matchID: UUID
    public var type: FairPlayFlagType
    public var score: Double
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        userID: UUID,
        matchID: UUID,
        type: FairPlayFlagType,
        score: Double,
        createdAt: Date = .now
    ) {
        self.id = id
        self.userID = userID
        self.matchID = matchID
        self.type = type
        self.score = score
        self.createdAt = createdAt
    }
}

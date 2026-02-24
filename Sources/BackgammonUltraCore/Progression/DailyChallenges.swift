import Foundation

public enum DailyChallengeType: String, Codable, CaseIterable, Sendable {
    case winMatches
    case playRanked
    case useDoublingCube
    case bearOffCheckers
}

public struct DailyChallenge: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public var type: DailyChallengeType
    public var targetCount: Int
    public var rewardXP: Int
    public var date: Date

    public init(
        id: UUID = UUID(),
        type: DailyChallengeType,
        targetCount: Int,
        rewardXP: Int,
        date: Date
    ) {
        self.id = id
        self.type = type
        self.targetCount = targetCount
        self.rewardXP = rewardXP
        self.date = date
    }
}

public struct DailyChallengeProgress: Codable, Hashable, Sendable {
    public var challengeID: UUID
    public var currentCount: Int
    public var isCompleted: Bool

    public init(challengeID: UUID, currentCount: Int = 0, isCompleted: Bool = false) {
        self.challengeID = challengeID
        self.currentCount = currentCount
        self.isCompleted = isCompleted
    }
}

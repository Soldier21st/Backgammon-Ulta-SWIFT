import Foundation

public enum AchievementID: String, Codable, CaseIterable, Sendable {
    case winStreak10
    case matchesPlayed100
    case firstRankedWin
    case dailyChallengeMaster
}

public struct AchievementDefinition: Codable, Hashable, Sendable {
    public let id: AchievementID
    public let title: String
    public let detail: String

    public init(id: AchievementID, title: String, detail: String) {
        self.id = id
        self.title = title
        self.detail = detail
    }
}

public struct PlayerAggregateStats: Codable, Hashable, Sendable {
    public var currentWinStreak: Int
    public var totalMatchesPlayed: Int
    public var rankedWins: Int
    public var dailyChallengesCompleted: Int

    public init(
        currentWinStreak: Int = 0,
        totalMatchesPlayed: Int = 0,
        rankedWins: Int = 0,
        dailyChallengesCompleted: Int = 0
    ) {
        self.currentWinStreak = currentWinStreak
        self.totalMatchesPlayed = totalMatchesPlayed
        self.rankedWins = rankedWins
        self.dailyChallengesCompleted = dailyChallengesCompleted
    }
}

public struct AchievementProgressEngine: Sendable {
    public static let definitions: [AchievementDefinition] = [
        .init(
            id: .winStreak10,
            title: "Hot Streak",
            detail: "Win 10 games in a row."
        ),
        .init(
            id: .matchesPlayed100,
            title: "Grinder",
            detail: "Play 100 matches."
        ),
        .init(
            id: .firstRankedWin,
            title: "First Blood",
            detail: "Win your first ranked match."
        ),
        .init(
            id: .dailyChallengeMaster,
            title: "Challenge Master",
            detail: "Complete 25 daily challenges."
        )
    ]

    public init() {}

    public func unlockedAchievements(for stats: PlayerAggregateStats) -> Set<AchievementID> {
        var unlocked = Set<AchievementID>()

        if stats.currentWinStreak >= 10 {
            unlocked.insert(.winStreak10)
        }
        if stats.totalMatchesPlayed >= 100 {
            unlocked.insert(.matchesPlayed100)
        }
        if stats.rankedWins >= 1 {
            unlocked.insert(.firstRankedWin)
        }
        if stats.dailyChallengesCompleted >= 25 {
            unlocked.insert(.dailyChallengeMaster)
        }

        return unlocked
    }
}

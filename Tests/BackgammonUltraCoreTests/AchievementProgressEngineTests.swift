import XCTest
@testable import BackgammonUltraCore

final class AchievementProgressEngineTests: XCTestCase {
    func testUnlocksExpectedAchievements() {
        let engine = AchievementProgressEngine()
        let stats = PlayerAggregateStats(
            currentWinStreak: 11,
            totalMatchesPlayed: 102,
            rankedWins: 3,
            dailyChallengesCompleted: 28
        )

        let unlocked = engine.unlockedAchievements(for: stats)

        XCTAssertTrue(unlocked.contains(.winStreak10))
        XCTAssertTrue(unlocked.contains(.matchesPlayed100))
        XCTAssertTrue(unlocked.contains(.firstRankedWin))
        XCTAssertTrue(unlocked.contains(.dailyChallengeMaster))
    }

    func testNoUnlocksForFreshAccount() {
        let engine = AchievementProgressEngine()
        let unlocked = engine.unlockedAchievements(for: .init())
        XCTAssertTrue(unlocked.isEmpty)
    }
}

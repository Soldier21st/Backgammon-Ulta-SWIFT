import XCTest
import BackgammonUltraCore
@testable import BackgammonUltraGameEngine

final class BackgammonBotTests: XCTestCase {
    func testChampionIsConfiguredWithLowerRandomnessThanBeginner() {
        let beginner = AIDifficultyProfile.profile(for: .beginner)
        let champion = AIDifficultyProfile.profile(for: .champion)

        XCTAssertLessThan(champion.randomness, beginner.randomness)
    }

    func testBotPrefersImmediateHitAtLowRandomness() {
        var points = Dictionary(uniqueKeysWithValues: (1...24).map { ($0, PointOccupancy()) })
        points[8] = PointOccupancy(color: .white, count: 1)
        points[10] = PointOccupancy(color: .white, count: 1)
        points[5] = PointOccupancy(color: .black, count: 1) // blot to hit

        let board = BoardState(points: points)

        var bot = BackgammonBot(level: .champion)
        bot.profile.randomness = 0.0
        let moves = bot.chooseTurn(for: .white, board: board, diceValues: [3])

        XCTAssertEqual(moves.count, 1)
        XCTAssertEqual(moves.first?.fromPoint, 8)
        XCTAssertEqual(moves.first?.toPoint, 5)
    }

    func testNoDiceProducesNoMoves() {
        let board = BoardState()
        let bot = BackgammonBot(level: .advanced)
        let moves = bot.chooseTurn(for: .white, board: board, diceValues: [])
        XCTAssertTrue(moves.isEmpty)
    }
}

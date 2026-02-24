import XCTest
@testable import BackgammonUltraCore

final class EloCalculatorTests: XCTestCase {
    func testWinnerGainsAndLoserLosesRating() {
        let calculator = EloCalculator()
        let playerA = RankedPlayerContext(rating: 1500, rankedMatchesPlayed: 120)
        let playerB = RankedPlayerContext(rating: 1500, rankedMatchesPlayed: 120)

        let result = calculator.updateRatings(
            playerA: playerA,
            playerB: playerB,
            playerAWon: true,
            matchLength: .five
        )

        XCTAssertGreaterThan(result.playerADelta, 0)
        XCTAssertLessThan(result.playerBDelta, 0)
        XCTAssertEqual(result.playerARatingAfter, 1500 + result.playerADelta)
        XCTAssertEqual(result.playerBRatingAfter, 1500 + result.playerBDelta)
    }

    func testLongerMatchLengthHasHigherImpact() {
        let calculator = EloCalculator()
        let playerA = RankedPlayerContext(rating: 1700, rankedMatchesPlayed: 120)
        let playerB = RankedPlayerContext(rating: 1700, rankedMatchesPlayed: 120)

        let shortMatch = calculator.updateRatings(
            playerA: playerA,
            playerB: playerB,
            playerAWon: true,
            matchLength: .one
        )
        let longMatch = calculator.updateRatings(
            playerA: playerA,
            playerB: playerB,
            playerAWon: true,
            matchLength: .eleven
        )

        XCTAssertGreaterThan(abs(longMatch.playerADelta), abs(shortMatch.playerADelta))
    }

    func testSeasonSoftResetMovesTowardAnchor() {
        let calculator = EloCalculator()
        let reset = calculator.seasonSoftReset(currentRating: 2000)
        XCTAssertLessThan(reset, 2000)
        XCTAssertGreaterThan(reset, 1500)
    }
}

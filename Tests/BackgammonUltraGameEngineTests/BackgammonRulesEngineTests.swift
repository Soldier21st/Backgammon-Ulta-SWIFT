import XCTest
@testable import BackgammonUltraGameEngine

final class BackgammonRulesEngineTests: XCTestCase {
    private let engine = BackgammonRulesEngine()

    func testLegalTurnCandidatesUseHigherDieWhenSingleMoveIsPossible() {
        var points = emptyPoints()
        points[7] = PointOccupancy(color: .white, count: 1)
        points[24] = PointOccupancy(color: .white, count: 1)
        points[23] = PointOccupancy(color: .black, count: 2)
        points[18] = PointOccupancy(color: .black, count: 2)

        let board = BoardState(points: points)
        let candidates = engine.legalTurnCandidates(for: [1, 6], color: .white, board: board)

        XCTAssertFalse(candidates.isEmpty)
        XCTAssertTrue(candidates.allSatisfy { $0.moves.count == 1 })
        XCTAssertTrue(candidates.allSatisfy { $0.moves.first?.dieValue == 6 })
    }

    func testLegalTurnCandidatesUseMaximumMovesWhenAvailable() {
        let board = BoardState()
        let roll = DiceRoll(first: 3, second: 1)
        let candidates = engine.legalTurnCandidates(for: roll, color: .white, board: board)

        XCTAssertFalse(candidates.isEmpty)
        XCTAssertTrue(candidates.allSatisfy { $0.moves.count == 2 })
    }

    func testBarEntryUsesNilOrigin() {
        var points = emptyPoints()
        points[24] = PointOccupancy(color: .black, count: 2)
        points[23] = PointOccupancy(color: .black, count: 1)

        let board = BoardState(
            points: points,
            barWhite: 1
        )

        let dieOneMoves = engine.legalMoves(for: 1, color: .white, board: board)
        let dieTwoMoves = engine.legalMoves(for: 2, color: .white, board: board)

        XCTAssertTrue(dieOneMoves.isEmpty)
        XCTAssertEqual(dieTwoMoves.count, 1)
        XCTAssertEqual(dieTwoMoves.first?.fromPoint, nil)
        XCTAssertEqual(dieTwoMoves.first?.toPoint, 23)
    }

    func testWhiteExactBearOffAllowed() {
        var points = emptyPoints()
        points[4] = PointOccupancy(color: .white, count: 1)

        let board = BoardState(points: points)
        let destinations = engine.legalDestinations(fromPoint: 4, dieValue: 4, color: .white, board: board)

        XCTAssertEqual(destinations, [nil])
    }

    func testWhiteOvershootBearOffAllowedWithoutHigherChecker() {
        var points = emptyPoints()
        points[4] = PointOccupancy(color: .white, count: 1)

        let board = BoardState(points: points)
        let destinations = engine.legalDestinations(fromPoint: 4, dieValue: 6, color: .white, board: board)

        XCTAssertEqual(destinations, [nil])
    }

    func testWhiteOvershootBearOffBlockedWhenHigherCheckerExists() {
        var points = emptyPoints()
        points[4] = PointOccupancy(color: .white, count: 1)
        points[6] = PointOccupancy(color: .white, count: 1)

        let board = BoardState(points: points)
        let destinations = engine.legalDestinations(fromPoint: 4, dieValue: 6, color: .white, board: board)

        XCTAssertTrue(destinations.isEmpty)
    }

    func testBlackExactBearOffAllowed() {
        var points = emptyPoints()
        points[22] = PointOccupancy(color: .black, count: 1)

        let board = BoardState(points: points)
        let destinations = engine.legalDestinations(fromPoint: 22, dieValue: 3, color: .black, board: board)

        XCTAssertEqual(destinations, [nil])
    }

    func testBlackOvershootBearOffAllowedWithoutLowerChecker() {
        var points = emptyPoints()
        points[22] = PointOccupancy(color: .black, count: 1)

        let board = BoardState(points: points)
        let destinations = engine.legalDestinations(fromPoint: 22, dieValue: 6, color: .black, board: board)

        XCTAssertEqual(destinations, [nil])
    }

    func testBlackOvershootBearOffBlockedWhenLowerCheckerExists() {
        var points = emptyPoints()
        points[22] = PointOccupancy(color: .black, count: 1)
        points[19] = PointOccupancy(color: .black, count: 1)

        let board = BoardState(points: points)
        let destinations = engine.legalDestinations(fromPoint: 22, dieValue: 6, color: .black, board: board)

        XCTAssertTrue(destinations.isEmpty)
    }

    func testCheckerOnBarMustEnterBeforeBearingOff() {
        var points = emptyPoints()
        points[2] = PointOccupancy(color: .white, count: 1)

        let board = BoardState(
            points: points,
            barWhite: 1
        )
        let destinations = engine.legalDestinations(fromPoint: 2, dieValue: 2, color: .white, board: board)

        XCTAssertTrue(destinations.isEmpty)
    }

    private func emptyPoints() -> [Int: PointOccupancy] {
        Dictionary(uniqueKeysWithValues: (1...24).map { ($0, PointOccupancy()) })
    }
}

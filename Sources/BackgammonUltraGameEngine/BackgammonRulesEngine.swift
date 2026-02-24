import Foundation
import BackgammonUltraCore

public enum RulesEngineError: Error, Sendable {
    case invalidOrigin
    case illegalDestination
    case blockedDestination
    case noCheckerAtOrigin
    case invalidDieValue
}

public struct BackgammonRulesEngine: Sendable {
    public init() {}

    public func legalDestinations(
        fromPoint: Int?,
        dieValue: Int,
        color: CheckerColor,
        board: BoardState
    ) -> [Int?] {
        guard (1...6).contains(dieValue) else {
            return []
        }

        // If checker on the bar, player must enter from bar.
        if hasCheckerOnBar(for: color, board: board), fromPoint != nil {
            return []
        }

        if let fromPoint {
            guard checkerCount(at: fromPoint, color: color, board: board) > 0 else {
                return []
            }
        }

        let target = targetPoint(fromPoint: fromPoint, dieValue: dieValue, color: color)
        guard let point = target else {
            guard let fromPoint else {
                return []
            }
            guard canBearOff(color: color, board: board) else {
                return []
            }
            guard canBearOffUsingDie(
                fromPoint: fromPoint,
                dieValue: dieValue,
                color: color,
                board: board
            ) else {
                return []
            }
            return [nil]
        }

        guard (1...24).contains(point) else {
            return []
        }

        return isDestinationOpen(point, for: color, board: board) ? [point] : []
    }

    public func applyMove(
        _ move: MoveIntent,
        color: CheckerColor,
        to board: BoardState
    ) throws -> BoardState {
        guard (1...6).contains(move.dieValue) else {
            throw RulesEngineError.invalidDieValue
        }

        let legalTargets = legalDestinations(
            fromPoint: move.fromPoint,
            dieValue: move.dieValue,
            color: color,
            board: board
        )
        guard legalTargets.contains(move.toPoint) else {
            throw RulesEngineError.illegalDestination
        }

        var updated = board
        try removeChecker(color: color, from: move.fromPoint, board: &updated)
        try placeChecker(color: color, at: move.toPoint, board: &updated)
        return updated
    }

    public func legalMoves(
        for dieValue: Int,
        color: CheckerColor,
        board: BoardState
    ) -> [MoveIntent] {
        let origins: [Int?]
        if hasCheckerOnBar(for: color, board: board) {
            origins = [nil]
        } else {
            let sortedPoints: [Int]
            if color == .white {
                sortedPoints = Array((1...24).reversed())
            } else {
                sortedPoints = Array(1...24)
            }
            origins = sortedPoints.filter { checkerCount(at: $0, color: color, board: board) > 0 }
        }

        var moves: [MoveIntent] = []
        for origin in origins {
            let destinations = legalDestinations(
                fromPoint: origin,
                dieValue: dieValue,
                color: color,
                board: board
            )
            for destination in destinations {
                moves.append(
                    MoveIntent(
                        fromPoint: origin,
                        toPoint: destination,
                        dieValue: dieValue
                    )
                )
            }
        }

        return moves
    }

    public func legalTurnCandidates(
        for roll: DiceRoll,
        color: CheckerColor,
        board: BoardState
    ) -> [TurnCandidate] {
        legalTurnCandidates(
            for: roll.values,
            color: color,
            board: board
        )
    }

    public func legalTurnCandidates(
        for diceValues: [Int],
        color: CheckerColor,
        board: BoardState
    ) -> [TurnCandidate] {
        let normalizedDice = diceValues.filter { (1...6).contains($0) }
        guard !normalizedDice.isEmpty else {
            return [TurnCandidate(moves: [], resultingBoard: board)]
        }

        let orders = uniqueDiceOrders(for: normalizedDice)
        var candidates: [TurnCandidate] = []
        for order in orders {
            candidates.append(
                contentsOf: exploreTurnCandidates(
                    board: board,
                    color: color,
                    diceValues: order,
                    dieIndex: 0,
                    accumulatedMoves: []
                )
            )
        }

        guard !candidates.isEmpty else {
            return [TurnCandidate(moves: [], resultingBoard: board)]
        }

        let maxMoveCount = candidates.map { $0.moves.count }.max() ?? 0
        var filtered = candidates.filter { $0.moves.count == maxMoveCount }

        // Backgammon rule: when only one die can be played from a non-double roll,
        // the higher die must be used if possible.
        if maxMoveCount == 1,
           Set(normalizedDice).count == 2,
           let highestDie = normalizedDice.max() {
            let highestDieCandidates = filtered.filter { $0.moves.first?.dieValue == highestDie }
            if !highestDieCandidates.isEmpty {
                filtered = highestDieCandidates
            }
        }

        return Array(Set(filtered))
    }

    private func hasCheckerOnBar(for color: CheckerColor, board: BoardState) -> Bool {
        switch color {
        case .white:
            return board.barWhite > 0
        case .black:
            return board.barBlack > 0
        }
    }

    private func checkerCount(at point: Int, color: CheckerColor, board: BoardState) -> Int {
        guard let occupancy = board.points[point], occupancy.color == color else {
            return 0
        }
        return occupancy.count
    }

    private func targetPoint(fromPoint: Int?, dieValue: Int, color: CheckerColor) -> Int? {
        if let fromPoint {
            switch color {
            case .white:
                let target = fromPoint - dieValue
                return target >= 1 ? target : nil
            case .black:
                let target = fromPoint + dieValue
                return target <= 24 ? target : nil
            }
        }

        // Entering from bar:
        switch color {
        case .white:
            return 25 - dieValue
        case .black:
            return dieValue
        }
    }

    private func uniqueDiceOrders(for diceValues: [Int]) -> [[Int]] {
        if diceValues.count <= 1 || Set(diceValues).count == 1 {
            return [diceValues]
        }

        if diceValues.count == 2 {
            return [[diceValues[0], diceValues[1]], [diceValues[1], diceValues[0]]]
        }

        return [diceValues]
    }

    private func exploreTurnCandidates(
        board: BoardState,
        color: CheckerColor,
        diceValues: [Int],
        dieIndex: Int,
        accumulatedMoves: [MoveIntent]
    ) -> [TurnCandidate] {
        if dieIndex >= diceValues.count {
            return [TurnCandidate(moves: accumulatedMoves, resultingBoard: board)]
        }

        let dieValue = diceValues[dieIndex]
        let legal = legalMoves(for: dieValue, color: color, board: board)

        if legal.isEmpty {
            return exploreTurnCandidates(
                board: board,
                color: color,
                diceValues: diceValues,
                dieIndex: dieIndex + 1,
                accumulatedMoves: accumulatedMoves
            )
        }

        var results: [TurnCandidate] = []
        for move in legal {
            guard let updated = try? applyMove(move, color: color, to: board) else {
                continue
            }
            results.append(
                contentsOf: exploreTurnCandidates(
                    board: updated,
                    color: color,
                    diceValues: diceValues,
                    dieIndex: dieIndex + 1,
                    accumulatedMoves: accumulatedMoves + [move]
                )
            )
        }
        return results
    }

    private func canBearOff(color: CheckerColor, board: BoardState) -> Bool {
        let homeRange: ClosedRange<Int> = color == .white ? 1...6 : 19...24
        let outsideHome = (1...24).contains { index in
            guard !homeRange.contains(index),
                  let occupancy = board.points[index],
                  occupancy.color == color else {
                return false
            }
            return occupancy.count > 0
        }
        return !outsideHome && !hasCheckerOnBar(for: color, board: board)
    }

    private func canBearOffUsingDie(
        fromPoint: Int,
        dieValue: Int,
        color: CheckerColor,
        board: BoardState
    ) -> Bool {
        let exactDistance: Int
        switch color {
        case .white:
            exactDistance = fromPoint
        case .black:
            exactDistance = 25 - fromPoint
        }

        if dieValue == exactDistance {
            return true
        }

        guard dieValue > exactDistance else {
            return false
        }

        // Overshoot is legal only if there is no checker farther from the bear-off tray.
        switch color {
        case .white:
            guard fromPoint < 6 else { return true }
            return !(fromPoint + 1...6).contains { point in
                checkerCount(at: point, color: color, board: board) > 0
            }
        case .black:
            guard fromPoint > 19 else { return true }
            return !(19..<fromPoint).contains { point in
                checkerCount(at: point, color: color, board: board) > 0
            }
        }
    }

    private func isDestinationOpen(_ point: Int, for color: CheckerColor, board: BoardState) -> Bool {
        guard let occupancy = board.points[point] else {
            return false
        }
        if occupancy.count == 0 || occupancy.color == color {
            return true
        }
        return occupancy.count == 1
    }

    private func removeChecker(color: CheckerColor, from point: Int?, board: inout BoardState) throws {
        if let point {
            guard var occupancy = board.points[point],
                  occupancy.color == color,
                  occupancy.count > 0 else {
                throw RulesEngineError.noCheckerAtOrigin
            }
            occupancy.count -= 1
            if occupancy.count == 0 {
                occupancy.color = nil
            }
            board.points[point] = occupancy
            return
        }

        switch color {
        case .white:
            guard board.barWhite > 0 else { throw RulesEngineError.noCheckerAtOrigin }
            board.barWhite -= 1
        case .black:
            guard board.barBlack > 0 else { throw RulesEngineError.noCheckerAtOrigin }
            board.barBlack -= 1
        }
    }

    private func placeChecker(color: CheckerColor, at point: Int?, board: inout BoardState) throws {
        guard let point else {
            switch color {
            case .white:
                board.borneOffWhite += 1
            case .black:
                board.borneOffBlack += 1
            }
            return
        }

        guard var occupancy = board.points[point] else {
            throw RulesEngineError.illegalDestination
        }

        if occupancy.count == 0 {
            occupancy.color = color
            occupancy.count = 1
            board.points[point] = occupancy
            return
        }

        if occupancy.color == color {
            occupancy.count += 1
            board.points[point] = occupancy
            return
        }

        if occupancy.count == 1 {
            // Hit blot.
            if occupancy.color == .white {
                board.barWhite += 1
            } else {
                board.barBlack += 1
            }
            occupancy.color = color
            occupancy.count = 1
            board.points[point] = occupancy
            return
        }

        throw RulesEngineError.blockedDestination
    }
}

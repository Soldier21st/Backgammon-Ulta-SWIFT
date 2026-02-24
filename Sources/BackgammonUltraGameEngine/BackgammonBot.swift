import Foundation
import BackgammonUltraCore

public struct AIDifficultyProfile: Sendable {
    public var level: AILevel
    public var randomness: Double
    public var pipWeight: Double
    public var bearOffWeight: Double
    public var hitWeight: Double
    public var primeWeight: Double
    public var safetyWeight: Double

    public init(
        level: AILevel,
        randomness: Double,
        pipWeight: Double,
        bearOffWeight: Double,
        hitWeight: Double,
        primeWeight: Double,
        safetyWeight: Double
    ) {
        self.level = level
        self.randomness = randomness
        self.pipWeight = pipWeight
        self.bearOffWeight = bearOffWeight
        self.hitWeight = hitWeight
        self.primeWeight = primeWeight
        self.safetyWeight = safetyWeight
    }

    public static func profile(for level: AILevel) -> AIDifficultyProfile {
        switch level {
        case .beginner:
            return .init(level: level, randomness: 0.85, pipWeight: 0.35, bearOffWeight: 0.7, hitWeight: 0.7, primeWeight: 0.4, safetyWeight: 0.4)
        case .novice:
            return .init(level: level, randomness: 0.72, pipWeight: 0.45, bearOffWeight: 0.8, hitWeight: 0.8, primeWeight: 0.5, safetyWeight: 0.5)
        case .casual:
            return .init(level: level, randomness: 0.60, pipWeight: 0.55, bearOffWeight: 0.9, hitWeight: 0.9, primeWeight: 0.6, safetyWeight: 0.6)
        case .intermediate:
            return .init(level: level, randomness: 0.45, pipWeight: 0.7, bearOffWeight: 1.0, hitWeight: 1.0, primeWeight: 0.75, safetyWeight: 0.75)
        case .advanced:
            return .init(level: level, randomness: 0.33, pipWeight: 0.8, bearOffWeight: 1.05, hitWeight: 1.1, primeWeight: 0.9, safetyWeight: 0.9)
        case .expert:
            return .init(level: level, randomness: 0.25, pipWeight: 0.95, bearOffWeight: 1.15, hitWeight: 1.2, primeWeight: 1.0, safetyWeight: 1.05)
        case .master:
            return .init(level: level, randomness: 0.17, pipWeight: 1.0, bearOffWeight: 1.2, hitWeight: 1.3, primeWeight: 1.1, safetyWeight: 1.15)
        case .grandmaster:
            return .init(level: level, randomness: 0.11, pipWeight: 1.1, bearOffWeight: 1.3, hitWeight: 1.35, primeWeight: 1.2, safetyWeight: 1.2)
        case .elite:
            return .init(level: level, randomness: 0.07, pipWeight: 1.2, bearOffWeight: 1.4, hitWeight: 1.45, primeWeight: 1.25, safetyWeight: 1.3)
        case .champion:
            return .init(level: level, randomness: 0.03, pipWeight: 1.35, bearOffWeight: 1.5, hitWeight: 1.55, primeWeight: 1.35, safetyWeight: 1.4)
        }
    }
}

public struct BackgammonBot: Sendable {
    public var profile: AIDifficultyProfile
    public var rulesEngine: BackgammonRulesEngine

    public init(
        level: AILevel,
        rulesEngine: BackgammonRulesEngine = .init()
    ) {
        self.profile = AIDifficultyProfile.profile(for: level)
        self.rulesEngine = rulesEngine
    }

    public mutating func setLevel(_ level: AILevel) {
        profile = AIDifficultyProfile.profile(for: level)
    }

    public func chooseTurn(
        for color: CheckerColor,
        board: BoardState,
        roll: DiceRoll
    ) -> [MoveIntent] {
        chooseTurn(for: color, board: board, diceValues: roll.values)
    }

    public func chooseTurn(
        for color: CheckerColor,
        board: BoardState,
        diceValues: [Int]
    ) -> [MoveIntent] {
        let candidates = rulesEngine.legalTurnCandidates(for: diceValues, color: color, board: board)
        guard !candidates.isEmpty else {
            return []
        }

        let scored = candidates
            .map { candidate in
                (
                    candidate: candidate,
                    score: evaluateCandidate(
                        candidate,
                        previousBoard: board,
                        color: color
                    )
                )
            }
            .sorted { $0.score > $1.score }

        guard scored.count > 1 else {
            return scored[0].candidate.moves
        }

        let randomRoll = Double.random(in: 0...1)
        if randomRoll >= profile.randomness {
            return scored[0].candidate.moves
        }

        let topPoolCount = max(2, min(scored.count, 2 + Int(profile.randomness * 6)))
        let choiceIndex = Int.random(in: 0..<topPoolCount)
        return scored[choiceIndex].candidate.moves
    }

    private func evaluateCandidate(
        _ candidate: TurnCandidate,
        previousBoard: BoardState,
        color: CheckerColor
    ) -> Double {
        let resultingBoard = candidate.resultingBoard
        let opponent = color.opponent

        let pipAdvantage = Double(resultingBoard.pipCount(for: opponent) - resultingBoard.pipCount(for: color))
        let bearOffAdvantage = Double(resultingBoard.borneOffCount(for: color) - resultingBoard.borneOffCount(for: opponent))
        let barAdvantage = Double(resultingBoard.barCount(for: opponent) - resultingBoard.barCount(for: color))
        let madePointAdvantage = Double(resultingBoard.madePointCount(for: color) - resultingBoard.madePointCount(for: opponent))
        let blotPenalty = Double(resultingBoard.blotCount(for: color))

        let hitDelta = Double(resultingBoard.barCount(for: opponent) - previousBoard.barCount(for: opponent))

        return (pipAdvantage * profile.pipWeight * 0.12)
            + (bearOffAdvantage * profile.bearOffWeight * 10.0)
            + (barAdvantage * profile.hitWeight * 6.0)
            + (madePointAdvantage * profile.primeWeight * 2.5)
            - (blotPenalty * profile.safetyWeight * 2.8)
            + (hitDelta * profile.hitWeight * 5.0)
    }
}

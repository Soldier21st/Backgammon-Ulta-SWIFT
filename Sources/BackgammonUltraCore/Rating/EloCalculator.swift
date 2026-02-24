import Foundation

public struct EloConfiguration: Sendable {
    public var provisionalK: Double
    public var establishedK: Double
    public var eliteK: Double
    public var provisionalMatchThreshold: Int
    public var eliteRatingThreshold: Int
    public var scale: Double

    public init(
        provisionalK: Double = 40,
        establishedK: Double = 24,
        eliteK: Double = 16,
        provisionalMatchThreshold: Int = 30,
        eliteRatingThreshold: Int = 2200,
        scale: Double = 400
    ) {
        self.provisionalK = provisionalK
        self.establishedK = establishedK
        self.eliteK = eliteK
        self.provisionalMatchThreshold = provisionalMatchThreshold
        self.eliteRatingThreshold = eliteRatingThreshold
        self.scale = scale
    }
}

public struct RankedPlayerContext: Hashable, Sendable {
    public var rating: Int
    public var rankedMatchesPlayed: Int

    public init(rating: Int, rankedMatchesPlayed: Int) {
        self.rating = rating
        self.rankedMatchesPlayed = rankedMatchesPlayed
    }
}

public struct EloMatchResult: Hashable, Sendable {
    public var playerARatingAfter: Int
    public var playerBRatingAfter: Int
    public var playerADelta: Int
    public var playerBDelta: Int

    public init(
        playerARatingAfter: Int,
        playerBRatingAfter: Int,
        playerADelta: Int,
        playerBDelta: Int
    ) {
        self.playerARatingAfter = playerARatingAfter
        self.playerBRatingAfter = playerBRatingAfter
        self.playerADelta = playerADelta
        self.playerBDelta = playerBDelta
    }
}

public struct EloCalculator: Sendable {
    public var configuration: EloConfiguration

    public init(configuration: EloConfiguration = .init()) {
        self.configuration = configuration
    }

    public func expectedScore(playerRating: Int, opponentRating: Int) -> Double {
        let exponent = Double(opponentRating - playerRating) / configuration.scale
        return 1.0 / (1.0 + pow(10.0, exponent))
    }

    public func matchLengthMultiplier(_ length: MatchLength) -> Double {
        switch length {
        case .one:
            return 0.75
        case .three:
            return 0.9
        case .five:
            return 1.0
        case .seven:
            return 1.1
        case .eleven:
            return 1.2
        }
    }

    public func effectiveK(for player: RankedPlayerContext, matchLength: MatchLength) -> Double {
        let baseK: Double
        if player.rankedMatchesPlayed < configuration.provisionalMatchThreshold {
            baseK = configuration.provisionalK
        } else if player.rating >= configuration.eliteRatingThreshold {
            baseK = configuration.eliteK
        } else {
            baseK = configuration.establishedK
        }
        return baseK * matchLengthMultiplier(matchLength)
    }

    public func updateRatings(
        playerA: RankedPlayerContext,
        playerB: RankedPlayerContext,
        playerAWon: Bool,
        matchLength: MatchLength
    ) -> EloMatchResult {
        let scoreA = playerAWon ? 1.0 : 0.0
        let scoreB = playerAWon ? 0.0 : 1.0
        let expectedA = expectedScore(playerRating: playerA.rating, opponentRating: playerB.rating)
        let expectedB = expectedScore(playerRating: playerB.rating, opponentRating: playerA.rating)
        let kA = effectiveK(for: playerA, matchLength: matchLength)
        let kB = effectiveK(for: playerB, matchLength: matchLength)

        let deltaA = Int((kA * (scoreA - expectedA)).rounded())
        let deltaB = Int((kB * (scoreB - expectedB)).rounded())

        return EloMatchResult(
            playerARatingAfter: playerA.rating + deltaA,
            playerBRatingAfter: playerB.rating + deltaB,
            playerADelta: deltaA,
            playerBDelta: deltaB
        )
    }

    public func seasonSoftReset(currentRating: Int, baseRating: Int = 1500, carryFactor: Double = 0.75) -> Int {
        let shifted = Double(currentRating - baseRating) * carryFactor
        return baseRating + Int(shifted.rounded())
    }
}

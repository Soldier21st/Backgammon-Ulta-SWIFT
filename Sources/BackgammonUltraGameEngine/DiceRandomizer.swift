import Foundation

public protocol DiceRolling: Sendable {
    mutating func roll() -> DiceRoll
}

public struct SecureDiceRandomizer: DiceRolling {
    private var generator: SystemRandomNumberGenerator

    public init(generator: SystemRandomNumberGenerator = .init()) {
        self.generator = generator
    }

    public mutating func roll() -> DiceRoll {
        DiceRoll(
            first: Int.random(in: 1...6, using: &generator),
            second: Int.random(in: 1...6, using: &generator)
        )
    }
}

public struct SeededDiceRandomizer: DiceRolling {
    private var generator: LinearCongruentialGenerator

    public init(seed: UInt64) {
        self.generator = LinearCongruentialGenerator(seed: seed)
    }

    public mutating func roll() -> DiceRoll {
        DiceRoll(
            first: Int.random(in: 1...6, using: &generator),
            second: Int.random(in: 1...6, using: &generator)
        )
    }
}

public struct LinearCongruentialGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        self.state = seed == 0 ? 0xDEADBEEF : seed
    }

    public mutating func next() -> UInt64 {
        state = 6364136223846793005 &* state &+ 1
        return state
    }
}

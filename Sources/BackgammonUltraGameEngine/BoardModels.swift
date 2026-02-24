import Foundation
import BackgammonUltraCore

public enum CheckerColor: String, Codable, Sendable {
    case white
    case black

    public var opponent: CheckerColor {
        switch self {
        case .white:
            return .black
        case .black:
            return .white
        }
    }
}

public struct PointOccupancy: Codable, Hashable, Sendable {
    public var color: CheckerColor?
    public var count: Int

    public init(color: CheckerColor? = nil, count: Int = 0) {
        self.color = count > 0 ? color : nil
        self.count = max(0, count)
    }
}

public struct DiceRoll: Codable, Hashable, Sendable {
    public let first: Int
    public let second: Int

    public init(first: Int, second: Int) {
        precondition((1...6).contains(first))
        precondition((1...6).contains(second))
        self.first = first
        self.second = second
    }

    public var values: [Int] {
        if first == second {
            return [first, first, first, first]
        }
        return [first, second]
    }
}

public struct MoveIntent: Codable, Hashable, Sendable {
    public let fromPoint: Int?
    public let toPoint: Int?
    public let dieValue: Int

    public init(fromPoint: Int?, toPoint: Int?, dieValue: Int) {
        self.fromPoint = fromPoint
        self.toPoint = toPoint
        self.dieValue = dieValue
    }
}

public struct BoardState: Codable, Hashable, Sendable {
    public var points: [Int: PointOccupancy]
    public var barWhite: Int
    public var barBlack: Int
    public var borneOffWhite: Int
    public var borneOffBlack: Int
    public var doublingCubeValue: Int
    public var cubeOwner: CheckerColor?

    public init(
        points: [Int: PointOccupancy] = BoardState.defaultStartingPoints(),
        barWhite: Int = 0,
        barBlack: Int = 0,
        borneOffWhite: Int = 0,
        borneOffBlack: Int = 0,
        doublingCubeValue: Int = 1,
        cubeOwner: CheckerColor? = nil
    ) {
        self.points = points
        self.barWhite = barWhite
        self.barBlack = barBlack
        self.borneOffWhite = borneOffWhite
        self.borneOffBlack = borneOffBlack
        self.doublingCubeValue = doublingCubeValue
        self.cubeOwner = cubeOwner
    }

    public static func defaultStartingPoints() -> [Int: PointOccupancy] {
        var points = Dictionary(uniqueKeysWithValues: (1...24).map { ($0, PointOccupancy()) })

        // White start.
        points[24] = PointOccupancy(color: .white, count: 2)
        points[13] = PointOccupancy(color: .white, count: 5)
        points[8] = PointOccupancy(color: .white, count: 3)
        points[6] = PointOccupancy(color: .white, count: 5)

        // Black start (mirrored).
        points[1] = PointOccupancy(color: .black, count: 2)
        points[12] = PointOccupancy(color: .black, count: 5)
        points[17] = PointOccupancy(color: .black, count: 3)
        points[19] = PointOccupancy(color: .black, count: 5)

        return points
    }
}

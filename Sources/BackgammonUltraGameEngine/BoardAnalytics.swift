import Foundation

public extension BoardState {
    func pipCount(for color: CheckerColor) -> Int {
        let boardPips = (1...24).reduce(into: 0) { partialResult, point in
            guard let occupancy = points[point], occupancy.color == color else {
                return
            }

            let pointDistance: Int
            switch color {
            case .white:
                pointDistance = point
            case .black:
                pointDistance = 25 - point
            }

            partialResult += pointDistance * occupancy.count
        }

        let barPips: Int
        switch color {
        case .white:
            barPips = barWhite * 25
        case .black:
            barPips = barBlack * 25
        }

        return boardPips + barPips
    }

    func barCount(for color: CheckerColor) -> Int {
        switch color {
        case .white:
            return barWhite
        case .black:
            return barBlack
        }
    }

    func borneOffCount(for color: CheckerColor) -> Int {
        switch color {
        case .white:
            return borneOffWhite
        case .black:
            return borneOffBlack
        }
    }

    func blotCount(for color: CheckerColor) -> Int {
        (1...24).reduce(into: 0) { partialResult, point in
            guard let occupancy = points[point], occupancy.color == color else {
                return
            }
            if occupancy.count == 1 {
                partialResult += 1
            }
        }
    }

    func madePointCount(for color: CheckerColor) -> Int {
        (1...24).reduce(into: 0) { partialResult, point in
            guard let occupancy = points[point], occupancy.color == color else {
                return
            }
            if occupancy.count >= 2 {
                partialResult += 1
            }
        }
    }
}

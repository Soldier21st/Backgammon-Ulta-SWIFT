import Foundation

public enum GameMode: String, Codable, CaseIterable, Sendable {
    case solo
    case rankedOnline
    case casualOnline
    case playWithFriends
    case localTwoPlayer
}

public enum AILevel: Int, Codable, CaseIterable, Sendable {
    case beginner = 1
    case novice = 2
    case casual = 3
    case intermediate = 4
    case advanced = 5
    case expert = 6
    case master = 7
    case grandmaster = 8
    case elite = 9
    case champion = 10

    public var title: String {
        switch self {
        case .beginner:
            return "Beginner"
        case .novice:
            return "Novice"
        case .casual:
            return "Casual"
        case .intermediate:
            return "Intermediate"
        case .advanced:
            return "Advanced"
        case .expert:
            return "Expert"
        case .master:
            return "Master"
        case .grandmaster:
            return "Grandmaster"
        case .elite:
            return "Elite"
        case .champion:
            return "Champion"
        }
    }
}

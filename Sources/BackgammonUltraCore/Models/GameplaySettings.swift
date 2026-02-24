import Foundation

public enum BoardOrientation: String, Codable, CaseIterable, Sendable {
    case auto
    case portrait
    case landscape
}

public enum BoardVisualStyle: String, Codable, CaseIterable, Sendable {
    case modern
    case classic
}

public enum MatchLength: Int, Codable, CaseIterable, Sendable {
    case one = 1
    case three = 3
    case five = 5
    case seven = 7
    case eleven = 11
}

public struct GameplaySettings: Codable, Hashable, Sendable {
    public var doublingCubeEnabled: Bool
    public var highlightLegalMoves: Bool
    public var forcedMovesEnabled: Bool
    public var pipsCounterEnabled: Bool
    public var boardOrientation: BoardOrientation
    public var boardVisualStyle: BoardVisualStyle
    public var preferredMatchLength: MatchLength

    public init(
        doublingCubeEnabled: Bool = true,
        highlightLegalMoves: Bool = true,
        forcedMovesEnabled: Bool = true,
        pipsCounterEnabled: Bool = true,
        boardOrientation: BoardOrientation = .auto,
        boardVisualStyle: BoardVisualStyle = .classic,
        preferredMatchLength: MatchLength = .five
    ) {
        self.doublingCubeEnabled = doublingCubeEnabled
        self.highlightLegalMoves = highlightLegalMoves
        self.forcedMovesEnabled = forcedMovesEnabled
        self.pipsCounterEnabled = pipsCounterEnabled
        self.boardOrientation = boardOrientation
        self.boardVisualStyle = boardVisualStyle
        self.preferredMatchLength = preferredMatchLength
    }
}

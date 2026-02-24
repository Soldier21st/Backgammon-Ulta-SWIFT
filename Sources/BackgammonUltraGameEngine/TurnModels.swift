import Foundation

public struct TurnCandidate: Hashable, Sendable {
    public var moves: [MoveIntent]
    public var resultingBoard: BoardState

    public init(moves: [MoveIntent], resultingBoard: BoardState) {
        self.moves = moves
        self.resultingBoard = resultingBoard
    }
}

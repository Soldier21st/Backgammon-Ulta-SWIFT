import Foundation
import Combine
import BackgammonUltraCore
import BackgammonUltraGameEngine
#if canImport(UIKit)
import UIKit
#endif

@MainActor
public final class SoloMatchViewModel: ObservableObject {
    public typealias MatchCompletionHandler = (MatchCompletion) -> Void

    public enum OriginSelection: Hashable, Sendable {
        case point(Int)
        case bar
    }

    public enum VictoryType: String, Sendable {
        case normal
        case gammon
        case backgammon

        public var title: String {
            switch self {
            case .normal:
                return "Normal Win"
            case .gammon:
                return "Gammon"
            case .backgammon:
                return "Backgammon"
            }
        }

        public var basePoints: Int {
            switch self {
            case .normal:
                return 1
            case .gammon:
                return 2
            case .backgammon:
                return 3
            }
        }
    }

    public struct MatchCompletion: Identifiable, Sendable {
        public let id: UUID
        public let winner: CheckerColor
        public let victoryType: VictoryType
        public let cubeMultiplier: Int
        public let pointsAwarded: Int
        public let userPointsDelta: Int
        public let abandoned: Bool
        public let finishedAt: Date

        public init(
            id: UUID = UUID(),
            winner: CheckerColor,
            victoryType: VictoryType,
            cubeMultiplier: Int,
            pointsAwarded: Int,
            userPointsDelta: Int,
            abandoned: Bool = false,
            finishedAt: Date = .now
        ) {
            self.id = id
            self.winner = winner
            self.victoryType = victoryType
            self.cubeMultiplier = max(cubeMultiplier, 1)
            self.pointsAwarded = max(pointsAwarded, 0)
            self.userPointsDelta = userPointsDelta
            self.abandoned = abandoned
            self.finishedAt = finishedAt
        }

        public var title: String {
            if abandoned {
                return "Match Abandoned"
            }
            return winner == .white ? "You win" : "AI wins"
        }

        public var message: String {
            if abandoned {
                return "Match was left and recorded as abandoned."
            }

            let cubeSuffix = cubeMultiplier > 1 ? " (cube x\(cubeMultiplier))" : ""
            let resultLine: String
            if winner == .white {
                resultLine = "\(victoryType.title)\(cubeSuffix)"
            } else {
                resultLine = "AI by \(victoryType.title.lowercased())\(cubeSuffix)"
            }

            let deltaPrefix = userPointsDelta >= 0 ? "+" : ""
            return "\(resultLine)\nPoints change: \(deltaPrefix)\(userPointsDelta)"
        }
    }

    private struct HumanMoveSnapshot {
        let board: BoardState
        let roll: DiceRoll?
        let remainingDice: [Int]
        let selectedOrigin: OriginSelection?
        let legalOrigins: Set<OriginSelection>
        let legalDestinations: Set<Int?>
        let availableFirstMoves: [MoveIntent]
    }

    @Published public private(set) var board: BoardState
    @Published public private(set) var currentTurn: CheckerColor
    @Published public private(set) var roll: DiceRoll?
    @Published public private(set) var remainingDice: [Int]
    @Published public private(set) var selectedOrigin: OriginSelection?
    @Published public private(set) var legalOrigins: Set<OriginSelection>
    @Published public private(set) var legalDestinations: Set<Int?>
    @Published public private(set) var statusText: String
    @Published public private(set) var isMatchFinished: Bool
    @Published public private(set) var canUndoLastMove: Bool
    @Published public private(set) var matchResult: MatchCompletion?
    @Published public private(set) var lastMove: MoveIntent?
    @Published public var aiLevel: AILevel {
        didSet {
            bot.setLevel(aiLevel)
        }
    }

    @Published public var gameplaySettings: GameplaySettings

    private let humanColor: CheckerColor = .white
    private let aiColor: CheckerColor = .black
    private let rulesEngine: BackgammonRulesEngine
    private var diceRandomizer: SecureDiceRandomizer
    private var bot: BackgammonBot
    private var availableFirstMoves: [MoveIntent]
    private var undoStack: [HumanMoveSnapshot]
    private let aiMovePauseNanoseconds: UInt64 = 1_100_000_000
    private let aiTurnStartPauseNanoseconds: UInt64 = 1_350_000_000
    private let moveTraceDurationNanoseconds: UInt64 = 1_500_000_000
    private let onMatchCompleted: MatchCompletionHandler?
    private var hasReportedMatchCompletion: Bool

    public init(
        aiLevel: AILevel = .intermediate,
        gameplaySettings: GameplaySettings = .init(),
        rulesEngine: BackgammonRulesEngine = .init(),
        diceRandomizer: SecureDiceRandomizer = .init(),
        onMatchCompleted: MatchCompletionHandler? = nil
    ) {
        self.aiLevel = aiLevel
        self.gameplaySettings = gameplaySettings
        self.rulesEngine = rulesEngine
        self.diceRandomizer = diceRandomizer
        self.bot = BackgammonBot(level: aiLevel, rulesEngine: rulesEngine)
        self.board = BoardState()
        self.currentTurn = .white
        self.roll = nil
        self.remainingDice = []
        self.selectedOrigin = nil
        self.legalOrigins = []
        self.legalDestinations = []
        self.statusText = "New match ready. White starts."
        self.isMatchFinished = false
        self.canUndoLastMove = false
        self.matchResult = nil
        self.lastMove = nil
        self.availableFirstMoves = []
        self.undoStack = []
        self.onMatchCompleted = onMatchCompleted
        self.hasReportedMatchCompletion = false
    }

    public var isHumanTurn: Bool {
        currentTurn == humanColor && !isMatchFinished
    }

    public var canRoll: Bool {
        !isMatchFinished && remainingDice.isEmpty
    }

    public var turnBadgeText: String {
        if isMatchFinished {
            return "Finished"
        }
        return isHumanTurn ? "Your Turn" : "AI Turn"
    }

    public var turnHint: String {
        if isMatchFinished {
            return "Start a new match to play again."
        }
        if canRoll {
            return isHumanTurn ? "Roll dice to begin your turn." : "AI is preparing its roll."
        }
        if selectedOrigin == nil {
            return "Select a checker to move."
        }
        return "Choose a destination."
    }

    public var whitePips: Int { board.pipCount(for: .white) }
    public var blackPips: Int { board.pipCount(for: .black) }
    public var whiteBar: Int { board.barWhite }
    public var blackBar: Int { board.barBlack }
    public var whiteOff: Int { board.borneOffWhite }
    public var blackOff: Int { board.borneOffBlack }

    public func startNewGame() {
        board = BoardState()
        currentTurn = .white
        roll = nil
        remainingDice = []
        selectedOrigin = nil
        legalOrigins = []
        legalDestinations = []
        availableFirstMoves = []
        isMatchFinished = false
        statusText = "New match ready. White starts."
        clearUndoHistory()
        matchResult = nil
        lastMove = nil
        hasReportedMatchCompletion = false
    }

    public func rollDiceIfNeeded() {
        guard !isMatchFinished else { return }
        guard remainingDice.isEmpty else { return }

        if currentTurn == humanColor {
            clearUndoHistory()
        }

        let nextRoll = diceRandomizer.roll()
        roll = nextRoll
        remainingDice = nextRoll.values
        statusText = "\(name(for: currentTurn)) rolled \(nextRoll.first)-\(nextRoll.second)."
        refreshMoveOptions()

        if currentTurn == aiColor {
            Task {
                await performAITurn()
            }
        }
    }

    public func tapPoint(_ point: Int) {
        guard !isMatchFinished else { return }
        guard (1...24).contains(point) else { return }
        guard currentTurn == humanColor else { return }

        if remainingDice.isEmpty {
            statusText = "Roll dice to begin your turn."
            return
        }

        let tappedOrigin = OriginSelection.point(point)

        if selectedOrigin == nil {
            if legalOrigins.contains(tappedOrigin) {
                selectedOrigin = tappedOrigin
                refreshDestinationsForSelectedOrigin()
            }
            return
        }

        if selectedOrigin == tappedOrigin {
            selectedOrigin = nil
            refreshDestinationsForSelectedOrigin()
            return
        }

        if legalDestinations.contains(point) {
            applyHumanMove(to: point)
            return
        }

        if legalOrigins.contains(tappedOrigin) {
            selectedOrigin = tappedOrigin
            refreshDestinationsForSelectedOrigin()
        }
    }

    public func tapBarOrigin() {
        guard !isMatchFinished else { return }
        guard currentTurn == humanColor else { return }
        guard remainingDice.isEmpty == false else { return }

        let barSelection: OriginSelection = .bar
        guard legalOrigins.contains(barSelection) else { return }
        selectedOrigin = barSelection
        refreshDestinationsForSelectedOrigin()
    }

    public func tapBearOffDestination() {
        guard !isMatchFinished else { return }
        guard currentTurn == humanColor else { return }
        guard legalDestinations.contains(nil) else { return }
        applyHumanMove(to: nil)
    }

    public func undoLastHumanMove() {
        guard !isMatchFinished else { return }
        guard currentTurn == humanColor else { return }
        guard let snapshot = undoStack.popLast() else { return }

        board = snapshot.board
        roll = snapshot.roll
        remainingDice = snapshot.remainingDice
        selectedOrigin = snapshot.selectedOrigin
        legalOrigins = snapshot.legalOrigins
        legalDestinations = snapshot.legalDestinations
        availableFirstMoves = snapshot.availableFirstMoves
        canUndoLastMove = !undoStack.isEmpty
        statusText = "Move undone. Choose another move."
    }

    public func clearMatchResult() {
        matchResult = nil
    }

    public func abandonAndResetMatch() {
        if !isMatchFinished {
            _ = finalizeMatch(winner: aiColor, abandoned: true, presentResultModal: false)
        }
        startNewGame()
    }

    public func isPointInteractive(_ point: Int) -> Bool {
        let selection = OriginSelection.point(point)
        if legalOrigins.contains(selection) {
            return true
        }
        return legalDestinations.contains(point)
    }

    public func pointCheckerCount(_ point: Int) -> Int {
        board.points[point]?.count ?? 0
    }

    public func pointCheckerColor(_ point: Int) -> CheckerColor? {
        board.points[point]?.color
    }

    public func remainingDice(for color: CheckerColor) -> [Int] {
        guard currentTurn == color else {
            return []
        }
        return remainingDice
    }

    public func destinationDiceHints(for point: Int?) -> [Int] {
        guard let selectedOrigin else {
            return []
        }
        let values = availableFirstMoves
            .filter { originSelection(from: $0) == selectedOrigin && $0.toPoint == point }
            .map(\.dieValue)
        return Array(Set(values)).sorted()
    }

    private func refreshMoveOptions() {
        guard remainingDice.isEmpty == false else {
            availableFirstMoves = []
            legalOrigins = []
            legalDestinations = []
            selectedOrigin = nil
            return
        }

        let candidates = rulesEngine.legalTurnCandidates(
            for: remainingDice,
            color: currentTurn,
            board: board
        )

        let uniqueFirstMoves = Array(
            Set(candidates.compactMap { $0.moves.first })
        )
        availableFirstMoves = uniqueFirstMoves
        legalOrigins = Set(uniqueFirstMoves.map(originSelection(from:)))

        if uniqueFirstMoves.isEmpty {
            statusText = "\(name(for: currentTurn)) has no legal moves."
            endTurn()
            return
        }

        if let selectedOrigin,
           !legalOrigins.contains(selectedOrigin) {
            self.selectedOrigin = nil
        }

        if gameplaySettings.forcedMovesEnabled,
           self.selectedOrigin == nil,
           legalOrigins.count == 1 {
            self.selectedOrigin = legalOrigins.first
        }

        refreshDestinationsForSelectedOrigin()
    }

    private func refreshDestinationsForSelectedOrigin() {
        guard let selectedOrigin else {
            legalDestinations = []
            return
        }

        legalDestinations = Set(
            availableFirstMoves
                .filter { originSelection(from: $0) == selectedOrigin }
                .map(\.toPoint)
        )
    }

    private func applyHumanMove(to destination: Int?) {
        guard let selectedOrigin else { return }

        guard let move = availableFirstMoves.first(where: {
            originSelection(from: $0) == selectedOrigin && $0.toPoint == destination
        }) else {
            return
        }

        guard let updated = try? rulesEngine.applyMove(move, color: humanColor, to: board) else {
            return
        }

        pushUndoSnapshot()
        board = updated
        consumeDie(move.dieValue)
        showMoveTrace(move)
        triggerMoveHaptic()

        statusText = "You played \(moveNotation(move))."
        self.selectedOrigin = nil

        if resolveWinnerIfNeeded() {
            return
        }

        if remainingDice.isEmpty {
            endTurn()
        } else {
            refreshMoveOptions()
        }
    }

    private func performAITurn() async {
        guard !isMatchFinished else { return }
        guard currentTurn == aiColor else { return }

        if remainingDice.isEmpty {
            rollDiceIfNeeded()
        }
        guard remainingDice.isEmpty == false else { return }

        let turnMoves = bot.chooseTurn(
            for: aiColor,
            board: board,
            diceValues: remainingDice
        )

        if turnMoves.isEmpty {
            endTurn()
            return
        }

        for move in turnMoves {
            try? await Task.sleep(nanoseconds: aiMovePauseNanoseconds)
            guard let updated = try? rulesEngine.applyMove(move, color: aiColor, to: board) else {
                continue
            }
            board = updated
            consumeDie(move.dieValue)
            showMoveTrace(move)
            statusText = "AI played \(moveNotation(move))."
            if resolveWinnerIfNeeded() {
                return
            }
        }

        endTurn()
    }

    private func consumeDie(_ dieValue: Int) {
        if let index = remainingDice.firstIndex(of: dieValue) {
            remainingDice.remove(at: index)
        }
    }

    private func endTurn() {
        guard !isMatchFinished else { return }
        roll = nil
        remainingDice = []
        selectedOrigin = nil
        legalOrigins = []
        legalDestinations = []
        availableFirstMoves = []
        clearUndoHistory()
        currentTurn = currentTurn.opponent

        if currentTurn == aiColor {
            statusText = "AI turn. Preparing move..."
            Task {
                try? await Task.sleep(nanoseconds: aiTurnStartPauseNanoseconds)
                rollDiceIfNeeded()
            }
        } else {
            statusText = "\(name(for: currentTurn)) turn. Roll dice."
        }
    }

    private func resolveWinnerIfNeeded() -> Bool {
        if board.borneOffCount(for: .white) >= 15 {
            _ = finalizeMatch(winner: .white)
            return true
        }
        if board.borneOffCount(for: .black) >= 15 {
            _ = finalizeMatch(winner: .black)
            return true
        }
        return false
    }

    @discardableResult
    private func finalizeMatch(
        winner: CheckerColor,
        abandoned: Bool = false,
        presentResultModal: Bool = true
    ) -> MatchCompletion {
        let victoryType: VictoryType
        if abandoned {
            victoryType = .normal
        } else {
            victoryType = determineVictoryType(forWinner: winner)
        }

        let cubeMultiplier = gameplaySettings.doublingCubeEnabled ? max(board.doublingCubeValue, 1) : 1
        let awardedPoints = abandoned ? 0 : (victoryType.basePoints * cubeMultiplier)
        let userPointsDelta = winner == humanColor && !abandoned ? awardedPoints : 0

        let completion = MatchCompletion(
            winner: winner,
            victoryType: victoryType,
            cubeMultiplier: cubeMultiplier,
            pointsAwarded: awardedPoints,
            userPointsDelta: userPointsDelta,
            abandoned: abandoned
        )

        if presentResultModal {
            matchResult = completion
            triggerSuccessHaptic()
        } else {
            matchResult = nil
        }

        isMatchFinished = true
        statusText = abandoned ? "Match abandoned." : (winner == .white ? "You win." : "AI wins.")
        clearTurnState()

        if !hasReportedMatchCompletion {
            hasReportedMatchCompletion = true
            onMatchCompleted?(completion)
        }
        return completion
    }

    private func determineVictoryType(forWinner winner: CheckerColor) -> VictoryType {
        let loser = winner.opponent
        let loserOff = board.borneOffCount(for: loser)
        if loserOff > 0 {
            return .normal
        }

        let loserOnBar = board.barCount(for: loser) > 0
        let loserInWinnersHomeBoard = hasChecker(of: loser, in: homeBoardRange(for: winner))
        if loserOnBar || loserInWinnersHomeBoard {
            return .backgammon
        }
        return .gammon
    }

    private func homeBoardRange(for color: CheckerColor) -> ClosedRange<Int> {
        color == .white ? 1...6 : 19...24
    }

    private func hasChecker(of color: CheckerColor, in range: ClosedRange<Int>) -> Bool {
        range.contains { point in
            guard let occupancy = board.points[point], occupancy.color == color else {
                return false
            }
            return occupancy.count > 0
        }
    }

    private func clearTurnState() {
        roll = nil
        remainingDice = []
        selectedOrigin = nil
        legalOrigins = []
        legalDestinations = []
        availableFirstMoves = []
        clearUndoHistory()
        lastMove = nil
    }

    private func pushUndoSnapshot() {
        let snapshot = HumanMoveSnapshot(
            board: board,
            roll: roll,
            remainingDice: remainingDice,
            selectedOrigin: selectedOrigin,
            legalOrigins: legalOrigins,
            legalDestinations: legalDestinations,
            availableFirstMoves: availableFirstMoves
        )
        undoStack.append(snapshot)
        canUndoLastMove = true
    }

    private func clearUndoHistory() {
        undoStack.removeAll()
        canUndoLastMove = false
    }

    private func originSelection(from move: MoveIntent) -> OriginSelection {
        if let from = move.fromPoint {
            return .point(from)
        }
        return .bar
    }

    private func name(for color: CheckerColor) -> String {
        color == .white ? "White" : "Black"
    }

    private func moveNotation(_ move: MoveIntent) -> String {
        let fromLabel = move.fromPoint.map(String.init) ?? "Bar"
        let toLabel = move.toPoint.map(String.init) ?? "Off"
        return "\(fromLabel)->\(toLabel) (\(move.dieValue))"
    }

    private func showMoveTrace(_ move: MoveIntent) {
        lastMove = move
        let traceDuration = moveTraceDurationNanoseconds
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: traceDuration)
            guard let self else { return }
            guard self.lastMove == move else { return }
            self.lastMove = nil
        }
    }

    private func triggerMoveHaptic() {
#if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
#endif
    }

    private func triggerSuccessHaptic() {
#if canImport(UIKit)
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
#endif
    }
}

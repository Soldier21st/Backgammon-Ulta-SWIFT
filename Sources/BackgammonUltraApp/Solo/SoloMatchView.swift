import SwiftUI
import BackgammonUltraCore
import BackgammonUltraGameEngine
#if canImport(UIKit)
import UIKit
#endif

// MARK: - SoloMatchView

public struct SoloMatchView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.displayScale) private var displayScale
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SoloMatchViewModel
    @State private var showMenu = false
    @State private var showQuickChatSheet = false
    @State private var showLeaveMatchConfirmation = false
    @State private var chatHistory: [ChatEntry] = []
    private let onGameplaySettingsChanged: ((GameplaySettings) -> Void)?

    private var isLandscape: Bool {
        switch viewModel.gameplaySettings.boardOrientation {
        case .auto: return verticalSizeClass == .compact
        case .landscape: return verticalSizeClass == .compact
        case .portrait: return false
        }
    }

    public init(
        aiLevel: AILevel = .intermediate,
        gameplaySettings: GameplaySettings = .init(),
        onGameplaySettingsChanged: ((GameplaySettings) -> Void)? = nil,
        onMatchCompleted: SoloMatchViewModel.MatchCompletionHandler? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: SoloMatchViewModel(
                aiLevel: aiLevel,
                gameplaySettings: gameplaySettings,
                onMatchCompleted: onMatchCompleted
            )
        )
        self.onGameplaySettingsChanged = onGameplaySettingsChanged
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Dark background
                Color(red: 0.06, green: 0.07, blue: 0.10)
                    .ignoresSafeArea()

                boardCentricLayout(size: proxy.size, safeArea: proxy.safeAreaInsets)
            }
        }
        .navigationTitle("")
#if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .statusBarHidden(isLandscape)
#endif
        .onChange(of: viewModel.gameplaySettings) { _, newValue in
            onGameplaySettingsChanged?(newValue)
        }
        .sheet(isPresented: $showQuickChatSheet) {
            quickChatSheet
        }
        .alert(
            viewModel.matchResult?.title ?? "Match Finished",
            isPresented: Binding(
                get: { viewModel.matchResult != nil },
                set: { if !$0 { viewModel.clearMatchResult() } }
            )
        ) {
            Button("Rematch") {
                viewModel.startNewGame()
                viewModel.clearMatchResult()
            }
            Button("Home", role: .cancel) {
                viewModel.startNewGame()
                viewModel.clearMatchResult()
                dismiss()
            }
        } message: {
            Text(viewModel.matchResult?.message ?? "")
        }
        .alert("Match verlassen?", isPresented: $showLeaveMatchConfirmation) {
            Button("Abbrechen", role: .cancel) {}
            Button("Verlassen", role: .destructive) { confirmLeaveMatch() }
        } message: {
            Text("Du verlässt das laufende Match und kehrst zum Dashboard zurück.")
        }
    }

    // MARK: - Main Layout

    private func boardCentricLayout(size: CGSize, safeArea: EdgeInsets) -> some View {
        let metrics = BoardMetrics(
            containerSize: size,
            safeArea: safeArea,
            isLandscape: isLandscape,
            displayScale: displayScale
        )

        return ZStack {
            // The board — fills the screen
            boardView(metrics: metrics)
                .frame(width: metrics.boardWidth, height: metrics.boardHeight)
                .position(x: metrics.boardCenterX, y: metrics.boardCenterY)

            // Floating overlays
            floatingOverlays(metrics: metrics, safeArea: safeArea)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Prevent layout-driving animations from checker updates
        .transaction { $0.animation = nil }
    }

    // MARK: - Floating Overlays

    private func floatingOverlays(metrics: BoardMetrics, safeArea: EdgeInsets) -> some View {
        ZStack {
            // Top-left: Player 2 (AI) info
            VStack {
                HStack(spacing: 8) {
                    playerInfoPill(
                        name: "AI (\(viewModel.aiLevel.title))",
                        checkerColor: .black,
                        pips: viewModel.blackPips,
                        bar: viewModel.blackBar,
                        off: viewModel.blackOff,
                        isTurn: viewModel.currentTurn == .black
                    )
                    Spacer()
                    controlButtons(safeArea: safeArea)
                }
                .padding(.top, safeArea.top + 4)
                .padding(.horizontal, max(safeArea.leading, 8))
                Spacer()
            }

            // Bottom: Player 1 (You) info + action buttons
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    playerInfoPill(
                        name: "You",
                        checkerColor: .white,
                        pips: viewModel.whitePips,
                        bar: viewModel.whiteBar,
                        off: viewModel.whiteOff,
                        isTurn: viewModel.currentTurn == .white
                    )
                    Spacer()
                    actionButtons
                }
                .padding(.bottom, safeArea.bottom + 4)
                .padding(.horizontal, max(safeArea.trailing, 8))
            }

            // Center: Roll Dice button (only when needed)
            if viewModel.canRoll && viewModel.isHumanTurn {
                rollDiceOverlay
            }

            // Center: Turn status (when AI is thinking)
            if !viewModel.isHumanTurn && !viewModel.isMatchFinished {
                aiThinkingIndicator
            }
        }
    }

    // MARK: - Player Info Pill

    private func playerInfoPill(
        name: String,
        checkerColor: CheckerColor,
        pips: Int,
        bar: Int,
        off: Int,
        isTurn: Bool
    ) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(checkerColor == .white ? Color.white : Color(red: 0.12, green: 0.14, blue: 0.19))
                .frame(width: 14, height: 14)
                .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 0.8))

            Text(name)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)

            if isTurn {
                Image(systemName: "arrowtriangle.right.fill")
                    .font(.system(size: 7))
                    .foregroundStyle(Color.green)
            }

            if viewModel.gameplaySettings.pipsCounterEnabled {
                Text("Pip \(pips)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial.opacity(0.85), in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(
                    isTurn ? Color.green.opacity(0.6) : Color.white.opacity(0.15),
                    lineWidth: isTurn ? 1.2 : 0.8
                )
        )
    }

    // MARK: - Control Buttons (top-right)

    private func controlButtons(safeArea: EdgeInsets) -> some View {
        HStack(spacing: 6) {
            iconButton(systemName: "message", action: { showQuickChatSheet = true })
            iconButton(systemName: "ellipsis", action: { showMenu = true })
                .popover(isPresented: $showMenu) { menuContent }
            iconButton(systemName: "xmark", action: { showLeaveMatchConfirmation = true })
        }
    }

    private func iconButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 30, height: 30)
                .background(.ultraThinMaterial.opacity(0.7), in: Circle())
                .overlay(Circle().strokeBorder(Color.white.opacity(0.15), lineWidth: 0.8))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Action Buttons (bottom-right)

    private var actionButtons: some View {
        HStack(spacing: 8) {
            if viewModel.canUndoLastMove {
                Button {
                    viewModel.undoLastHumanMove()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(.ultraThinMaterial.opacity(0.7), in: Circle())
                        .overlay(Circle().strokeBorder(Color.white.opacity(0.2), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Roll Dice Overlay

    private var rollDiceOverlay: some View {
        Button {
            viewModel.rollDiceIfNeeded()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "dice.fill")
                    .font(.system(size: 16, weight: .bold))
                Text("Roll")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color(red: 0.13, green: 0.48, blue: 0.95))
                    .shadow(color: .black.opacity(0.4), radius: 8, y: 3)
            )
        }
        .buttonStyle(.plain)
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - AI Thinking Indicator

    private var aiThinkingIndicator: some View {
        HStack(spacing: 6) {
            ProgressView()
                .tint(.white)
                .scaleEffect(0.7)
            Text("AI")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial.opacity(0.6), in: Capsule())
    }

    // MARK: - Menu Content

    @ViewBuilder
    private var menuContent: some View {
        VStack(spacing: 0) {
            menuButton(label: "New Match", icon: "arrow.clockwise") {
                viewModel.startNewGame()
                showMenu = false
            }
            menuButton(label: "Quick Chat", icon: "message") {
                showQuickChatSheet = true
                showMenu = false
            }

            Divider().padding(.vertical, 4)

            // AI Level picker
            Menu {
                ForEach(AILevel.allCases, id: \.self) { level in
                    Button(level.title) {
                        viewModel.aiLevel = level
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "cpu")
                    Text("AI: \(viewModel.aiLevel.title)")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                }
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }

            Divider().padding(.vertical, 4)

            // Settings toggles
            Toggle(isOn: Binding(
                get: { viewModel.gameplaySettings.highlightLegalMoves },
                set: { viewModel.gameplaySettings.highlightLegalMoves = $0 }
            )) {
                Label("Legal Moves", systemImage: "sparkles")
                    .font(.subheadline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)

            Toggle(isOn: Binding(
                get: { viewModel.gameplaySettings.pipsCounterEnabled },
                set: { viewModel.gameplaySettings.pipsCounterEnabled = $0 }
            )) {
                Label("Pip Counter", systemImage: "number.circle")
                    .font(.subheadline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)

            Divider().padding(.vertical, 4)

            menuButton(label: "Leave Match", icon: "rectangle.portrait.and.arrow.right", role: .destructive) {
                showLeaveMatchConfirmation = true
                showMenu = false
            }
        }
        .padding(.vertical, 8)
        .frame(width: 220)
    }

    private func menuButton(
        label: String,
        icon: String,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(role: role, action: action) {
            HStack {
                Image(systemName: icon)
                Text(label)
                Spacer()
            }
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}

// MARK: - Board View

extension SoloMatchView {
    private func boardView(metrics: BoardMetrics) -> some View {
        ZStack {
            // Board frame background
            RoundedRectangle(cornerRadius: metrics.boardCornerRadius)
                .fill(BoardColors.frame)

            // Board inner surface
            RoundedRectangle(cornerRadius: metrics.boardCornerRadius - 2)
                .fill(BoardColors.surface)
                .padding(metrics.frameBorder)

            // Board content
            boardContent(metrics: metrics)
                .padding(metrics.frameBorder + metrics.innerPadding)
                .clipShape(RoundedRectangle(cornerRadius: metrics.boardCornerRadius - 4))
        }
        // Subtle outer shadow for depth
        .shadow(color: .black.opacity(0.5), radius: 12, y: 4)
    }

    private func boardContent(metrics: BoardMetrics) -> some View {
        HStack(spacing: 0) {
            // Left off tray (black bear-off)
            offTray(for: .black, metrics: metrics)
                .frame(width: metrics.trayWidth)

            // Left 6 points (outer board)
            pointSection(
                points: Array(13...18),
                metrics: metrics
            )

            // Center BAR
            barColumn(metrics: metrics)
                .frame(width: metrics.barWidth)

            // Right 6 points (home board)
            pointSection(
                points: Array(19...24),
                metrics: metrics
            )

            // Right off tray (white bear-off)
            offTray(for: .white, metrics: metrics)
                .frame(width: metrics.trayWidth)
        }
    }

    // MARK: - Point Section (6 points top + dice lane + 6 points bottom)

    private func pointSection(points: [Int], metrics: BoardMetrics) -> some View {
        let topPoints = points  // 13-18 or 19-24 → top row
        let bottomPoints = points.map { 25 - $0 }  // 12-7 or 6-1 → bottom row

        return VStack(spacing: 0) {
            // Top row
            HStack(spacing: metrics.pointSpacing) {
                ForEach(topPoints, id: \.self) { point in
                    pointTriangle(
                        point: point,
                        row: .top,
                        metrics: metrics,
                        triangleIndex: point - topPoints.first!
                    )
                }
            }
            .frame(height: metrics.rowHeight)

            // Dice lane
            diceLane(metrics: metrics, isLeftSection: topPoints.first == 13)
                .frame(height: metrics.diceLaneHeight)

            // Bottom row (offset +1 for alternating triangle colors)
            HStack(spacing: metrics.pointSpacing) {
                ForEach(Array(bottomPoints.enumerated()), id: \.element) { index, point in
                    pointTriangle(
                        point: point,
                        row: .bottom,
                        metrics: metrics,
                        triangleIndex: index + 1
                    )
                }
            }
            .frame(height: metrics.rowHeight)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Point Triangle

    private func pointTriangle(point: Int, row: BoardRow, metrics: BoardMetrics, triangleIndex: Int) -> some View {
        let count = viewModel.pointCheckerCount(point)
        let checkerColor = viewModel.pointCheckerColor(point)
        let isOrigin = viewModel.gameplaySettings.highlightLegalMoves && viewModel.legalOrigins.contains(.point(point))
        let isDestination = viewModel.gameplaySettings.highlightLegalMoves && viewModel.legalDestinations.contains(point)
        let isSelected = viewModel.selectedOrigin == .point(point)
        let isDark = triangleIndex.isMultiple(of: 2)
        let destinationHints = viewModel.destinationDiceHints(for: point)

        return Button {
            viewModel.tapPoint(point)
        } label: {
            ZStack {
                // Triangle shape
                BackgammonTriangleShape(pointsDownward: row == .top)
                    .fill(triangleFillColor(isDark: isDark, isSelected: isSelected, isOrigin: isOrigin, isDestination: isDestination))
                    .padding(.horizontal, 1)

                // Checker stack
                checkerStack(
                    count: count,
                    checkerColor: checkerColor,
                    row: row,
                    metrics: metrics
                )

                // Point number
                pointNumberLabel(point, row: row, metrics: metrics)

                // Destination dice badge
                if isDestination, !destinationHints.isEmpty {
                    destinationBadge(destinationHints, row: row, metrics: metrics)
                }

                // Selection/highlight border
                if isSelected || isDestination || isOrigin {
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(
                            highlightColor(isSelected: isSelected, isOrigin: isOrigin, isDestination: isDestination),
                            lineWidth: 2
                        )
                        .padding(1)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .anchorPreference(key: PointFramePreferenceKey.self, value: .bounds) { [point: $0] }
    }

    // MARK: - Checker Stack

    private func checkerStack(count: Int, checkerColor: CheckerColor?, row: BoardRow, metrics: BoardMetrics) -> some View {
        let checkerSize = metrics.checkerSize
        let maxVisible = max(3, Int(metrics.rowHeight / (checkerSize * 0.72)))
        let visibleCount = min(maxVisible, count)
        let overlap = -checkerSize * 0.22

        return VStack(spacing: overlap) {
            if row == .bottom {
                Spacer(minLength: 0)
            }

            if count > visibleCount {
                overflowBadge(count - visibleCount)
                    .padding(row == .top ? .top : .bottom, 1)
            }

            ForEach(0..<visibleCount, id: \.self) { _ in
                checkerPiece(color: checkerColor, size: checkerSize)
            }

            if row == .top {
                Spacer(minLength: 0)
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func checkerPiece(color: CheckerColor?, size: CGFloat) -> some View {
        let fill: Color = {
            guard let color else { return .clear }
            switch color {
            case .white: return Color(red: 0.95, green: 0.93, blue: 0.88)
            case .black: return Color(red: 0.10, green: 0.12, blue: 0.16)
            }
        }()

        let border: Color = {
            guard let color else { return .clear }
            switch color {
            case .white: return Color(red: 0.78, green: 0.74, blue: 0.68)
            case .black: return Color.white.opacity(0.25)
            }
        }()

        return Circle()
            .fill(fill)
            .frame(width: size, height: size)
            .overlay(Circle().stroke(border, lineWidth: 1.2))
            .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
    }

    // MARK: - Bar Column

    private func barColumn(metrics: BoardMetrics) -> some View {
        Button {
            viewModel.tapBarOrigin()
        } label: {
            let isActive = viewModel.gameplaySettings.highlightLegalMoves && viewModel.legalOrigins.contains(.bar)
            let isSelected = viewModel.selectedOrigin == .bar

            ZStack {
                // Bar background
                Rectangle()
                    .fill(BoardColors.bar)

                VStack(spacing: 4) {
                    // Black bar checkers
                    barCheckers(count: viewModel.blackBar, color: .black, metrics: metrics)
                    Spacer(minLength: 0)
                    // White bar checkers
                    barCheckers(count: viewModel.whiteBar, color: .white, metrics: metrics)
                }
                .padding(.vertical, 6)

                // Highlight border
                if isActive || isSelected {
                    Rectangle()
                        .strokeBorder(Color.orange.opacity(0.9), lineWidth: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func barCheckers(count: Int, color: CheckerColor, metrics: BoardMetrics) -> some View {
        let size = min(metrics.barWidth - 6, metrics.checkerSize * 0.85)
        return VStack(spacing: 2) {
            ForEach(0..<min(count, 5), id: \.self) { _ in
                checkerPiece(color: color, size: size)
            }
            if count > 5 {
                overflowBadge(count - 5)
            }
            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }

    // MARK: - Off Tray

    private func offTray(for color: CheckerColor, metrics: BoardMetrics) -> some View {
        let offCount = color == .white ? viewModel.whiteOff : viewModel.blackOff
        let isHumanTray = color == .white
        let isActive = isHumanTray
            && viewModel.gameplaySettings.highlightLegalMoves
            && viewModel.legalDestinations.contains(nil)
        let destinationHints = viewModel.destinationDiceHints(for: nil)

        return Button {
            guard isHumanTray else { return }
            viewModel.tapBearOffDestination()
        } label: {
            ZStack {
                // Tray background
                Rectangle()
                    .fill(BoardColors.tray)

                VStack(spacing: 2) {
                    if color == .black {
                        offTrayCheckers(count: offCount, color: color, metrics: metrics)
                        Spacer(minLength: 0)
                    } else {
                        Spacer(minLength: 0)
                        offTrayCheckers(count: offCount, color: color, metrics: metrics)
                    }
                }
                .padding(.vertical, 4)

                // Active highlight for bearing off
                if isActive {
                    Rectangle()
                        .strokeBorder(Color.green.opacity(0.9), lineWidth: 2)

                    if !destinationHints.isEmpty {
                        VStack {
                            if color == .white { Spacer() }
                            Text(destinationHints.prefix(2).map(String.init).joined(separator: "/"))
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.85), in: Capsule())
                            if color == .black { Spacer() }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func offTrayCheckers(count: Int, color: CheckerColor, metrics: BoardMetrics) -> some View {
        let pieceHeight: CGFloat = 6
        let maxVisible = min(count, 15)

        return VStack(spacing: 1) {
            ForEach(0..<maxVisible, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color == .white
                          ? Color(red: 0.92, green: 0.90, blue: 0.84)
                          : Color(red: 0.15, green: 0.17, blue: 0.22))
                    .frame(width: metrics.trayWidth - 6, height: pieceHeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(color == .white
                                    ? Color(red: 0.75, green: 0.72, blue: 0.66)
                                    : Color.white.opacity(0.2),
                                    lineWidth: 0.6)
                    )
            }
            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }

    // MARK: - Dice Lane

    private func diceLane(metrics: BoardMetrics, isLeftSection: Bool) -> some View {
        HStack {
            if isLeftSection {
                // Black dice on the left section
                diceDisplay(for: .black, metrics: metrics)
                Spacer(minLength: 0)
            } else {
                // White dice on the right section
                Spacer(minLength: 0)
                diceDisplay(for: .white, metrics: metrics)
            }
        }
        .frame(maxWidth: .infinity)
        .background(BoardColors.surface.opacity(0.3))
    }

    private func diceDisplay(for color: CheckerColor, metrics: BoardMetrics) -> some View {
        let values = viewModel.remainingDice(for: color)
        let dieSize: CGFloat = min(metrics.diceLaneHeight - 8, 28)

        return HStack(spacing: 4) {
            if !values.isEmpty {
                ForEach(Array(values.enumerated()), id: \.offset) { _, die in
                    dieView(value: die, color: color, size: dieSize)
                }
            }
        }
        .padding(.horizontal, 8)
    }

    private func dieView(value: Int, color: CheckerColor, size: CGFloat) -> some View {
        let bgColor = color == .white
            ? Color(red: 0.95, green: 0.93, blue: 0.88)
            : Color(red: 0.14, green: 0.16, blue: 0.22)
        let textColor = color == .white
            ? Color(red: 0.15, green: 0.12, blue: 0.08)
            : Color.white.opacity(0.95)

        return Text("\(value)")
            .font(.system(size: size * 0.52, weight: .black, design: .rounded))
            .foregroundStyle(textColor)
            .monospacedDigit()
            .frame(width: size, height: size)
            .background(bgColor, in: RoundedRectangle(cornerRadius: size * 0.18))
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.18)
                    .stroke(Color.white.opacity(color == .white ? 0.3 : 0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
    }

    // MARK: - Helpers

    private func pointNumberLabel(_ point: Int, row: BoardRow, metrics: BoardMetrics) -> some View {
        VStack {
            if row == .top {
                Text("\(point)")
                    .font(.system(size: max(8, metrics.checkerSize * 0.42), weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                    .monospacedDigit()
                    .padding(.top, 2)
                Spacer(minLength: 0)
            } else {
                Spacer(minLength: 0)
                Text("\(point)")
                    .font(.system(size: max(8, metrics.checkerSize * 0.42), weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                    .monospacedDigit()
                    .padding(.bottom, 2)
            }
        }
    }

    private func overflowBadge(_ overflow: Int) -> some View {
        Text("+\(min(overflow, 99))")
            .font(.system(size: 8, weight: .black, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white)
            .padding(.horizontal, 3)
            .padding(.vertical, 1)
            .background(Color.black.opacity(0.6), in: Capsule())
    }

    private func destinationBadge(_ values: [Int], row: BoardRow, metrics: BoardMetrics) -> some View {
        let text = values.prefix(2).map(String.init).joined(separator: "/")
        return VStack {
            if row == .top { Spacer(minLength: 0) }
            Text(text)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.green.opacity(0.85), in: Capsule())
            if row == .bottom { Spacer(minLength: 0) }
        }
        .padding(.vertical, 4)
    }

    private func triangleFillColor(isDark: Bool, isSelected: Bool, isOrigin: Bool, isDestination: Bool) -> Color {
        if isSelected { return Color.blue.opacity(0.55) }
        if isDestination { return Color.green.opacity(0.35) }
        if isOrigin { return Color.orange.opacity(0.35) }
        return isDark ? BoardColors.triangleDark : BoardColors.triangleLight
    }

    private func highlightColor(isSelected: Bool, isOrigin: Bool, isDestination: Bool) -> Color {
        if isSelected { return Color.blue.opacity(0.9) }
        if isDestination { return Color.green.opacity(0.85) }
        if isOrigin { return Color.orange.opacity(0.85) }
        return .clear
    }

    // MARK: - Actions

    private func confirmLeaveMatch() {
        showQuickChatSheet = false
        showMenu = false
        viewModel.abandonAndResetMatch()
        dismiss()
    }
}

// MARK: - Quick Chat Sheet

extension SoloMatchView {
    private var quickChatSheet: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.07, blue: 0.10).ignoresSafeArea()
                VStack(spacing: 12) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                if chatHistory.isEmpty {
                                    Text("No messages yet.")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.5))
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.top, 20)
                                } else {
                                    ForEach(chatHistory) { entry in
                                        chatBubble(entry)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                        }
                        .onChange(of: chatHistory.count) { _, _ in
                            if let last = chatHistory.last {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                        ForEach(QuickChatMessage.allCases, id: \.self) { message in
                            Button {
                                sendQuickChat(message.rawValue)
                            } label: {
                                Text(message.rawValue)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
            .navigationTitle("Chat")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showQuickChatSheet = false }
                }
#endif
            }
        }
#if os(iOS)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
#endif
    }

    private func chatBubble(_ entry: ChatEntry) -> some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text(entry.text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color.blue.opacity(0.7), in: RoundedRectangle(cornerRadius: 14))

            HStack(spacing: 4) {
                Text(chatTimestamp(for: entry.createdAt))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
                Image(systemName: entry.delivery == .sent ? "checkmark.circle.fill" : "clock")
                    .font(.caption2)
                    .foregroundStyle(entry.delivery == .sent ? Color.green.opacity(0.8) : .white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .id(entry.id)
    }

    private func sendQuickChat(_ text: String) {
        let pending = ChatEntry(text: text, createdAt: Date(), delivery: .sending)
        chatHistory.append(pending)
        let messageID = pending.id
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard let index = chatHistory.firstIndex(where: { $0.id == messageID }) else { return }
            chatHistory[index].delivery = .sent
        }
    }

    private func chatTimestamp(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Board Metrics

private struct BoardMetrics {
    let boardWidth: CGFloat
    let boardHeight: CGFloat
    let boardCenterX: CGFloat
    let boardCenterY: CGFloat
    let boardCornerRadius: CGFloat
    let frameBorder: CGFloat
    let innerPadding: CGFloat
    let barWidth: CGFloat
    let trayWidth: CGFloat
    let rowHeight: CGFloat
    let diceLaneHeight: CGFloat
    let pointSpacing: CGFloat
    let checkerSize: CGFloat

    init(containerSize: CGSize, safeArea: EdgeInsets, isLandscape: Bool, displayScale: CGFloat) {
        let safeWidth = containerSize.width - safeArea.leading - safeArea.trailing
        let safeHeight = containerSize.height - safeArea.top - safeArea.bottom

        let margin: CGFloat = isLandscape ? 4 : 6
        let availWidth = max(200, safeWidth - margin * 2)
        let availHeight = max(200, safeHeight - margin * 2)

        if isLandscape {
            // Landscape: board aspect ~1.85:1, fill the screen
            let landscapeAspect: CGFloat = 1.85
            let widthFromHeight = availHeight * landscapeAspect
            boardWidth = Self.px(min(availWidth, widthFromHeight), scale: displayScale)
            boardHeight = Self.px(boardWidth / landscapeAspect, scale: displayScale)
        } else {
            // Portrait: board fills the width and expands vertically
            // Use a portrait aspect (wider-than-tall but filling height)
            // Reserve ~36pt top + ~36pt bottom for overlay pills
            let reservedOverlay: CGFloat = 72
            let maxBoardHeight = availHeight - reservedOverlay
            let portraitAspect: CGFloat = 0.58 // width/height ratio
            let heightFromWidth = availWidth / portraitAspect

            boardWidth = Self.px(availWidth, scale: displayScale)
            boardHeight = Self.px(min(maxBoardHeight, heightFromWidth), scale: displayScale)
        }

        boardCenterX = containerSize.width / 2
        boardCenterY = containerSize.height / 2

        boardCornerRadius = min(16, boardWidth * 0.02)
        frameBorder = max(3, boardWidth * 0.008)
        innerPadding = max(2, boardWidth * 0.004)

        // Internal dimensions
        let innerWidth = boardWidth - (frameBorder + innerPadding) * 2
        let innerHeight = boardHeight - (frameBorder + innerPadding) * 2

        barWidth = Self.px(max(18, min(36, innerWidth * 0.045)), scale: displayScale)
        trayWidth = Self.px(max(16, min(30, innerWidth * 0.038)), scale: displayScale)
        pointSpacing = Self.px(max(1, min(2, innerWidth * 0.004)), scale: displayScale)

        diceLaneHeight = Self.px(max(24, min(42, innerHeight * 0.08)), scale: displayScale)
        rowHeight = Self.px(max(60, (innerHeight - diceLaneHeight) / 2), scale: displayScale)

        // Checker size: proportional to point width, capped to prevent oversized checkers
        let pointAreaWidth = (innerWidth - barWidth - trayWidth * 2) / 2
        let singlePointWidth = (pointAreaWidth - pointSpacing * 5) / 6
        checkerSize = Self.px(
            max(10, min(singlePointWidth * 0.82, min(rowHeight * 0.14, 26))),
            scale: displayScale
        )
    }

    private static func px(_ value: CGFloat, scale: CGFloat) -> CGFloat {
        guard scale > 0 else { return value }
        return (value * scale).rounded(.toNearestOrAwayFromZero) / scale
    }
}

// MARK: - Board Colors

private enum BoardColors {
    static let frame = Color(red: 0.22, green: 0.16, blue: 0.10)
    static let surface = Color(red: 0.32, green: 0.24, blue: 0.16)
    static let bar = Color(red: 0.18, green: 0.13, blue: 0.08)
    static let tray = Color(red: 0.25, green: 0.18, blue: 0.12)
    static let triangleDark = Color(red: 0.38, green: 0.18, blue: 0.12)
    static let triangleLight = Color(red: 0.82, green: 0.74, blue: 0.58)
}

// MARK: - Board Row

private enum BoardRow {
    case top, bottom
}

// MARK: - Chat Entry

private struct ChatEntry: Identifiable {
    let id = UUID()
    let text: String
    let createdAt: Date
    var delivery: ChatDeliveryStatus
}

private enum ChatDeliveryStatus: String {
    case sending, sent
}

// MARK: - Triangle Shape

private struct BackgammonTriangleShape: Shape {
    let pointsDownward: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if pointsDownward {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Preference Key

private struct PointFramePreferenceKey: PreferenceKey {
    static let defaultValue: [Int: Anchor<CGRect>] = [:]
    static func reduce(value: inout [Int: Anchor<CGRect>], nextValue: () -> [Int: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// MARK: - Board Orientation Extension

private extension BoardOrientation {
    var uiTitle: String {
        switch self {
        case .auto: return "Auto"
        case .portrait: return "Portrait"
        case .landscape: return "Landscape"
        }
    }
}

// MARK: - Haptics

private enum Haptics {
    static func selection() {
#if canImport(UIKit)
        Task { @MainActor in
            UISelectionFeedbackGenerator().selectionChanged()
        }
#endif
    }
}

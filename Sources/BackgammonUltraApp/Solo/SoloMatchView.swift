import SwiftUI
import BackgammonUltraCore
import BackgammonUltraGameEngine
#if canImport(UIKit)
import UIKit
#endif

public struct SoloMatchView: View {
    private struct BoardViewportMetrics {
        let boardSize: CGSize
        let boardCenter: CGPoint
    }

    private struct ClassicBoardMetrics {
        let boardWidth: CGFloat
        let boardHeight: CGFloat
        let padding: CGFloat
        let rowSpacing: CGFloat
        let pointSpacing: CGFloat
        let sectionSpacing: CGFloat
        let middleLaneHeight: CGFloat
        let barWidth: CGFloat
        let offTrayWidth: CGFloat
        let mirrorWidth: CGFloat
        let halfWidth: CGFloat
        let pointWidth: CGFloat
        let rowHeight: CGFloat
        let showZoneLabels: Bool
    }

    private enum PointStackDirection {
        case downward
        case upward
    }

    private enum BoardRow {
        case top
        case bottom
    }

    private enum ChatDeliveryStatus: String {
        case sending
        case sent
    }

    private struct ChatEntry: Identifiable {
        let id = UUID()
        let text: String
        let createdAt: Date
        var delivery: ChatDeliveryStatus
    }

    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.displayScale) private var displayScale
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SoloMatchViewModel
    @State private var isHUDVisible = false
    @State private var showQuickChatSheet = false
    @State private var showLeaveMatchConfirmation = false
    @State private var isFocusModeEnabled = true
    @State private var chatHistory: [ChatEntry] = []
    private let onGameplaySettingsChanged: ((GameplaySettings) -> Void)?
    
    private var isLandscapeChrome: Bool {
        switch viewModel.gameplaySettings.boardOrientation {
        case .auto:
            return verticalSizeClass == .compact
        case .landscape:
            return true
        case .portrait:
            return false
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
        ZStack {
            backgroundLayer
            contentLayer
        }
        .navigationTitle("")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar(isLandscapeChrome ? .hidden : .visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
#endif
        .toolbar {
#if os(iOS)
            if !isLandscapeChrome {
                ToolbarItem(placement: .principal) {
                    Text("Solo Match")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                leaveMatchButton
                if !isLandscapeChrome {
                    focusModeToggleButton
                    if !isFocusModeEnabled {
                        detailsToggleButton
                    }
                }
                chatToggleButton
                matchMenuButton
            }
#else
            ToolbarItemGroup(placement: .automatic) {
                focusModeToggleButton
                detailsToggleButton
                chatToggleButton
                matchMenuButton
            }
#endif
        }
        .onChange(of: verticalSizeClass) { _, newValue in
            if newValue == .compact {
                isHUDVisible = false
            }
        }
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
                set: { newValue in
                    if !newValue {
                        viewModel.clearMatchResult()
                    }
                }
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
            Button("Verlassen", role: .destructive) {
                confirmLeaveMatch()
            }
        } message: {
            Text("Du verlässt das laufende Match und kehrst zum Dashboard zurück.")
        }
        .animation(.easeInOut(duration: 0.2), value: isHUDVisible)
        .animation(.easeInOut(duration: 0.2), value: isFocusModeEnabled)
    }

    private var contentLayer: some View {
        GeometryReader { proxy in
            let prefersLandscapeBoard = shouldUseLandscapeBoard(for: proxy.size)
            let viewport = boardViewportMetrics(
                for: proxy.size,
                safeInsets: proxy.safeAreaInsets,
                prefersLandscapeBoard: prefersLandscapeBoard
            )

            ZStack {
                boardSurface(in: viewport.boardSize)
                    .frame(width: viewport.boardSize.width, height: viewport.boardSize.height)
                    .position(x: viewport.boardCenter.x, y: viewport.boardCenter.y)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .overlay(alignment: .top) {
                if !isLandscapeChrome {
                    topHUDInset
                        .padding(.top, proxy.safeAreaInsets.top + 2)
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity, alignment: .top)
                }
            }
            .overlay(alignment: .topTrailing) {
                if isLandscapeChrome {
                    landscapeTopControls
                        .padding(.top, proxy.safeAreaInsets.top + 4)
                        .padding(.trailing, 8)
                }
            }
                // Prevent checker/hint updates from driving parent layout animations.
                .transaction { transaction in
                    transaction.animation = nil
                }
        }
        .safeAreaInset(edge: .bottom, spacing: isLandscapeChrome ? 2 : 4) {
            if isLandscapeChrome {
                landscapeActionDock
                    .padding(.horizontal, 6)
            } else {
                bottomDock
                    .padding(.horizontal, 8)
            }
        }
    }

    private func boardViewportMetrics(
        for size: CGSize,
        safeInsets: EdgeInsets,
        prefersLandscapeBoard: Bool
    ) -> BoardViewportMetrics {
        let horizontalPadding: CGFloat = prefersLandscapeBoard ? 1 : 2
        let topReserved = topChromeReservedHeight(prefersLandscapeBoard: prefersLandscapeBoard) + safeInsets.top + 1
        let bottomReserved = bottomChromeReservedHeight(prefersLandscapeBoard: prefersLandscapeBoard) + safeInsets.bottom + 1

        let availableWidth = max(220, size.width - (horizontalPadding * 2))
        let availableHeight = max(220, size.height - topReserved - bottomReserved)

        // Board-first geometry: keep the board large in portrait and avoid a flattened look.
        let aspect: CGFloat = prefersLandscapeBoard ? 1.92 : 0.54
        let widthFromHeight = availableHeight * aspect
        let boardWidth = alignToPixel(min(availableWidth, widthFromHeight))
        let boardHeight = alignToPixel(boardWidth / aspect)

        let boardOriginY = topReserved + max(0, (availableHeight - boardHeight) / 2)
        let center = CGPoint(
            x: alignToPixel(size.width / 2),
            y: alignToPixel(boardOriginY + (boardHeight / 2))
        )

        return BoardViewportMetrics(
            boardSize: CGSize(width: boardWidth, height: boardHeight),
            boardCenter: center
        )
    }

    private func topChromeReservedHeight(prefersLandscapeBoard: Bool) -> CGFloat {
        if prefersLandscapeBoard {
            return 16
        }
        let isCompact = verticalSizeClass == .compact
        if isFocusModeEnabled {
            return 8
        }
        if isHUDVisible && !isCompact {
            return 196
        }
        return 34
    }

    private func bottomChromeReservedHeight(prefersLandscapeBoard: Bool) -> CGFloat {
        if prefersLandscapeBoard {
            return 40
        }
        return isFocusModeEnabled ? 46 : 70
    }

    private var topHUDInset: some View {
        let isCompact = verticalSizeClass == .compact
        return VStack(spacing: isFocusModeEnabled ? 0 : (isHUDVisible && !isCompact ? 10 : 6)) {
            if !isFocusModeEnabled {
                if isHUDVisible && !isCompact {
                    hudPanel
                        .transition(.move(edge: .top).combined(with: .opacity))
                } else {
                    compactTurnBanner
                }
            }
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.08, blue: 0.15),
                    Color(red: 0.10, green: 0.13, blue: 0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.cyan.opacity(0.1))
                .frame(width: 280, height: 280)
                .offset(x: 120, y: -230)
                .blur(radius: 30)

            Circle()
                .fill(Color.blue.opacity(0.12))
                .frame(width: 260, height: 260)
                .offset(x: -150, y: 280)
                .blur(radius: 30)
        }
    }

    private var detailsToggleButton: some View {
        Button {
            guard verticalSizeClass != .compact else { return }
            withAnimation {
                isHUDVisible.toggle()
            }
        } label: {
            Image(systemName: isHUDVisible ? "rectangle.compress.vertical" : "rectangle.expand.vertical")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .opacity(verticalSizeClass == .compact ? 0.45 : 1)
        .disabled(verticalSizeClass == .compact)
        .accessibilityLabel(isHUDVisible ? "Hide details" : "Show details")
    }

    private var focusModeToggleButton: some View {
        Button {
            withAnimation {
                isFocusModeEnabled.toggle()
                if isFocusModeEnabled {
                    isHUDVisible = false
                }
            }
        } label: {
            Image(systemName: isFocusModeEnabled ? "viewfinder.circle.fill" : "viewfinder.circle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .accessibilityLabel(isFocusModeEnabled ? "Disable focus mode" : "Enable focus mode")
    }

    private var chatToggleButton: some View {
        Button {
            showQuickChatSheet = true
        } label: {
            Image(systemName: showQuickChatSheet ? "message.fill" : "message")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .accessibilityLabel("Open quick chat")
    }

    private var leaveMatchButton: some View {
        Button(role: .destructive) {
            showLeaveMatchConfirmation = true
        } label: {
            Image(systemName: "house.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .accessibilityLabel("Leave match")
    }

    private var matchMenuButton: some View {
        Menu {
            matchMenuContent
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .accessibilityLabel("Match options")
    }

    @ViewBuilder
    private var matchMenuContent: some View {
        Button {
            viewModel.startNewGame()
        } label: {
            Label("New Match", systemImage: "arrow.clockwise")
        }

        Button {
            showQuickChatSheet = true
        } label: {
            Label("Quick Chat", systemImage: "message")
        }

        Menu {
            ForEach(BoardOrientation.allCases, id: \.self) { orientation in
                Button {
                    withAnimation {
                        viewModel.gameplaySettings.boardOrientation = orientation
                    }
                } label: {
                    if viewModel.gameplaySettings.boardOrientation == orientation {
                        Label(orientation.uiTitle, systemImage: "checkmark")
                    } else {
                        Text(orientation.uiTitle)
                    }
                }
            }
        } label: {
            Label("Board Orientation", systemImage: "iphone")
        }

        Button {
            withAnimation {
                viewModel.gameplaySettings.pipsCounterEnabled.toggle()
            }
        } label: {
            Label(
                viewModel.gameplaySettings.pipsCounterEnabled ? "Hide Pip Counter" : "Show Pip Counter",
                systemImage: "number.circle"
            )
        }

        if !isFocusModeEnabled {
            Button {
                withAnimation {
                    isHUDVisible.toggle()
                }
            } label: {
                Label(isHUDVisible ? "Hide Details" : "Show Details", systemImage: "rectangle.compress.vertical")
            }
        }
    }

    private func shouldUseLandscapeBoard(for size: CGSize) -> Bool {
        switch viewModel.gameplaySettings.boardOrientation {
        case .auto:
            return size.width > size.height
        case .portrait:
            return false
        case .landscape:
            // Never force a flattened landscape board into portrait screens.
            return size.width > size.height
        }
    }

    private var compactTurnBanner: some View {
        HStack(spacing: 10) {
            Text(viewModel.turnBadgeText)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.4), in: Capsule())
                .foregroundStyle(.white)

            Text(viewModel.turnHint)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.86))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .layoutPriority(1)
        }
        .sectionCard()
    }

    private var focusStatusRibbon: some View {
        HStack(spacing: 8) {
            Text(viewModel.turnBadgeText)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.blue.opacity(0.45), in: Capsule())
                .foregroundStyle(.white)

            Text(viewModel.turnHint)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.82))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .layoutPriority(1)

            if !statusRibbonDetail.isEmpty {
                Text(statusRibbonDetail)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.18), in: Capsule())
    }

    private var hudPanel: some View {
        VStack(spacing: 8) {
            header
            statusBanner
            playerStats
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Competitive Solo")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Solo AI \(viewModel.aiLevel.title)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
            }

            Spacer()

            Menu {
                ForEach(AILevel.allCases, id: \.self) { level in
                    Button(level.title) {
                        viewModel.aiLevel = level
                    }
                }
            } label: {
                Label(viewModel.aiLevel.title, systemImage: "cpu")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            }
            .tint(.white)

            Text(viewModel.turnBadgeText)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.12), in: Capsule())
                .foregroundStyle(.white)
        }
        .sectionCard()
    }

    private var statusBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.turnHint)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Text(viewModel.statusText)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.78))
                .lineLimit(2)

            if let selected = selectedOriginLabel {
                Text("Selected: \(selected)")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.72))
            }

            if viewModel.gameplaySettings.pipsCounterEnabled {
                Text(pipRaceSummary)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.72))
            }

            Text("Bar = captured checkers · Off = borne off")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.58))
        }
        .sectionCard()
    }

    private var playerStats: some View {
        HStack(spacing: 10) {
            playerStatCard(
                title: "You",
                color: .white,
                pips: viewModel.whitePips,
                bar: viewModel.whiteBar,
                off: viewModel.whiteOff,
                isTurn: viewModel.currentTurn == .white
            )

            playerStatCard(
                title: "AI",
                color: Color(red: 0.14, green: 0.17, blue: 0.23),
                pips: viewModel.blackPips,
                bar: viewModel.blackBar,
                off: viewModel.blackOff,
                isTurn: viewModel.currentTurn == .black
            )
        }
    }

    private func playerStatCard(
        title: String,
        color: Color,
        pips: Int,
        bar: Int,
        off: Int,
        isTurn: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 11, height: 11)
                    .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 0.8))
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                if isTurn {
                    Text("TURN")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.6), in: Capsule())
                }
            }

            HStack {
                if viewModel.gameplaySettings.pipsCounterEnabled {
                    statMetric(label: "Pips", value: pips)
                }
                statMetric(label: "Bar", value: bar)
                statMetric(label: "Off", value: off)
            }
        }
        .sectionCard()
    }

    private func statMetric(label: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.55))
            Text("\(value)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.92))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func boardSurface(in availableSize: CGSize) -> some View {
        classicBoardSurface(in: availableSize)
    }

    private var modernBoardSurface: some View {
        GeometryReader { proxy in
            let innerHeight = max(proxy.size.height - 24, 220)
            let centerHeight = max(46, min(74, innerHeight * 0.17))
            let sideControlWidth = max(74, min(98, proxy.size.width * 0.19))
            let cellHeight = max(54, min(118, (innerHeight - centerHeight - 18) / 2))

            VStack(spacing: 10) {
                pointGridModern(
                    Array((13...24).reversed()),
                    cellHeight: cellHeight,
                    stackDirection: .downward
                )

                HStack(spacing: 10) {
                    barControl
                        .frame(width: sideControlWidth, height: centerHeight)
                    diceStrip
                        .frame(maxWidth: .infinity, minHeight: centerHeight, maxHeight: centerHeight)
                    bearOffControl
                        .frame(width: sideControlWidth, height: centerHeight)
                }

                pointGridModern(
                    Array(1...12),
                    cellHeight: cellHeight,
                    stackDirection: .upward
                )
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(boardCardBackground)
        }
    }

    private func classicBoardSurface(in availableSize: CGSize) -> some View {
        let metrics = classicBoardMetrics(for: availableSize)

        return ZStack {
            VStack(spacing: metrics.rowSpacing) {
                pointGridClassic(
                    Array(13...24),
                    rowHeight: metrics.rowHeight,
                    row: .top,
                    pointWidth: metrics.pointWidth,
                    pointSpacing: metrics.pointSpacing,
                    sectionSpacing: metrics.sectionSpacing,
                    middleBarWidth: metrics.barWidth,
                    offTrayColor: .black,
                    offTrayWidth: metrics.offTrayWidth,
                    mirrorWidth: metrics.mirrorWidth
                )
                classicMiddleLane(height: metrics.middleLaneHeight, middleBarWidth: metrics.barWidth)
                pointGridClassic(
                    Array((1...12).reversed()),
                    rowHeight: metrics.rowHeight,
                    row: .bottom,
                    pointWidth: metrics.pointWidth,
                    pointSpacing: metrics.pointSpacing,
                    sectionSpacing: metrics.sectionSpacing,
                    middleBarWidth: metrics.barWidth,
                    offTrayColor: .white,
                    offTrayWidth: metrics.offTrayWidth,
                    mirrorWidth: metrics.mirrorWidth
                )
            }
            .padding(metrics.padding)
            .frame(width: metrics.boardWidth, height: metrics.boardHeight)
            .background(boardCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(alignment: .top) {
                if metrics.showZoneLabels {
                    boardZoneLabels(top: true)
                        .padding(.top, metrics.padding + 2)
                        .padding(.horizontal, metrics.padding + 8)
                }
            }
            .overlay(alignment: .bottom) {
                if metrics.showZoneLabels {
                    boardZoneLabels(top: false)
                        .padding(.bottom, metrics.padding + 2)
                        .padding(.horizontal, metrics.padding + 8)
                }
            }
            .overlayPreferenceValue(PointFramePreferenceKey.self) { anchors in
                GeometryReader { proxy in
                    ForEach(anchors.keys.sorted(), id: \.self) { point in
                        if let anchor = anchors[point],
                           let highlight = pointHighlightStyle(for: point) {
                            let rect = proxy[anchor]
                            RoundedRectangle(cornerRadius: 7)
                                .strokeBorder(highlight.color, lineWidth: highlight.width)
                                .frame(width: rect.width, height: rect.height)
                                .position(x: rect.midX, y: rect.midY)
                        }
                    }
                }
                .allowsHitTesting(false)
            }
        }
        .frame(width: metrics.boardWidth, height: metrics.boardHeight)
    }

    private func classicBoardMetrics(for availableSize: CGSize) -> ClassicBoardMetrics {
        let boardWidth = alignToPixel(max(220, availableSize.width))
        let boardHeight = alignToPixel(max(220, availableSize.height))
        let showZoneLabels = verticalSizeClass == .compact

        let padding: CGFloat = showZoneLabels ? 8 : 6
        let rowSpacing: CGFloat = 2
        let pointSpacing: CGFloat = 2
        let sectionSpacing: CGFloat = 2

        let innerHeight = max(160, boardHeight - (padding * 2))
        let middleLaneHeight = alignToPixel(max(24, min(34, innerHeight * 0.10)))
        let rowHeight = alignToPixel(max(42, (innerHeight - middleLaneHeight - (rowSpacing * 2)) / 2))

        let innerWidth = max(220, boardWidth - (padding * 2))
        let barWidth = alignToPixel(max(30, min(40, innerWidth * 0.068)))
        let offTrayWidth = alignToPixel(max(22, min(30, innerWidth * 0.050)))
        let mirrorWidth = offTrayWidth

        let pointAreaWidth = max(
            120,
            innerWidth
                - mirrorWidth
                - barWidth
                - offTrayWidth
                - (sectionSpacing * 4)
        )
        let halfWidth = alignToPixel(pointAreaWidth / 2)
        let pointWidth = alignToPixel(max(12, (halfWidth - (pointSpacing * 5)) / 6))

        return ClassicBoardMetrics(
            boardWidth: boardWidth,
            boardHeight: boardHeight,
            padding: padding,
            rowSpacing: rowSpacing,
            pointSpacing: pointSpacing,
            sectionSpacing: sectionSpacing,
            middleLaneHeight: middleLaneHeight,
            barWidth: barWidth,
            offTrayWidth: offTrayWidth,
            mirrorWidth: mirrorWidth,
            halfWidth: halfWidth,
            pointWidth: pointWidth,
            rowHeight: rowHeight,
            showZoneLabels: showZoneLabels
        )
    }

    private var boardCardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(red: 0.09, green: 0.11, blue: 0.16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
            )
    }

    private func boardZoneLabels(top: Bool) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Outfield")
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                Text(top ? "13-18" : "12-7")
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .foregroundStyle(.white.opacity(0.58))

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text(top ? "Home Black" : "Home White")
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                Text(top ? "19-24" : "6-1")
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .foregroundStyle(.white.opacity(0.58))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(Color.black.opacity(0.12), in: Capsule())
        .clipShape(Capsule())
    }

    private func classicMiddleLane(height: CGFloat, middleBarWidth: CGFloat) -> some View {
        HStack(spacing: 6) {
            playerDiceZone(for: .black)
                .frame(maxWidth: .infinity, alignment: .leading)

            barSpineControl(height: height, width: middleBarWidth)

            playerDiceZone(for: .white)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(height: height)
    }

    private func pointGridModern(
        _ points: [Int],
        cellHeight: CGFloat,
        stackDirection: PointStackDirection
    ) -> some View {
        HStack(spacing: 5) {
            pointRowGroup(points, cellHeight: cellHeight, stackDirection: stackDirection)
        }
    }

    private func pointGridClassic(
        _ points: [Int],
        rowHeight: CGFloat,
        row: BoardRow,
        pointWidth: CGFloat,
        pointSpacing: CGFloat,
        sectionSpacing: CGFloat,
        middleBarWidth: CGFloat,
        offTrayColor: CheckerColor,
        offTrayWidth: CGFloat,
        mirrorWidth: CGFloat
    ) -> some View {
        let leftHalf = Array(points.prefix(6))
        let rightHalf = Array(points.suffix(6))
        let halfWidth = alignToPixel((pointWidth * 6) + (pointSpacing * 5))

        return HStack(spacing: sectionSpacing) {
            Color.clear
                .frame(width: mirrorWidth, height: rowHeight)
            classicPointRowGroup(
                leftHalf,
                row: row,
                rowHeight: rowHeight,
                pointWidth: pointWidth,
                pointSpacing: pointSpacing
            )
            .frame(width: halfWidth, height: rowHeight)
            middleBarLane(height: rowHeight, width: middleBarWidth, showLabel: false)
            classicPointRowGroup(
                rightHalf,
                row: row,
                rowHeight: rowHeight,
                pointWidth: pointWidth,
                pointSpacing: pointSpacing
            )
            .frame(width: halfWidth, height: rowHeight)
            offTrayControl(for: offTrayColor)
                .frame(width: offTrayWidth, height: rowHeight)
        }
        .frame(height: rowHeight)
        .clipped()
    }

    private func classicPointRowGroup(
        _ points: [Int],
        row: BoardRow,
        rowHeight: CGFloat,
        pointWidth: CGFloat,
        pointSpacing: CGFloat
    ) -> some View {
        HStack(spacing: pointSpacing) {
            ForEach(Array(points.enumerated()), id: \.element) { index, point in
                Button {
                    viewModel.tapPoint(point)
                } label: {
                    classicPointCell(
                        point,
                        row: row,
                        rowHeight: rowHeight,
                        pointWidth: pointWidth,
                        triangleIndex: index
                    )
                }
                .buttonStyle(.plain)
                .frame(width: pointWidth, height: rowHeight)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: rowHeight, alignment: .center)
    }

    private func classicPointCell(
        _ point: Int,
        row: BoardRow,
        rowHeight: CGFloat,
        pointWidth: CGFloat,
        triangleIndex: Int
    ) -> some View {
        let count = viewModel.pointCheckerCount(point)
        let checkerColor = viewModel.pointCheckerColor(point)
        let isDestination = viewModel.gameplaySettings.highlightLegalMoves && viewModel.legalDestinations.contains(point)
        let destinationHints = viewModel.destinationDiceHints(for: point)
        let checkerSize = min(24, max(10, min(pointWidth * 0.84, rowHeight * 0.22)))
        let maxVisible = rowHeight > 160 ? 7 : (rowHeight > 120 ? 6 : 5)
        let visibleCheckers = min(maxVisible, count)
        let isDarkTriangle = triangleIndex.isMultiple(of: 2)
        let triangleFill = isDarkTriangle
            ? Color(red: 0.16, green: 0.21, blue: 0.33)
            : Color(red: 0.79, green: 0.71, blue: 0.54).opacity(0.84)

        return ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(Color.white.opacity(0.03))
                .frame(height: rowHeight)

            BackgammonTriangleShape(pointsDownward: row == .top)
                .fill(triangleFill)
                .padding(.horizontal, 1.5)
                .padding(.vertical, 2)
                .frame(height: rowHeight)

            VStack(spacing: 0) {
                if row == .top {
                    pointNumberBadge(point)
                        .padding(.top, 3)
                }

                Spacer(minLength: 0)

                classicCheckerStack(
                    count: count,
                    checkerColor: checkerColor,
                    checkerSize: checkerSize,
                    visibleCheckers: visibleCheckers,
                    row: row
                )
                .frame(maxHeight: .infinity)

                if row == .bottom {
                    pointNumberBadge(point)
                        .padding(.bottom, 3)
                }
            }
            .frame(maxHeight: .infinity)

            if isDestination, !destinationHints.isEmpty {
                destinationDiceBadge(destinationHints, row: row)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .anchorPreference(key: PointFramePreferenceKey.self, value: .bounds) { [point: $0] }
    }

    private func classicCheckerStack(
        count: Int,
        checkerColor: CheckerColor?,
        checkerSize: CGFloat,
        visibleCheckers: Int,
        row: BoardRow
    ) -> some View {
        let spacing = -checkerSize * 0.16

        return VStack(spacing: spacing) {
            if row == .bottom {
                Spacer(minLength: 0)
            }

            if count > visibleCheckers {
                overflowCountBadge(count - visibleCheckers)
                    .padding(.bottom, row == .top ? 2 : 0)
                    .padding(.top, row == .bottom ? 2 : 0)
            }

            ForEach(0..<visibleCheckers, id: \.self) { _ in
                Circle()
                    .fill(checkerFill(for: checkerColor))
                    .frame(width: checkerSize, height: checkerSize)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.36), lineWidth: 0.8)
                    )
                    .shadow(color: .black.opacity(0.32), radius: 1.8, y: 0.8)
            }

            if row == .top {
                Spacer(minLength: 0)
            }
        }
        .padding(.vertical, 6)
    }

    private func middleBarLane(height: CGFloat, width: CGFloat, showLabel: Bool) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.48),
                        Color.black.opacity(0.28)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.white.opacity(0.22), lineWidth: 1.2)
            )
            .overlay {
                Rectangle()
                    .fill(Color.white.opacity(0.14))
                    .frame(width: 1)
            }
            .overlay {
                if showLabel {
                    Text("BAR")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.58))
                        .rotationEffect(.degrees(-90))
                }
            }
            .frame(width: width, height: height)
    }

    private func pointRowGroup(
        _ points: [Int],
        cellHeight: CGFloat,
        stackDirection: PointStackDirection
    ) -> some View {
        GeometryReader { rowProxy in
            let spacing: CGFloat = 5
            let totalSpacing = spacing * CGFloat(max(points.count - 1, 0))
            let pointWidth = alignToPixel(max(12, (rowProxy.size.width - totalSpacing) / CGFloat(max(points.count, 1))))

            HStack(spacing: spacing) {
                ForEach(points, id: \.self) { point in
                    Button {
                        viewModel.tapPoint(point)
                    } label: {
                        pointCell(point, cellHeight: cellHeight, stackDirection: stackDirection)
                    }
                    .buttonStyle(.plain)
                    .frame(width: pointWidth, height: cellHeight)
                }
            }
        }
        .frame(height: cellHeight)
    }

    private func pointCell(
        _ point: Int,
        cellHeight: CGFloat,
        stackDirection: PointStackDirection
    ) -> some View {
        let count = viewModel.pointCheckerCount(point)
        let checkerColor = viewModel.pointCheckerColor(point)
        let isOrigin = viewModel.gameplaySettings.highlightLegalMoves && viewModel.legalOrigins.contains(.point(point))
        let isDestination = viewModel.gameplaySettings.highlightLegalMoves && viewModel.legalDestinations.contains(point)
        let isSelected = viewModel.selectedOrigin == .point(point)
        let isRecentFrom = viewModel.lastMove?.fromPoint == point
        let isRecentTo = viewModel.lastMove?.toPoint == point
        let checkerSize = min(14, max(10, cellHeight * 0.16))
        let maxVisible = cellHeight > 110 ? 6 : (cellHeight > 85 ? 5 : 4)
        let visibleCheckers = min(maxVisible, count)

        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    pointBackground(
                        isOrigin: isOrigin,
                        isDestination: isDestination,
                        isSelected: isSelected,
                        isRecentFrom: isRecentFrom,
                        isRecentTo: isRecentTo
                    )
                )
                .frame(height: cellHeight)

            Text("\(point)")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.8))
                .padding(.leading, 5)
                .padding(.top, 4)

            checkerStack(
                count: count,
                checkerColor: checkerColor,
                checkerSize: checkerSize,
                visibleCheckers: visibleCheckers,
                stackDirection: stackDirection
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func checkerStack(
        count: Int,
        checkerColor: CheckerColor?,
        checkerSize: CGFloat,
        visibleCheckers: Int,
        stackDirection: PointStackDirection
    ) -> some View {
        VStack(spacing: checkerSize < 12 ? 2 : 3) {
            if stackDirection == .upward {
                Spacer(minLength: 0)
            }

            if count > visibleCheckers {
                overflowCountBadge(count - visibleCheckers)
            }

            ForEach(0..<visibleCheckers, id: \.self) { _ in
                Circle()
                    .fill(checkerFill(for: checkerColor))
                    .frame(width: checkerSize, height: checkerSize)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.22), lineWidth: 0.7)
                    )
            }

            if stackDirection == .downward {
                Spacer(minLength: 0)
            }
        }
        .padding(.top, stackDirection == .downward ? 18 : 4)
        .padding(.bottom, stackDirection == .upward ? 8 : 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func barSpineControl(height: CGFloat, width: CGFloat) -> some View {
        let isActive = viewModel.gameplaySettings.highlightLegalMoves && viewModel.legalOrigins.contains(.bar)
        let isSelected = viewModel.selectedOrigin == .bar
        let isRecent = viewModel.lastMove?.fromPoint == nil

        return Button {
            viewModel.tapBarOrigin()
        } label: {
            VStack(spacing: 3) {
                barCounterBadge(count: viewModel.blackBar, checkerColor: .black)
                Text("BAR")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.86))
                    .rotationEffect(.degrees(-90))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: true)
                barCounterBadge(count: viewModel.whiteBar, checkerColor: .white)
            }
            .frame(width: width, height: height)
            .background(
                (isSelected || isActive ? Color.orange.opacity(0.34) : Color.black.opacity(0.45)),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isSelected || isActive
                        ? Color.orange.opacity(0.92)
                        : (isRecent ? Color.cyan.opacity(0.78) : Color.white.opacity(0.15)),
                        lineWidth: isSelected || isActive ? 1.6 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func offTrayControl(for color: CheckerColor) -> some View {
        let offCount = boardOffCount(for: color)
        let isHumanTray = color == .white
        let isActive = isHumanTray
            && viewModel.gameplaySettings.highlightLegalMoves
            && viewModel.legalDestinations.contains(nil)
        let isRecent = isHumanTray && viewModel.lastMove?.toPoint == nil
        let destinationHints = viewModel.destinationDiceHints(for: nil)

        return Button {
            guard isHumanTray else { return }
            viewModel.tapBearOffDestination()
        } label: {
            VStack(spacing: 4) {
                Text("OFF")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
                if isActive, !destinationHints.isEmpty {
                    Text(destinationHints.prefix(2).map(String.init).joined(separator: "/"))
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.95))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.green.opacity(0.8), in: Capsule())
                }
                miniCounterCheckers(count: offCount, checkerColor: color)
                Text("\(offCount)")
                    .font(.system(size: 10, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                isActive ? Color.green.opacity(0.32) : Color.white.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        isActive
                        ? Color.green.opacity(0.88)
                        : (isRecent ? Color.cyan.opacity(0.78) : Color.white.opacity(0.14)),
                        lineWidth: isActive ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func boardOffCount(for color: CheckerColor) -> Int {
        switch color {
        case .white:
            return viewModel.whiteOff
        case .black:
            return viewModel.blackOff
        }
    }

    private func playerDiceZone(for color: CheckerColor) -> some View {
        let values = viewModel.remainingDice(for: color)
        return HStack(spacing: 4) {
            if values.isEmpty {
                Text("–")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55))
            } else {
                ForEach(Array(values.enumerated()), id: \.offset) { _, die in
                    diePill(value: die, color: color)
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.white.opacity(0.06), in: Capsule())
    }

    private func diePill(value: Int, color: CheckerColor) -> some View {
        let fillColor = color == .white ? Color.white.opacity(0.93) : Color(red: 0.09, green: 0.12, blue: 0.20)
        let textColor = color == .white ? Color.black.opacity(0.85) : Color.white.opacity(0.96)
        return Text("\(value)")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(textColor)
            .monospacedDigit()
            .frame(width: 18, height: 18)
            .background(fillColor, in: RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.white.opacity(color == .white ? 0.22 : 0.32), lineWidth: 0.8)
            )
    }

    // Kept for modern board compatibility.
    private var barControl: some View {
        barSpineControl(height: 66, width: 34)
    }

    // Kept for modern board compatibility.
    private var bearOffControl: some View {
        offTrayControl(for: .white)
    }

    private var diceStrip: some View {
        HStack(spacing: 6) {
            if viewModel.remainingDice.isEmpty {
                Text("--")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            } else {
                ForEach(Array(viewModel.remainingDice.enumerated()), id: \.offset) { _, die in
                    Text("\(die)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.blue.opacity(0.8), in: RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var quickChatSheet: some View {
        NavigationStack {
            ZStack {
                backgroundLayer
                VStack(spacing: 12) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                if chatHistory.isEmpty {
                                    Text("No messages yet. Send a quick chat below.")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.62))
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.top, 20)
                                } else {
                                    ForEach(chatHistory) { entry in
                                        VStack(alignment: .trailing, spacing: 3) {
                            Text(entry.text)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 9)
                                                .background(
                                                    Color.blue.opacity(0.74),
                                                    in: RoundedRectangle(cornerRadius: 14)
                                                )

                                            HStack(spacing: 5) {
                                                Text(chatTimestamp(for: entry.createdAt))
                                                    .font(.caption2)
                                                    .foregroundStyle(.white.opacity(0.6))
                                                Label(
                                                    entry.delivery == .sent ? "Sent" : "Sending",
                                                    systemImage: entry.delivery == .sent ? "checkmark.circle.fill" : "clock"
                                                )
                                                .font(.caption2.weight(.semibold))
                                                .foregroundStyle(
                                                    entry.delivery == .sent
                                                    ? Color.green.opacity(0.9)
                                                    : .white.opacity(0.58)
                                                )
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                        .id(entry.id)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                            .padding(.bottom, 4)
                        }
                        .onChange(of: chatHistory.count) { _, _ in
                            if let last = chatHistory.last {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                        ForEach(QuickChatMessage.allCases, id: \.self) { message in
                            Button {
                                sendQuickChat(message.rawValue)
                                Haptics.selection()
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
                    Button("Done") {
                        showQuickChatSheet = false
                    }
                }
#endif
            }
        }
#if os(iOS)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
#endif
    }

    private var landscapeActionDock: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.undoLastHumanMove()
            } label: {
                Label("Undo", systemImage: "arrow.uturn.backward")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(viewModel.canUndoLastMove ? .white : .white.opacity(0.64))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        viewModel.canUndoLastMove ? Color.white.opacity(0.18) : Color.white.opacity(0.14),
                        in: Capsule()
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(viewModel.canUndoLastMove ? 0.18 : 0.28), lineWidth: 0.9)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canUndoLastMove)

            if viewModel.canRoll && viewModel.isHumanTurn {
                Button {
                    viewModel.rollDiceIfNeeded()
                } label: {
                    Label("Roll Dice", systemImage: "dice")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color(red: 0.10, green: 0.45, blue: 0.92), in: Capsule())
                }
                .buttonStyle(.plain)
            } else if viewModel.isHumanTurn {
                Text("Your move")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.88))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.10), in: Capsule())
            } else {
                Text("AI")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.82))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.10), in: Capsule())
            }

            Spacer(minLength: 4)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.24), in: Capsule())
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var landscapeTopControls: some View {
        HStack(spacing: 8) {
            Menu {
                matchMenuContent
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.08), in: Circle())
            }
            .accessibilityLabel("Match options")

            Button {
                showQuickChatSheet = true
            } label: {
                Image(systemName: "message")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.08), in: Circle())
            }
            .accessibilityLabel("Open quick chat")

            Button(role: .destructive) {
                showLeaveMatchConfirmation = true
            } label: {
                Image(systemName: "house.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.08), in: Circle())
            }
            .accessibilityLabel("Leave match")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.28), in: Capsule())
    }

    private var bottomDock: some View {
        actionDock
            .padding(.horizontal, 1)
            .padding(.bottom, 1)
    }

    private var actionDock: some View {
        if isFocusModeEnabled {
            return AnyView(focusActionDock)
        }
        return AnyView(expandedActionDock)
    }

    private var focusActionDock: some View {
        HStack(spacing: 8) {
            Button {
                viewModel.undoLastHumanMove()
            } label: {
                Label("Undo", systemImage: "arrow.uturn.backward")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        viewModel.canUndoLastMove
                        ? Color.white.opacity(0.15)
                        : Color.white.opacity(0.14),
                        in: Capsule()
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(viewModel.canUndoLastMove ? 0.16 : 0.28), lineWidth: 0.9)
                    )
                    .foregroundStyle(viewModel.canUndoLastMove ? .white : .white.opacity(0.64))
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canUndoLastMove)

            if viewModel.canRoll && viewModel.isHumanTurn {
                Button {
                    viewModel.rollDiceIfNeeded()
                } label: {
                    Label("Roll", systemImage: "dice")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.10, green: 0.45, blue: 0.92), in: Capsule())
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            } else if viewModel.isHumanTurn {
                Label("Your move", systemImage: "hand.tap")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
            } else {
                Label("AI is moving...", systemImage: "cpu")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(1)
            }

            Spacer(minLength: 8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 14))
    }

    private var expandedActionDock: some View {
        HStack(spacing: 10) {
            Button {
                viewModel.undoLastHumanMove()
            } label: {
                Label("Undo", systemImage: "arrow.uturn.backward")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 100, height: 44)
                    .background(
                        viewModel.canUndoLastMove
                        ? Color.white.opacity(0.16)
                        : Color.white.opacity(0.14),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(viewModel.canUndoLastMove ? 0.16 : 0.28), lineWidth: 0.9)
                    )
                    .foregroundStyle(viewModel.canUndoLastMove ? .white : .white.opacity(0.64))
            }
            .disabled(!viewModel.canUndoLastMove)

            if viewModel.canRoll && viewModel.isHumanTurn {
                Button {
                    viewModel.rollDiceIfNeeded()
                } label: {
                    Label("Roll Dice", systemImage: "dice")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Color(red: 0.10, green: 0.45, blue: 0.92),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .foregroundStyle(.white)
                }
            } else if viewModel.isHumanTurn {
                Label("Your move", systemImage: "hand.tap")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.11), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white.opacity(0.9))
            } else {
                Label("AI is moving...", systemImage: "cpu")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.11), in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white.opacity(0.82))
            }
        }
    }

    private var selectedOriginLabel: String? {
        guard let origin = viewModel.selectedOrigin else {
            return nil
        }
        switch origin {
        case let .point(point):
            return "\(point)"
        case .bar:
            return "Bar"
        }
    }

    private var pipLeadLabel: String {
        let white = viewModel.whitePips
        let black = viewModel.blackPips
        if white == black {
            return "Race even"
        }
        if white < black {
            return "White +\(black - white)"
        }
        return "Black +\(white - black)"
    }

    private var pipRaceSummary: String {
        "Pip race: \(pipLeadLabel) (lower is better)"
    }

    private var statusRibbonDetail: String {
        var chunks: [String] = []
        if let roll = viewModel.roll {
            chunks.append("Dice \(roll.first)-\(roll.second)")
        }
        let cleanStatus = viewModel.statusText
            .replacingOccurrences(of: ".", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanStatus.isEmpty && cleanStatus != viewModel.turnHint {
            chunks.append(cleanStatus)
        }
        return chunks.joined(separator: " · ")
    }

    private func confirmLeaveMatch() {
        showQuickChatSheet = false
        isHUDVisible = false
        isFocusModeEnabled = true
        viewModel.abandonAndResetMatch()
        dismiss()
    }

    private func sendQuickChat(_ text: String) {
        let pending = ChatEntry(
            text: text,
            createdAt: Date(),
            delivery: .sending
        )
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

    private func miniCounterCheckers(count: Int, checkerColor: CheckerColor) -> some View {
        let visible = min(count, 5)
        return HStack(spacing: 2) {
            ForEach(0..<visible, id: \.self) { _ in
                Circle()
                    .fill(checkerColor == .white ? Color.white : Color(red: 0.12, green: 0.14, blue: 0.18))
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
            }
            if count > visible {
                Text("+\(count - visible)")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
        .frame(height: 10)
    }

    private func barCounterBadge(count: Int, checkerColor: CheckerColor) -> some View {
        VStack(spacing: 1) {
            Circle()
                .fill(checkerColor == .white ? Color.white : Color(red: 0.10, green: 0.12, blue: 0.16))
                .frame(width: 10, height: 10)
                .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 0.7))

            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 7, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(Color.black.opacity(0.42), in: Capsule())
            }
        }
        .frame(width: 20, height: 18)
    }

    private func pointNumberBadge(_ point: Int) -> some View {
        Text("\(point)")
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.92))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(1)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color.black.opacity(0.24), in: Capsule())
    }

    private func overflowCountBadge(_ overflow: Int) -> some View {
        Text(overflow > 99 ? "99+" : "\(overflow)")
            .font(.system(size: 8, weight: .black, design: .rounded))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(1)
            .foregroundStyle(.white.opacity(0.95))
            .padding(.horizontal, overflow > 9 ? 4 : 3)
            .padding(.vertical, 2)
            .background(Color.black.opacity(0.52), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.38), lineWidth: 0.7)
            )
            .fixedSize(horizontal: true, vertical: true)
    }

    private func destinationDiceBadge(_ values: [Int], row: BoardRow) -> some View {
        let preview = values.prefix(2).map(String.init).joined(separator: "/")
        return Text(preview)
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(Color.white.opacity(0.95))
            .lineLimit(1)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color.green.opacity(0.82), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.55), lineWidth: 0.8)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: row == .top ? .bottomTrailing : .topTrailing)
            .padding(.trailing, 3)
            .padding(row == .top ? .bottom : .top, 18)
    }

    private func pointHighlightStyle(for point: Int) -> (color: Color, width: CGFloat)? {
        let isOrigin = viewModel.gameplaySettings.highlightLegalMoves && viewModel.legalOrigins.contains(.point(point))
        let isDestination = viewModel.gameplaySettings.highlightLegalMoves && viewModel.legalDestinations.contains(point)
        let isSelected = viewModel.selectedOrigin == .point(point)
        let isRecentFrom = viewModel.lastMove?.fromPoint == point
        let isRecentTo = viewModel.lastMove?.toPoint == point
        guard isOrigin || isDestination || isSelected || isRecentFrom || isRecentTo else {
            return nil
        }
        let color = highlightStrokeColor(
            isOrigin: isOrigin,
            isDestination: isDestination,
            isSelected: isSelected,
            isRecentFrom: isRecentFrom,
            isRecentTo: isRecentTo
        )
        return (color: color, width: isSelected || isDestination ? 2.0 : 1.8)
    }

    private func alignToPixel(_ value: CGFloat) -> CGFloat {
        guard displayScale > 0 else { return value }
        return (value * displayScale).rounded(.toNearestOrAwayFromZero) / displayScale
    }

    private func checkerFill(for color: CheckerColor?) -> Color {
        guard let color else {
            return Color.clear
        }
        switch color {
        case .white:
            return Color.white
        case .black:
            return Color(red: 0.03, green: 0.05, blue: 0.08)
        }
    }

    private func highlightStrokeColor(
        isOrigin: Bool,
        isDestination: Bool,
        isSelected: Bool,
        isRecentFrom: Bool,
        isRecentTo: Bool
    ) -> Color {
        if isSelected {
            return Color.blue.opacity(0.95)
        }
        if isDestination {
            return Color.green.opacity(0.9)
        }
        if isOrigin {
            return Color.orange.opacity(0.9)
        }
        if isRecentTo || isRecentFrom {
            return Color.cyan.opacity(0.82)
        }
        return .clear
    }

    private func pointBackground(
        isOrigin: Bool,
        isDestination: Bool,
        isSelected: Bool,
        isRecentFrom: Bool,
        isRecentTo: Bool
    ) -> Color {
        if isSelected {
            return Color.blue.opacity(0.75)
        }
        if isRecentTo {
            return Color.cyan.opacity(0.40)
        }
        if isRecentFrom {
            return Color.cyan.opacity(0.22)
        }
        if isDestination {
            return Color.green.opacity(0.65)
        }
        if isOrigin {
            return Color.orange.opacity(0.68)
        }
        return Color.white.opacity(0.08)
    }
}

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

private struct PointFramePreferenceKey: PreferenceKey {
    static let defaultValue: [Int: Anchor<CGRect>] = [:]

    static func reduce(value: inout [Int: Anchor<CGRect>], nextValue: () -> [Int: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

private extension BoardOrientation {
    var uiTitle: String {
        switch self {
        case .auto:
            return "Auto"
        case .portrait:
            return "Portrait"
        case .landscape:
            return "Landscape"
        }
    }
}

private extension BoardVisualStyle {
    var uiTitle: String {
        switch self {
        case .modern:
            return "Modern"
        case .classic:
            return "Classic"
        }
    }
}

private extension View {
    func sectionCard() -> some View {
        padding(11)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
    }
}

private enum Haptics {
    static func selection() {
#if canImport(UIKit)
        Task { @MainActor in
            UISelectionFeedbackGenerator().selectionChanged()
        }
#endif
    }
}

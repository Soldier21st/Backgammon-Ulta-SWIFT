import SwiftUI
import BackgammonUltraCore
#if canImport(UIKit)
import UIKit
#endif

public struct BackgammonUltraShellView: View {
    @StateObject private var store = AppExperienceStore()
    @State private var selectedTab: AppTab = .play

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                PlayHubView(store: store)
            }
            .tabItem {
                Label("Play", systemImage: "gamecontroller")
            }
            .tag(AppTab.play)

            NavigationStack {
                CompeteHubView(store: store)
            }
            .tabItem {
                Label("Compete", systemImage: "trophy")
            }
            .tag(AppTab.compete)

            NavigationStack {
                SocialHubView(store: store)
            }
            .tabItem {
                Label("Social", systemImage: "person.2")
            }
            .tag(AppTab.social)

            NavigationStack {
                ProfileHubView(store: store)
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
            .tag(AppTab.profile)

            NavigationStack {
                StoreHubView(store: store)
            }
            .tabItem {
                Label("Store", systemImage: "bag")
            }
            .tag(AppTab.store)
        }
        .tint(UltraPalette.accent)
    }
}

private enum AppTab: Hashable {
    case play
    case compete
    case social
    case profile
    case store
}

private enum HomeModal: String, Identifiable {
    case stats
    case leaderboard
    case tutorial
    case design

    var id: String { rawValue }
}

private enum LeaderboardMetric: String, CaseIterable, Identifiable {
    case rating
    case seasonPoints
    case dailyPoints

    var id: Self { self }

    var title: String {
        switch self {
        case .rating:
            return "Rating"
        case .seasonPoints:
            return "Punkte"
        case .dailyPoints:
            return "Tagespunkte"
        }
    }
}

private struct LeaderboardRow: Identifiable, Hashable {
    let id = UUID()
    let rank: Int
    let username: String
    let countryCode: String
    let score: Int
    let wins: Int
    let losses: Int
    let delta: Int
    let isCurrentUser: Bool

    var record: String { "\(wins)-\(losses)" }
}

private struct AchievementBadge: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let progress: String
    let symbol: String
}

private struct StoreItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let rarity: String
    let price: String
}

private struct TutorialSlide: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let body: String
    let symbol: String
}

private struct DesignThemeOption: Identifiable {
    let id: Int
    let name: String
    let boardBase: Color
    let boardAccent: Color
}

private struct DesignCheckerOption: Identifiable {
    let id: Int
    let light: Color
    let dark: Color
}

@MainActor
private final class AppExperienceStore: ObservableObject {
    @Published var gameplaySettings: GameplaySettings
    @Published var voiceChatEnabled: Bool
    @Published var quickChatEnabled: Bool
    @Published var emojiReactionsEnabled: Bool
    @Published var preferredAILevel: AILevel
    @Published var selectedLeaderboardMetric: LeaderboardMetric
    @Published var premiumUnlocked: Bool

    @Published var selectedDesignThemeID: Int
    @Published var selectedCheckerStyleID: Int
    @Published var designShowPointNumbers: Bool
    @Published var designBoardFlipped: Bool
    @Published var tutorialPageIndex: Int

    @Published var showTwoDicePairs: Bool
    @Published var showRating: Bool
    @Published var oneClickMoveEnabled: Bool
    @Published var hintsEnabled: Bool
    @Published var dailyBonusX2Enabled: Bool

    @Published var profile: PlayerProfile
    let season: Season
    let achievements: [AchievementBadge]
    @Published var matchHistory: [MatchHistoryEntry]
    let cosmetics: [StoreItem]
    let tutorialSlides: [TutorialSlide]
    let appVersionLabel: String

    let designThemeOptions: [DesignThemeOption]
    let designCheckerOptions: [DesignCheckerOption]

    private let leaderboardByMetric: [LeaderboardMetric: [LeaderboardRow]]

    init() {
        self.gameplaySettings = .init()
        self.voiceChatEnabled = true
        self.quickChatEnabled = true
        self.emojiReactionsEnabled = true
        self.preferredAILevel = .advanced
        self.selectedLeaderboardMetric = .rating
        self.premiumUnlocked = false

        self.selectedDesignThemeID = 0
        self.selectedCheckerStyleID = 0
        self.designShowPointNumbers = true
        self.designBoardFlipped = false
        self.tutorialPageIndex = 0

        self.showTwoDicePairs = true
        self.showRating = true
        self.oneClickMoveEnabled = true
        self.hintsEnabled = true
        self.dailyBonusX2Enabled = true

        let now = Date()
        let calendar = Calendar.current
        let startsAt = calendar.date(byAdding: .day, value: -19, to: now) ?? now
        let endsAt = calendar.date(byAdding: .day, value: 11, to: now) ?? now

        self.profile = PlayerProfile(
            username: "Aledo0001",
            countryCode: "DE",
            ranking: 1546,
            winRate: 0.59,
            matchesPlayed: 4166
        )

        self.season = Season(
            name: "Season 04",
            startsAt: startsAt,
            endsAt: endsAt
        )

        self.achievements = [
            AchievementBadge(title: "Hot Streak", progress: "8/10", symbol: "flame.fill"),
            AchievementBadge(title: "Veteran", progress: "82/100", symbol: "shield.checkered"),
            AchievementBadge(title: "Cube Master", progress: "14/25", symbol: "cube.fill"),
            AchievementBadge(title: "Tactician", progress: "36/50", symbol: "brain.head.profile")
        ]

        self.matchHistory = [
            MatchHistoryEntry(opponentUsername: "Dr Long Legs", mode: .rankedOnline, outcome: .win, ratingDelta: 14),
            MatchHistoryEntry(opponentUsername: "Jonny76", mode: .rankedOnline, outcome: .loss, ratingDelta: -11),
            MatchHistoryEntry(opponentUsername: "NervoAdirato6", mode: .casualOnline, outcome: .win, ratingDelta: 0),
            MatchHistoryEntry(opponentUsername: "Eman", mode: .playWithFriends, outcome: .win, ratingDelta: 0),
            MatchHistoryEntry(opponentUsername: "pooppee69420", mode: .rankedOnline, outcome: .loss, ratingDelta: -13)
        ]

        self.cosmetics = [
            StoreItem(name: "Obsidian Board", rarity: "Epic", price: "$4.99"),
            StoreItem(name: "Nordic Marble", rarity: "Rare", price: "$2.99"),
            StoreItem(name: "Graphite Pieces", rarity: "Common", price: "$1.49"),
            StoreItem(name: "Aurora Dice", rarity: "Epic", price: "$3.49")
        ]

        self.tutorialSlides = [
            TutorialSlide(title: "Willkommen", body: "Spiele Solo, lokal zu zweit oder online. Starte mit Solo für den sauberen Flow.", symbol: "sparkles"),
            TutorialSlide(title: "Solo-Stufen", body: "10 AI-Stufen von Beginner bis Champion. Neue Stufen werden durch Siege freigeschaltet.", symbol: "trophy.fill"),
            TutorialSlide(title: "Board Layout", body: "Das Brett hat 24 Punkte, eine Mittel-Bar und zwei Ausspiel-Trays. Mit Classic View siehst du Home-, Outfield- und Bar-Struktur klar getrennt.", symbol: "rectangle.split.2x1"),
            TutorialSlide(title: "Grundregeln", body: "Zugrichtung beachten, schlagen auf Blots, geschlagene Steine kommen auf die Bar.", symbol: "dice.fill"),
            TutorialSlide(title: "Bearing Off", body: "Sobald alle Steine im Heimfeld sind, kannst du korrekt auswürfeln und das Match beenden.", symbol: "flag.checkered"),
            TutorialSlide(title: "Pip Counting", body: "Pips messen die Renndistanz. Weniger Pips heißt Vorteil im Race. Du kannst Pip-Counting in den Einstellungen ein- oder ausblenden.", symbol: "number.circle.fill"),
            TutorialSlide(title: "Verdopplungswürfel", body: "Optional aktivierbar. Werte 2, 4, 8, 16, 32, 64. Ein Double wird vor dem Würfeln angeboten.", symbol: "square.stack.3d.up.fill"),
            TutorialSlide(title: "Tipps", body: "One-Click-Moves und legale Highlights machen den Zugablauf schneller und klarer.", symbol: "lightbulb.fill")
        ]

        self.appVersionLabel = "Backgammon v3.7.7"

        self.designThemeOptions = [
            DesignThemeOption(id: 0, name: "Graphite", boardBase: Color(red: 0.08, green: 0.11, blue: 0.16), boardAccent: Color(red: 0.18, green: 0.23, blue: 0.33)),
            DesignThemeOption(id: 1, name: "Walnut", boardBase: Color(red: 0.28, green: 0.18, blue: 0.10), boardAccent: Color(red: 0.43, green: 0.29, blue: 0.16)),
            DesignThemeOption(id: 2, name: "Slate", boardBase: Color(red: 0.10, green: 0.13, blue: 0.20), boardAccent: Color(red: 0.22, green: 0.30, blue: 0.47)),
            DesignThemeOption(id: 3, name: "Midnight", boardBase: Color(red: 0.06, green: 0.09, blue: 0.14), boardAccent: Color(red: 0.15, green: 0.22, blue: 0.33)),
            DesignThemeOption(id: 4, name: "Emerald", boardBase: Color(red: 0.06, green: 0.16, blue: 0.16), boardAccent: Color(red: 0.17, green: 0.30, blue: 0.28))
        ]

        self.designCheckerOptions = [
            DesignCheckerOption(id: 0, light: .white, dark: Color(red: 0.11, green: 0.14, blue: 0.19)),
            DesignCheckerOption(id: 1, light: Color(red: 0.95, green: 0.90, blue: 0.82), dark: Color(red: 0.25, green: 0.17, blue: 0.13)),
            DesignCheckerOption(id: 2, light: Color(red: 0.91, green: 0.96, blue: 1.0), dark: Color(red: 0.13, green: 0.20, blue: 0.30)),
            DesignCheckerOption(id: 3, light: Color(red: 0.94, green: 0.95, blue: 0.87), dark: Color(red: 0.19, green: 0.25, blue: 0.18)),
            DesignCheckerOption(id: 4, light: Color(red: 0.98, green: 0.90, blue: 0.88), dark: Color(red: 0.30, green: 0.14, blue: 0.14))
        ]

        self.leaderboardByMetric = [
            .rating: [
                LeaderboardRow(rank: 1, username: "Dr Long Legs", countryCode: "US", score: 1746, wins: 68, losses: 24, delta: 19, isCurrentUser: false),
                LeaderboardRow(rank: 2, username: "pooppee69420", countryCode: "GB", score: 1739, wins: 65, losses: 26, delta: 12, isCurrentUser: false),
                LeaderboardRow(rank: 3, username: "TroublesomeGunner", countryCode: "CA", score: 1739, wins: 60, losses: 25, delta: 6, isCurrentUser: false),
                LeaderboardRow(rank: 4, username: "fiedler80", countryCode: "DE", score: 1730, wins: 59, losses: 24, delta: 8, isCurrentUser: false),
                LeaderboardRow(rank: 5, username: "Onana_61", countryCode: "NL", score: 1724, wins: 57, losses: 26, delta: 3, isCurrentUser: false),
                LeaderboardRow(rank: 6, username: "Lutzer83", countryCode: "AT", score: 1718, wins: 56, losses: 28, delta: 2, isCurrentUser: false),
                LeaderboardRow(rank: 782, username: "Aledo0001", countryCode: "DE", score: 1546, wins: 112, losses: 77, delta: 0, isCurrentUser: true)
            ],
            .seasonPoints: [
                LeaderboardRow(rank: 1, username: "ScruffyLapin", countryCode: "IL", score: 4920, wins: 84, losses: 29, delta: 34, isCurrentUser: false),
                LeaderboardRow(rank: 2, username: "Eman", countryCode: "GB", score: 4872, wins: 80, losses: 30, delta: 27, isCurrentUser: false),
                LeaderboardRow(rank: 3, username: "rainbow unicorn dad", countryCode: "US", score: 4851, wins: 81, losses: 34, delta: 21, isCurrentUser: false),
                LeaderboardRow(rank: 4, username: "TM2535", countryCode: "TR", score: 4816, wins: 79, losses: 31, delta: 18, isCurrentUser: false),
                LeaderboardRow(rank: 5, username: "Edward Zakharyan", countryCode: "AM", score: 4788, wins: 78, losses: 34, delta: 13, isCurrentUser: false),
                LeaderboardRow(rank: 438, username: "Aledo0001", countryCode: "DE", score: 4166, wins: 112, losses: 77, delta: 0, isCurrentUser: true)
            ],
            .dailyPoints: [
                LeaderboardRow(rank: 1, username: "moskevuvi", countryCode: "GE", score: 242, wins: 9, losses: 2, delta: 41, isCurrentUser: false),
                LeaderboardRow(rank: 2, username: "cmcnasty", countryCode: "US", score: 231, wins: 8, losses: 2, delta: 30, isCurrentUser: false),
                LeaderboardRow(rank: 3, username: "jannnoify89", countryCode: "SE", score: 228, wins: 8, losses: 3, delta: 27, isCurrentUser: false),
                LeaderboardRow(rank: 4, username: "jonny76", countryCode: "GB", score: 221, wins: 7, losses: 2, delta: 18, isCurrentUser: false),
                LeaderboardRow(rank: 5, username: "NervoAdirato6", countryCode: "IT", score: 214, wins: 7, losses: 3, delta: 12, isCurrentUser: false),
                LeaderboardRow(rank: 91, username: "Aledo0001", countryCode: "DE", score: 136, wins: 5, losses: 3, delta: 0, isCurrentUser: true)
            ]
        ]
    }

    var seasonProgress: Double {
        let total = season.endsAt.timeIntervalSince(season.startsAt)
        guard total > 0 else { return 0.5 }
        let elapsed = Date().timeIntervalSince(season.startsAt)
        return min(max(elapsed / total, 0), 1)
    }

    var seasonDaysRemaining: Int {
        max(Calendar.current.dateComponents([.day], from: Date(), to: season.endsAt).day ?? 0, 0)
    }

    var leaderboardRows: [LeaderboardRow] {
        leaderboardByMetric[selectedLeaderboardMetric] ?? []
    }

    var myLeaderboardRow: LeaderboardRow? {
        leaderboardRows.first(where: { $0.isCurrentUser })
    }

    var countryFlag: String {
        profile.countryCode.flagEmoji
    }

    var winRatePercent: Int {
        Int((profile.winRate * 100).rounded())
    }

    var premiumFeatures: [String] {
        [
            "No ads",
            "Voice chat access",
            "Advanced statistics",
            "Exclusive boards and skins"
        ]
    }

    var dailyChallengeText: String {
        "Win 2 ranked games and finish one game with less than 90 total pips."
    }

    var selectedTheme: DesignThemeOption {
        designThemeOptions.first(where: { $0.id == selectedDesignThemeID }) ?? designThemeOptions[0]
    }

    var selectedCheckerStyle: DesignCheckerOption {
        designCheckerOptions.first(where: { $0.id == selectedCheckerStyleID }) ?? designCheckerOptions[0]
    }

    func gameplayBinding<Value>(_ keyPath: WritableKeyPath<GameplaySettings, Value>) -> Binding<Value> {
        Binding(
            get: { self.gameplaySettings[keyPath: keyPath] },
            set: { newValue in
                self.gameplaySettings[keyPath: keyPath] = newValue
                Haptics.selection()
            }
        )
    }

    func setPreferredAILevel(_ level: AILevel) {
        preferredAILevel = level
        Haptics.selection()
    }

    func setMatchLength(_ length: MatchLength) {
        gameplaySettings.preferredMatchLength = length
        Haptics.selection()
    }

    func togglePremium() {
        premiumUnlocked.toggle()
        Haptics.success()
    }

    func registerSoloMatchCompletion(_ completion: SoloMatchViewModel.MatchCompletion) {
        let previousMatches = max(profile.matchesPlayed, 0)
        let previousWins = min(
            previousMatches,
            max(0, Int((Double(previousMatches) * profile.winRate).rounded()))
        )

        let userWon = completion.winner == .white && !completion.abandoned
        let updatedMatches = previousMatches + 1
        let updatedWins = previousWins + (userWon ? 1 : 0)

        profile.matchesPlayed = updatedMatches
        if updatedMatches > 0 {
            profile.winRate = Double(updatedWins) / Double(updatedMatches)
        }
        profile.ranking += completion.userPointsDelta

        let historyEntry = MatchHistoryEntry(
            opponentUsername: "AI \(preferredAILevel.title)",
            mode: .solo,
            outcome: userWon ? .win : .loss,
            ratingDelta: completion.userPointsDelta
        )
        matchHistory.insert(historyEntry, at: 0)
    }
}

private struct PlayHubView: View {
    @ObservedObject var store: AppExperienceStore
    @State private var activeModal: HomeModal?

    private let modeColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            UltraBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    heroCard
                    modeGrid
                    shortcuts
                    aiLevelCard
                    challengeCard
                    achievementStrip
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
#endif
        .toolbar {
#if os(iOS)
            ToolbarItem(placement: .principal) {
                Text("Backgammon Ultra")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsHubView(store: store)
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
            }
#else
            ToolbarItem(placement: .automatic) {
                NavigationLink {
                    SettingsHubView(store: store)
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
            }
#endif
        }
        .sheet(item: $activeModal) { modal in
            switch modal {
            case .stats:
                SoloStatsModalView()
            case .leaderboard:
                LeaderboardModalView(store: store)
            case .tutorial:
                TutorialModalView(store: store)
            case .design:
                DesignModalView(store: store)
            }
        }
    }

    private var heroCard: some View {
        UltraCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Competitive Profile")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("\(store.season.name) • \(store.seasonDaysRemaining) days left")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                    Spacer()
                    Text(store.countryFlag)
                        .font(.title2)
                }

                HStack(spacing: 12) {
                    statPill(title: "Rating", value: "\(store.profile.ranking)")
                    statPill(title: "Win Rate", value: "\(store.winRatePercent)%")
                    statPill(title: "Matches", value: "\(store.profile.matchesPlayed)")
                }

                ProgressView(value: store.seasonProgress)
                    .tint(UltraPalette.accent)
                    .scaleEffect(x: 1, y: 1.3, anchor: .center)
            }
        }
    }

    private var modeGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Game Modes", subtitle: "Focus the experience on clean, competitive gameplay.")

            LazyVGrid(columns: modeColumns, spacing: 12) {
                NavigationLink {
                    SoloMatchView(
                        aiLevel: store.preferredAILevel,
                        gameplaySettings: store.gameplaySettings,
                        onGameplaySettingsChanged: { updated in
                            store.gameplaySettings = updated
                        },
                        onMatchCompleted: { completion in
                            store.registerSoloMatchCompletion(completion)
                        }
                    )
                } label: {
                    ModeCard(
                        title: "Solo",
                        subtitle: "10 AI levels from Beginner to Champion.",
                        symbol: "cpu",
                        accent: UltraPalette.blue,
                        status: "Live"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    ModePreviewView(mode: .rankedOnline)
                } label: {
                    ModeCard(
                        title: "Ranked",
                        subtitle: "Online ELO ladder with seasonal ranking.",
                        symbol: "chart.line.uptrend.xyaxis",
                        accent: UltraPalette.orange,
                        status: "Online"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    ModePreviewView(mode: .localTwoPlayer)
                } label: {
                    ModeCard(
                        title: "Local 2P",
                        subtitle: "Pass-and-play mode for the same device.",
                        symbol: "rectangle.on.rectangle",
                        accent: UltraPalette.teal,
                        status: "Local"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    ModePreviewView(mode: .playWithFriends)
                } label: {
                    ModeCard(
                        title: "Friends",
                        subtitle: "Private matches via link or Game Center.",
                        symbol: "person.2.wave.2",
                        accent: UltraPalette.pink,
                        status: "Invite"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var shortcuts: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Quick Access", subtitle: "Tutorial, leaderboard, stats and design tools.")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    shortcutButton("Stats", icon: "chart.bar.fill", color: UltraPalette.teal) { activeModal = .stats }
                    shortcutButton("Leaderboard", icon: "trophy.fill", color: UltraPalette.orange) { activeModal = .leaderboard }
                    shortcutButton("Guide", icon: "graduationcap.fill", color: UltraPalette.blue) { activeModal = .tutorial }
                    shortcutButton("Design", icon: "paintpalette.fill", color: UltraPalette.pink) { activeModal = .design }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private func shortcutButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            action()
            Haptics.selection()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color.white.opacity(0.08), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var aiLevelCard: some View {
        UltraCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Solo Difficulty", subtitle: "Choose your current training level.")

                Picker("AI", selection: Binding(
                    get: { store.preferredAILevel },
                    set: { store.setPreferredAILevel($0) }
                )) {
                    ForEach(AILevel.allCases, id: \.self) { level in
                        Text(level.title).tag(level)
                    }
                }
                .pickerStyle(.menu)
                .tint(.white)
            }
        }
    }

    private var challengeCard: some View {
        UltraCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Daily Challenge", subtitle: store.dailyChallengeText)

                Button {
                    Haptics.selection()
                } label: {
                    Label("Start Challenge", systemImage: "target")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(UltraPalette.accent.opacity(0.95), in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.black.opacity(0.85))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var achievementStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Achievements", subtitle: "Track mastery milestones.")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(store.achievements) { badge in
                        UltraCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Label(badge.title, systemImage: badge.symbol)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white)
                                Text("Progress \(badge.progress)")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.72))
                            }
                            .frame(width: 170, alignment: .leading)
                        }
                    }
                }
            }
        }
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.55))
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct CompeteHubView: View {
    @ObservedObject var store: AppExperienceStore

    var body: some View {
        ZStack {
            UltraBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    UltraCard {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Season Leaderboard", subtitle: "Visible rank and momentum in one view.")
                            Picker("Leaderboard Metric", selection: $store.selectedLeaderboardMetric) {
                                ForEach(LeaderboardMetric.allCases) { metric in
                                    Text(metric.title).tag(metric)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    VStack(spacing: 8) {
                        ForEach(store.leaderboardRows) { row in
                            leaderboardRow(row)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Compete")
    }

    private func leaderboardRow(_ row: LeaderboardRow) -> some View {
        HStack(spacing: 12) {
            Text("#\(row.rank)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(row.isCurrentUser ? UltraPalette.accent : .white.opacity(0.82))
                .frame(width: 48, alignment: .leading)
                .monospacedDigit()

            VStack(alignment: .leading, spacing: 2) {
                Text("\(row.countryCode.flagEmoji) \(row.username)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("Record \(row.record)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.62))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(row.score)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                Text(row.delta > 0 ? "+\(row.delta)" : "\(row.delta)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(row.delta >= 0 ? UltraPalette.green : UltraPalette.red)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(row.isCurrentUser ? UltraPalette.accent.opacity(0.18) : Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            row.isCurrentUser ? UltraPalette.accent.opacity(0.7) : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
        )
    }
}

private struct SocialHubView: View {
    @ObservedObject var store: AppExperienceStore

    var body: some View {
        ZStack {
            UltraBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    UltraCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Voice Channel", subtitle: "Real-time voice with safety controls.")
                            Toggle("Enable voice in online matches", isOn: $store.voiceChatEnabled)
                                .tint(UltraPalette.accent)
                            Toggle("Enable quick chat", isOn: $store.quickChatEnabled)
                                .tint(UltraPalette.accent)
                            Toggle("Enable emoji reactions", isOn: $store.emojiReactionsEnabled)
                                .tint(UltraPalette.accent)
                        }
                    }

                    UltraCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Quick Chat", subtitle: "One tap strategic communication.")
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], spacing: 8) {
                                ForEach(QuickChatMessage.allCases, id: \.self) { message in
                                    Text(message.rawValue)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white.opacity(0.9))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Social")
        .onChange(of: store.voiceChatEnabled) { _, _ in Haptics.selection() }
        .onChange(of: store.quickChatEnabled) { _, _ in Haptics.selection() }
        .onChange(of: store.emojiReactionsEnabled) { _, _ in Haptics.selection() }
    }
}

private struct ProfileHubView: View {
    @ObservedObject var store: AppExperienceStore

    private let historyDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        ZStack {
            UltraBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    profileCard
                    historyCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Profile")
    }

    private var profileCard: some View {
        UltraCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(UltraPalette.accent.opacity(0.3))
                        Text(String(store.profile.username.prefix(1)).uppercased())
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 54, height: 54)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.profile.username)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("\(store.countryFlag)  Rank \(store.profile.ranking)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                }

                HStack(spacing: 10) {
                    profileMetric(title: "Win Rate", value: "\(store.winRatePercent)%")
                    profileMetric(title: "Matches", value: "\(store.profile.matchesPlayed)")
                    profileMetric(title: "Best Streak", value: "8")
                }
            }
        }
    }

    private var historyCard: some View {
        UltraCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Recent Matches", subtitle: "Fast post-match review.")
                ForEach(store.matchHistory) { entry in
                    HStack(spacing: 8) {
                        Image(systemName: entry.outcome == .win ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                            .foregroundStyle(entry.outcome == .win ? UltraPalette.green : UltraPalette.red)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("vs \(entry.opponentUsername)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Text("\(entry.mode.uiTitle) • \(historyDateFormatter.string(from: entry.finishedAt))")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.62))
                        }

                        Spacer()

                        Text(entry.ratingDelta == 0 ? "--" : (entry.ratingDelta > 0 ? "+\(entry.ratingDelta)" : "\(entry.ratingDelta)"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(entry.ratingDelta >= 0 ? UltraPalette.green : UltraPalette.red)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func profileMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.55))
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct StoreHubView: View {
    @ObservedObject var store: AppExperienceStore

    private let grid = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ZStack {
            UltraBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    UltraCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Premium", subtitle: "Unlock voice and advanced stats.")
                            ForEach(store.premiumFeatures, id: \.self) { feature in
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(UltraPalette.accent)
                                    Text(feature)
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.9))
                                }
                            }

                            Button {
                                store.togglePremium()
                            } label: {
                                Text(store.premiumUnlocked ? "Premium Active" : "Start Premium")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        store.premiumUnlocked ? UltraPalette.green : UltraPalette.accent,
                                        in: RoundedRectangle(cornerRadius: 10)
                                    )
                                    .foregroundStyle(.black.opacity(0.86))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Cosmetics", subtitle: "Visual only, no gameplay advantage.")
                        LazyVGrid(columns: grid, spacing: 10) {
                            ForEach(store.cosmetics) { item in
                                UltraCard {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(item.name)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.white)
                                        Text(item.rarity.uppercased())
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(UltraPalette.accent)
                                        Text(item.price)
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(.white.opacity(0.72))
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Store")
    }
}

private struct SettingsHubView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: AppExperienceStore

    private let matchLengthGrid = [GridItem(.adaptive(minimum: 86), spacing: 8)]

    var body: some View {
        ZStack {
            UltraBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    UltraCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Brettansicht", subtitle: "Auto / Landschaft / Portrait")
                            Picker("Board orientation", selection: store.gameplayBinding(\.boardOrientation)) {
                                ForEach(BoardOrientation.allCases, id: \.self) { orientation in
                                    Text(orientation.uiTitle).tag(orientation)
                                }
                            }
                            .pickerStyle(.segmented)

                            SectionHeader(title: "Board View", subtitle: "Modern / Classic")
                            Picker("Board style", selection: store.gameplayBinding(\.boardVisualStyle)) {
                                ForEach(BoardVisualStyle.allCases, id: \.self) { style in
                                    Text(style.uiTitle).tag(style)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    UltraCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Gameplay", subtitle: "Core flow options.")
                            Toggle("Zwei Würfelpaare", isOn: $store.showTwoDicePairs).tint(UltraPalette.accent)
                            Toggle("Rating zeigen", isOn: $store.showRating).tint(UltraPalette.accent)
                            Toggle("Verdopplungswürfel", isOn: store.gameplayBinding(\.doublingCubeEnabled)).tint(UltraPalette.accent)
                            Toggle("Einmal-Anklickfunktion", isOn: $store.oneClickMoveEnabled).tint(UltraPalette.accent)
                            Toggle("Pips zeigen", isOn: store.gameplayBinding(\.pipsCounterEnabled)).tint(UltraPalette.accent)
                            Toggle("Hinweis 💡", isOn: $store.hintsEnabled).tint(UltraPalette.accent)
                            Toggle("Erzwungene Züge spielen ⚡", isOn: store.gameplayBinding(\.forcedMovesEnabled)).tint(UltraPalette.accent)
                            Toggle("Markieren Sie erlaubte Positionen", isOn: store.gameplayBinding(\.highlightLegalMoves)).tint(UltraPalette.accent)
                            Toggle("Täglicher Bonus x2", isOn: $store.dailyBonusX2Enabled).tint(UltraPalette.accent)
                        }
                    }

                    UltraCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Match Length", subtitle: "1, 3, 5, 7 oder 11 Punkte")
                            LazyVGrid(columns: matchLengthGrid, spacing: 8) {
                                ForEach(MatchLength.allCases, id: \.self) { length in
                                    Button {
                                        store.setMatchLength(length)
                                    } label: {
                                        Text(length.uiTitle)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(
                                                store.gameplaySettings.preferredMatchLength == length
                                                ? .black.opacity(0.82)
                                                : .white
                                            )
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(
                                                store.gameplaySettings.preferredMatchLength == length
                                                ? UltraPalette.accent
                                                : Color.white.opacity(0.08),
                                                in: RoundedRectangle(cornerRadius: 10)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    UltraCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Button("Werbung entfernen") { Haptics.selection() }
                                .buttonStyle(.plain)
                                .foregroundStyle(UltraPalette.accent)
                            Divider().background(Color.white.opacity(0.2))
                            Button("Wiederherstellung des Kaufs") { Haptics.selection() }
                                .buttonStyle(.plain)
                                .foregroundStyle(UltraPalette.accent)
                        }
                    }

                    Text(store.appVersionLabel)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(.horizontal, 4)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Settings")
        .toolbar {
#if os(iOS)
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
#endif
        }
        .onChange(of: store.showTwoDicePairs) { _, _ in Haptics.selection() }
        .onChange(of: store.showRating) { _, _ in Haptics.selection() }
        .onChange(of: store.oneClickMoveEnabled) { _, _ in Haptics.selection() }
        .onChange(of: store.hintsEnabled) { _, _ in Haptics.selection() }
        .onChange(of: store.dailyBonusX2Enabled) { _, _ in Haptics.selection() }
    }
}

private struct ModePreviewView: View {
    let mode: GameMode

    var body: some View {
        ZStack {
            UltraBackground()

            VStack(spacing: 14) {
                UltraCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label(mode.uiTitle, systemImage: mode.symbolName)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(mode.uiSubtitle)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.78))
                    }
                }

                UltraCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Product Direction")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.72))
                        Text("Competitive integrity first: low-latency real-time turns, anti-cheat validation, and consistent UX across portrait and landscape.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.88))
                    }
                }

                Spacer()
            }
            .padding(16)
        }
        .navigationTitle(mode.uiTitle)
    }
}

private struct TutorialModalView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: AppExperienceStore

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Guide")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(18)

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Label(currentSlide.title, systemImage: currentSlide.symbol)
                        .font(.title3.weight(.bold))
                    Text(currentSlide.body)
                        .font(.body)
                }
                .padding(18)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                Divider()

                HStack {
                    Button {
                        guard store.tutorialPageIndex > 0 else { return }
                        store.tutorialPageIndex -= 1
                    } label: {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .disabled(store.tutorialPageIndex == 0)

                    Spacer()
                    Text("\(store.tutorialPageIndex + 1) / 39")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Spacer()

                    Button {
                        guard store.tutorialPageIndex < store.tutorialSlides.count - 1 else { return }
                        store.tutorialPageIndex += 1
                    } label: {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .disabled(store.tutorialPageIndex == store.tutorialSlides.count - 1)
                }
                .padding(16)
            }
            .frame(maxWidth: 720, maxHeight: 580)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                    )
            )
            .padding(16)
        }
    }

    private var currentSlide: TutorialSlide {
        store.tutorialSlides[store.tutorialPageIndex]
    }
}

private struct SoloStatsModalView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Text("Solo-Statistiken")
                        .font(.title2.weight(.bold))
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                    ForEach(1...10, id: \.self) { index in
                        Circle()
                            .fill(index <= 2 ? Color.green.opacity(0.25) : Color.gray.opacity(0.2))
                            .overlay(
                                Group {
                                    if index <= 2 {
                                        Text("\(index)")
                                            .font(.headline.weight(.bold))
                                            .foregroundStyle(.green)
                                    } else {
                                        Image(systemName: "lock.fill")
                                            .foregroundStyle(.gray)
                                    }
                                }
                            )
                            .frame(width: 52, height: 52)
                    }
                }

                metricRow("Spiele", wins: 74, losses: 31)
                metricRow("einfach", wins: 56, losses: 20)
                metricRow("gammon", wins: 13, losses: 7)
                metricRow("backgammon", wins: 5, losses: 4)
                metricRow("Matches", wins: 74, losses: 31)
                metricRow("Punkte", wins: 412, losses: 195)
            }
            .padding(20)
            .frame(maxWidth: 700)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(16)
        }
    }

    private func metricRow(_ title: String, wins: Int, losses: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline.weight(.semibold))
            HStack(spacing: 10) {
                Text("\(wins)")
                    .font(.headline.monospacedDigit())
                GeometryReader { proxy in
                    let total = max(wins + losses, 1)
                    let ratio = CGFloat(wins) / CGFloat(total)
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.red.opacity(0.2))
                        Capsule().fill(Color.green.opacity(0.35))
                            .frame(width: proxy.size.width * ratio)
                    }
                }
                .frame(height: 24)
                Text("\(losses)")
                    .font(.headline.monospacedDigit())
            }
        }
    }
}

private struct LeaderboardModalView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: AppExperienceStore

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()

            VStack(spacing: 10) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Text("Bestenliste")
                        .font(.title2.weight(.bold))
                    Spacer()
                    Color.clear.frame(width: 24, height: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Picker("Metrik", selection: $store.selectedLeaderboardMetric) {
                    ForEach(LeaderboardMetric.allCases) { metric in
                        Text(metric.title).tag(metric)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(store.leaderboardRows) { row in
                            HStack {
                                Text("\(row.rank)")
                                    .monospacedDigit()
                                    .frame(width: 42, alignment: .leading)
                                Text("\(row.countryCode.flagEmoji) \(row.username)")
                                    .lineLimit(1)
                                Spacer()
                                Text("\(row.score)")
                                    .monospacedDigit()
                            }
                            .font(.headline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 70)
                }
            }
            .frame(maxWidth: 700, maxHeight: 760)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                    )
            )
            .overlay(alignment: .bottom) {
                if let me = store.myLeaderboardRow {
                    HStack {
                        Text("\(me.rank)")
                            .monospacedDigit()
                            .frame(width: 52, alignment: .leading)
                        Text(me.username)
                            .lineLimit(1)
                        Spacer()
                        Text("\(me.score)")
                            .monospacedDigit()
                    }
                    .font(.headline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 12))
                    .padding(14)
                }
            }
            .padding(16)
        }
    }
}

private struct DesignModalView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: AppExperienceStore

    var body: some View {
        ZStack {
            Color(red: 0.74, green: 0.75, blue: 0.79)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                HStack {
                    Spacer()
                    Text("Design")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Color(red: 0.35, green: 0.20, blue: 0.08))
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.title.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 58, height: 58)
                            .background(Circle().fill(Color(red: 0.52, green: 0.31, blue: 0.13)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)

                HStack(spacing: 14) {
                    VStack(spacing: 10) {
                        Button {
                            store.designBoardFlipped.toggle()
                            Haptics.selection()
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.title3.weight(.bold))
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.black.opacity(0.85)))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)

                        Divider().background(Color.white.opacity(0.5))

                        ForEach(store.designCheckerOptions) { option in
                            Button {
                                store.selectedCheckerStyleID = option.id
                                Haptics.selection()
                            } label: {
                                Circle()
                                    .fill(option.light)
                                    .overlay(Circle().stroke(option.dark, lineWidth: 3))
                                    .frame(width: 42, height: 42)
                                    .overlay(
                                        Circle().stroke(
                                            store.selectedCheckerStyleID == option.id ? Color.orange : Color.clear,
                                            lineWidth: 3
                                        )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 10)
                    .frame(width: 64)
                    .background(Color.black.opacity(0.24), in: RoundedRectangle(cornerRadius: 20))

                    DesignBoardPreview(
                        theme: store.selectedTheme,
                        checker: store.selectedCheckerStyle,
                        showNumbers: store.designShowPointNumbers,
                        flipped: store.designBoardFlipped
                    )

                    VStack(spacing: 12) {
                        Button {
                            store.designBoardFlipped.toggle()
                        } label: {
                            circularControl("arrow.uturn.backward")
                        }
                        .buttonStyle(.plain)

                        Button {
                            store.designShowPointNumbers.toggle()
                        } label: {
                            circularControl("123.rectangle")
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)

                HStack(spacing: 16) {
                    Button {
                        guard store.selectedDesignThemeID > 0 else { return }
                        store.selectedDesignThemeID -= 1
                    } label: {
                        circularPagerArrow("arrow.left")
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 8) {
                        ForEach(store.designThemeOptions) { option in
                            Circle()
                                .fill(option.id == store.selectedDesignThemeID ? Color.white : Color(red: 0.53, green: 0.32, blue: 0.13))
                                .frame(width: 11, height: 11)
                        }
                    }

                    Button {
                        guard store.selectedDesignThemeID < store.designThemeOptions.count - 1 else { return }
                        store.selectedDesignThemeID += 1
                    } label: {
                        circularPagerArrow("arrow.right")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 16)
            }
            .frame(maxWidth: 1100, maxHeight: 740)
            .padding(.top, 6)
        }
    }

    private func circularControl(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.title3.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 54, height: 54)
            .background(Circle().fill(Color.black.opacity(0.82)))
    }

    private func circularPagerArrow(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.title3.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 52, height: 52)
            .background(Circle().fill(Color(red: 0.52, green: 0.31, blue: 0.13)))
    }
}

private struct DesignBoardPreview: View {
    let theme: DesignThemeOption
    let checker: DesignCheckerOption
    let showNumbers: Bool
    let flipped: Bool

    var body: some View {
        GeometryReader { proxy in
            let midHeight = max(70, proxy.size.height * 0.18)
            let cellHeight = max(86, (proxy.size.height - midHeight - 32) / 2)

            VStack(spacing: 10) {
                pointRow(points: flipped ? Array(1...12) : Array((13...24).reversed()), height: cellHeight)
                HStack(spacing: 10) {
                    trayLabel("Bar")
                    HStack(spacing: 8) {
                        dice("5")
                        dice("2")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 12))
                    trayLabel("Off")
                }
                .frame(height: midHeight)
                pointRow(points: flipped ? Array((13...24).reversed()) : Array(1...12), height: cellHeight)
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(LinearGradient(colors: [theme.boardBase, theme.boardAccent], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Color.black.opacity(0.2), lineWidth: 1))
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func pointRow(points: [Int], height: CGFloat) -> some View {
        HStack(spacing: 4) {
            ForEach(points, id: \.self) { point in
                VStack(spacing: 2) {
                    if showNumbers {
                        Text("\(point)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Spacer(minLength: 2)
                    ForEach(0..<checkerCount(point), id: \.self) { i in
                        Circle()
                            .fill(i.isMultiple(of: 2) ? checker.light : checker.dark)
                            .frame(width: 11, height: 11)
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.7))
                    }
                    Spacer(minLength: 2)
                }
                .frame(maxWidth: .infinity, minHeight: height)
                .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func trayLabel(_ title: String) -> some View {
        Text(title)
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: 110, maxHeight: .infinity)
            .background(Color.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
    }

    private func dice(_ value: String) -> some View {
        Text(value)
            .font(.headline.weight(.bold))
            .frame(width: 36, height: 36)
            .foregroundStyle(.black.opacity(0.8))
            .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
    }

    private func checkerCount(_ point: Int) -> Int {
        switch point {
        case 1, 24:
            return 2
        case 6, 13:
            return 5
        case 8:
            return 3
        case 12, 19:
            return 4
        default:
            return 0
        }
    }
}

private struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.67))
        }
    }
}

private struct ModeCard: View {
    let title: String
    let subtitle: String
    let symbol: String
    let accent: Color
    let status: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(accent)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.73))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 0)

            Text(status)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.black.opacity(0.84))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(accent, in: Capsule())
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 148, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                )
        )
    }
}

private struct UltraCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.white.opacity(0.13), lineWidth: 1)
                    )
            )
    }
}

private struct UltraBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [UltraPalette.canvasTop, UltraPalette.canvasBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(UltraPalette.accent.opacity(0.12))
                .frame(width: 320, height: 320)
                .blur(radius: 30)
                .offset(x: 150, y: -280)

            Circle()
                .fill(UltraPalette.blue.opacity(0.1))
                .frame(width: 280, height: 280)
                .blur(radius: 30)
                .offset(x: -150, y: 290)
        }
    }
}

private enum UltraPalette {
    static let canvasTop = Color(red: 0.06, green: 0.08, blue: 0.13)
    static let canvasBottom = Color(red: 0.09, green: 0.11, blue: 0.18)
    static let accent = Color(red: 0.34, green: 0.86, blue: 0.98)
    static let blue = Color(red: 0.41, green: 0.66, blue: 1.0)
    static let orange = Color(red: 1.0, green: 0.67, blue: 0.37)
    static let teal = Color(red: 0.43, green: 0.95, blue: 0.82)
    static let pink = Color(red: 1.0, green: 0.56, blue: 0.75)
    static let green = Color(red: 0.47, green: 0.92, blue: 0.6)
    static let red = Color(red: 1.0, green: 0.47, blue: 0.52)
}

private extension BoardOrientation {
    var uiTitle: String {
        switch self {
        case .auto:
            return "Auto"
        case .portrait:
            return "Portrait"
        case .landscape:
            return "Landschaft"
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

private extension MatchLength {
    var uiTitle: String { "\(rawValue) pt" }
}

private extension GameMode {
    var uiTitle: String {
        switch self {
        case .solo: return "Solo"
        case .rankedOnline: return "Ranked"
        case .casualOnline: return "Casual"
        case .playWithFriends: return "Friends"
        case .localTwoPlayer: return "Local 2P"
        }
    }

    var uiSubtitle: String {
        switch self {
        case .solo:
            return "Play against 10 AI levels with clear progression."
        case .rankedOnline:
            return "Compete on the ELO ladder with seasonal ranking."
        case .casualOnline:
            return "Fast online matchmaking without rating pressure."
        case .playWithFriends:
            return "Invite links and Game Center support."
        case .localTwoPlayer:
            return "Pass-and-play mode on one device."
        }
    }

    var symbolName: String {
        switch self {
        case .solo: return "cpu"
        case .rankedOnline: return "trophy"
        case .casualOnline: return "sparkles"
        case .playWithFriends: return "person.2"
        case .localTwoPlayer: return "rectangle.on.rectangle"
        }
    }
}

private extension String {
    var flagEmoji: String {
        let normalized = uppercased()
        guard normalized.count == 2 else { return "🏳️" }
        let base: UInt32 = 127397
        let scalars = normalized.unicodeScalars.compactMap { scalar -> UnicodeScalar? in
            guard scalar.properties.isAlphabetic else { return nil }
            return UnicodeScalar(base + scalar.value)
        }
        guard scalars.count == 2 else { return "🏳️" }
        return String(String.UnicodeScalarView(scalars))
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

    static func success() {
#if canImport(UIKit)
        Task { @MainActor in
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
#endif
    }
}

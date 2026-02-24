import Foundation

public enum SubscriptionTier: String, Codable, Sendable {
    case free
    case premium
}

public enum CosmeticType: String, Codable, CaseIterable, Sendable {
    case boardTheme
    case checkerSet
    case diceSkin
    case profileFrame
}

public struct CosmeticItem: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public var type: CosmeticType
    public var title: String
    public var priceInCents: Int
    public var isPremiumExclusive: Bool

    public init(
        id: UUID = UUID(),
        type: CosmeticType,
        title: String,
        priceInCents: Int,
        isPremiumExclusive: Bool
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.priceInCents = priceInCents
        self.isPremiumExclusive = isPremiumExclusive
    }
}

public struct Entitlements: Codable, Hashable, Sendable {
    public var tier: SubscriptionTier
    public var voiceChatEnabled: Bool
    public var adsDisabled: Bool
    public var advancedStatsEnabled: Bool

    public init(
        tier: SubscriptionTier,
        voiceChatEnabled: Bool,
        adsDisabled: Bool,
        advancedStatsEnabled: Bool
    ) {
        self.tier = tier
        self.voiceChatEnabled = voiceChatEnabled
        self.adsDisabled = adsDisabled
        self.advancedStatsEnabled = advancedStatsEnabled
    }

    public static var free: Entitlements {
        Entitlements(
            tier: .free,
            voiceChatEnabled: false,
            adsDisabled: false,
            advancedStatsEnabled: false
        )
    }

    public static var premium: Entitlements {
        Entitlements(
            tier: .premium,
            voiceChatEnabled: true,
            adsDisabled: true,
            advancedStatsEnabled: true
        )
    }
}

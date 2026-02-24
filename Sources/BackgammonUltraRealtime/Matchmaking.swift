import Foundation
import BackgammonUltraCore

public enum QueueType: String, Codable, Sendable {
    case ranked
    case casual
    case friendsPrivate
}

public struct MatchmakingRequest: Codable, Hashable, Sendable {
    public var userID: UUID
    public var queueType: QueueType
    public var currentRating: Int
    public var region: String
    public var preferredMatchLength: MatchLength
    public var voiceEnabled: Bool

    public init(
        userID: UUID,
        queueType: QueueType,
        currentRating: Int,
        region: String,
        preferredMatchLength: MatchLength,
        voiceEnabled: Bool
    ) {
        self.userID = userID
        self.queueType = queueType
        self.currentRating = currentRating
        self.region = region
        self.preferredMatchLength = preferredMatchLength
        self.voiceEnabled = voiceEnabled
    }
}

public struct MatchmakingTicket: Codable, Hashable, Sendable {
    public var id: UUID
    public var request: MatchmakingRequest
    public var createdAt: Date
    public var maxPingMS: Int

    public init(
        id: UUID = UUID(),
        request: MatchmakingRequest,
        createdAt: Date = .now,
        maxPingMS: Int = 140
    ) {
        self.id = id
        self.request = request
        self.createdAt = createdAt
        self.maxPingMS = maxPingMS
    }
}

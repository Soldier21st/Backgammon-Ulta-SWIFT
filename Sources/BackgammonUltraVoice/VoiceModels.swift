import Foundation

public struct VoiceSessionToken: Codable, Hashable, Sendable {
    public var roomID: String
    public var participantID: UUID
    public var token: String
    public var expiresAt: Date

    public init(roomID: String, participantID: UUID, token: String, expiresAt: Date) {
        self.roomID = roomID
        self.participantID = participantID
        self.token = token
        self.expiresAt = expiresAt
    }
}

public enum VoiceModerationAction: String, Codable, Sendable {
    case mute
    case unmute
    case block
    case report
}

public struct VoiceReportPayload: Codable, Hashable, Sendable {
    public var reportedUserID: UUID
    public var reporterUserID: UUID
    public var matchID: UUID
    public var reason: String
    public var createdAt: Date

    public init(
        reportedUserID: UUID,
        reporterUserID: UUID,
        matchID: UUID,
        reason: String,
        createdAt: Date = .now
    ) {
        self.reportedUserID = reportedUserID
        self.reporterUserID = reporterUserID
        self.matchID = matchID
        self.reason = reason
        self.createdAt = createdAt
    }
}

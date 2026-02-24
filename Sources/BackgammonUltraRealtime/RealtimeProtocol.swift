import Foundation

public enum RealtimeEventType: String, Codable, Sendable {
    case joinMatch
    case stateSnapshot
    case actionRequest
    case actionResult
    case quickChat
    case emojiReaction
    case heartbeat
    case resumeSession
    case playerReported
    case spectatorJoined
}

public struct RealtimeEnvelope: Codable, Hashable, Sendable {
    public var id: UUID
    public var sequence: Int
    public var matchID: UUID
    public var eventType: RealtimeEventType
    public var payloadJSON: String?
    public var sentAt: Date

    public init(
        id: UUID = UUID(),
        sequence: Int,
        matchID: UUID,
        eventType: RealtimeEventType,
        payloadJSON: String? = nil,
        sentAt: Date = .now
    ) {
        self.id = id
        self.sequence = sequence
        self.matchID = matchID
        self.eventType = eventType
        self.payloadJSON = payloadJSON
        self.sentAt = sentAt
    }
}

public enum ConnectionState: String, Sendable {
    case idle
    case connecting
    case connected
    case reconnecting
    case disconnected
}

public protocol RealtimeTransport: Sendable {
    var state: ConnectionState { get async }
    func connect(to url: URL, authToken: String) async throws
    func disconnect() async
    func send(_ envelope: RealtimeEnvelope) async throws
    func incomingStream() async -> AsyncStream<RealtimeEnvelope>
}

import Foundation

public enum VoiceEngineState: String, Sendable {
    case idle
    case joining
    case connected
    case disconnected
    case failed
}

public protocol VoiceEngine: Sendable {
    var state: VoiceEngineState { get async }
    func joinRoom(with token: VoiceSessionToken) async throws
    func leaveRoom() async
    func setMuted(_ isMuted: Bool) async
    func block(userID: UUID) async
    func report(_ payload: VoiceReportPayload) async throws
}

public actor MockVoiceEngine: VoiceEngine {
    private var blockedUsers = Set<UUID>()
    private var currentState: VoiceEngineState = .idle
    private var isMuted: Bool = false

    public init() {}

    public var state: VoiceEngineState {
        currentState
    }

    public func joinRoom(with _: VoiceSessionToken) async throws {
        currentState = .connected
    }

    public func leaveRoom() async {
        currentState = .disconnected
    }

    public func setMuted(_ isMuted: Bool) async {
        self.isMuted = isMuted
    }

    public func block(userID: UUID) async {
        blockedUsers.insert(userID)
    }

    public func report(_: VoiceReportPayload) async throws {
        // Integrate with backend moderation endpoint.
    }
}

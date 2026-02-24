import Foundation

public actor MockRealtimeTransport: RealtimeTransport {
    private var currentState: ConnectionState = .idle
    private var continuation: AsyncStream<RealtimeEnvelope>.Continuation?
    private var stream: AsyncStream<RealtimeEnvelope>

    public init() {
        var localContinuation: AsyncStream<RealtimeEnvelope>.Continuation?
        self.stream = AsyncStream { continuation in
            localContinuation = continuation
        }
        self.continuation = localContinuation
    }

    public var state: ConnectionState {
        currentState
    }

    public func connect(to _: URL, authToken _: String) async throws {
        currentState = .connected
    }

    public func disconnect() async {
        currentState = .disconnected
        continuation?.finish()
    }

    public func send(_ envelope: RealtimeEnvelope) async throws {
        continuation?.yield(envelope)
    }

    public func incomingStream() async -> AsyncStream<RealtimeEnvelope> {
        stream
    }
}

import Foundation
import HaishinKit

actor WHEPSession: Session {
    var connected: Bool {
        get async {
            false
        }
    }

    @AsyncStreamed(.closed)
    private(set) var readyState: AsyncStream<SessionReadyState>

    var stream: any StreamConvertible {
        get async {
            await connection.stream
        }
    }

    private var disconnctedTask: Task<Void, any Error>? {
        didSet {
            oldValue?.cancel()
        }
    }

    private let uri: URL
    private let connection = WHEPConnection()
    private var maxRetryCount: Int = 0

    init(uri: URL, method: SessionMethod) {
        self.uri = uri
    }

    func setMaxRetryCount(_ maxRetryCount: Int) {
        self.maxRetryCount = maxRetryCount
    }

    func connect(_ disconnected: @Sendable @escaping () -> Void) async throws {
        _readyState.value = .connecting
        try await connection.connect(uri)
        _readyState.value = .open
    }

    func close() async throws {
        _readyState.value = .closing
        try await connection.close()
        _readyState.value = .closed
    }
}

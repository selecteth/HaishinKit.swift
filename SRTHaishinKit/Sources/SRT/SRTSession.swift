@preconcurrency import Combine
import Foundation
import HaishinKit

actor SRTSession: Session {
    var connected: Bool {
        get async {
            await connection.connected
        }
    }

    @AsyncStreamed(.closed)
    private(set) var readyState: AsyncStream<SessionReadyState>

    var stream: any StreamConvertible {
        _stream
    }

    private let uri: URL
    private var retryCount: Int = 0
    private var maxRetryCount: Int = 0
    private lazy var connection = SRTConnection()
    private lazy var _stream: SRTStream = {
        SRTStream(connection: connection)
    }()
    private var cancellables: Set<AnyCancellable> = []
    private var disconnctedTask: Task<Void, any Error>? {
        didSet {
            oldValue?.cancel()
        }
    }

    init(uri: URL) {
        self.uri = uri
    }

    func setMaxRetryCount(_ maxRetryCount: Int) {
        self.maxRetryCount = maxRetryCount
    }

    func connect(_ method: SessionMethod, disconnected: @Sendable @escaping () -> Void) async throws {
        guard await connection.connected == false else {
            return
        }
        _readyState.value = .connecting
        do {
            try await connection.connect(uri)
        } catch {
            guard retryCount < maxRetryCount else {
                retryCount = 0
                _readyState.value = .closed
                throw error
            }
            // It is being delayed using backoff for congestion control.
            try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(retryCount))) * 1_000_000_000)
            retryCount += 1
            try await connect(method, disconnected: disconnected)
        }
        _readyState.value = .open
        retryCount = 0
        switch method {
        case .playback:
            await _stream.play()
        case .ingest:
            await _stream.publish()
        }
        disconnctedTask = Task {
            cancellables.removeAll()
            await connection.$connected.sink {
                if $0 == false {
                    disconnected()
                }
            }.store(in: &cancellables)
        }
    }

    func close() async throws {
        guard await connection.connected else {
            return
        }
        _readyState.value = .closing
        await connection.close()
        _readyState.value = .closed
    }
}

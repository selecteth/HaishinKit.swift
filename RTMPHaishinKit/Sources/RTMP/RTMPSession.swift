import Foundation
import HaishinKit

actor RTMPSession: Session {
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

    private let uri: RTMPURL
    private var retryCount: Int = 0
    private var maxRetryCount: Int = 5
    private lazy var connection = RTMPConnection()
    private lazy var _stream: RTMPStream = {
        RTMPStream(connection: connection)
    }()
    private var disconnctedTask: Task<Void, any Error>? {
        didSet {
            oldValue?.cancel()
        }
    }

    init(uri: URL) {
        self.uri = RTMPURL(url: uri)
    }

    func setMaxRetryCount(_ maxRetryCount: Int) {
        self.maxRetryCount = maxRetryCount
    }

    func connect(_ method: SessionMethod, disconnected: @Sendable @escaping () -> Void) async throws {
        guard await connection.connected == false else {
            return
        }
        _readyState.value = .connecting
        disconnctedTask = nil
        // Retry handling at the TCP/IP level and during RTMP connection.
        do {
            _ = try await connection.connect(uri.command)
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
        // Errors at the NetStream layer, such as incorrect stream names,
        // cannot be resolved by retrying, so they are thrown as exceptions.
        switch method {
        case .ingest:
            _ = try await _stream.publish(uri.streamName)
        case .playback:
            _ = try await _stream.play(uri.streamName)
        }
        disconnctedTask = Task {
            for await event in await connection.status {
                switch event.code {
                case RTMPConnection.Code.connectClosed.rawValue:
                    _readyState.value = .closed
                    disconnected()
                default:
                    break
                }
            }
        }
    }

    func close() async throws {
        guard await connection.connected else {
            return
        }
        _readyState.value = .closing
        disconnctedTask = nil
        try await connection.close()
        _readyState.value = .closed
    }
}

import Foundation
import HaishinKit

actor SRTSession: Session {
    var isConnected: Bool {
        get async {
            await connection.connected
        }
    }

    var stream: any HaishinKit.HKStream {
        _stream
    }

    private let uri: URL
    private lazy var connection = SRTConnection()
    private lazy var _stream: SRTStream = {
        SRTStream(connection: connection)
    }()

    init(uri: URL) {
        self.uri = uri
    }

    func setMaxRetryCount(_ maxRetryCount: Int) {
    }

    func connect(_ method: HaishinKit.SessionMethod) async throws {
        try await connection.connect(uri)
        switch method {
        case .playback:
            await _stream.play()
        case .ingest:
            await _stream.publish()
        }
    }

    func close() async throws {
        await connection.close()
    }
}

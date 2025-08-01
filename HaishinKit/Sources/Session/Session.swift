import Foundation

public enum SessionMethod {
    case ingest
    case playback
}

/// A type that represents a foundation of streaming session.
///
/// Streaming with RTMPConneciton is difficult to use because it requires many idioms.
public protocol Session: NetworkConnection {
    /// The stream instance.
    var stream: any StreamConvertible { get }

    /// Creates a new session with uri.
    init(uri: URL)

    /// Sets a max retry count.
    func setMaxRetryCount(_ maxRetryCount: Int)

    /// Creates a connection to the server.
    func connect(_ method: SessionMethod) async throws
}

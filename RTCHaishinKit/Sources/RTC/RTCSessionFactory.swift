import Foundation
import HaishinKit

public struct RTCSessionFactory: SessionFactory {
    public let supportedProtocols: Set<String> = ["http", "https"]

    public init() {
    }

    public func make(_ uri: URL, method: SessionMethod) -> any Session {
        switch method {
        case .ingest:
            return WHEPSession(uri: uri, method: method)
        case .playback:
            return WHEPSession(uri: uri, method: method)
        }
    }
}

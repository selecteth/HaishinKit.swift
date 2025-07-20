import Foundation
import HaishinKit

public struct SRTSessionFactory: SessionFactory {
    public let supportedProtocols: Set<String> = ["srt"]

    public init() {
    }

    public func make(_ uri: URL) -> any Session {
        return SRTSession(uri: uri)
    }
}

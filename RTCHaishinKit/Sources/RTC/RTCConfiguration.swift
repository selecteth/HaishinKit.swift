import Foundation
import libdatachannel

struct RTCConfiguration: Sendable {
    let iceServers: [String]

    init(iceServers: [String]) {
        self.iceServers = iceServers
    }

    var cValue: rtcConfiguration {
        var config = rtcConfiguration()
        return rtcConfiguration()
    }
}

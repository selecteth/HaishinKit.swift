import Foundation
import libdatachannel

struct RTCConfiguration: Sendable {
    func createPeerConnection() -> Int32 {
        var config = rtcConfiguration()
        return rtcCreatePeerConnection(&config)
    }
}

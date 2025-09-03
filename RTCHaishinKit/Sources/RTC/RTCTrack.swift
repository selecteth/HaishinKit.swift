import Foundation
import libdatachannel

protocol RTCTrackDelegate: AnyObject {
    func track(_ track: RTCTrack, didSetOpen open: Bool)
    func track(_ track: RTCTrack, didReceiveMessage message: Data)
}

final class RTCTrack: RTCChannel {
    weak var delegate: (any RTCTrackDelegate)?

    override var isOpen: Bool {
        didSet {
            delegate?.track(self, didSetOpen: isOpen)
        }
    }

    var mid: String {
        return CUtil.getString { buffer, size in
            rtcGetTrackMid(id, buffer, size)
        }
    }

    var description: String {
        return CUtil.getString { buffer, size in
            rtcGetTrackDescription(id, buffer, size)
        }
    }

    var ssrc: UInt32 {
        return CUtil.getUInt32 { buffer, size in
            rtcGetSsrcsForTrack(id, buffer, size)
        }
    }

    deinit {
        rtcDeleteTrack(id)
    }

    override func didReceiveMessage(_ message: Data) {
        delegate?.track(self, didReceiveMessage: message)
    }
}

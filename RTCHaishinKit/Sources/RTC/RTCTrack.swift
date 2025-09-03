import Foundation
import libdatachannel

protocol RTCTrackDelegate: AnyObject {
    func track(_ track: RTCTrack, didSetIsOpen isOpen: Bool)
    func track(_ track: RTCTrack, didReceiveMessage message: Data)
}

final class RTCTrack: RTCChannel {
    weak var delegate: RTCTrackDelegate?

    override var isOpen: Bool {
        didSet {
            delegate?.track(self, didSetIsOpen: isOpen)
        }
    }

    deinit {
        rtcDeleteTrack(id)
    }

    override func didReceiveMessage(_ message: Data) {
        delegate?.track(self, didReceiveMessage: message)
    }
}

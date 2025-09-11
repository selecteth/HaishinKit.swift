import AVFAudio
import CoreMedia
import Foundation
import libdatachannel

protocol RTCTrackDelegate: AnyObject {
    func track(_ track: RTCTrack, didSetOpen open: Bool)
    func track(_ track: RTCTrack, didOutput buffer: CMSampleBuffer)
}

final class RTCTrack: RTCChannel {
    weak var delegate: (any RTCTrackDelegate)?

    override var isOpen: Bool {
        didSet {
            delegate?.track(self, didSetOpen: isOpen)
            if description.contains("audio") {
                let p = RTPOpusPacketizer<RTCTrack>(ssrc: ssrc, payloadType: 111)
                p.delegate = self
                packetizer = p
            }
            if description.contains("video") {
                let p = RTPH264Packetizer<RTCTrack>(ssrc: ssrc, payloadType: 98)
                p.delegate = self
                packetizer = p
            }
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

    private var packetizer: (any RTPPacketizer)?

    deinit {
        rtcDeleteTrack(id)
    }

    func append(_ buffer: CMSampleBuffer) {
        packetizer?.append(buffer) { packet in
            try? send(packet.data)
        }
    }

    func append(_ buffer: AVAudioCompressedBuffer, when: AVAudioTime) {
        packetizer?.append(buffer, when: when) { packet in
            try? send(packet.data)
        }
    }

    override func didReceiveMessage(_ message: Data) {
        do {
            let packet = try RTPPacket(message)
            packetizer?.append(packet)
        } catch {
            logger.warn(error)
        }
    }
}

extension RTCTrack: RTPPacketizerDelegate {
    // MARK: RTPPacketizerDelegate
    func packetizer(_ packetizer: some RTPPacketizer, didOutput buffer: CMSampleBuffer) {
        delegate?.track(self, didOutput: buffer)
    }
}

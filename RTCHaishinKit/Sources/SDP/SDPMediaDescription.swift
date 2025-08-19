import Foundation
import HaishinKit
import libdatachannel

protocol SDPMediaDescription {
    var ssrc: UInt32 { get }
    var pt: Int32 { get }
    var mid: String { get }
    var msid: String { get }
    var trackId: String { get }

    func makeRtcTrackInit(_ direction: RTCDirection) throws -> rtcTrackInit
}

struct SDPAudioDescription: Sendable, SDPMediaDescription {
    let format: AudioCodecSettings.Format
    let ssrc: UInt32
    let pt: Int32
    let mid: String
    let msid: String
    let trackId: String

    init(format: AudioCodecSettings.Format, ssrc: UInt32, pt: Int32, mid: String = "", msid: String = "", trackId: String = "") {
        self.format = format
        self.ssrc = ssrc
        self.pt = pt
        self.mid = mid
        self.msid = msid
        self.trackId = trackId
    }
}

extension SDPAudioDescription {
    func makeRtcTrackInit(_ direction: RTCDirection) throws -> rtcTrackInit {
        guard let codec = format.cValue else {
            throw RTCError.failure
        }
        return rtcTrackInit(
            direction: direction.cValue,
            codec: codec,
            payloadType: pt,
            ssrc: ssrc,
            mid: strdup(mid),
            name: strdup("hoge"),
            msid: strdup(msid),
            trackId: strdup(trackId),
            profile: nil
        )
    }
}

struct SDPVideoDescription: Sendable, SDPMediaDescription {
    let format: VideoCodecSettings.Format
    let ssrc: UInt32
    let pt: Int32
    let mid: String
    let msid: String
    let trackId: String

    init(format: VideoCodecSettings.Format, ssrc: UInt32, pt: Int32, mid: String = "", msid: String = "", trackId: String = "") {
        self.format = format
        self.ssrc = ssrc
        self.pt = pt
        self.mid = mid
        self.msid = msid
        self.trackId = trackId
    }
}

extension SDPVideoDescription {
    func makeRtcTrackInit(_ direction: RTCDirection) throws -> rtcTrackInit {
        return rtcTrackInit(
            direction: direction.cValue,
            codec: format.cValue,
            payloadType: pt,
            ssrc: ssrc,
            mid: strdup(mid),
            name: strdup("hoge2"),
            msid: strdup(msid),
            trackId: strdup(trackId),
            profile: nil
        )
    }
}

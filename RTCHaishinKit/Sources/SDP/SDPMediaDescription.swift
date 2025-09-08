import Foundation
import HaishinKit
import libdatachannel

protocol SDPMediaDescription {
    var ssrc: UInt32 { get }
    var pt: Int32 { get }
    var mid: String { get }
    var name: String { get }
    var msid: String { get }
    var trackId: String { get }

    func makeRtcTrackInit(_ direction: RTCDirection) throws -> rtcTrackInit
}

struct SDPAudioDescription: Sendable, SDPMediaDescription {
    let format: AudioCodecSettings.Format
    let ssrc: UInt32
    let pt: Int32
    let mid: String
    let name: String
    let msid: String
    let trackId: String
}

extension SDPAudioDescription {
    func makeRtcTrackInit(_ direction: RTCDirection) throws -> rtcTrackInit {
        guard let codec = format.cValue else {
            throw RTCError.failure
        }
        // TODO: Fix memory leak
        return rtcTrackInit(
            direction: direction.cValue,
            codec: codec,
            payloadType: pt,
            ssrc: ssrc,
            mid: strdup(mid),
            name: strdup(name),
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
    let name: String
    let msid: String
    let trackId: String
}

extension SDPVideoDescription {
    func makeRtcTrackInit(_ direction: RTCDirection) throws -> rtcTrackInit {
        // TODO: Fix memory leak

        var profile = "level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=42e01f"

        return rtcTrackInit(
            direction: direction.cValue,
            codec: format.cValue,
            payloadType: pt,
            ssrc: ssrc,
            mid: strdup(mid),
            name: strdup(name),
            msid: strdup(msid),
            trackId: strdup(trackId),
            profile: strdup(profile)
        )
    }
}

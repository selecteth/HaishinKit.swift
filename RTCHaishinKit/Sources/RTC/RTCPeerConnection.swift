import Foundation
import libdatachannel

protocol RTCPeerConnectionDelegate: AnyObject {
    func peerConnection(_ peerConnection: RTCPeerConnection, didSet state: RTCState)
    func peerConnection(_ peerConnection: RTCPeerConnection, didSet gatheringState: RTCGatheringState)
    func peerConnection(_ peerConnection: RTCPeerConnection, didReceive track: RTCTrack)
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidated: RTCICECandidate)
}

final class RTCPeerConnection {
    static let bufferSize: Int = 1024 * 16

    weak var delegate: (any RTCPeerConnectionDelegate)?
    private let connection: Int32
    private(set) var state: RTCState = .new {
        didSet {
            delegate?.peerConnection(self, didSet: state)
        }
    }
    private(set) var tracks: [RTCTrack] = []
    private(set) var iceState: RTCICEState = .new
    private(set) var candidates: [RTCICECandidate] = []
    private(set) var signalingState: RTCSignalingState = .stable
    private(set) var gatheringState: RTCGatheringState = .new {
        didSet {
            delegate?.peerConnection(self, didSet: gatheringState)
        }
    }
    private(set) var localDescription: String = ""

    init() {
        var config = RTCConfiguration(iceServers: []).cValue
        connection = rtcCreatePeerConnection(&config)
        rtcSetUserPointer(connection, Unmanaged.passUnretained(self).toOpaque())
        rtcSetLocalDescriptionCallback(connection) { _, sdp, _, pointer in
            guard let pointer else { return }
            if let sdp {
                Unmanaged<RTCPeerConnection>.fromOpaque(pointer).takeUnretainedValue().localDescription = String(cString: sdp)
            }
        }
        rtcSetLocalCandidateCallback(connection) { _, candidate, mid, pointer in
            guard let pointer else { return }
            Unmanaged<RTCPeerConnection>.fromOpaque(pointer).takeUnretainedValue().didGenerateCandidate(.init(
                candidate: candidate,
                mid: mid
            ))
        }
        rtcSetStateChangeCallback(connection) { _, state, pointer in
            guard let pointer else { return }
            if let state = RTCState(cValue: state) {
                Unmanaged<RTCPeerConnection>.fromOpaque(pointer).takeUnretainedValue().state = state
            }
        }
        rtcSetGatheringStateChangeCallback(connection) { _, gatheringState, pointer in
            guard let pointer else { return }
            if let gatheringState = RTCGatheringState(cValue: gatheringState) {
                Unmanaged<RTCPeerConnection>.fromOpaque(pointer).takeUnretainedValue().gatheringState = gatheringState
            }
        }
        rtcSetSignalingStateChangeCallback(connection) { _, signalingState, pointer in
            guard let pointer else { return }
            if let signalingState = RTCSignalingState(cValue: signalingState) {
                Unmanaged<RTCPeerConnection>.fromOpaque(pointer).takeUnretainedValue().signalingState = signalingState
            }
        }
        rtcSetTrackCallback(connection) { _, track, pointer in
            guard let pointer else { return }
            Unmanaged<RTCPeerConnection>.fromOpaque(pointer).takeUnretainedValue().didReceiveTrack(.init(id: track))
        }
    }

    deinit {
        tracks.removeAll()
        rtcDeletePeerConnection(connection)
    }

    func addTrack(_ media: (some SDPMediaDescription), direction: RTCDirection) throws -> RTCTrack {
        var trackInit = try media.makeRtcTrackInit(direction)
        let result = try RTCError.check(rtcAddTrackEx(connection, &trackInit))
        let track = RTCTrack(id: result)
        tracks.append(track)
        return track
    }

    func addTrack(_ sdp: String) throws -> RTCTrack {
        let result = try RTCError.check(sdp.withCString { cString in
            rtcAddTrack(connection, cString)
        })
        let track = RTCTrack(id: result)
        tracks.append(track)
        return track
    }

    func setRemoteDesciption(_ sdp: String, type: SDPSessionDescriptionType) throws {
        logger.debug(sdp, type.rawValue)
        try RTCError.check([sdp, type.rawValue].withCStrings { cStrings in
            rtcSetRemoteDescription(connection, cStrings[0], cStrings[1])
        })
    }

    func setLocalDesciption(_ type: SDPSessionDescriptionType) throws {
        logger.debug(type.rawValue)
        try RTCError.check([type.rawValue].withCStrings { cStrings in
            rtcSetLocalDescription(connection, cStrings[0])
        })
    }

    func createOffer() -> String {
        return CUtil.getString { buffer, size in
            rtcCreateOffer(connection, buffer, size)
        }
    }

    func createAnswer() -> String {
        return CUtil.getString { buffer, size in
            rtcCreateAnswer(connection, buffer, size)
        }
    }

    func close() {
        do {
            try RTCError.check(rtcClosePeerConnection(connection))
        } catch {
            logger.warn(error)
        }
    }

    private func didGenerateCandidate(_ candidated: RTCICECandidate) {
        candidates.append(candidated)
        delegate?.peerConnection(self, didGenerate: candidated)
    }

    private func didReceiveTrack(_ track: RTCTrack) {
        delegate?.peerConnection(self, didReceive: track)
    }
}

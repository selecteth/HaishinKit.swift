import Foundation
import HaishinKit

actor HTTPSession: Session {
    static let audioMediaDescription = """
m=audio 9 UDP/TLS/RTP/SAVPF 111
a=mid:0
a=recvonly
a=rtpmap:111 opus/48000/2
a=fmtp:111 minptime=10;useinbandfec=1;stereo=1;sprop-stereo=1
"""

    static let videoMediaDescription = """
m=video 9 UDP/TLS/RTP/SAVPF 98
a=mid:1
a=recvonly
a=rtpmap:98 H264/90000
a=rtcp-fb:98 goog-remb
a=rtcp-fb:98 nack
a=rtcp-fb:98 nack pli
a=fmtp:98 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=42e01f
"""

    var connected: Bool {
        get async {
            peerConnection.state == .connected
        }
    }

    @AsyncStreamed(.closed)
    private(set) var readyState: AsyncStream<SessionReadyState>

    var stream: any StreamConvertible {
        _stream
    }

    private let uri: URL
    private var location: URL?
    private var maxRetryCount: Int = 0
    private var _stream = RTCMediaStream()
    private var method: SessionMethod
    private lazy var peerConnection: RTCPeerConnection = {
        let conneciton = RTCPeerConnection()
        conneciton.delegate = self
        return conneciton
    }()

    init(uri: URL, method: SessionMethod) {
        logger.level = .debug
        self.uri = uri
        self.method = method
    }

    func setMaxRetryCount(_ maxRetryCount: Int) {
        self.maxRetryCount = maxRetryCount
    }

    func connect(_ disconnected: @Sendable @escaping () -> Void) async throws {
        _readyState.value = .connecting
        switch method {
        case .ingest:
            try await _stream.setAudioSettings(.init(format: .opus))
            let audioTrack = try peerConnection.addTrack(SDPAudioDescription(
                                                            format: .opus,
                                                            ssrc: 12345678,
                                                            pt: 111,
                                                            mid: "0",
                                                            name: "audio1",
                                                            msid: "stream-0",
                                                            trackId: "audio1-track1"), direction: .sendonly
            )
            audioTrack.delegate = _stream
            let videoTrack = try peerConnection.addTrack(SDPVideoDescription(
                                                            format: .h264,
                                                            ssrc: 12345679,
                                                            pt: 98,
                                                            mid: "1",
                                                            name: "video1",
                                                            msid: "stream-1",
                                                            trackId: "video1-track1"), direction: .sendonly)
            videoTrack.delegate = _stream
        case .playback:
            await _stream.setDirection(.recvonly)
            let audioTrack = try peerConnection.addTrack(Self.audioMediaDescription)
            audioTrack.delegate = _stream
            let videoTrack = try peerConnection.addTrack(Self.videoMediaDescription)
            videoTrack.delegate = _stream
        }
        do {
            try peerConnection.setLocalDesciption(.offer)
            let answer = try await requestOffer(uri, offer: peerConnection.createOffer())
            try peerConnection.setRemoteDesciption(answer, type: .answer)
            _readyState.value = .open
        } catch {
            logger.warn(error)
            _readyState.value = .closed
            throw error
        }
    }

    func close() async throws {
        guard let location else {
            return
        }
        _readyState.value = .closing
        var request = URLRequest(url: location)
        request.httpMethod = "DELETE"
        request.addValue("application/sdp", forHTTPHeaderField: "Content-Type")
        _ = try await URLSession.shared.data(for: request)
        peerConnection.close()
        self.location = nil
        _readyState.value = .closed
    }

    private func requestOffer(_ url: URL, offer: String) async throws -> String {
        logger.debug(offer)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/sdp", forHTTPHeaderField: "Content-Type")
        request.httpBody = offer.data(using: .utf8)
        let (data, response) = try await URLSession.shared.data(for: request)
        if let response = response as? HTTPURLResponse {
            if let location = response.allHeaderFields["Location"] as? String {
                if location.hasSuffix("http") {
                    self.location = URL(string: location)
                } else {
                    var baseURL = "\(url.scheme ?? "http")://\(url.host ?? "")"
                    if let port = url.port {
                        baseURL += ":\(port)"
                    }
                    self.location = URL(string: "\(baseURL)\(location)")
                }
            }
        }
        return String(data: data, encoding: .utf8) ?? ""
    }
}

extension HTTPSession: RTCPeerConnectionDelegate {
    // MARK: RTCPeerConnectionDelegate
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didSet gatheringState: RTCGatheringState) {
    }

    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didSet state: RTCState) {
        Task {
            if (state == .connected) {
                await _stream.setDirection(.sendonly)
            }
        }
    }

    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didReceive track: RTCTrack) {
    }
    
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidated: RTCICECandidate) {
    
    }
}

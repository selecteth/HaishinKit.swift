import Foundation
import Logboard

/// https://datatracker.ietf.org/doc/draft-ietf-wish-whep/
actor WHEPConnection {
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

    private(set) lazy var stream = RTCStream()
    private lazy var peerConnection = {
        let connection = RTCPeerConnection()
        connection.delegate = self
        return connection
    }()
    private var location: URL?

    init() {
        logger.level = .debug
    }

    func connect(_ url: URL) async throws {
        let audioTrack = try peerConnection.addTrack(Self.audioMediaDescription)
        audioTrack.delegate = stream
        let videoTrack = try peerConnection.addTrack(Self.videoMediaDescription)
        videoTrack.delegate = stream
        try peerConnection.setLocalDesciption(.offer)
        let answer = try await requestOffer(url, offer: peerConnection.createOffer())
        try peerConnection.setRemoteDesciption(answer, type: .answer)
    }

    func close() async throws {
        guard let location else {
            return
        }
        var request = URLRequest(url: location)
        request.httpMethod = "DELETE"
        request.addValue("application/sdp", forHTTPHeaderField: "Content-Type")
        _ = try await URLSession.shared.data(for: request)
        peerConnection.close()
        self.location = nil
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

extension WHEPConnection: RTCPeerConnectionDelegate {
    // MARK: PeerConnectionDelegate
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didSet gatheringState: RTCGatheringState) {
    }

    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didReceive track: RTCTrack) {
    }

    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidated: RTCICECandidate) {
    }
}

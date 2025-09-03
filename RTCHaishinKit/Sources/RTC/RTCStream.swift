import AVFoundation
import HaishinKit

actor RTCStream {
    /// The error domain code.
    enum Error: Swift.Error {
        /// An unsupported codec.
        case unsupportedCodec
    }

    static let supportedAudioCodecs: [AudioCodecSettings.Format] = [.aac, .opus]
    static let supportedVideoCodecs: [VideoCodecSettings.Format] = VideoCodecSettings.Format.allCases

    private(set) var videoTrackId: UInt8?
    private(set) var audioTrackId: UInt8?
    package lazy var incoming = IncomingStream(self)
    package lazy var outgoing = OutgoingStream()
    package var outputs: [any StreamOutput] = []
    package var readyState: StreamReadyState = .idle
    package var bitRateStrategy: (any StreamBitRateStrategy)?

    private lazy var videoPacketizer: any RTPPacketizer = {
        let packetizer = RTPH264Packetizer<RTCStream>()
        packetizer.delegate = self
        return packetizer
    }()

    private lazy var audioPacketizer: any RTPPacketizer = {
        let packetizer = RTPOpusPacketizer<RTCStream>()
        packetizer.delegate = self
        return packetizer
    }()
}

extension RTCStream: _Stream {
    func setAudioSettings(_ audioSettings: AudioCodecSettings) throws {
        guard Self.supportedAudioCodecs.contains(audioSettings.format) else {
            throw Error.unsupportedCodec
        }
        outgoing.audioSettings = audioSettings
    }

    func setVideoSettings(_ videoSettings: VideoCodecSettings) throws {
        guard Self.supportedVideoCodecs.contains(videoSettings.format) else {
            throw Error.unsupportedCodec
        }
        outgoing.videoSettings = videoSettings
    }

    func append(_ sampleBuffer: CMSampleBuffer) {
        switch sampleBuffer.formatDescription?.mediaType {
        case .video:
            if sampleBuffer.formatDescription?.isCompressed == true {
                Task { await incoming.append(sampleBuffer) }
            } else {
                outgoing.append(sampleBuffer)
                outputs.forEach { $0.stream(self, didOutput: sampleBuffer) }
            }
        case .audio:
            if sampleBuffer.formatDescription?.isCompressed == true {
                Task { await incoming.append(sampleBuffer) }
            } else {
                outgoing.append(sampleBuffer)
            }
        default:
            break
        }
    }

    func append(_ audioBuffer: AVAudioBuffer, when: AVAudioTime) {
    }

    func dispatch(_ event: NetworkMonitorEvent) async {
        await bitRateStrategy?.adjustBitrate(event, stream: self)
    }
}

extension RTCStream: RTPPacketizerDelegate {
    // MARK: RTPPacketizerDelegate
    nonisolated func packetizer(_ packetizer: some RTPPacketizer, didOutput sampleBuffer: CMSampleBuffer) {
        Task { await append(sampleBuffer) }
    }

    nonisolated func packetizer(_ packetizer: some RTPPacketizer, didOutput packet: RTPPacket) {
    }
}

extension RTCStream: RTCTrackDelegate {
    // MARK: RTCTrackDelegate
    nonisolated func track(_ track: RTCTrack, didSetIsOpen isOpen: Bool) {
        Task {
            await incoming.startRunning()
        }
    }

    nonisolated func track(_ track: RTCTrack, didReceiveMessage message: Data) {
        Task {
            do {
                await append(try RTPPacket(message))
            } catch {
                logger.warn(error)
            }
        }
    }

    private func append(_ packet: RTPPacket) {
        switch packet.payloadType {
        case 98:
            videoPacketizer.append(packet)
        case 111:
            audioPacketizer.append(packet)
        default:
            break
        }
    }
}

extension RTCStream: MediaMixerOutput {
    // MARK: MediaMixerOutput
    func selectTrack(_ id: UInt8?, mediaType: CMFormatDescription.MediaType) {
        switch mediaType {
        case .audio:
            audioTrackId = id
        case .video:
            videoTrackId = id
        default:
            break
        }
    }

    nonisolated public func mixer(_ mixer: MediaMixer, didOutput sampleBuffer: CMSampleBuffer) {
        Task { await append(sampleBuffer) }
    }

    nonisolated public func mixer(_ mixer: MediaMixer, didOutput buffer: AVAudioPCMBuffer, when: AVAudioTime) {
        Task { await append(buffer, when: when) }
    }
}

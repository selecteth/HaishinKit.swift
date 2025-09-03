import AVFoundation
import HaishinKit
import libdatachannel

actor RTCMediaStream {
    enum Error: Swift.Error {
        case unsupportedCodec
    }

    static let supportedAudioCodecs: [AudioCodecSettings.Format] = [.aac, .opus]
    static let supportedVideoCodecs: [VideoCodecSettings.Format] = VideoCodecSettings.Format.allCases

    private(set) var videoTrackId: UInt8? = UInt8.max
    private(set) var audioTrackId: UInt8? = UInt8.max
    package lazy var incoming = IncomingStream(self)
    package lazy var outgoing = OutgoingStream()
    package var outputs: [any StreamOutput] = []
    package var readyState: StreamReadyState = .idle
    package var bitRateStrategy: (any StreamBitRateStrategy)?
    private var mapper: [UInt32: Int32] = [:]

    private lazy var videoPacketizer: any RTPPacketizer = {
        let packetizer = RTPH264Packetizer<RTCMediaStream>()
        packetizer.delegate = self
        return packetizer
    }()

    private lazy var audioPacketizer: any RTPPacketizer = {
        let packetizer = RTPOpusPacketizer<RTCMediaStream>()
        packetizer.delegate = self
        return packetizer
    }()
    private var direction: RTCDirection = .sendonly

    func setDirection(_ direction: RTCDirection) {
        self.direction = direction
        switch direction {
        case .recvonly:
            Task {
                await incoming.startRunning()
            }
        case .sendonly:
            outgoing.startRunning()
            Task {
                for await audio in outgoing.audioOutputStream {
                    append(audio.0, when: audio.1)
                }
            }
            Task {
                for await video in outgoing.videoOutputStream {
                    append(video)
                }
            }
            Task {
                for await video in outgoing.videoInputStream {
                    outgoing.append(video: video)
                }
            }
        default:
            break
        }
    }

    private func send(_ packet: RTPPacket) {
        guard let track = mapper[packet.ssrc] else {
            return
        }
        do {
            let message = packet.data
            try RTCError.check(message.withUnsafeBytes { pointer in
                rtcSendMessage(track, pointer.bindMemory(to: CChar.self).baseAddress, Int32(message.count))
            })
        } catch {
            logger.warn(error)
        }
    }
}

extension RTCMediaStream: _Stream {
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
                guard mapper[videoPacketizer.ssrc] != nil else {
                    return
                }
                videoPacketizer.append(sampleBuffer) { packet in
                    send(packet)
                }
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
        switch audioBuffer {
        case let audioBuffer as AVAudioPCMBuffer:
            outgoing.append(audioBuffer, when: when)
            outputs.forEach { $0.stream(self, didOutput: audioBuffer, when: when) }
        case let audioBuffer as AVAudioCompressedBuffer:
            guard mapper[audioPacketizer.ssrc] != nil else {
                return
            }
            audioPacketizer.append(audioBuffer, when: when).forEach { packet in
                send(packet)
            }
        default:
            break
        }
    }

    func dispatch(_ event: NetworkMonitorEvent) async {
        await bitRateStrategy?.adjustBitrate(event, stream: self)
    }

    func addTrack(_ ssrc: UInt32, id: Int32) {
        mapper[ssrc] = id
    }
}

extension RTCMediaStream: RTPPacketizerDelegate {
    // MARK: RTPPacketizerDelegate
    nonisolated func packetizer(_ packetizer: some RTPPacketizer, didOutput sampleBuffer: CMSampleBuffer) {
        Task {
            await incoming.append(sampleBuffer)
        }
    }
}

extension RTCMediaStream: RTCTrackDelegate {
    // MARK: RTCTrackDelegate
    nonisolated func track(_ track: RTCTrack, didSetOpen isOpen: Bool) {
        let ssrc = track.ssrc
        let id = track.id
        Task {
            await addTrack(ssrc, id: id)
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

extension RTCMediaStream: MediaMixerOutput {
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

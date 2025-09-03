import AVFAudio
import CoreMedia
import Foundation
import HaishinKit

final class RTPOpusPacketizer<T: RTPPacketizerDelegate>: RTPPacketizer {
    weak var delegate: T?

    var ssrc: UInt32 = 12345678
    var payloadType: UInt8 = 111
    private var sequenceNumber: UInt16 = 0
    private var formatDescription: CMAudioFormatDescription?
    private lazy var jitterBuffer: RTPJitterBuffer<RTPOpusPacketizer> = {
        let jitterBuffer = RTPJitterBuffer<RTPOpusPacketizer>()
        jitterBuffer.delegate = self
        return jitterBuffer
    }()

    func append(_ packet: RTPPacket) {
        jitterBuffer.append(packet)
    }

    func append(_ buffer: CMSampleBuffer, lambda: (RTPPacket) -> Void) {
    }

    func append(_ buffer: AVAudioCompressedBuffer, when: AVAudioTime) -> [RTPPacket] {
        let packet = RTPPacket(
            version: RTPPacket.version,
            padding: false,
            extension: false,
            cc: 0,
            marker: true,
            payloadType: payloadType,
            sequenceNumber: sequenceNumber,
            timestamp: timestamp,
            ssrc: ssrc,
            payload: Data(
                bytes: buffer.data.assumingMemoryBound(to: UInt8.self),
                count: Int(buffer.byteLength)
            )
        )
        timestamp += 960
        sequenceNumber &+= 1
        return [packet]
    }

    var timestamp: UInt32 = 0
    var baseRtpTimestamp: UInt32 = 0
    var baseSampleTime: AVAudioFramePosition = -1
    let sampleRate: Double = 48_000

    private func timestamp(for audioTime: AVAudioTime) -> UInt32 {
        if baseSampleTime == -1 {
            baseSampleTime = audioTime.sampleTime
        }
        let delta = audioTime.sampleTime - baseSampleTime
        return baseRtpTimestamp &+ UInt32(delta)
    }

    private func decode(_ packet: RTPPacket) {
        if formatDescription == nil {
            formatDescription = makeFormatDescription()
        }
        if let buffer = makeSampleBuffer(packet.payload, timestamp: packet.timestamp) {
            delegate?.packetizer(self, didOutput: buffer)
        }
    }

    private func makeSampleBuffer(_ buffer: Data, timestamp: UInt32) -> CMSampleBuffer? {
        guard formatDescription != nil else {
            return nil
        }
        let presentationTimeStamp: CMTime = .init(value: CMTimeValue(timestamp), timescale: 48000)
        // TODO
        let newBuffer = Data([UInt8](repeating: 0, count: 7)) + buffer
        var blockBuffer: CMBlockBuffer?
        blockBuffer = newBuffer.makeBlockBuffer()
        var sampleSizes: [Int] = []
        var sampleBuffer: CMSampleBuffer?
        var timing = CMSampleTimingInfo(
            duration: .invalid,
            presentationTimeStamp: presentationTimeStamp,
            decodeTimeStamp: .invalid
        )
        sampleSizes.append(newBuffer.count)
        guard let blockBuffer, CMSampleBufferCreate(
                allocator: kCFAllocatorDefault,
                dataBuffer: blockBuffer,
                dataReady: true,
                makeDataReadyCallback: nil,
                refcon: nil,
                formatDescription: formatDescription,
                sampleCount: sampleSizes.count,
                sampleTimingEntryCount: 1,
                sampleTimingArray: &timing,
                sampleSizeEntryCount: sampleSizes.count,
                sampleSizeArray: &sampleSizes,
                sampleBufferOut: &sampleBuffer) == noErr else {
            return nil
        }
        sampleBuffer?.isNotSync = false
        return sampleBuffer
    }

    package func makeFormatDescription() -> CMFormatDescription? {
        var formatDescription: CMAudioFormatDescription?
        // TODO
        let framesPerPacket = AVAudioFrameCount(48000 * 0.02)
        var audioStreamBasicDescription = AudioStreamBasicDescription(
            mSampleRate: 48000,
            mFormatID: kAudioFormatOpus,
            mFormatFlags: 0,
            mBytesPerPacket: 0,
            mFramesPerPacket: framesPerPacket,
            mBytesPerFrame: 0,
            mChannelsPerFrame: 2,
            mBitsPerChannel: 0,
            mReserved: 0
        )
        guard CMAudioFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            asbd: &audioStreamBasicDescription,
            layoutSize: 0,
            layout: nil,
            magicCookieSize: 0,
            magicCookie: nil,
            extensions: nil,
            formatDescriptionOut: &formatDescription
        ) == noErr else {
            return nil
        }
        return formatDescription
    }
}

extension RTPOpusPacketizer: RTPJitterBufferDelegate {
    // MARK: RTPJitterBufferDelegate
    func jitterBuffer(_ buffer: RTPJitterBuffer<RTPOpusPacketizer<T>>, sequenced: RTPPacket) {
        decode(sequenced)
    }
}

import Foundation

protocol RTPJitterBufferDelegate: AnyObject {
    func jitterBuffer(_ buffer: RTPJitterBuffer<Self>, sequenced: RTPPacket)
}

/// TODO: I prioritized getting it to run, so I haven’t implemented packet loss handling yet.
final class RTPJitterBuffer<T: RTPJitterBufferDelegate> {
    weak var delegate: T?
    private var buffer: [UInt16: RTPPacket] = [:]
    private var expectedSequence: UInt16 = 0

    func append(_ packet: RTPPacket) {
        buffer[packet.sequenceNumber] = packet
        while let packet = buffer[expectedSequence] {
            delegate?.jitterBuffer(self, sequenced: packet)
            buffer.removeValue(forKey: expectedSequence)
            expectedSequence &+= 1
        }
    }
}

import CoreMedia

protocol RTPPacketizerDelegate: AnyObject {
    func packetizer(_ packetizer: some RTPPacketizer, didOutput sampleBuffer: CMSampleBuffer)
    func packetizer(_ packetizer: some RTPPacketizer, didOutput packet: RTPPacket)
}

protocol RTPPacketizer {
    associatedtype T: RTPPacketizerDelegate

    var delegate: T? { get }

    func append(_ packet: RTPPacket)
}

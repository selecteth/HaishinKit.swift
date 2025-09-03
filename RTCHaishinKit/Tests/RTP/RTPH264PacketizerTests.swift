import AVFoundation
import Foundation
import Testing

@testable import RTCHaishinKit

@Suite struct RTPH264PacketizerTests {
    final class Delegate: RTPPacketizerDelegate {
        func packetizer(_ packetizer: some RTCHaishinKit.RTPPacketizer, didOutput buffer: CMSampleBuffer) {
        }
    }

    @Test func packet() throws {
        let packetizer = RTPH264Packetizer<Delegate>()
    }
}

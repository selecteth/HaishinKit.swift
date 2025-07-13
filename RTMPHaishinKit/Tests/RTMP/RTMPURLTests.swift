import AVFoundation
import Foundation
import Testing

@testable import RTMPHaishinKit

@Suite struct RTMPURLTests {
    @Test func main() {
        let url = RTMPURL(url: URL(string: "rtmp://localhost/live/live")!)
        #expect(url.streamName == "live")
        #expect(url.command == "rtmp://localhost/live")
    }
}

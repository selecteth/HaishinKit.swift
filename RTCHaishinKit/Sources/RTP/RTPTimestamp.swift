import CoreMedia
import Foundation

struct RTPTimestamp {
    private let rate: Double
    private var startedAt: Double = -1

    init(_ rate: Double) {
        self.rate = rate
    }

    func convert(_ timestamp: UInt32) -> CMTime {
        return CMTime(seconds: Double(timestamp), preferredTimescale: CMTimeScale(rate))
    }

    mutating func convert(_ time: CMTime) -> UInt32 {
        let seconds = time.seconds
        if startedAt == -1 {
            startedAt = seconds
        }
        let timestamp = UInt64((seconds - startedAt) * rate)
        return UInt32(timestamp & 0xFFFFFFFF)
    }

    mutating func reset() {
        startedAt = -1
    }
}

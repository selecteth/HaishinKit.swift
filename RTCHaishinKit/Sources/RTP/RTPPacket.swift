import Foundation

/// https://datatracker.ietf.org/doc/html/rfc3550
struct RTPPacket: Sendable {
    static let headerSize: Int = 12

    enum Error: Swift.Error {
        case bufferUnderrun
    }

    let version: UInt8
    let padding: Bool
    let `extension`: Bool
    let cc: UInt8
    let marker: Bool
    let payloadType: UInt8
    let sequenceNumber: UInt16
    let timestamp: UInt32
    let ssrc: UInt32
    let payload: Data
}

extension RTPPacket {
    init(_ data: Data) throws {
        guard RTPPacket.headerSize < data.count else {
            throw Error.bufferUnderrun
        }
        let first = data[0]
        version = (first & 0b11000000) >> 6
        padding = (first & 0b00100000) >> 5 == 1
        `extension` = (first & 0b00010000) >> 4 == 1
        cc = (first & 0b00001111)
        let second = data[1]
        marker = (second & 0b10000000) >> 7 == 1
        payloadType = (second & 0b01111111)
        sequenceNumber = UInt16(data[2]) << 8 | UInt16(data[3])
        timestamp = UInt32(data: data[4...7]).bigEndian
        ssrc = UInt32(data: data[8...11]).bigEndian
        payload = Data(data[12...])
    }
}

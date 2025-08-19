import CoreMedia
import Foundation

final package class NALUnitReader {
    static package let defaultNALUnitHeaderLength: Int32 = 4
    package var nalUnitHeaderLength: Int32 = NALUnitReader.defaultNALUnitHeaderLength

    package init() {
    }

    package func read<T: NALUnit>(_ data: inout Data, type: T.Type) -> [T] {
        var units: [T] = .init()
        var lastIndexOf = data.count - 1
        for i in (2..<data.count).reversed() {
            guard data[i] == 1 && data[i - 1] == 0 && data[i - 2] == 0 else {
                continue
            }
            let startCodeLength = 0 <= i - 3 && data[i - 3] == 0 ? 4 : 3
            units.append(T.init(data.subdata(in: (i + 1)..<lastIndexOf + 1)))
            lastIndexOf = i - startCodeLength
        }
        return units
    }
}

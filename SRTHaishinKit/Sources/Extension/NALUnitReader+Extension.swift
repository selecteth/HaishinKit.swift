import CoreMedia
import Foundation
import HaishinKit

extension NALUnitReader {
    func makeFormatDescription(_ data: inout Data, type: ESStreamType) -> CMFormatDescription? {
        switch type {
        case .h264:
            let units = read(&data, type: AVCNALUnit.self)
            return units.makeFormatDescription(nalUnitHeaderLength)
        case .h265:
            let units = read(&data, type: HEVCNALUnit.self)
            return units.makeFormatDescription(nalUnitHeaderLength)
        default:
            return nil
        }
    }
}

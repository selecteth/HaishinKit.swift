enum RTCError: Int32, Swift.Error {
    case invalid = -1
    case failure = -2
    case notAvail = -3
    case tooSmall = -4

    @discardableResult
    static func check(_ result: Int32) throws -> Int32 {
        if result < 0 {
            throw RTCError(rawValue: result) ?? .invalid
        }
        return result
    }
}

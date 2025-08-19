import libdatachannel

public actor RTCLogger {
    public enum Level {
        case none
        case fatal
        case error
        case warning
        case info
        case debug
        case verbose

        var cValue: rtcLogLevel {
            switch self {
            case .none:
                return RTC_LOG_NONE
            case .fatal:
                return RTC_LOG_FATAL
            case .error:
                return RTC_LOG_ERROR
            case .warning:
                return RTC_LOG_WARNING
            case .info:
                return RTC_LOG_INFO
            case .debug:
                return RTC_LOG_DEBUG
            case .verbose:
                return RTC_LOG_VERBOSE
            }
        }
    }

    public static let shared = RTCLogger()

    public private(set) var level: Level = .none

    public func setLevel(_ level: Level) {
        rtcInitLogger(level.cValue, nil)
    }
}

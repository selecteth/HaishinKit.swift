import Foundation

struct Preference: Sendable {
    // Temp
    static nonisolated(unsafe) var `default` = Preference()

    var uri: String? = "rtmp://192.168.1.7/live"
    var streamName: String? = "live"

    func makeURL() -> URL? {
        guard let uri, let streamName else {
            return nil
        }
        return URL(string: uri + "/" + streamName)
    }
}

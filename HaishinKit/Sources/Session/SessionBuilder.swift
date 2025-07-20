import Foundation

/// A structure that provides builder for Session object.
public struct SessionBuilder: Sendable {
    private let manager: SessionBuilderFactory
    private let uri: URL

    init(manager: SessionBuilderFactory, uri: URL) {
        self.manager = manager
        self.uri = uri
    }

    /// Creates a Session instance with the specified fields.
    public func build() async throws -> (any Session)? {
        return try await manager.build(uri)
    }
}

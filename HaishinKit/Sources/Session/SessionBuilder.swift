import Foundation

/// A structure that provides builder for Session object.
public actor SessionBuilder {
    private let factory: SessionBuilderFactory
    private let uri: URL
    private var method: SessionMethod = .ingest

    init(factory: SessionBuilderFactory, uri: URL) {
        self.factory = factory
        self.uri = uri
    }

    /// Sets a method.
    public func setMethod(_ method: SessionMethod) -> Self {
        self.method = method
        return self
    }

    /// Creates a Session instance with the specified fields.
    public func build() async throws -> (any Session)? {
        return try await factory.build(uri, method: method)
    }
}

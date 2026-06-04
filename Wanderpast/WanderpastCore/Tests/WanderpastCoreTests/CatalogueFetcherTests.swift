import Testing
import Foundation
@testable import WanderpastCore

@Suite("CatalogueFetcher", .serialized)
struct CatalogueFetcherTests {

    @Test("Successful response returns the body bytes")
    func successfulResponseReturnsData() async throws {
        let url = URL(string: "https://example.com/catalogue.json")!
        let payload = #"{"cities":[],"tours":[],"waypoints":[]}"#.data(using: .utf8)!
        StubURLProtocol.stub(status: 200, data: payload, for: url)
        let fetcher = CatalogueFetcher(session: StubURLProtocol.makeSession())

        let data = try await fetcher.fetch(from: url)

        #expect(data == payload)
    }

    @Test("Network unavailable throws CatalogueFetchError.networkUnavailable")
    func networkUnavailable() async throws {
        StubURLProtocol.reset()
        let url = URL(string: "https://example.com/x.json")!
        StubURLProtocol.failWith(
            error: URLError(.notConnectedToInternet),
            for: url
        )
        let fetcher = CatalogueFetcher(session: StubURLProtocol.makeSession())

        await #expect(throws: CatalogueFetchError.networkUnavailable) {
            try await fetcher.fetch(from: url)
        }
    }

    @Test("Timeout throws CatalogueFetchError.timeout")
    func timeoutError() async throws {
        StubURLProtocol.reset()
        let url = URL(string: "https://example.com/slow.json")!
        StubURLProtocol.failWith(error: URLError(.timedOut), for: url)
        let fetcher = CatalogueFetcher(session: StubURLProtocol.makeSession())

        await #expect(throws: CatalogueFetchError.timeout) {
            try await fetcher.fetch(from: url)
        }
    }

    @Test("404 response throws CatalogueFetchError.notFound")
    func notFoundResponse() async throws {
        StubURLProtocol.reset()
        let url = URL(string: "https://example.com/missing.json")!
        StubURLProtocol.stub(status: 404, data: Data(), for: url)
        let fetcher = CatalogueFetcher(session: StubURLProtocol.makeSession())

        await #expect(throws: CatalogueFetchError.notFound) {
            try await fetcher.fetch(from: url)
        }
    }
}

// MARK: - URLProtocol stub

private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    private struct Stub {
        let status: Int
        let data: Data
    }
    nonisolated(unsafe) private static var stubs: [URL: Stub] = [:]
    nonisolated(unsafe) private static var errors: [URL: Error] = [:]
    private static let lock = NSLock()

    static func reset() {
        lock.lock(); defer { lock.unlock() }
        stubs.removeAll()
        errors.removeAll()
    }

    static func stub(status: Int, data: Data, for url: URL) {
        lock.lock(); defer { lock.unlock() }
        stubs[url] = Stub(status: status, data: data)
    }

    static func failWith(error: Error, for url: URL) {
        lock.lock(); defer { lock.unlock() }
        errors[url] = error
    }

    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: config)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else { return }
        Self.lock.lock()
        let error = Self.errors[url]
        let stub = Self.stubs[url]
        Self.lock.unlock()

        if let error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        if let stub {
            let response = HTTPURLResponse(
                url: url,
                statusCode: stub.status,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: stub.data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

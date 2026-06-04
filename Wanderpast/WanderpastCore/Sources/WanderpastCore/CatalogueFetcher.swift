import Foundation

public enum CatalogueFetchError: Error, Equatable, Sendable {
    case notFound
    case networkUnavailable
    case timeout
    case unexpectedResponse
}

public protocol CatalogueFetching: Sendable {
    func fetch(from url: URL) async throws -> Data
}

public struct CatalogueFetcher: CatalogueFetching {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetch(from url: URL) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet,
                 .networkConnectionLost,
                 .cannotConnectToHost,
                 .cannotFindHost,
                 .dnsLookupFailed:
                throw CatalogueFetchError.networkUnavailable
            case .timedOut:
                throw CatalogueFetchError.timeout
            default:
                throw CatalogueFetchError.unexpectedResponse
            }
        }
        guard let http = response as? HTTPURLResponse else {
            throw CatalogueFetchError.unexpectedResponse
        }
        switch http.statusCode {
        case 200..<300: return data
        case 404: throw CatalogueFetchError.notFound
        default: throw CatalogueFetchError.unexpectedResponse
        }
    }
}

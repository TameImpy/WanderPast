import Foundation

public enum CatalogueError: Error, Equatable, Sendable {
    case empty
    case malformed
    case invalid(field: String)
}

public enum CatalogueParser {
    public static func parse(data: Data) throws -> Catalogue {
        guard !data.isEmpty else { throw CatalogueError.empty }
        do {
            return try JSONDecoder().decode(Catalogue.self, from: data)
        } catch let DecodingError.keyNotFound(key, _) {
            throw CatalogueError.invalid(field: key.stringValue)
        } catch let DecodingError.typeMismatch(_, context) {
            throw CatalogueError.invalid(field: context.codingPath.last?.stringValue ?? "unknown")
        } catch let DecodingError.valueNotFound(_, context) {
            throw CatalogueError.invalid(field: context.codingPath.last?.stringValue ?? "unknown")
        } catch is DecodingError {
            throw CatalogueError.malformed
        }
    }
}

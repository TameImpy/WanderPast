import Foundation

public protocol CatalogueCaching: Sendable {
    func save(data: Data) throws
    func loadCachedData() -> Data?
    var lastFetchDate: Date? { get }
}

public struct CatalogueCache: CatalogueCaching {
    private let directory: URL
    private let filename: String

    public init(directory: URL, filename: String = "catalogue.json") {
        self.directory = directory
        self.filename = filename
    }

    private var fileURL: URL {
        directory.appendingPathComponent(filename)
    }

    public func save(data: Data) throws {
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        try data.write(to: fileURL, options: .atomic)
    }

    public func loadCachedData() -> Data? {
        try? Data(contentsOf: fileURL)
    }

    public var lastFetchDate: Date? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
        return attributes?[.modificationDate] as? Date
    }
}

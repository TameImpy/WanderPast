import Testing
import Foundation
@testable import WanderpastCore

@Suite("CatalogueCache")
struct CatalogueCacheTests {

    @Test("Saving then loading returns the same bytes")
    func saveThenLoadRoundTrips() throws {
        let dir = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let cache = CatalogueCache(directory: dir)
        let payload = "hello".data(using: .utf8)!

        try cache.save(data: payload)
        let loaded = cache.loadCachedData()

        #expect(loaded == payload)
    }

    @Test("Empty cache returns nil for both data and date")
    func emptyCacheReturnsNil() throws {
        let dir = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let cache = CatalogueCache(directory: dir)

        #expect(cache.loadCachedData() == nil)
        #expect(cache.lastFetchDate == nil)
    }

    @Test("After save, lastFetchDate is non-nil")
    func lastFetchDateAfterSave() throws {
        let dir = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let cache = CatalogueCache(directory: dir)

        try cache.save(data: Data("x".utf8))

        #expect(cache.lastFetchDate != nil)
    }
}

// MARK: - Helpers

private func makeTempDirectory() throws -> URL {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
}

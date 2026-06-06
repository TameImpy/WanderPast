import Foundation

public struct RemoteUserPayload: Equatable, Codable, Sendable {
    public let stableID: String
    public let completedTourIDs: [String]
    public let ownedProductIDs: [String]
    public let updatedAt: Date

    public init(
        stableID: String,
        completedTourIDs: [String],
        ownedProductIDs: [String],
        updatedAt: Date
    ) {
        self.stableID = stableID
        self.completedTourIDs = completedTourIDs
        self.ownedProductIDs = ownedProductIDs
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case stableID = "stable_id"
        case completedTourIDs = "completed_tour_ids"
        case ownedProductIDs = "owned_product_ids"
        case updatedAt = "updated_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.stableID = try container.decode(String.self, forKey: .stableID)
        self.completedTourIDs = try container.decodeIfPresent([String].self, forKey: .completedTourIDs) ?? []
        self.ownedProductIDs = try container.decodeIfPresent([String].self, forKey: .ownedProductIDs) ?? []
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    public static func merging(local: RemoteUserPayload, remote: RemoteUserPayload) -> RemoteUserPayload {
        let completed = Set(local.completedTourIDs).union(remote.completedTourIDs).sorted()
        let owned = Set(local.ownedProductIDs).union(remote.ownedProductIDs).sorted()
        return RemoteUserPayload(
            stableID: local.stableID,
            completedTourIDs: completed,
            ownedProductIDs: owned,
            updatedAt: max(local.updatedAt, remote.updatedAt)
        )
    }

    public static let wireEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    public static let wireDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

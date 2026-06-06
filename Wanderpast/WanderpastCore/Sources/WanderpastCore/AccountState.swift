import Foundation

public struct AccountIdentity: Equatable, Codable, Sendable {
    public let stableID: String
    public let fullName: String?
    public let email: String?

    public init(stableID: String, fullName: String? = nil, email: String? = nil) {
        self.stableID = stableID
        self.fullName = fullName
        self.email = email
    }
}

public enum AccountState: Equatable, Sendable {
    case signedOut
    case signedIn(AccountIdentity)
}

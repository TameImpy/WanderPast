import AuthenticationServices
import UIKit
import WanderpastCore

/// Thin async wrapper around `ASAuthorizationAppleIDProvider`. Calling
/// `signIn()` presents the Apple sign-in sheet and resolves to an
/// `AccountIdentity` (stableID + optional name/email returned on first
/// authorisation only — Apple omits them on subsequent sign-ins).
@MainActor
final class AppleSignInController: NSObject {
    enum SignInError: Error {
        case cancelled
        case failed(underlying: Error)
    }

    private var continuation: CheckedContinuation<AccountIdentity, Error>?

    func signIn() async throws -> AccountIdentity {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }
}

extension AppleSignInController: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation?.resume(throwing: SignInError.failed(
                underlying: NSError(domain: "AppleSignIn", code: -1)
            ))
            continuation = nil
            return
        }

        let formatter = PersonNameComponentsFormatter()
        let fullName = credential.fullName.map { formatter.string(from: $0) }
            .flatMap { $0.isEmpty ? nil : $0 }

        let identity = AccountIdentity(
            stableID: credential.user,
            fullName: fullName,
            email: credential.email
        )

        continuation?.resume(returning: identity)
        continuation = nil
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        if let asError = error as? ASAuthorizationError, asError.code == .canceled {
            continuation?.resume(throwing: SignInError.cancelled)
        } else {
            continuation?.resume(throwing: SignInError.failed(underlying: error))
        }
        continuation = nil
    }
}

extension AppleSignInController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })
            ?? ASPresentationAnchor()
    }
}

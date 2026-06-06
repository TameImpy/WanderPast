import SwiftUI
import AuthenticationServices
import WanderpastCore

struct SettingsView: View {
    @EnvironmentObject private var accountStore: AccountStore

    var body: some View {
        ZStack {
            Color.warmPaper.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 24) {
                header
                body(for: accountStore.state)
                Spacer()
                syncStatus
            }
            .padding(24)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("ACCOUNT")
                .font(.overline)
                .foregroundStyle(Color.stone)
            Text("Settings")
                .font(.displayLarge)
                .foregroundStyle(Color.deepInk)
        }
    }

    @ViewBuilder
    private func body(for state: AccountState) -> some View {
        switch state {
        case .signedOut:
            signedOutBody
        case .signedIn(let identity):
            signedInBody(identity: identity)
        }
    }

    private var signedOutBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sign in to sync your completed tours across devices and restore them after reinstalling.")
                .font(.bodyPrimary)
                .foregroundStyle(Color.charcoal)

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { _ in
                Task { await accountStore.signIn() }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 48)
            .clipShape(Capsule())

            Text("Free tours don't need an account.")
                .font(.caption)
                .foregroundStyle(Color.stone)
        }
    }

    private func signedInBody(identity: AccountIdentity) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("SIGNED IN AS")
                    .font(.overline)
                    .foregroundStyle(Color.stone)
                Text(identity.fullName ?? identity.email ?? "Apple account")
                    .font(.displaySmall)
                    .foregroundStyle(Color.deepInk)
                if let email = identity.email, identity.fullName != nil {
                    Text(email)
                        .font(.bodySecondary)
                        .foregroundStyle(Color.charcoal)
                }
            }

            Button {
                Task { await accountStore.syncIfSignedIn() }
            } label: {
                Text("Sync now")
                    .font(.bodyPrimary.weight(.medium))
                    .foregroundStyle(Color.deepInk)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.parchment))
            }

            Button {
                accountStore.signOut()
            } label: {
                Text("Sign out")
                    .font(.bodyPrimary.weight(.medium))
                    .foregroundStyle(Color.burntSienna)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .overlay(
                        Capsule().stroke(Color.burntSienna.opacity(0.4), lineWidth: 1)
                    )
            }
        }
    }

    @ViewBuilder
    private var syncStatus: some View {
        switch accountStore.syncState {
        case .idle:
            EmptyView()
        case .syncing:
            Label("Syncing…", systemImage: "arrow.triangle.2.circlepath")
                .font(.caption)
                .foregroundStyle(Color.stone)
        case .synced(let at):
            Label("Synced \(at.formatted(date: .omitted, time: .shortened))", systemImage: "checkmark.circle")
                .font(.caption)
                .foregroundStyle(Color.stone)
        case .failed(let retryable):
            Label(
                retryable ? "Sync failed. Tap Sync now to retry." : "Sign in again to resume sync.",
                systemImage: "exclamationmark.triangle"
            )
            .font(.caption)
            .foregroundStyle(Color.burntSienna)
        }
    }
}

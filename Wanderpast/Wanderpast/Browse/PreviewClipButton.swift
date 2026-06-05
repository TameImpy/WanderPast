import SwiftUI

/// Plays a 60-second preview clip of a tour via `AudioEngine.playPreviewClip(url:)`.
/// Renders as a pill button that toggles label/style while the clip is playing.
/// Disabled when `url` is nil (catalogue entry has no preview clip available).
struct PreviewClipButton: View {
    let url: URL?
    @ObservedObject var audioEngine: AudioEngine

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: WPSpacing.xs) {
                Image(systemName: audioEngine.isPreviewPlaying ? "stop.fill" : "play.fill")
                Text(audioEngine.isPreviewPlaying ? "STOP PREVIEW" : "PLAY 60-SEC PREVIEW")
                    .font(.overline)
                    .tracking(2)
            }
            .foregroundStyle(audioEngine.isPreviewPlaying ? Color.warmPaper : Color.terracotta)
            .padding(.horizontal, WPSpacing.md)
            .padding(.vertical, WPSpacing.sm)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: WPRadius.sm)
                    .fill(audioEngine.isPreviewPlaying ? Color.terracotta : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: WPRadius.sm)
                    .stroke(Color.terracotta, lineWidth: 1)
            )
        }
        .disabled(url == nil)
        .opacity(url == nil ? 0.4 : 1.0)
    }

    private func toggle() {
        if audioEngine.isPreviewPlaying {
            audioEngine.stopPreviewClip()
        } else if let url {
            audioEngine.playPreviewClip(url: url)
        }
    }
}

import AVFoundation
import MediaPlayer
import WanderpastCore

/// Wraps AVFoundation to play dual-channel audio (ambient + waypoint).
/// All decisions are made by AudioEngineState — this class just translates
/// state into real AVAudioPlayer calls.
final class AudioEngine: NSObject, ObservableObject {
    private(set) var state = AudioEngineState()

    private var ambientPlayer: AVAudioPlayer?
    private var waypointPlayer: AVAudioPlayer?
    private var transitionPlayer: AVAudioPlayer?

    /// Separate AVPlayer for streaming the 60-second preview clip from the catalogue's CDN URL.
    /// Kept fully isolated from the tour audio path so the two flows never tangle.
    private var previewPlayer: AVPlayer?
    private var previewTimeObserver: Any?
    @Published private(set) var isPreviewPlaying: Bool = false

    /// Hard ceiling on preview playback. Catalogue clips are produced at 60s; this is a safety net
    /// if the upstream file ever exceeds that.
    private let previewMaxDuration: TimeInterval = 60

    private var fadeDuration: TimeInterval = 0.5
    private var tourTitle: String = ""
    private var waypointTitles: [String: String] = [:]

    var onWaypointFinished: (() -> Void)?
    var onTransitionFinished: (() -> Void)?

    override init() {
        super.init()
        configureAudioSession()
        setupRemoteCommands()
        registerForInterruptions()
    }

    // MARK: - Audio session

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .spokenAudio)
            try session.setActive(true)
        } catch {
            print("[AudioEngine] Failed to configure audio session: \(error)")
        }
    }

    // MARK: - Tour lifecycle

    func startTour(waypointIDs: [String], ambientFile: String, tourTitle: String, waypointTitles: [String: String]) {
        state.startTour(waypoints: waypointIDs)
        self.tourTitle = tourTitle
        self.waypointTitles = waypointTitles

        // Start ambient loop
        if let url = Bundle.main.url(forResource: ambientFile, withExtension: "m4a") {
            ambientPlayer = try? AVAudioPlayer(contentsOf: url)
            ambientPlayer?.numberOfLoops = -1  // loop forever
            ambientPlayer?.volume = state.ambientVolume
            ambientPlayer?.play()
        }

        updateNowPlaying()
    }

    func triggerWaypoint(id: String, audioFile: String) {
        state.triggerWaypoint(id: id)

        // Fade ambient down
        ambientPlayer?.setVolume(state.ambientVolume, fadeDuration: fadeDuration)

        // Play waypoint audio
        if let url = Bundle.main.url(forResource: audioFile, withExtension: "m4a") {
            waypointPlayer = try? AVAudioPlayer(contentsOf: url)
            waypointPlayer?.delegate = self
            waypointPlayer?.play()
        }

        updateNowPlaying()
    }

    func playTransition(audioFile: String) {
        if let url = Bundle.main.url(forResource: audioFile, withExtension: "m4a") {
            transitionPlayer = try? AVAudioPlayer(contentsOf: url)
            transitionPlayer?.delegate = self
            transitionPlayer?.play()
        }
    }

    // MARK: - Controls

    func togglePause() {
        let wasPaused = state.isPaused
        state.togglePause()
        applyPlaybackState()

        if wasPaused {
            try? AVAudioSession.sharedInstance().setActive(true)
        }
        updateNowPlaying()
    }

    func skipForward() {
        state.skipForward()
        waypointPlayer?.stop()
        updateNowPlaying()
    }

    func skipBackward() {
        state.skipBackward()
        waypointPlayer?.stop()
        updateNowPlaying()
    }

    // MARK: - Preview clip

    /// Streams a 60-second preview clip from a remote URL using a dedicated AVPlayer.
    /// Does not touch the tour audio players. Auto-stops at `previewMaxDuration`.
    func playPreviewClip(url: URL) {
        stopPreviewClip()

        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        previewPlayer = player

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePreviewDidFinish),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )

        let stopTime = CMTime(seconds: previewMaxDuration, preferredTimescale: 600)
        previewTimeObserver = player.addBoundaryTimeObserver(
            forTimes: [NSValue(time: stopTime)],
            queue: .main
        ) { [weak self] in
            self?.stopPreviewClip()
        }

        player.play()
        isPreviewPlaying = true
    }

    func stopPreviewClip() {
        if let observer = previewTimeObserver {
            previewPlayer?.removeTimeObserver(observer)
            previewTimeObserver = nil
        }
        previewPlayer?.pause()
        previewPlayer = nil
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        if isPreviewPlaying { isPreviewPlaying = false }
    }

    @objc private func handlePreviewDidFinish() {
        stopPreviewClip()
    }

    // MARK: - Private helpers

    private func applyPlaybackState() {
        if state.isPaused {
            ambientPlayer?.pause()
            waypointPlayer?.pause()
            transitionPlayer?.pause()
        } else {
            if state.isAmbientPlaying { ambientPlayer?.play() }
            if state.isWaypointPlaying { waypointPlayer?.play() }
        }
        ambientPlayer?.setVolume(state.ambientVolume, fadeDuration: fadeDuration)
    }

    // MARK: - Interruptions

    private func registerForInterruptions() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleInterruptionNotification),
            name: AVAudioSession.interruptionNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleRouteChangeNotification),
            name: AVAudioSession.routeChangeNotification, object: nil
        )
    }

    @objc private func handleInterruptionNotification(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            state.handleInterruption(.began)
            applyPlaybackState()
        case .ended:
            let shouldResume = (info[AVAudioSessionInterruptionOptionKey] as? UInt)
                .map { AVAudioSession.InterruptionOptions(rawValue: $0).contains(.shouldResume) } ?? false
            state.handleInterruption(.ended(shouldResume: shouldResume))
            applyPlaybackState()
        @unknown default:
            break
        }
    }

    @objc private func handleRouteChangeNotification(_ notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        if reason == .oldDeviceUnavailable {
            state.handleRouteChange(.headphonesUnplugged)
            applyPlaybackState()
        }
    }

    // MARK: - Lock screen / Now Playing

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in
            self?.togglePause()
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.togglePause()
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            self?.skipForward()
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            self?.skipBackward()
            return .success
        }
    }

    private func updateNowPlaying() {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: waypointTitles[state.currentWaypointID ?? ""] ?? tourTitle,
            MPMediaItemPropertyArtist: "Wanderpast",
            MPMediaItemPropertyAlbumTitle: tourTitle,
            MPNowPlayingInfoPropertyPlaybackRate: state.isPaused ? 0.0 : 1.0,
        ]
        if let duration = waypointPlayer?.duration {
            info[MPMediaItemPropertyPlaybackDuration] = duration
        }
        if let elapsed = waypointPlayer?.currentTime {
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioEngine: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if player === waypointPlayer {
            state.waypointDidFinishPlaying()
            ambientPlayer?.setVolume(state.ambientVolume, fadeDuration: fadeDuration)
            updateNowPlaying()
            onWaypointFinished?()
        } else if player === transitionPlayer {
            onTransitionFinished?()
        }
    }
}

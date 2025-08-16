import AVFoundation
import HaishinKit
import SwiftUI

@MainActor
final class IngestViewModel: ObservableObject {
    @Published var currentFPS: FPS = .fps30
    @Published var visualEffectItem: VideoEffectItem = .none
    @Published private(set) var error: Error?
    @Published var isShowError = false
    @Published private(set) var isTorchEnabled = false
    @Published private(set) var readyState: SessionReadyState = .closed
    // If you want to use the multi-camera feature, please make create a MediaMixer with a multiCamSession mode.
    // let mixer = MediaMixer(multiCamSessionEnabled: true)
    private(set) var mixer = MediaMixer(multiCamSessionEnabled: true, multiTrackAudioMixingEnabled: false)
    private var session: (any Session)?
    private var currentPosition: AVCaptureDevice.Position = .back
    @ScreenActor private var videoScreenObject: VideoTrackScreenObject?
    @ScreenActor private var currentVideoEffect: VideoEffect?

    init() {
        Task { @ScreenActor in
            videoScreenObject = VideoTrackScreenObject()
        }
    }

    func startIngest(_ preference: PreferenceViewModel) {
        Task {
            guard let session else {
                return
            }
            do {
                try await session.stream.setVideoSettings(preference.makeVideoCodecSettings(session.stream.videoSettings))
                try await session.connect {
                    Task { @MainActor in
                        self.isShowError = true
                    }
                }
            } catch {
                self.error = error
                self.isShowError = true
                logger.error(error)
            }
        }
    }

    func stopIngest() {
        Task {
            do {
                try await session?.close()
            } catch {
                logger.error(error)
            }
        }
    }

    func makeSession(_ preference: PreferenceViewModel) async {
        // Make session.
        do {
            session = try await SessionBuilderFactory.shared.make(preference.makeURL()).build()
            guard let session else {
                return
            }
            await mixer.addOutput(session.stream)
            Task {
                for await readyState in await session.readyState {
                    self.readyState = readyState
                    switch readyState {
                    case .open:
                        UIApplication.shared.isIdleTimerDisabled = false
                    default:
                        UIApplication.shared.isIdleTimerDisabled = true
                    }
                }
            }
        } catch {
            logger.error(error)
        }
    }

    func startRunning() async {
        // SetUp a mixer.
        await mixer.setMonitoringEnabled(DeviceUtil.isHeadphoneConnected())
        var videoMixerSettings = await mixer.videoMixerSettings
        videoMixerSettings.mode = .offscreen
        await mixer.setVideoMixerSettings(videoMixerSettings)
        // Attach devices
        let back = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentPosition)
        try? await mixer.attachVideo(back, track: 0)
        try? await mixer.attachAudio(AVCaptureDevice.default(for: .audio))
        let front = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        try? await mixer.attachVideo(front, track: 1) { videoUnit in
            videoUnit.isVideoMirrored = true
        }
        orientationDidChange()
        await mixer.startRunning()
        Task { @ScreenActor in
            guard let videoScreenObject else {
                return
            }
            videoScreenObject.cornerRadius = 16.0
            videoScreenObject.track = 1
            videoScreenObject.horizontalAlignment = .right
            videoScreenObject.layoutMargin = .init(top: 16, left: 0, bottom: 0, right: 16)
            videoScreenObject.size = .init(width: 160 * 2, height: 90 * 2)
            await mixer.screen.size = .init(width: 720, height: 1280)
            await mixer.screen.backgroundColor = UIColor.black.cgColor
            try? await mixer.screen.addChild(videoScreenObject)
        }
    }

    func stopRunning() async {
        await mixer.stopRunning()
        try? await mixer.attachAudio(nil)
        try? await mixer.attachVideo(nil, track: 0)
        try? await mixer.attachVideo(nil, track: 1)
        if let session {
            await mixer.removeOutput(session.stream)
        }
    }

    func flipCamera() {
        Task {
            if await mixer.isMultiCamSessionEnabled {
                var videoMixerSettings = await mixer.videoMixerSettings
                if videoMixerSettings.mainTrack == 0 {
                    videoMixerSettings.mainTrack = 1
                    await mixer.setVideoMixerSettings(videoMixerSettings)
                    Task { @ScreenActor in
                        videoScreenObject?.track = 0
                    }
                } else {
                    videoMixerSettings.mainTrack = 0
                    await mixer.setVideoMixerSettings(videoMixerSettings)
                    Task { @ScreenActor in
                        videoScreenObject?.track = 1
                    }
                }
            } else {
                let position: AVCaptureDevice.Position = currentPosition == .back ? .front : .back
                try? await mixer.attachVideo(AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)) { videoUnit in
                    videoUnit.isVideoMirrored = position == .front
                }
                currentPosition = position
            }
        }
    }

    func setVisualEffet(_ videoEffect: VideoEffectItem) {
        Task { @ScreenActor in
            if let currentVideoEffect {
                _ = await mixer.screen.unregisterVideoEffect(currentVideoEffect)
            }
            if let videoEffect = videoEffect.makeVideoEffect() {
                currentVideoEffect = videoEffect
                _ = await mixer.screen.registerVideoEffect(videoEffect)
            }
        }
    }

    func toggleTorch() {
        Task {
            await mixer.setTorchEnabled(!isTorchEnabled)
            isTorchEnabled.toggle()
        }
    }

    func setFrameRate(_ fps: Float64) {
        Task {
            do {
                // Sets to input frameRate.
                try? await mixer.configuration(video: 0) { video in
                    do {
                        try video.setFrameRate(fps)
                    } catch {
                        logger.error(error)
                    }
                }
                try? await mixer.configuration(video: 1) { video in
                    do {
                        try video.setFrameRate(fps)
                    } catch {
                        logger.error(error)
                    }
                }
                // Sets to output frameRate.
                try await mixer.setFrameRate(fps)
            } catch {
                logger.error(error)
            }
        }
    }

    func orientationDidChange() {
        Task { @ScreenActor in
            if let orientation = await DeviceUtil.videoOrientation(by: UIApplication.shared.statusBarOrientation) {
                await mixer.setVideoOrientation(orientation)
            }
            if await UIDevice.current.orientation.isLandscape {
                await mixer.screen.size = .init(width: 1280, height: 720)
            } else {
                await mixer.screen.size = .init(width: 720, height: 1280)
            }
        }
    }
}

extension IngestViewModel: MTHKSwiftUiView.PreviewSource {
    nonisolated func connect(to view: HaishinKit.MTHKView) {
        Task {
            await mixer.addOutput(view)
        }
    }
}

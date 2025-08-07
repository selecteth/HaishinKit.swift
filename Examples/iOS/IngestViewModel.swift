import AVFoundation
import HaishinKit
import SwiftUI

actor IngestViewModel: ObservableObject {
    @MainActor @Published var currentFPS: FPS = .fps30
    @MainActor @Published var visualEffectItem: VideoEffectItem = .none
    @MainActor @Published private(set) var isTorchEnabled = false
    @MainActor @Published private(set) var isIngesting = false
    // If you want to use the multi-camera feature, please make create a MediaMixer with a multiCamSession mode.
    // let mixer = MediaMixer(multiCamSessionEnabled: true)
    private(set) var mixer = MediaMixer(multiCamSessionEnabled: true, multiTrackAudioMixingEnabled: false)
    private var session: (any Session)?
    private var currentPosition: AVCaptureDevice.Position = .back
    @ScreenActor
    private var videoScreenObject = VideoTrackScreenObject()
    @ScreenActor
    private var currentVideoEffect: VideoEffect?

    func startIngest() async {
        do {
            try await session?.connect(.ingest)
            Task { @MainActor in
                UIApplication.shared.isIdleTimerDisabled = true
                isIngesting = true
            }
        } catch {
            logger.error(error)
        }
    }

    func stopIngest() async {
        do {
            Task { @MainActor in
                UIApplication.shared.isIdleTimerDisabled = false
                isIngesting = false
            }
            try await session?.close()
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
        await orientationDidChange()
        await mixer.startRunning()
        // Make session.
        do {
            session = try await SessionBuilderFactory.shared.make(Preference.default.makeURL()).build()
            if let session {
                await mixer.addOutput(session.stream)
            }
        } catch {
            logger.error(error)
        }

        Task { @ScreenActor in
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

    func flipCamera() async {
        if await mixer.isMultiCamSessionEnabled {
            var videoMixerSettings = await mixer.videoMixerSettings
            if videoMixerSettings.mainTrack == 0 {
                videoMixerSettings.mainTrack = 1
                await mixer.setVideoMixerSettings(videoMixerSettings)
                Task { @ScreenActor in
                    videoScreenObject.track = 0
                }
            } else {
                videoMixerSettings.mainTrack = 0
                await mixer.setVideoMixerSettings(videoMixerSettings)
                Task { @ScreenActor in
                    videoScreenObject.track = 1
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

    func setVisualEffet(_ videoEffect: VideoEffectItem) async {
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

    func toggleTorch() async {
        await mixer.setTorchEnabled(!isTorchEnabled)
        Task { @MainActor in
            isTorchEnabled.toggle()
        }
    }

    func setFrameRate(_ fps: Float64) async {
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

    func orientationDidChange() async {
        if let orientation = await DeviceUtil.videoOrientation(by: UIApplication.shared.statusBarOrientation) {
            await mixer.setVideoOrientation(orientation)
        }
        Task { @ScreenActor in
            if await UIDevice.current.orientation.isLandscape {
                await mixer.screen.size = .init(width: 1280, height: 720)
            } else {
                await mixer.screen.size = .init(width: 720, height: 1280)
            }
        }
    }
}

extension IngestViewModel: MTHKSwiftUiView.PreviewSource {
    func connect(to view: HaishinKit.MTHKView) async {
        await mixer.addOutput(view)
    }
}

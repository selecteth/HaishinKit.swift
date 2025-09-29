import AVFoundation

extension CaptureSession {
    #if os(macOS)
    struct Capabilities {
        static let isMultiCamSupported = true

        var isMultiCamSessionEnabled = true {
            didSet {
                isMultiCamSessionEnabled = true
            }
        }

        func makeSession(_ sessionPreset: AVCaptureSession.Preset) -> AVCaptureSession {
            let session = AVCaptureSession()
            if session.canSetSessionPreset(sessionPreset) {
                session.sessionPreset = sessionPreset
            }
            return session
        }

        func isMultitaskingCameraAccessEnabled(_ session: AVCaptureSession) -> Bool {
            session.isMultitaskingCameraAccessEnabled
        }
    }
    #elseif os(iOS) || os(tvOS)
    struct Capabilities {
        static var isMultiCamSupported: Bool {
            if #available(tvOS 17.0, *) {
                return AVCaptureMultiCamSession.isMultiCamSupported
            } else {
                return false
            }
        }

        var isMultiCamSessionEnabled = false {
            didSet {
                if !Self.isMultiCamSupported {
                    isMultiCamSessionEnabled = false
                    logger.info("This device can't support the AVCaptureMultiCamSession.")
                }
            }
        }

        @available(tvOS 17.0, *)
        func isMultitaskingCameraAccessEnabled(_ session: AVCaptureSession) -> Bool {
            session.isMultitaskingCameraAccessEnabled
        }

        @available(tvOS 17.0, *)
        func makeSession(_ sessionPreset: AVCaptureSession.Preset) -> AVCaptureSession {
            let session: AVCaptureSession
            if isMultiCamSessionEnabled {
                session = AVCaptureMultiCamSession()
            } else {
                session = AVCaptureSession()
            }
            if session.canSetSessionPreset(sessionPreset) {
                session.sessionPreset = sessionPreset
            }
            if session.isMultitaskingCameraAccessSupported {
                session.isMultitaskingCameraAccessEnabled = true
            }
            return session
        }
    }
    #else
    struct Capabilities {
        static let isMultiCamSupported = false

        var isMultiCamSessionEnabled = false {
            didSet {
                isMultiCamSessionEnabled = false
            }
        }

        func isMultitaskingCameraAccessEnabled(_ session: AVCaptureSession) -> Bool {
            false
        }
    }
    #endif
}

import AppKit
import Foundation
import HaishinKit
#if canImport(ScreenCaptureKit)
@preconcurrency import ScreenCaptureKit
#endif

class SCStreamPublishViewController: NSViewController {
    @IBOutlet private weak var cameraPopUpButton: NSPopUpButton!
    @IBOutlet private weak var urlField: NSTextField!
    @IBOutlet private weak var mthkView: MTHKView!
    private var session: (any Session)?
    private let lockQueue = DispatchQueue(label: "SCStreamPublishViewController.lock")
    private var _scstream: Any?

    @available(macOS 12.3, *)
    private var scstream: SCStream? {
        get {
            _scstream as? SCStream
        }
        set {
            _scstream = newValue
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        urlField.stringValue = Preference.default.uri ?? ""
        Task {
            session = try? await SessionBuilderFactory.shared.make(Preference.default.makeURL()).build()
            guard let session else {
                return
            }
            await session.stream.addOutput(mthkView!)
            try await SCShareableContent.current.windows.forEach {
                cameraPopUpButton.addItem(withTitle: $0.owningApplication?.applicationName ?? "")
            }
        }
    }

    @IBAction private func publishOrStop(_ sender: NSButton) {
        Task {
            // Publish
            if sender.title == "Publish" {
                sender.title = "Stop"
                try? await session?.connect(.ingest) {
                }
            } else {
                // Stop
                sender.title = "Publish"
                try? await session?.connect(.ingest) {
                }
            }
        }
    }

    @IBAction private func selectCamera(_ sender: AnyObject) {
        if #available(macOS 12.3, *) {
            Task {
                guard let window = try? await SCShareableContent.current.windows.first(where: { $0.owningApplication?.applicationName == cameraPopUpButton.title }) else {
                    return
                }
                print(window)
                let filter = SCContentFilter(desktopIndependentWindow: window)
                let configuration = SCStreamConfiguration()
                configuration.width = Int(window.frame.width)
                configuration.height = Int(window.frame.height)
                configuration.showsCursor = true
                self.scstream = SCStream(filter: filter, configuration: configuration, delegate: self)
            }
        }
    }
}

extension SCStreamPublishViewController: SCStreamDelegate {
    // MARK: SCStreamDelegate
    nonisolated func stream(_ stream: SCStream, didStopWithError error: any Error) {
        print(error)
    }
}

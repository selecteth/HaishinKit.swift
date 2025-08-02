import AVFoundation
import HaishinKit
import SwiftUI

struct PiPHKSwiftUiView: UIViewRepresentable {
    protocol PreviewSource: Actor {
        func connect(to view: PiPHKView) async
    }

    typealias UIViewType = HaishinKit.PiPHKView

    let previewSource: PreviewSource
    private var view = HaishinKit.PiPHKView(frame: .zero)

    init(previewSource: PreviewSource) {
        self.previewSource = previewSource
    }

    func makeUIView(context: Context) -> HaishinKit.PiPHKView {
        Task {
            await previewSource.connect(to: view)
        }
        return view
    }

    func updateUIView(_ uiView: HaishinKit.PiPHKView, context: Context) {
    }
}

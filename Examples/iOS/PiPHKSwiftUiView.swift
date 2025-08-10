import AVFoundation
import HaishinKit
import SwiftUI

struct PiPHKSwiftUiView: UIViewRepresentable {
    protocol PreviewSource {
        func connect(to view: PiPHKView)
    }

    typealias UIViewType = HaishinKit.PiPHKView

    let previewSource: PreviewSource
    private var view = HaishinKit.PiPHKView(frame: .zero)

    init(previewSource: PreviewSource) {
        self.previewSource = previewSource
    }

    func makeUIView(context: Context) -> PiPHKView {
        previewSource.connect(to: view)
        return view
    }

    func updateUIView(_ uiView: PiPHKView, context: Context) {
    }
}

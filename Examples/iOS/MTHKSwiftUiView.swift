import AVFoundation
import HaishinKit
import SwiftUI

struct MTHKSwiftUiView: UIViewRepresentable {
    protocol PreviewSource: Actor {
        func connect(to view: MTHKView) async
    }

    typealias UIViewType = HaishinKit.MTHKView

    let previewSource: PreviewSource
    private var view = HaishinKit.MTHKView(frame: .zero)

    init(previewSource: PreviewSource) {
        self.previewSource = previewSource
    }

    func makeUIView(context: Context) -> HaishinKit.MTHKView {
        Task {
            await previewSource.connect(to: view)
        }
        return view
    }

    func updateUIView(_ uiView: HaishinKit.MTHKView, context: Context) {
    }
}

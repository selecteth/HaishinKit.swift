import HaishinKit
import RTMPHaishinKit
import SRTHaishinKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = ViewModel()

    private var lfView: PiPHKSwiftUiView!

    init() {
        viewModel.config()
        lfView = PiPHKSwiftUiView(rtmpStream: $viewModel.stream)
        Task {
            await SessionBuilderFactory.shared.register(RTMPSessionFactory())
            await SessionBuilderFactory.shared.register(SRTSessionFactory())
        }
    }

    var body: some View {
        VStack {
            lfView
                .ignoresSafeArea()
                .onTapGesture { _ in
                    self.viewModel.startPlaying()
                }
            Text("Hello, world!")
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}

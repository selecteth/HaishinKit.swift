import HaishinKit
import SwiftUI

struct PlaybackView: View {
    @StateObject private var model = PlaybackViewModel()
    @EnvironmentObject var preference: PreferenceViewModel

    var body: some View {
        ZStack {
            VStack {
                PiPHKViewRepresentable(previewSource: model)
            }
            if model.readyState == .connecting {
                VStack {
                    ProgressView()
                }
            }
        }.onAppear {
            Task { await model.makeSession(preference) }
        }.alert(isPresented: $model.isShowError) {
            Alert(
                title: Text("Error"),
                message: Text(model.error?.localizedDescription ?? ""),
                dismissButton: .default(Text("OK"))
            )
        }
        .navigationTitle("Playback")
        .toolbar {
            switch model.readyState {
            case .connecting:
                ToolbarItem(placement: .primaryAction) {
                }
            case .open:
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        Task {
                            await model.stop()
                        }
                    }) {
                        Image(systemName: "stop.circle")
                    }
                }
            case .closed:
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        Task {
                            await model.start()
                        }
                    }) {
                        Image(systemName: "play.circle")
                    }
                }
            case .closing:
                ToolbarItem(placement: .primaryAction) {
                }
            }
        }
    }
}

#Preview {
    PlaybackView()
}

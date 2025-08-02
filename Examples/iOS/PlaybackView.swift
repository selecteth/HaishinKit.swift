import SwiftUI

struct PlaybackView: View {
    @State var error: Error?
    @State var isShowError = false
    @StateObject private var model = PlaybackViewModel()

    var body: some View {
        ZStack {
            VStack {
                PiPHKSwiftUiView(previewSource: model)
            }
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    switch model.state {
                    case .connecting:
                        Spacer()
                    case .connected:
                        Button(action: {
                            Task {
                                await model.stop()
                            }
                        }, label: {
                            Image(systemName: "stop.circle")
                                .foregroundColor(.white)
                                .font(.system(size: 24))
                        })
                        .frame(width: 60, height: 60)
                        .background(Color.blue)
                        .cornerRadius(30.0)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 16.0, trailing: 16.0))
                    case .closed:
                        Button(action: {
                            Task {
                                do {
                                    try await model.start()
                                } catch {
                                    self.error = error
                                    isShowError = true
                                }
                            }
                        }, label: {
                            Image(systemName: "play.circle")
                                .foregroundColor(.white)
                                .font(.system(size: 24))
                        })
                        .frame(width: 60, height: 60)
                        .background(Color.blue)
                        .cornerRadius(30.0)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 16.0, trailing: 16.0))
                    }
                }
            }

            if model.state == .connecting {
                VStack {
                    ProgressView()
                }
            }
        }.task {
            await model.makeSession()
        }.alert(isPresented: $isShowError) {
            Alert(
                title: Text("Error"),
                message: Text(error?.localizedDescription ?? ""),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

#Preview {
    PlaybackView()
}

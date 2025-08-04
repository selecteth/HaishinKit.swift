import SwiftUI

struct PreferenceView: View {
    @State private var url: String = ""
    @State private var streamName: String = ""

    var body: some View {
        Form {
            Section {
                TextField(Preference.default.uri ?? "", text: $url)
                    .onSubmit {
                        Preference.default.uri = url
                    }
            } header: {
                Text("Stream URL:")
            }
            Section {
                TextField(Preference.default.streamName ?? "", text: $streamName)
                    .onSubmit {
                        Preference.default.streamName = streamName
                    }
            } header: {
                Text("Stream name:")
            }
        }.onAppear {
        }
    }
}

#Preview {
    PreferenceView()
}

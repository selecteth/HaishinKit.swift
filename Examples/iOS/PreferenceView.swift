import SwiftUI

struct PreferenceView: View {
    @State private var url: String = ""
    @State private var streamName: String = ""

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("URL")
                        .frame(width: 80, alignment: .leading)
                        .foregroundColor(.secondary)
                    TextField(Preference.default.uri, text: $url)
                        .onSubmit {
                            Preference.default.uri = url
                        }
                }.padding(.vertical, 4)
                HStack {
                    Text("Name")
                        .frame(width: 80, alignment: .leading)
                        .foregroundColor(.secondary)
                    TextField(Preference.default.streamName, text: $streamName)
                        .onSubmit {
                            Preference.default.streamName = streamName
                        }
                }.padding(.vertical, 4)
            } header: {
                Text("Stream")
            }
        }
    }
}

#Preview {
    PreferenceView()
}

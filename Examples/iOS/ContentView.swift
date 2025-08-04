import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            IngestView()
                .tabItem {
                    Image(systemName: "record.circle")
                    Text("Ingest")
                }

            PlaybackView()
                .tabItem {
                    Image(systemName: "play.circle")
                    Text("Playback")
                }

            PreferenceView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Preference")
                }
        }
    }
}

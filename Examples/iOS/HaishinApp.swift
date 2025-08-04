import HaishinKit
@preconcurrency import Logboard
import RTMPHaishinKit
import SRTHaishinKit
import SwiftUI

@main
struct HaishinApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    init() {
        Task {
            await SessionBuilderFactory.shared.register(RTMPSessionFactory())
            await SessionBuilderFactory.shared.register(SRTSessionFactory())
        }
    }
}

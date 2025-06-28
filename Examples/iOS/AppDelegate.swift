import AVFoundation
import HaishinKit
@preconcurrency import Logboard
import RTMPHaishinKit
import SRTHaishinKit
import UIKit

let logger = LBLogger.with("com.haishinkit.Exsample.iOS")

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // LBLogger.with(kHaishinKitIdentifier).level = .trace
        Task {
            await SessionBuilderFactory.shared.register(RTMPSessionFactory())
            await SessionBuilderFactory.shared.register(SRTSessionFactory())
        }
        let session = AVAudioSession.sharedInstance()
        do {
            // If you set the "mode" parameter, stereo capture is not possible, so it is left unspecified.
            try session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            logger.error(error)
        }
        return true
    }
}

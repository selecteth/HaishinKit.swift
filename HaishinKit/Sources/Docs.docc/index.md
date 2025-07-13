# ``HaishinKit``
This is the main module.

## Overview
This is the main module. It is mainly responsible for video and audio mixing, and provides a common interface.

## 🎨 Features
### Session
This is an API that consolidates the connection handling of RTMP and SRT into a unified interface.
It encapsulates retry logic and best practices for establishing connections
```swift
import HaishinKit
import RTMPHaishinKit
import SRTHaishinKit

Task {
  await SessionBuilderFactory.shared.register(RTMPSessionFactory())
  await SessionBuilderFactory.shared.register(SRTSessionFactory())
}
```
```swift
private var session: (any Session)?
private lazy var mixer = MediaMixer(multiCamSessionEnabled: true, multiTrackAudioMixingEnabled: true, useManualCapture: true)

do {
  session = try await SessionBuilderFactory.shared.make(Preference.default.makeURL()).build()
  guard let session else {
    return
  }
  await mixer.addOutput(session.stream)
  if let view = view as? (any HKStreamOutput) {
    await session.stream.addOutput(view)
  }
} catch {
  logger.error(error)
}
```

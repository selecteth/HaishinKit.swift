# ``HaishinKit``
This is the main module.

## Overview
This is the main module. It is mainly responsible for video and audio mixing, and provides a common interface.

## 🎨 Features
### Session
This is an API that consolidates the connection handling of RTMP and SRT into a unified interface. It encapsulates retry logic and best practices for establishing connections
#### Prerequisites
```swift
import HaishinKit
import RTMPHaishinKit
import SRTHaishinKit

Task {
  await SessionBuilderFactory.shared.register(RTMPSessionFactory())
  await SessionBuilderFactory.shared.register(SRTSessionFactory())
}
```
#### Make session
```swift
let session = try await SessionBuilderFactory.shared.make(URL(string: "rtmp://hostname/live/live"))
  .setMode(.ingest)
  .build()
```
```swift
let session = try await SessionBuilderFactory.shared.make(URL(string: "srt://hostname:448?stream=xxxxx"))
  .setMode(.playback)
  .build()
```
#### Connect
Publish or playback will be performed according to the selected mode setting.
```swift
try session.connect {
  print("on disconnected")
}
```

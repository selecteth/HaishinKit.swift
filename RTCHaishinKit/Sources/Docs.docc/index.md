# ``RTCHaishinKit``
This module supports WHIP/WHEP protocols.

## Overview
RTCHaishinKit is WHIP/WHEP protocols stack in Swift. It internally uses a library that is built from [libdatachannel](https://github.com/paullouisageneau/libdatachannel) and converted into an xcframework.

## 📓Usage
### Logging
- Defining a Swift wrapper method for `rtcInitLogger`.
```swift
await RTCLogger.shared.setLevel(.debug)
```


# ``HaishinKit``
メインモジュールです。

## 🔍 概要
ライブストリーミングに必要なカメラやマイクのミキシング機能の提供を行います。各モジュールに対して共通の処理を提供します。

### モジュール構成
|モジュール|説明|
|:-|:-|
|HaishinKit|本モジュールです。|
|RTMPHaishinKit|RTMPプロトコルスタックを提供します。|
|SRTHaishinKit|SRTプロトコルスタックを提供します。|
|RTCHaishinKit|WebRTCのWHEP/WHIPプロトコルスタックを提供します。現在α版です。|
|MoQTHaishinKit|MoQTプロトコルスタックを提供します。現在α版です。

## 🎨 機能
以下の機能を提供しています。
- ライブミキシング
  - [映像のミキシング](doc://HaishinKit/videomixing)
    - カメラ映像や静止画を一つの配信映像ソースとして扱います。
  - 音声のミキシング
    - 異なるマイク音声を合成して一つの配信音声ソースとして扱います。
- [Session](doc://HaishinKit/sessionapi)
  - RTMP/SRT/WHEP/WHIPといったプロトコルを統一的なAPIで扱えます。

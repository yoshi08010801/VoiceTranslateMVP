# VoiceTranslateMVP

Swift / SwiftUIで開発した音声文字起こしアプリです。

音声を録音し、AppleのSpeech Frameworkを利用して
テキストへ文字起こしできます。
文字起こし結果は履歴として保存・確認できます。

## Features

- 音声録音
- 音声からテキストへの文字起こし
- 文字起こし履歴の保存
- 過去の文字起こし結果の確認
- カスタム辞書
- ファイルからの文字起こし
- UIテーマ設定

## Tech Stack

- Swift
- SwiftUI
- Speech Framework
- AVFoundation
- SwiftData
- Xcode

## Development Notes

個人開発として、企画・実装・UI改善まで行いました。

音声認識だけでなく、履歴保存やカスタム辞書など、
実際に継続して使えることを意識して機能を追加しています。

## Project Structure

- `ViewModels/` - 画面と処理をつなぐロジック
- `VoiceTranslateMVP/` - メインアプリ
- `VoiceTranslateMVPTests/` - テスト
- `VoiceTranslateMVPUITests/` - UIテスト

## Environment

- iOS
- Xcode
- Swift / SwiftUI

## Author

Yoshi K

# 音声メモおこしくん

Swift / SwiftUIで開発したiOS向け音声文字起こしアプリです。

AppleのSpeech Frameworkを利用し、マイクからの音声入力や音声ファイルをテキストへ文字起こしできます。

文字起こし結果はSwiftDataを利用して端末内に保存し、履歴として後から確認できます。

Repository: `VoiceTranslateMVP`

## Features

- マイク音声の録音
- リアルタイム音声文字起こし
- 音声ファイルからの文字起こし
- 文字起こし結果の履歴保存
- 過去の文字起こし結果の確認
- カスタム辞書による認識補助
- 文字起こし結果のコピー / 共有
- 録音中の音量レベル表示
- UIテーマ設定

## Tech Stack

- Swift
- SwiftUI
- Speech Framework
- AVFoundation
- SwiftData
- UniformTypeIdentifiers
- Xcode

## Architecture

画面表示と音声認識処理を分離するため、SwiftUIのViewと`SpeechViewModel`を分けて実装しています。

`SpeechViewModel`では主に以下を担当しています。

- Speech Frameworkを利用した音声認識
- AVAudioEngineを利用したマイク入力
- 音声認識状態の管理
- 録音中の音量レベル計算
- 音声ファイルの文字起こし
- カスタム辞書の適用

文字起こし結果の永続化にはSwiftDataを利用しています。

## Technical Highlights

### Speech Framework

`SFSpeechRecognizer`を利用し、リアルタイム音声と音声ファイルの両方に対応しています。

途中結果と確定結果を分けて管理し、認識中のテキストもUIへ反映しています。

### AVFoundation

`AVAudioEngine`から取得した音声バッファをSpeech Frameworkへ渡して音声認識を行っています。

また、音声バッファからRMS値を計算し、録音中の音量レベルを0〜1の範囲へ正規化してUIへ反映しています。

### SwiftData

文字起こし完了時に結果をSwiftDataへ保存し、履歴画面から過去の文字起こし結果を確認できるようにしています。

### Refactoring

マイク入力とファイル入力で重複していた音声認識結果の更新処理をprivateメソッドへ共通化し、処理の重複を減らしました。

`updateRecognitionResult(text:isFinal:)` を利用し、認識方法が異なってもUIへ反映する処理は共通化する構成にしています。

## Project Structure

    VoiceTranslateMVP
    ├── ViewModels/
    │   └── SpeechViewModel.swift
    ├── VoiceTranslateMVP/
    │   ├── ContentView.swift
    │   ├── SettingsView.swift
    │   └── VoiceTranslateMVPApp.swift
    ├── TranscriptItem.swift
    ├── TranscriptListView.swift
    ├── CustomDictionaryView.swift
    ├── RecordingWaveView.swift
    ├── ThemeSettingsView.swift
    ├── VoiceTranslateMVPTests/
    └── VoiceTranslateMVPUITests/

## Development

個人開発として、企画・UI設計・実装・改善・App Store公開まで行いました。

最初は音声文字起こしを中心としたMVPとして開発し、実際に継続して利用できるアプリを目指して、履歴保存、カスタム辞書、ファイル文字起こしなどの機能を追加しました。

また、機能追加を優先して開発した部分については、コードの重複や責務を確認しながら段階的にリファクタリングしています。

## Future Improvements

今後は以下の改善を検討しています。

- 音声認識処理をService層へ分離
- AVAudioEngine周辺の処理を専用クラスへ分離
- Speech Frameworkに依存しない形でViewModelをテスト可能にする
- エラーハンドリングの改善
- Unit Test / UI Testの追加
- Swift Concurrencyを利用した非同期処理の整理

## Environment

- iOS
- Swift
- SwiftUI
- Xcode

## Author

Yoshi K

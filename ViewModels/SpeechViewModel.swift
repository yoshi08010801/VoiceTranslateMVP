import Foundation
import Speech
import AVFoundation
import SwiftUI

final class SpeechViewModel: NSObject, ObservableObject {
    @Published var recognizedText: String = ""
    @Published var isRecording: Bool = false
    @Published var finalText: String = ""
    @Published var partialText: String = ""
    @Published var isFileTranscribing: Bool = false
    @Published var audioLevel: CGFloat = 0.0

    var onFinalText: ((String) -> Void)?

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    // MARK: - 権限

    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("Speech authorized")

                case .denied, .restricted, .notDetermined:
                    self.recognizedText = "音声認識の権限がありません。設定から許可してください。"

                @unknown default:
                    break
                }
            }
        }
    }

    // MARK: - UI操作

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    func clearText() {
        recognizedText = ""
        finalText = ""
        partialText = ""
        audioLevel = 0.0
    }

    // MARK: - マイク録音の文字起こし

    private func startRecording() {
        clearText()

        recognitionTask?.cancel()
        recognitionTask = nil

        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(
                .record,
                mode: .measurement,
                options: .duckOthers
            )
            try audioSession.setActive(
                true,
                options: .notifyOthersOnDeactivation
            )
        } catch {
            print("AudioSession error: \(error)")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            return
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation

        // カスタム辞書を音声認識に適用
        let customWords = DataManager.shared.fetchCustomWords()
        recognitionRequest.contextualStrings = customWords
        print("辞書:", customWords)

        let inputNode = audioEngine.inputNode

        recognitionTask = speechRecognizer?.recognitionTask(
            with: recognitionRequest
        ) { result, error in

            if let result = result {
                let text = result.bestTranscription.formattedString

                if result.isFinal {
                    DispatchQueue.main.async {
                        self.finalText = text.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                        self.partialText = ""
                        self.recognizedText = self.finalText
                        self.onFinalText?(self.finalText)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.partialText = text
                        self.recognizedText = self.finalText + self.partialText
                    }
                }
            }

            if error != nil || (result?.isFinal ?? false) {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                DispatchQueue.main.async {
                    self.isRecording = false
                }

                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: recordingFormat
        ) { buffer, _ in

            // 音声認識へオーディオバッファを渡す
            self.recognitionRequest?.append(buffer)

            // 音量レベルを算出
            guard let channelData = buffer.floatChannelData?[0] else {
                return
            }

            let frameLength = Int(buffer.frameLength)

            var sum: Float = 0.0

            for i in 0..<frameLength {
                let sample = channelData[i]
                sum += sample * sample
            }

            let rms = sqrt(sum / Float(frameLength))

            // RMS値をdBへ変換
            let avgPower = 20 * log10(rms + 1e-8)

            // -50dB〜0dBを0〜1へ正規化
            let normalized = max(
                0,
                min(1, (avgPower + 50) / 50)
            )

            DispatchQueue.main.async {
                self.audioLevel = CGFloat(normalized)
            }
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()

            DispatchQueue.main.async {
                self.isRecording = true
            }
        } catch {
            print("audioEngine couldn't start: \(error)")
        }
    }

    private func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()

        isRecording = false
        audioLevel = 0.0
    }

    // MARK: - ファイル文字起こし

    func transcribeFile(from url: URL) {
        isFileTranscribing = true
        print("拡張子:", url.pathExtension)

        if isRecording {
            stopRecording()
        }

        clearText()

        // 進行中の認識タスクを終了
        recognitionTask?.cancel()
        recognitionTask = nil

        // ファイルインポートで取得したURLへのアクセスを開始
        let accessing = url.startAccessingSecurityScopedResource()

        print("ファイル文字起こし開始: \(url.lastPathComponent)")

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = true
        request.taskHint = .dictation

        // カスタム辞書をファイル文字起こしにも適用
        let customWords = DataManager.shared.fetchCustomWords()
        request.contextualStrings = customWords
        print("辞書:", customWords)

        recognitionTask = speechRecognizer?.recognitionTask(
            with: request
        ) { result, error in

            if let result = result {
                let text = result.bestTranscription.formattedString

                if result.isFinal {
                    DispatchQueue.main.async {
                        self.finalText = text.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                        self.partialText = ""
                        self.recognizedText = self.finalText
                        self.onFinalText?(self.finalText)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.partialText = text
                        self.recognizedText = self.finalText + self.partialText
                    }
                }
            }

            if let error = error {
                print("認識エラー:", error.localizedDescription)
            }

            if error != nil || (result?.isFinal ?? false) {
                DispatchQueue.main.async {
                    self.isFileTranscribing = false
                }

                print("ファイル文字起こし終了")

                self.recognitionTask = nil

                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
        }
    }
}

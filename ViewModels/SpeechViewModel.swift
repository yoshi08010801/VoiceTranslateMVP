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
    
    // MARK: - UI から呼ぶメソッド
    
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
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("AudioSession error: \(error)")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation
        // 🔥 カスタム辞書を適用
        let customWords = DataManager.shared.fetchCustomWords()
        recognitionRequest.contextualStrings = customWords
        print("辞書:", customWords)


        
        let inputNode = audioEngine.inputNode
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                let text = result.bestTranscription.formattedString
                
                if result.isFinal {
                    DispatchQueue.main.async {
                        self.finalText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        self.partialText = ""
                        self.recognizedText = self.finalText
                    }
                }
 else {
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
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            // 文字起こし用にバッファを渡す
            self.recognitionRequest?.append(buffer)

            // ===== 音量レベルの計算 =====
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)

            var sum: Float = 0.0
            for i in 0..<frameLength {
                let sample = channelData[i]
                sum += sample * sample
            }
            let rms = sqrt(sum / Float(frameLength))

            // dB に変換（小さい値を扱いやすくする）
            let avgPower = 20 * log10(rms + 1e-8)

            // -50dB〜0dB を 0〜1 に正規化
            let normalized = max(0, min(1, (avgPower + 50) / 50))

            DispatchQueue.main.async {
                self.audioLevel = CGFloat(normalized)
            }
            // ===== 音量レベルの計算ここまで =====
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

        // 録音中なら止める
        if isRecording {
            stopRecording()
        }

        // 文字は全部リセット
        clearText()

        // 以前のタスクキャンセル
        recognitionTask?.cancel()
        recognitionTask = nil

        // セキュリティスコープ開始（ファイルに触れるようにする）
        let accessing = url.startAccessingSecurityScopedResource()
        print("ファイル文字起こし開始: \(url.lastPathComponent)")

        // URL 用のリクエスト
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = true       // ★ 途中経過も欲しい
        request.taskHint = .dictation
        
        // 🔥 カスタム辞書を適用
        let customWords = DataManager.shared.fetchCustomWords()
        request.contextualStrings = customWords
        print("辞書:", customWords)

// ★ メモ用ヒント

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { result, error in
            if let result = result {
                let text = result.bestTranscription.formattedString

                if result.isFinal {
                    DispatchQueue.main.async {
                        // self.finalText += text + "\n"  ← やめる
                        self.finalText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        self.partialText = ""
                        self.recognizedText = self.finalText
                    }
                }
 else {
                    // ★ 途中経過：partial にだけ入れる
                    DispatchQueue.main.async {
                        self.partialText = text
                        self.recognizedText = self.finalText + self.partialText
                    }
                }
            }

            // エラー or 最後まで終わったら後片付け
            if let error = error {
                print("認識エラー:", error.localizedDescription)
            }

            if error != nil || (result?.isFinal ?? false) {

                // ★ ファイル文字起こしはここで終了扱いにする
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


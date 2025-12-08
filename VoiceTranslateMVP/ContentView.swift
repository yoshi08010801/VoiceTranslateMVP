
import SwiftUI
import Speech
import AVFoundation
import UIKit

struct ContentView: View {
    @StateObject private var viewModel = SpeechViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // タイトル
                Text("音声メモおこしくん")
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 24)
                
                
                
                
                
                
                // メモ欄（文字起こし結果）
                // VStack の中の ScrollView をこの形に置き換え

                ScrollView {
                    Text(
                        viewModel.recognizedText.isEmpty
                        ? "ここに文字起こし結果が表示されます"
                        : viewModel.recognizedText
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.separator), lineWidth: 0.5) // うっすら枠
                    )
                    .lineSpacing(6)
                    .foregroundColor(
                        viewModel.recognizedText.isEmpty ? .secondary : .primary
                    )
                }
                .frame(minHeight: 200)   // ← ScrollView に対して付ける
                .padding(.top, 8)

                
                // 🔽 ここから下を「下寄せゾーン」にしたいので Spacer を入れる
                Spacer()
                
                // 録音していない & テキストがあるときだけ表示
                if !viewModel.recognizedText.isEmpty && !viewModel.isRecording {
                    HStack {
                        Button("クリア") {
                            viewModel.clearText()
                        }

                        Button("コピー") {
                            UIPasteboard.general.string = viewModel.recognizedText
                        }

                        ShareLink(item: viewModel.recognizedText) {
                            Label("共有", systemImage: "square.and.arrow.up")
                        }
                    }
                    .buttonStyle(.bordered)
                }

                // 録音ボタン（常に一番下）
                Button(action: {
                    viewModel.toggleRecording()
                }) {
                    Text(viewModel.isRecording ? "録音停止" : "録音開始")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isRecording ? Color.red : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .onAppear {
                viewModel.requestAuthorization()
            }
        }
    }
}



final class SpeechViewModel: NSObject, ObservableObject {
    @Published var recognizedText: String = ""
    @Published var isRecording: Bool = false
    
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    
    
    
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
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    func clearText() {
        recognizedText = ""
    }
    
    private func startRecording() {
        recognizedText = ""
        
        // 以前のタスクがあればキャンセル
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
        
        let inputNode = audioEngine.inputNode
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString
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
            self.recognitionRequest?.append(buffer)
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
    }
}


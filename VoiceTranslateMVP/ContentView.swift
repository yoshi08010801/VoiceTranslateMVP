import SwiftUI
import UniformTypeIdentifiers   // ファイル選択に必要

struct ContentView: View {
    @StateObject private var viewModel = SpeechViewModel()
    @State private var showingFileImporter = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // タイトル
                Text("音声メモおこしくん")
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 24)
                
                // メモ欄（partial + final）
                // メモ欄（partial + final）
                // メモ欄（partial + final）
                VStack(alignment: .leading, spacing: 8) {

                    if viewModel.finalText.isEmpty && viewModel.partialText.isEmpty {
                        Text("ここに文字起こし結果が表示されます")
                            .foregroundColor(.secondary)
                    }

                    if !viewModel.finalText.isEmpty {
                        Text(viewModel.finalText)
                            .foregroundColor(.primary)
                    }

                    if !viewModel.partialText.isEmpty {
                        Text(viewModel.partialText)
                            .foregroundColor(
                                viewModel.isFileTranscribing
                                ? .secondary   // ← ファイル読み込み中はグレー
                                : .primary     // ← 録音中は黒
                            )
                    }
                }
                .padding(12)                                  // ← VStack にかかる
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )




                Spacer()
                
                // テキストがある & 録音していないときだけ表示
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

                // 録音ボタン + ファイル読み込みボタン
                HStack(spacing: 12) {
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
                    
                    Button {
                        showingFileImporter = true
                    } label: {
                        Image(systemName: "folder.fill")
                            .font(.title2)
                            .frame(width: 52, height: 52)
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding()
            .onAppear {
                viewModel.requestAuthorization()
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.audio, .mpeg4Audio, .mp3, .wav, .aiff],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        viewModel.transcribeFile(from: url)
                    }
                case .failure(let error):
                    print("ファイル選択エラー:", error.localizedDescription)
                }
            }
        }
    }
}


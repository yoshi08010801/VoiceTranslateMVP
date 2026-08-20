import SwiftUI
import UniformTypeIdentifiers
import SwiftData

struct ContentView: View {
    @StateObject private var viewModel = SpeechViewModel()
    @State private var showingFileImporter = false
    @State private var showSettings = false

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // タイトル
                Text("音声メモおこしくん")
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 24)

                // メモ欄
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
                                ? .secondary
                                : .primary
                            )
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )

                Spacer()

                // コピー／共有ボタン
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

                // 波形 + 録音ボタン + ファイルボタン
                HStack(spacing: 12) {
                    RecordingWaveView(
                        level: viewModel.audioLevel,
                        isRecording: viewModel.isRecording
                    )

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
                    .disabled(viewModel.isRecording)
                    .opacity(viewModel.isRecording ? 0.4 : 1.0)
                }
            }
            .padding()
            .onAppear {
                viewModel.requestAuthorization()

                viewModel.onFinalText = { final in
                    let trimmed = final.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }

                    let item = TranscriptItem(title: "", text: trimmed, tagsCSV: "")
                    modelContext.insert(item)
                    try? modelContext.save()
                }
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
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // 履歴画面
                    NavigationLink {
                        TranscriptListView()
                    } label: {
                        Image(systemName: "list.bullet")
                    }

                    // 設定画面
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationView {
                    SettingsView()
                }
            }
        }
    }
}

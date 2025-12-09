import SwiftUI

struct CustomDictionaryView: View {
    @State private var words: [String] = DataManager.shared.fetchCustomWords()
    @State private var newWord: String = ""
    
    var body: some View {
        List {
            // 上部：現在の登録状況
            Section {
                Text("現在 \(words.count) 語を登録中")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 登録済み単語
            Section(header: Text("登録済みの単語")) {
                if words.isEmpty {
                    Text("まだ単語が登録されていません")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(words, id: \.self) { word in
                        Text(word)
                    }
                    .onDelete(perform: deleteWords)
                }
            }
            
            // 新規追加
            Section(header: Text("単語を追加")) {
                HStack {
                    TextField("例）田中, 太郎 など", text: $newWord)
                        .textInputAutocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Button("追加") {
                        addWord()
                    }
                    .disabled(newWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                Text("単語は無制限に登録できます。")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("カスタム辞書")
    }
    
    // MARK: - Actions
    
    private func addWord() {
        let trimmed = newWord.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // 重複チェック
        if words.contains(trimmed) {
            newWord = ""
            return
        }
        
        words.append(trimmed)
        DataManager.shared.saveWords(words)
        newWord = ""
    }
    
    private func deleteWords(at offsets: IndexSet) {
        words.remove(atOffsets: offsets)
        DataManager.shared.saveWords(words)
    }
}


import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {

            Section(header: Text("外観")) {
                NavigationLink("テーマを選ぶ") {
                    ThemeSettingsView()
                }
            }

            Section(header: Text("文字起こし")) {
                NavigationLink("カスタム辞書を編集") {
                    CustomDictionaryView()
                }
            }
        }
        .navigationTitle("設定")   // ← NavigationView は作らない！
    }
}


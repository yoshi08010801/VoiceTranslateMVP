import SwiftUI

struct ThemeSettingsView: View {
    @AppStorage("appTheme") private var appTheme: String = "system"

    var body: some View {
        List {
            Section(header: Text("テーマを選択")) {

                themeButton("システムに合わせる", "system")
                themeButton("ライトモード", "light")
                themeButton("ダークモード", "dark")
            }
        }
        .navigationTitle("テーマ設定")
        // 🔴 これを追加：この画面自身にもテーマを適用
        .preferredColorScheme(
            appTheme == "light" ? .light :
            appTheme == "dark" ? .dark : nil
        )
    }

    private func themeButton(_ title: String, _ value: String) -> some View {
        Button {
            appTheme = value
        } label: {
            HStack {
                Text(title)
                Spacer()
                if appTheme == value {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
        }
    }
}


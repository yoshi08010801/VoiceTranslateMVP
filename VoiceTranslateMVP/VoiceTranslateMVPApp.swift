import SwiftUI
import SwiftData

@main
struct VoiceTranslateMVPApp: App {
    @AppStorage("appTheme") private var appTheme: String = "system"

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(
                    appTheme == "light" ? .light :
                    appTheme == "dark" ? .dark : nil
                )
        }
        .modelContainer(for: [TranscriptItem.self]) // ✅これ必須
    }
}


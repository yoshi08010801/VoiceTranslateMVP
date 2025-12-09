//
//  VoiceTranslateMVPApp.swift
//  VoiceTranslateMVP
//
//  Created by k on 2025/12/05.
//

import SwiftUI

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
    }
}

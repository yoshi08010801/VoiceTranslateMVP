import SwiftUI

struct RecordingWaveView: View {
    let level: CGFloat      // 0.0〜1.0
    let isRecording: Bool   // 録音中かどうか

    var body: some View {
        ZStack {
            Circle()
                .frame(width: 40, height: 40)
                .foregroundColor(
                    isRecording ? .red.opacity(0.2) : .gray.opacity(0.2)
                )

            Circle()
                .frame(width: 18, height: 18)
                .foregroundColor(isRecording ? .red : .gray)
                .scaleEffect(isRecording ? (1.0 + 1.0 * level) : 1.0)
                .animation(.easeOut(duration: 0.06), value: level)

        }
    }
}


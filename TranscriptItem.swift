import Foundation
import SwiftData

@Model
final class TranscriptItem {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var title: String
    var text: String
    /// Step0はシンプルにCSV文字列でOK（後でTagモデルに拡張できる）
    var tagsCSV: String

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        title: String = "",
        text: String,
        tagsCSV: String = ""
    ) {
        self.id = id
        self.createdAt = createdAt
        self.title = title
        self.text = text
        self.tagsCSV = tagsCSV
    }
}


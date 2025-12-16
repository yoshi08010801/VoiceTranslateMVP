import SwiftUI
import SwiftData

struct TranscriptListView: View {
    @Query(sort: \TranscriptItem.createdAt, order: .reverse)
    private var items: [TranscriptItem]

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            ForEach(items) { item in
                NavigationLink {
                    TranscriptDetailView(item: item)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.title.isEmpty ? "Untitled" : item.title)
                            .font(.headline)
                        Text(item.text)
                            .lineLimit(2)
                            .foregroundStyle(.secondary)
                        Text(item.createdAt, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete(perform: delete)
        }
        .navigationTitle("History")
    }

    private func delete(at offsets: IndexSet) {
        for i in offsets { modelContext.delete(items[i]) }
        try? modelContext.save()
    }
}

struct TranscriptDetailView: View {
    let item: TranscriptItem
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(item.title.isEmpty ? "Untitled" : item.title)
                    .font(.title2).bold()
                Text(item.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Divider()
                Text(item.text).textSelection(.enabled)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}


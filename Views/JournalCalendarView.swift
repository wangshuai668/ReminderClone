import SwiftUI
import SwiftData

/// 日志日历 — 按日期查看所有记录
struct JournalCalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.date, order: .reverse) private var allEntries: [JournalEntry]
    
    /// 按日期分组
    private var groupedEntries: [(date: Date, entries: [JournalEntry])] {
        let grouped = Dictionary(grouping: allEntries) { entry in
            Calendar.current.startOfDay(for: entry.date)
        }
        return grouped.map { (date: $0.key, entries: $0.value) }
            .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationStack {
            if allEntries.isEmpty {
                ContentUnavailableView(
                    "暂无记录",
                    systemImage: "bookmark",
                    description: Text("完成事项后添加文字或照片记录")
                )
            }
            
            List {
                ForEach(groupedEntries, id: \.date) { group in
                    Section {
                        ForEach(group.entries) { entry in
                            VStack(alignment: .leading, spacing: 6) {
                                // 关联事项
                                if let item = entry.todoItem {
                                    HStack {
                                        Image(systemName: item.isCompleted
                                            ? "checkmark.circle.fill"
                                            : "circle")
                                            .foregroundStyle(item.isCompleted ? .green : .secondary)
                                            .font(.caption)
                                        Text(item.title)
                                            .font(.subheadline).fontWeight(.medium)
                                        Spacer()
                                        if let list = entry.list {
                                            HStack(spacing: 3) {
                                                Image(systemName: list.icon)
                                                    .font(.caption2)
                                                Text(list.name)
                                                    .font(.caption2)
                                            }
                                            .foregroundStyle(Color(hex: list.colorHex))
                                        }
                                    }
                                }
                                
                                // 文字
                                if !entry.text.isEmpty {
                                    Text(entry.text)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                }
                                
                                // 照片
                                if !entry.photoDataList.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 6) {
                                            ForEach(entry.photoDataList.indices, id: \.self) { i in
                                                if let uiImage = UIImage(data: entry.photoDataList[i]) {
                                                    Image(uiImage: uiImage)
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 80, height: 80)
                                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                Text(entry.date.formatted(date: .omitted, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Text(group.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.headline)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("日志")
        }
    }
}

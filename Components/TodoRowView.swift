import SwiftUI
import SwiftData

/// 事项行组件 — 显示单个待办事项
struct TodoRowView: View {
    let item: TodoItem
    var showListName: Bool = false
    var onToggle: (() -> Void)?
    @State private var showingJournal = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 完成/未完成圆圈
            Button(action: { onToggle?() }) {
                Image(systemName: item.isCompleted
                    ? "checkmark.circle.fill"
                    : "circle")
                    .font(.title2)
                    .foregroundStyle(item.isCompleted ? .green : .secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                // 标题
                Text(item.title)
                    .font(.body)
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
                
                // 标签行
                if !item.tags.isEmpty || item.dueDate != nil || (showListName && item.list != nil) {
                    HStack(spacing: 6) {
                        // 清单名称
                        if showListName, let list = item.list {
                            HStack(spacing: 3) {
                                Image(systemName: list.icon)
                                    .font(.caption2)
                                Text(list.name)
                                    .font(.caption)
                            }
                            .foregroundStyle(Color(hex: list.colorHex))
                        }
                        
                        // 标签
                        ForEach(item.tags.prefix(3)) { tag in
                            TagBadgeView(tag: tag)
                        }
                        
                        if item.tags.count > 3 {
                            Text("+\(item.tags.count - 3)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        // 日期
                        if let dateDisplay = dateDisplay {
                            HStack(spacing: 3) {
                                Image(systemName: item.isOverdue ? "exclamationmark.circle.fill" : "calendar")
                                    .font(.caption2)
                                Text(dateDisplay)
                                    .font(.caption)
                            }
                            .foregroundStyle(item.isOverdue ? .red : .secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            if !item.notes.isEmpty {
                Image(systemName: "note.text")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            // 记录按钮
            Button(action: { showingJournal = true }) {
                Image(systemName: "bookmark")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .opacity(item.isCompleted ? 0.6 : 1)
        .animation(.easeInOut(duration: 0.2), value: item.isCompleted)
        .sheet(isPresented: $showingJournal) {
            JournalEntryView(item: item)
        }
    }
    
    private var dateDisplay: String? {
        guard let due = item.dueDate else { return nil }
        let calendar = Calendar.current
        if calendar.isDateInToday(due) {
            return item.hasTime
                ? "今天 \(due.formatted(date: .omitted, time: .shortened))"
                : "今天"
        } else if calendar.isDateInTomorrow(due) {
            return "明天"
        } else {
            return due.formatted(date: .abbreviated, time: .omitted)
        }
    }
}

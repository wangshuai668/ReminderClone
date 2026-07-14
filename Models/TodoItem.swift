import Foundation
import SwiftData

/// 单个待办事项模型
@Model
final class TodoItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var notes: String           // 备注
    var isCompleted: Bool
    var dueDate: Date?
    var hasTime: Bool           // 是否带有具体时间
    var createdAt: Date
    var completedAt: Date?
    var sortOrder: Int
    
    /// 所属清单
    var list: TodoList?
    
    /// 标签
    @Relationship(deleteRule: .nullify)
    var tags: [Tag]
    
    /// 格式化后的截止日期显示
    var dueDateDisplay: String {
        guard let date = dueDate else { return "" }
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            if hasTime {
                return "今天 \(date.formatted(date: .omitted, time: .shortened))"
            }
            return "今天"
        } else if calendar.isDateInTomorrow(date) {
            if hasTime {
                return "明天 \(date.formatted(date: .omitted, time: .shortened))"
            }
            return "明天"
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else {
            if hasTime {
                return date.formatted(date: .abbreviated, time: .shortened)
            }
            return date.formatted(date: .abbreviated, time: .omitted)
        }
    }
    
    /// 是否已逾期
    var isOverdue: Bool {
        guard let date = dueDate, !isCompleted else { return false }
        return date < Date()
    }
    
    /// 是否即将到期（今天或明天）
    var isDueSoon: Bool {
        guard let date = dueDate, !isCompleted else { return false }
        let calendar = Calendar.current
        return calendar.isDateInToday(date) || calendar.isDateInTomorrow(date)
    }
    
    init(
        title: String,
        notes: String = "",
        list: TodoList? = nil,
        tags: [Tag] = [],
        dueDate: Date? = nil,
        hasTime: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.isCompleted = false
        self.dueDate = dueDate
        self.hasTime = hasTime
        self.createdAt = Date()
        self.completedAt = nil
        self.sortOrder = 0
        self.list = list
        self.tags = tags
    }
}

import Foundation
import SwiftData

/// 重复周期
enum RepeatType: String, Codable, CaseIterable {
    case none = "不重复"
    case daily = "每天"
    case weekly = "每周"
    case monthly = "每月"
}

/// 单个待办事项模型
@Model
final class TodoItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var notes: String
    var isCompleted: Bool
    var dueDate: Date?
    var hasTime: Bool
    var createdAt: Date
    var completedAt: Date?
    var sortOrder: Int
    var repeatType: String          // RepeatType rawValue
    var repeatEndDate: Date?        // 重复截止日期
    
    var list: TodoList?
    
    @Relationship(deleteRule: .nullify)
    var tags: [Tag]
    
    var repeatTypeEnum: RepeatType {
        get { RepeatType(rawValue: repeatType) ?? .none }
        set { repeatType = newValue.rawValue }
    }
    
    /// 完成并生成下一次副本（重复事项）
    func completeAndRepeat(in context: ModelContext) {
        isCompleted = true
        completedAt = Date()
        
        // 取消通知（切到主线程）
        Task { @MainActor in
            NotificationManager.shared.cancelNotification(for: self)
        }
        
        // 如果是重复事项，创建下一周期副本
        guard repeatTypeEnum != .none, let due = dueDate else { return }
        
        // 检查是否超过重复截止日期
        if let end = repeatEndDate, due >= end { return }
        
        let calendar = Calendar.current
        let nextDate: Date?
        switch repeatTypeEnum {
        case .daily:   nextDate = calendar.date(byAdding: .day, value: 1, to: due)
        case .weekly:  nextDate = calendar.date(byAdding: .day, value: 7, to: due)
        case .monthly: nextDate = calendar.date(byAdding: .month, value: 1, to: due)
        case .none:    nextDate = nil
        }
        
        guard let nextDue = nextDate else { return }
        
        let copy = TodoItem(
            title: title,
            notes: notes,
            list: list,
            tags: tags,
            dueDate: nextDue,
            hasTime: hasTime
        )
        copy.repeatType = repeatType
        copy.repeatEndDate = repeatEndDate
        context.insert(copy)
        
        // 安排下一次通知（切到主线程）
        Task { @MainActor in
            NotificationManager.shared.scheduleNotification(for: copy)
        }
    }
    
    var dueDateDisplay: String {
        guard let date = dueDate else { return "" }
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            if hasTime {
                return "今天 \(date.formatted(date: .omitted, time: .shortened))"
            }
            return "今天"
        } else if calendar.isDateInTomorrow(date) {
            return "明天"
        } else {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
    }
    
    var isOverdue: Bool {
        guard let date = dueDate, !isCompleted else { return false }
        return date < Date()
    }
    
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
        self.repeatType = RepeatType.none.rawValue
        self.repeatEndDate = nil
        self.list = list
        self.tags = tags
    }
}

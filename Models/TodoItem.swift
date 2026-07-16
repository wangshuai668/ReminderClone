import Foundation
import SwiftData

// MARK: - 优先级
enum Priority: String, Codable, CaseIterable {
    case none = "普通"
    case low = "⭐ 低"
    case medium = "🔥 中"
    case high = "🚨 高"
    
    var sortOrder: Int {
        switch self {
        case .none: return 0
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }
}

// MARK: - 能量等级
enum EnergyLevel: String, Codable, CaseIterable {
    case any = "不限"
    case low = "💤 低能量"
    case high = "⚡ 高能量"
}

// MARK: - 重复周期
enum RepeatType: String, Codable, CaseIterable {
    case none = "不重复"
    case daily = "每天"
    case weekly = "每周"
    case monthly = "每月"
}

// MARK: - 子任务
@Model
final class SubTask {
    @Attribute(.unique) var id: UUID
    var title: String
    var isCompleted: Bool
    var sortOrder: Int
    var createdAt: Date
    var parentItem: TodoItem?
    
    init(title: String, sortOrder: Int = 0) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }
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
    
    // 优先级
    var priority: String
    var isImportant: Bool
    
    // 预计耗时（分钟）
    var estimatedMinutes: Int
    
    // 能量等级
    var energyLevel: String
    
    // 重复
    var repeatType: String
    var repeatEndDate: Date?
    
    // 独立提醒
    var reminderEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int
    
    // 子任务
    @Relationship(deleteRule: .cascade)
    var subTasks: [SubTask]
    
    var list: TodoList?
    
    @Relationship(deleteRule: .nullify)
    var tags: [Tag]
    
    @Relationship(deleteRule: .cascade)
    var journalEntries: [JournalEntry] = []
    
    // MARK: - 计算属性
    
    var priorityEnum: Priority {
        get { Priority(rawValue: priority) ?? .none }
        set { priority = newValue.rawValue }
    }
    
    var energyLevelEnum: EnergyLevel {
        get { EnergyLevel(rawValue: energyLevel) ?? .any }
        set { energyLevel = newValue.rawValue }
    }
    
    var repeatTypeEnum: RepeatType {
        get { RepeatType(rawValue: repeatType) ?? .none }
        set { repeatType = newValue.rawValue }
    }
    
    /// 子任务进度
    var subTaskProgress: String {
        let total = subTasks.count
        guard total > 0 else { return "" }
        let done = subTasks.filter(\.isCompleted).count
        return "\(done)/\(total)"
    }
    
    /// 预计耗时显示
    var estimatedTimeDisplay: String {
        guard estimatedMinutes > 0 else { return "" }
        if estimatedMinutes < 60 { return "\(estimatedMinutes)分钟" }
        let h = estimatedMinutes / 60
        let m = estimatedMinutes % 60
        return m > 0 ? "\(h)小时\(m)分钟" : "\(h)小时"
    }
    
    /// 完成并生成下一次副本（重复事项）
    func completeAndRepeat(in context: ModelContext) {
        isCompleted = true
        completedAt = Date()
        
        Task { @MainActor in
            NotificationManager.shared.cancelNotification(for: self)
        }
        
        guard repeatTypeEnum != .none, let due = dueDate else { return }
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
        copy.reminderEnabled = reminderEnabled
        copy.reminderHour = reminderHour
        copy.reminderMinute = reminderMinute
        copy.priority = priority
        copy.isImportant = isImportant
        copy.estimatedMinutes = estimatedMinutes
        copy.energyLevel = energyLevel
        context.insert(copy)
        
        Task { @MainActor in
            NotificationManager.shared.scheduleNotification(for: copy)
        }
    }
    
    /// 提醒时间字符串
    var reminderTimeDisplay: String {
        let h = reminderHour
        let m = reminderMinute
        return String(format: "%02d:%02d", h, m)
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
        self.priority = Priority.none.rawValue
        self.isImportant = false
        self.estimatedMinutes = 0
        self.energyLevel = EnergyLevel.any.rawValue
        self.repeatType = RepeatType.none.rawValue
        self.repeatEndDate = nil
        self.reminderEnabled = false
        self.reminderHour = 9
        self.reminderMinute = 0
        self.subTasks = []
        self.list = list
        self.tags = tags
    }
}

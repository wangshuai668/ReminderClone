import Foundation
import SwiftData

// MARK: - Agent 任务（JSON 解码用）
struct AgentTaskDTO: Codable {
    let title: String
    let notes: String?
    let dueDate: String?       // ISO 8601
    let hasTime: Bool?
    let priority: String?      // "high" / "medium" / "low" / "none"
    let isImportant: Bool?
    let estimatedMinutes: Int?
    let energyLevel: String?   // "high" / "low" / "any"
    let repeatType: String?    // "daily" / "weekly" / "monthly" / "none"
    let reminderEnabled: Bool?
    let reminderHour: Int?
    let reminderMinute: Int?
}

struct AgentInbox: Codable {
    let version: Int
    let tasks: [AgentTaskDTO]
}

// MARK: - Agent 任务桥接器
/// 从 agent-tasks.json 读取 Agent 下达的任务并导入 SwiftData
final class AgentBridge {
    
    static let shared = AgentBridge()
    private let fileName = "agent-tasks"
    private let fileExt = "json"
    
    private init() {}
    
    /// 导入所有待处理的 Agent 任务
    /// 返回导入数量，调用者负责 save() 和清空 inbox
    @discardableResult
    func importPendingTasks(into context: ModelContext) -> Int {
        guard let inbox = readInbox(), !inbox.tasks.isEmpty else { return 0 }
        
        var imported = 0
        let df = ISO8601DateFormatter()
        df.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        for t in inbox.tasks {
            let item = TodoItem(title: t.title)
            item.notes = t.notes ?? ""
            
            if let ds = t.dueDate, let d = df.date(from: ds) ?? ISO8601DateFormatter().date(from: ds) {
                item.dueDate = d
                item.hasTime = t.hasTime ?? false
            }
            
            // 优先级
            if let p = t.priority {
                switch p {
                case "high":   item.priority = Priority.high.rawValue; item.isImportant = true
                case "medium": item.priority = Priority.medium.rawValue
                case "low":    item.priority = Priority.low.rawValue
                default:       item.priority = Priority.none.rawValue
                }
            }
            item.isImportant = t.isImportant ?? item.isImportant
            item.estimatedMinutes = t.estimatedMinutes ?? 0
            
            // 能量
            if let e = t.energyLevel {
                switch e {
                case "high": item.energyLevel = EnergyLevel.high.rawValue
                case "low":  item.energyLevel = EnergyLevel.low.rawValue
                default:     item.energyLevel = EnergyLevel.any.rawValue
                }
            }
            
            // 重复
            if let r = t.repeatType {
                switch r {
                case "daily":   item.repeatType = RepeatType.daily.rawValue
                case "weekly":  item.repeatType = RepeatType.weekly.rawValue
                case "monthly": item.repeatType = RepeatType.monthly.rawValue
                default:        item.repeatType = RepeatType.none.rawValue
                }
            }
            
            item.reminderEnabled = t.reminderEnabled ?? false
            item.reminderHour = t.reminderHour ?? 9
            item.reminderMinute = t.reminderMinute ?? 0
            
            context.insert(item)
            imported += 1
        }
        
        // 清空 inbox，下次不重复导入
        clearInbox()
        
        print("🤖 AgentBridge: 已导入 \(imported) 个 Agent 任务")
        return imported
    }
    
    /// 检查是否有待处理的任务
    var hasPendingTasks: Bool {
        guard let inbox = readInbox() else { return false }
        guard !inbox.tasks.isEmpty else { return false }
        let key = "agent_inbox_processed_version"
        let processedVersion = UserDefaults.standard.integer(forKey: key)
        return inbox.version > processedVersion
    }
    
    var pendingCount: Int {
        guard hasPendingTasks else { return 0 }
        return readInbox()?.tasks.count ?? 0
    }
    
    // MARK: - 私有
    
    private func readInbox() -> AgentInbox? {
        guard let url = bundleURL() else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(AgentInbox.self, from: data)
    }
    
    private func bundleURL() -> URL? {
        Bundle.main.url(forResource: fileName, withExtension: fileExt)
    }
    
    private func clearInbox() {
        // inbox 在 bundle 里是只读的，无法写入
        // 通过标记已导入 + 下次编译时 Agent 清空 JSON 来解决
        // 这里用 UserDefaults 记录已处理的版本
        if let inbox = readInbox() {
            let key = "agent_inbox_processed_version"
            UserDefaults.standard.set(inbox.version, forKey: key)
        }
    }
}

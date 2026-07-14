import Foundation
import SwiftData

/// 清单分类模型
@Model
final class TodoList {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String           // SF Symbol 名称
    var colorHex: String       // 自定义颜色
    var createdAt: Date
    var sortOrder: Int
    
    @Relationship(deleteRule: .cascade, inverse: \TodoItem.list)
    var items: [TodoItem]
    
    /// 未完成事项数量
    var incompleteCount: Int {
        items.filter { !$0.isCompleted }.count
    }
    
    /// 最近未完成事项（用于预览）
    var latestIncompleteItem: TodoItem? {
        items.filter { !$0.isCompleted }
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }
    
    init(name: String, icon: String = "list.bullet", colorHex: String = "#007AFF") {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.createdAt = Date()
        self.sortOrder = 0
        self.items = []
    }
}

// MARK: - 预置颜色
extension TodoList {
    static let presetColors: [(name: String, hex: String)] = [
        ("红色", "#FF3B30"),
        ("橙色", "#FF9500"),
        ("黄色", "#FFCC00"),
        ("绿色", "#34C759"),
        ("蓝色", "#007AFF"),
        ("紫色", "#AF52DE"),
        ("粉色", "#FF2D55"),
        ("灰色", "#8E8E93"),
    ]
}

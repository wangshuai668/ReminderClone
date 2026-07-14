import Foundation
import SwiftData

/// 标签模型
@Model
final class Tag {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String
    
    @Relationship(inverse: \TodoItem.tags)
    var items: [TodoItem]
    
    init(name: String, colorHex: String = "#007AFF") {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.items = []
    }
}

// MARK: - 预设标签
extension Tag {
    static let presetTags: [(name: String, colorHex: String)] = [
        ("工作", "#007AFF"),
        ("个人", "#AF52DE"),
        ("重要", "#FF3B30"),
        ("紧急", "#FF9500"),
        ("购物", "#34C759"),
        ("学习", "#5856D6"),
        ("健康", "#FF2D55"),
        ("创意", "#FFCC00"),
    ]
}

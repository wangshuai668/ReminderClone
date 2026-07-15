import Foundation
import SwiftData
import SwiftUI

/// 事项日志条目 — 文字记录 + 照片
@Model
final class JournalEntry {
    @Attribute(.unique) var id: UUID
    var todoItem: TodoItem?          // 所属事项
    var date: Date                   // 记录日期（用户可手动选择）
    var text: String                 // 文字记录
    @Attribute(.externalStorage)     // 大数据存储
    var photoDataList: [Data]        // 照片二进制
    var createdAt: Date
    
    var list: TodoList?              // 关联清单（方便按清单筛选）
    
    init(
        todoItem: TodoItem? = nil,
        date: Date = Date(),
        text: String = "",
        photoDataList: [Data] = [],
        list: TodoList? = nil
    ) {
        self.id = UUID()
        self.todoItem = todoItem
        self.date = date
        self.text = text
        self.photoDataList = photoDataList
        self.createdAt = Date()
        self.list = list
    }
}

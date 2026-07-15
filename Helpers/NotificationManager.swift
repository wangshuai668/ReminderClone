import Foundation
import UserNotifications
import SwiftUI

/// 本地通知管理器
@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    private init() {
        Task { await checkAuthorization() }
    }
    
    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
        } catch {
            print("通知授权失败: \(error.localizedDescription)")
        }
    }
    
    func checkAuthorization() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }
    
    /// 为事项安排所有通知（截止日期提醒 + 独立提醒）
    func scheduleNotification(for item: TodoItem) {
        guard isAuthorized else { return }
        
        // 截止日期提醒
        if let dueDate = item.dueDate {
            scheduleDueDateNotification(for: item, at: dueDate)
        }
        
        // 独立每日提醒
        if item.reminderEnabled {
            scheduleDailyReminder(for: item)
        }
    }
    
    /// 截止日期通知（一次性）
    private func scheduleDueDateNotification(for item: TodoItem, at date: Date) {
        let center = UNUserNotificationCenter.current()
        let content = makeNotificationContent(for: item, prefix: "截止")
        
        let triggerDate: Date
        if item.hasTime {
            triggerDate = date
        } else {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = 9
            components.minute = 0
            triggerDate = calendar.date(from: components) ?? date
        }
        
        let triggerComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "due-\(item.id.uuidString)",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }
    
    /// 每日重复提醒
    private func scheduleDailyReminder(for item: TodoItem) {
        let center = UNUserNotificationCenter.current()
        let content = makeNotificationContent(for: item, prefix: "提醒")
        
        var components = DateComponents()
        components.hour = item.reminderHour
        components.minute = item.reminderMinute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "reminder-\(item.id.uuidString)",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }
    
    /// 创建通知内容
    private func makeNotificationContent(for item: TodoItem, prefix: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "\(prefix): \(item.title)"
        content.body = item.notes.isEmpty ? "查看详情" : item.notes
        content.sound = .default
        return content
    }
    
    /// 取消事项的所有通知
    func cancelNotification(for item: TodoItem) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [
            "due-\(item.id.uuidString)",
            "reminder-\(item.id.uuidString)"
        ])
    }
    
    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

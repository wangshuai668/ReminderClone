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
    
    /// 请求通知权限
    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
        } catch {
            print("通知授权失败: \(error.localizedDescription)")
        }
    }
    
    /// 检查权限状态
    func checkAuthorization() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }
    
    /// 为事项安排通知
    func scheduleNotification(for item: TodoItem) {
        guard let dueDate = item.dueDate, isAuthorized else { return }
        
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "提醒事项"
        content.body = item.title
        content.sound = .default
        
        let trimmedNotes = item.notes.trimmingCharacters(in: .whitespaces)
        if !trimmedNotes.isEmpty {
            content.body = "\(item.title) — \(trimmedNotes)"
        }
        
        // 计算触发时间
        let triggerDate: Date
        if item.hasTime {
            triggerDate = dueDate
        } else {
            // 没有具体时间则设为当天上午9点
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: dueDate)
            components.hour = 9
            components.minute = 0
            triggerDate = calendar.date(from: components) ?? dueDate
        }
        
        let triggerComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: triggerComponents,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: item.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("通知调度失败: \(error.localizedDescription)")
            }
        }
    }
    
    /// 取消事项的通知
    func cancelNotification(for item: TodoItem) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [item.id.uuidString])
    }
    
    /// 取消所有通知
    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

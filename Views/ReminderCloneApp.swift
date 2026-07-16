import SwiftUI
import SwiftData

@main
struct ReminderCloneApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    static let container: ModelContainer = {
        let schema = Schema([TodoList.self, TodoItem.self, Tag.self, JournalEntry.self, SubTask.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            // 模型变更导致迁移失败 → 删除旧库重建，不会 crash
            print("⚠️ SwiftData 迁移失败: \(error)")
            if let storeURL = config.url {
                let storeDir = storeURL.deletingLastPathComponent()
                try? FileManager.default.removeItem(at: storeDir)
                print("✅ 已删除旧数据库，重建新库")
            }
            return try! ModelContainer(for: schema, configurations: config)
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(Self.container)
    }
}

/// App Delegate: 启动时请求通知权限 + 恢复已有事项的通知
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Task { @MainActor in
            await NotificationManager.shared.requestAuthorization()
            // 恢复所有未完成事项的通知（处理重装/重启后通知丢失）
            NotificationManager.shared.rescheduleAll(in: ReminderCloneApp.container.mainContext)
        }
        return true
    }
}

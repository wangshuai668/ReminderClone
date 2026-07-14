import SwiftUI
import SwiftData

@main
struct ReminderCloneApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    let container: ModelContainer = {
        let schema = Schema([TodoList.self, TodoItem.self, Tag.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("SwiftData 初始化失败: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(container)
    }
}

/// App Delegate: 启动时请求通知权限
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Task { @MainActor in
            await NotificationManager.shared.requestAuthorization()
        }
        return true
    }
}

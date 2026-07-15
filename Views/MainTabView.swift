import SwiftUI

/// 主 Tab 容器
struct MainTabView: View {
    var body: some View {
        TabView {
            ListHomeView()
                .tabItem {
                    Label("清单", systemImage: "list.bullet")
                }
            
            TodayView()
                .tabItem {
                    Label("今天", systemImage: "calendar.day.timeline.left")
                }
            
            SearchView()
                .tabItem {
                    Label("搜索", systemImage: "magnifyingglass")
                }
            
            JournalCalendarView()
                .tabItem {
                    Label("日志", systemImage: "bookmark")
                }
        }
        .tint(.blue)
    }
}

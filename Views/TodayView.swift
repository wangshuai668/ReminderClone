import SwiftUI
import SwiftData

/// 今日待办 — 汇聚所有清单中今日到期/逾期的事项
struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(filter: #Predicate<TodoItem> { !$0.isCompleted },
           sort: \TodoItem.dueDate, order: .forward)
    private var allItems: [TodoItem]
    
    private var overdueItems: [TodoItem] {
        allItems.filter { $0.isOverdue }
    }
    
    private var todayItems: [TodoItem] {
        allItems.filter { item in
            guard let date = item.dueDate else { return false }
            return Calendar.current.isDateInToday(date) && !item.isOverdue
        }
    }
    
    private var upcomingItems: [TodoItem] {
        allItems.filter { item in
            guard let date = item.dueDate else { return false }
            return !Calendar.current.isDateInToday(date) && !item.isOverdue && date > Date()
        }
    }
    
    private var noDateItems: [TodoItem] {
        allItems.filter { $0.dueDate == nil }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // 逾期
                if !overdueItems.isEmpty {
                    Section {
                        ForEach(overdueItems) { item in
                            TodoRowView(item: item, showListName: true) {
                                toggleItem(item)
                            }
                        }
                    } header: {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.red)
                            Text("逾期")
                            Spacer()
                            Text("\(overdueItems.count)")
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                    }
                }
                
                // 今天
                Section {
                    if todayItems.isEmpty && overdueItems.isEmpty {
                        Text("今天没有待办事项 🎉")
                            .foregroundStyle(.tertiary)
                    }
                    ForEach(todayItems) { item in
                        TodoRowView(item: item, showListName: true) {
                            toggleItem(item)
                        }
                    }
                } header: {
                    HStack {
                        Image(systemName: "calendar.day.timeline.left")
                        Text("今天")
                    }
                }
                
                // 以后
                if !upcomingItems.isEmpty {
                    Section {
                        ForEach(upcomingItems) { item in
                            TodoRowView(item: item, showListName: true) {
                                toggleItem(item)
                            }
                        }
                    } header: {
                        HStack {
                            Image(systemName: "calendar")
                            Text("以后")
                        }
                    }
                }
                
                // 无日期
                if !noDateItems.isEmpty {
                    Section {
                        ForEach(noDateItems) { item in
                            TodoRowView(item: item, showListName: true) {
                                toggleItem(item)
                            }
                        }
                    } header: {
                        HStack {
                            Image(systemName: "tray")
                            Text("未设定日期")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("今日待办")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: {
                        NewTodoSheet()
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    private func toggleItem(_ item: TodoItem) {
        withAnimation {
            item.isCompleted.toggle()
            item.completedAt = item.isCompleted ? Date() : nil
            if item.isCompleted {
                NotificationManager.shared.cancelNotification(for: item)
            }
        }
    }
}

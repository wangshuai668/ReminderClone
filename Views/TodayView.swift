import SwiftUI
import SwiftData

/// 今日待办 — 智能分组 + 今日最佳任务
struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(filter: #Predicate<TodoItem> { !$0.isCompleted },
           sort: \TodoItem.dueDate, order: .forward)
    private var allItems: [TodoItem]
    
    // MARK: - 智能分组
    
    /// 今日最佳任务：按优先级 × 能量等级排序
    private var bestTasks: [TodoItem] {
        let today = Calendar.current.isDateInToday
        return allItems.filter { item in
            // 今天到期的、或重要的、或高优先级的
            guard let date = item.dueDate else {
                return item.isImportant || item.priorityEnum != .none
            }
            return today(date) || item.isImportant || item.priorityEnum != .none
        }
        .sorted { a, b in
            // 排序：优先级高→低 → 重要→不重要 → 快到期的优先
            if a.priorityEnum.sortOrder != b.priorityEnum.sortOrder {
                return a.priorityEnum.sortOrder > b.priorityEnum.sortOrder
            }
            if a.isImportant != b.isImportant { return a.isImportant }
            return (a.dueDate ?? .distantFuture) < (b.dueDate ?? .distantFuture)
        }
    }
    
    /// 高能量任务（适合上午）
    private var highEnergyTasks: [TodoItem] {
        bestTasks.filter { $0.energyLevelEnum == .high || $0.energyLevelEnum == .any }
    }
    
    /// 低能量任务（适合晚上）
    private var lowEnergyTasks: [TodoItem] {
        bestTasks.filter { $0.energyLevelEnum == .low }
    }
    
    private var overdueItems: [TodoItem] {
        allItems.filter { $0.isOverdue }
    }
    
    private var todayItems: [TodoItem] {
        allItems.filter { item in
            guard let date = item.dueDate else { return false }
            return Calendar.current.isDateInToday(date) && !item.isOverdue
        }
    }
    
    /// 明天到期（即将逾期）
    private var dueTomorrowItems: [TodoItem] {
        allItems.filter { item in
            guard let date = item.dueDate else { return false }
            return Calendar.current.isDateInTomorrow(date) && !item.isOverdue
        }
        .sorted { a, b in a.priorityEnum.sortOrder > b.priorityEnum.sortOrder }
    }
    
    private var upcomingItems: [TodoItem] {
        allItems.filter { item in
            guard let date = item.dueDate else { return false }
            return !Calendar.current.isDateInToday(date) && !Calendar.current.isDateInTomorrow(date) && !item.isOverdue && date > Date()
        }
    }
    
    private var noDateItems: [TodoItem] {
        allItems.filter { $0.dueDate == nil }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: — 今日最佳任务
                if !bestTasks.isEmpty {
                    Section {
                        if !highEnergyTasks.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("☀️ 上午安排", systemImage: "sun.max")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.orange)
                                ForEach(highEnergyTasks) { item in
                                    TodoRowView(item: item, showListName: true) {
                                        toggleItem(item)
                                    }
                                }
                            }
                        }
                        
                        if !lowEnergyTasks.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("🌙 晚上安排", systemImage: "moon.stars")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.indigo)
                                ForEach(lowEnergyTasks) { item in
                                    TodoRowView(item: item, showListName: true) {
                                        toggleItem(item)
                                    }
                                }
                            }
                        }
                    } header: {
                        Label("今日最佳", systemImage: "star.fill")
                            .foregroundStyle(.yellow)
                    }
                }
                
                // MARK: — 逾期
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
                
                // MARK: — 今天
                Section {
                    if todayItems.isEmpty && overdueItems.isEmpty && bestTasks.isEmpty {
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
                
                // MARK: — 即将逾期（明天）
                if !dueTomorrowItems.isEmpty {
                    Section {
                        ForEach(dueTomorrowItems) { item in
                            TodoRowView(item: item, showListName: true) {
                                toggleItem(item)
                            }
                        }
                    } header: {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundStyle(.orange)
                            Text("明天截止")
                            Spacer()
                            Text("\(dueTomorrowItems.count)")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                
                // MARK: — 以后
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
                
                // MARK: — 无日期
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
                    NavigationLink(destination: NewTodoSheet()) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    private func toggleItem(_ item: TodoItem) {
        withAnimation {
            item.completeAndRepeat(in: modelContext)
        }
    }
}

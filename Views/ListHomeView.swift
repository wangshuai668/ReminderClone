import SwiftUI
import SwiftData

/// 清单主页 — 显示所有清单分类
struct ListHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoList.sortOrder) private var lists: [TodoList]
    
    /// 全局未完成事项数
    @Query(filter: #Predicate<TodoItem> { !$0.isCompleted })
    private var allItems: [TodoItem]
    
    private var dueTomorrowCount: Int {
        allItems.filter {
            guard let d = $0.dueDate else { return false }
            return Calendar.current.isDateInTomorrow(d)
        }.count
    }
    
    private var importantCount: Int {
        allItems.filter { $0.isImportant }.count
    }
    
    @State private var showingNewList = false
    @State private var newListName = ""
    @State private var newListIcon = "list.bullet"
    @State private var newListColor = "#007AFF"
    @State private var showingAIQuickAdd = false
    @State private var showingGoalPlanner = false
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: — 智能列表
                Section {
                    // AI 创建
                    Button(action: { showingAIQuickAdd = true }) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing).opacity(0.2))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "sparkles")
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("AI 创建")
                                    .font(.subheadline.weight(.medium))
                                Text("自然语言快速添加任务")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    // 目标规划
                    Button(action: { showingGoalPlanner = true }) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing).opacity(0.2))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "brain.head.profile")
                                    .font(.subheadline)
                                    .foregroundStyle(.purple)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("目标规划")
                                    .font(.subheadline.weight(.medium))
                                Text("AI 自动拆分每日任务")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    // 今日最佳
                    NavigationLink(destination: TodayView()) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.yellow.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "star.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.yellow)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("今日最佳")
                                    .font(.subheadline.weight(.medium))
                                Text("按优先级·能量智能排序")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    // 明天截止
                    if dueTomorrowCount > 0 {
                        NavigationLink(destination: TodayView()) {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.orange.opacity(0.15))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "bell.fill")
                                        .font(.subheadline)
                                        .foregroundStyle(.orange)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("即将逾期")
                                        .font(.subheadline.weight(.medium))
                                    Text("\(dueTomorrowCount) 项明天截止")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    
                    // 重要事项
                    if importantCount > 0 {
                        NavigationLink(destination: TodayView()) {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.red.opacity(0.15))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.subheadline)
                                        .foregroundStyle(.red)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("重要事项")
                                        .font(.subheadline.weight(.medium))
                                    Text("\(importantCount) 项标记为重要")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } header: {
                    Label("智能列表", systemImage: "sparkle.magnifyingglass")
                        .foregroundStyle(.blue)
                }
                
                // MARK: — 我的清单
                Section {
                    ForEach(lists) { list in
                        NavigationLink(destination: ListDetailView(list: list)) {
                            ListCardView(list: list)
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                    }
                    .onDelete(perform: deleteLists)
                } header: {
                    HStack {
                        Text("我的清单")
                        Spacer()
                        Text("\(lists.count) 个清单 · \(allItems.count) 项待办")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // MARK: — 更多
                Section {
                    NavigationLink(destination: CompletedView()) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.green.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.green)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("已完成")
                                    .font(.subheadline.weight(.medium))
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("我的清单")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: { showingNewList = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("新建清单")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                }
                .buttonStyle(.plain)
            }
            .sheet(isPresented: $showingNewList) {
                newListSheet
            }
            .sheet(isPresented: $showingAIQuickAdd) {
                AIQuickAddView()
            }
            .sheet(isPresented: $showingGoalPlanner) {
                GoalPlannerView()
            }
        }
    }
    
    // MARK: - 新建清单 Sheet
    private var newListSheet: some View {
        NavigationStack {
            Form {
                Section("清单名称") {
                    TextField("例如：工作、个人、购物", text: $newListName)
                }
                
                Section("图标") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                        ForEach(listIcons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title3)
                                .frame(width: 36, height: 36)
                                .background(newListIcon == icon ? Color.blue.opacity(0.2) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .onTapGesture { newListIcon = icon }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("颜色") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(TodoList.presetColors, id: \.hex) { color in
                            Circle()
                                .fill(Color(hex: color.hex))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    newListColor == color.hex
                                        ? Image(systemName: "checkmark")
                                            .font(.caption).fontWeight(.bold)
                                            .foregroundStyle(.white)
                                        : nil
                                )
                                .onTapGesture { newListColor = color.hex }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("新建清单")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { showingNewList = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { addList() }
                        .disabled(newListName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private var listIcons: [String] {
        ["list.bullet", "folder", "star", "heart", "bookmark", "flag",
         "cart", "person", "house", "bag", "gym", "music",
         "pencil", "calendar", "clock", "bell", "gift", "camera",
         "book", "dollarsign", "phone", "envelope", "map", "wand.and.stars"]
    }
    
    private func addList() {
        let name = newListName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        
        let list = TodoList(name: name, icon: newListIcon, colorHex: newListColor)
        list.sortOrder = lists.count
        modelContext.insert(list)
        
        newListName = ""
        newListIcon = "list.bullet"
        newListColor = "#007AFF"
        showingNewList = false
    }
    
    private func deleteLists(_ indexSet: IndexSet) {
        for index in indexSet {
            modelContext.delete(lists[index])
        }
    }
}

/// 已完成事项视图
struct CompletedView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<TodoItem> { $0.isCompleted == true },
           sort: \TodoItem.completedAt, order: .reverse) private var items: [TodoItem]
    
    var body: some View {
        List {
            if items.isEmpty {
                ContentUnavailableView("没有已完成的事项", systemImage: "checkmark.circle")
            }
            ForEach(items) { item in
                TodoRowView(item: item) {
                    item.isCompleted = false
                    item.completedAt = nil
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    modelContext.delete(items[index])
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("已完成")
    }
}

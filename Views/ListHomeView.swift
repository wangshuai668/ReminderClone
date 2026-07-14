import SwiftUI
import SwiftData

/// 清单主页 — 显示所有清单分类
struct ListHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoList.sortOrder) private var lists: [TodoList]
    
    @State private var showingNewList = false
    @State private var newListName = ""
    @State private var newListIcon = "list.bullet"
    @State private var newListColor = "#007AFF"
    
    var body: some View {
        NavigationStack {
            List {
                // 所有清单
                ForEach(lists) { list in
                    NavigationLink(destination: ListDetailView(list: list)) {
                        ListCardView(list: list)
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                }
                .onDelete(perform: deleteLists)
                
                // "已完成" 入口
                NavigationLink(destination: CompletedView()) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.green)
                        }
                        Text("已完成")
                            .font(.headline)
                    }
                    .padding(.vertical, 8)
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
            }
            .listStyle(.insetGrouped)
            .navigationTitle("我的清单")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .safeAreaInset(edge: .bottom) {
                // 新建清单按钮
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

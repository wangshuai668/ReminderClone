import SwiftUI
import SwiftData

/// 清单详情 — 显示某个清单下的所有待办事项
struct ListDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let list: TodoList
    
    @State private var showingNewItem = false
    
    /// 按是否完成分组
    private var incompleteItems: [TodoItem] {
        list.items.filter { !$0.isCompleted }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }
    
    private var completedItems: [TodoItem] {
        list.items.filter { $0.isCompleted }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }
    
    var body: some View {
        List {
            // 未完成
            Section {
                if incompleteItems.isEmpty {
                    Text("暂无待办事项")
                        .foregroundStyle(.tertiary)
                        .listRowBackground(Color.clear)
                }
                ForEach(incompleteItems) { item in
                    TodoRowView(item: item) {
                        withAnimation {
                            item.isCompleted.toggle()
                            item.completedAt = item.isCompleted ? Date() : nil
                            if item.isCompleted {
                                NotificationManager.shared.cancelNotification(for: item)
                            }
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            modelContext.delete(item)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            withAnimation {
                                item.isCompleted.toggle()
                                item.completedAt = item.isCompleted ? Date() : nil
                            }
                        } label: {
                            Label("完成", systemImage: "checkmark.circle.fill")
                        }
                        .tint(.green)
                    }
                }
            } header: {
                HStack {
                    Text("待办")
                    Spacer()
                    Text("\(incompleteItems.count)")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            
            // 已完成
            if !completedItems.isEmpty {
                Section("已完成") {
                    ForEach(completedItems) { item in
                        TodoRowView(item: item) {
                            withAnimation {
                                item.isCompleted.toggle()
                                item.completedAt = nil
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                modelContext.delete(item)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(list.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingNewItem = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewItem) {
            NewTodoSheet(initialList: list)
        }
    }
}

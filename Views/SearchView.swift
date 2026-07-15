import SwiftUI
import SwiftData

/// 搜索视图 — 按关键词搜索所有事项
struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allItems: [TodoItem]
    
    @State private var searchText = ""
    @State private var showingNewItem = false
    
    private var searchResults: [TodoItem] {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return allItems.filter { !$0.isCompleted }
                .sorted { $0.createdAt > $1.createdAt }
        }
        
        let query = searchText.lowercased()
        return allItems.filter { item in
            item.title.lowercased().contains(query) ||
            item.notes.lowercased().contains(query) ||
            item.tags.contains { $0.name.lowercased().contains(query) } ||
            (item.list?.name.lowercased().contains(query) ?? false)
        }
        .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if searchResults.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "搜索所有事项" : "无匹配结果",
                        systemImage: searchText.isEmpty ? "magnifyingglass" : "magnifyingglass.circle",
                        description: Text(searchText.isEmpty ? "输入关键词搜索标题、备注、标签" : "尝试其他关键词")
                    )
                }
                
                ForEach(searchResults) { item in
                    TodoRowView(item: item, showListName: true) {
                        withAnimation {
                            item.completeAndRepeat(in: modelContext)
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
            .listStyle(.insetGrouped)
            .navigationTitle("搜索")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索标题、备注或标签")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: NewTodoSheet()) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

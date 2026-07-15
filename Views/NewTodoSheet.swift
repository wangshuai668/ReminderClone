import SwiftUI
import SwiftData

/// 新建事项 Sheet — 在所有页面中复用
struct NewTodoSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \TodoList.sortOrder) private var lists: [TodoList]
    @Query(sort: \Tag.name) private var allTags: [Tag]
    
    var initialList: TodoList? = nil
    var initialText: String = ""
    
    @State private var title: String
    @State private var notes: String
    @State private var selectedList: TodoList?
    @State private var selectedTags: Set<Tag> = []
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date()
    @State private var hasTime: Bool = false
    @State private var repeatType: RepeatType = .none
    @State private var repeatEndDate: Date = Date().addingTimeInterval(365*86400)
    @State private var hasRepeatEnd: Bool = false
    
    @State private var showingTagPicker = false
    @State private var showingNewTag = false
    @State private var newTagName = ""
    
    init(initialList: TodoList? = nil, initialText: String = "") {
        self.initialList = initialList
        self.initialText = initialText
        _title = State(initialValue: initialText)
        _notes = State(initialValue: "")
        _selectedList = State(initialValue: initialList)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("事项标题", text: $title, axis: .vertical)
                        .font(.body)
                    
                    TextField("备注", text: $notes, axis: .vertical)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Section {
                    // 清单选择
                    Picker(selection: $selectedList) {
                        Text("无").tag(nil as TodoList?)
                        ForEach(lists) { list in
                            HStack {
                                Image(systemName: list.icon)
                                    .foregroundStyle(Color(hex: list.colorHex))
                                Text(list.name)
                            }
                            .tag(list as TodoList?)
                        }
                    } label: {
                        Label("清单", systemImage: "folder")
                    }
                    
                    // 日期
                    Toggle(isOn: $hasDueDate) {
                        Label("日期", systemImage: "calendar")
                    }
                    
                    if hasDueDate {
                        DatePicker(
                            "日期",
                            selection: $dueDate,
                            displayedComponents: hasTime ? [.date, .hourAndMinute] : [.date]
                        )
                        .datePickerStyle(.graphical)
                        
                        Toggle("指定时间", isOn: $hasTime)
                    }
                    
                    // 重复
                    if hasDueDate {
                        Picker("重复", selection: $repeatType) {
                            ForEach(RepeatType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        
                        if repeatType != .none {
                            Toggle("截止日期", isOn: $hasRepeatEnd)
                            if hasRepeatEnd {
                                DatePicker("重复截止", selection: $repeatEndDate,
                                           displayedComponents: .date)
                            }
                        }
                    }
                    
                    // 标签
                    HStack {
                        Label("标签", systemImage: "tag")
                        Spacer()
                        if !selectedTags.isEmpty {
                            HStack(spacing: 4) {
                                ForEach(Array(selectedTags)) { tag in
                                    TagBadgeView(tag: tag)
                                }
                            }
                        }
                        Button("选择") { showingTagPicker = true }
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("新建事项")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { addItem() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showingTagPicker) {
                tagPickerSheet
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    // MARK: - 标签选择弹窗
    private var tagPickerSheet: some View {
        NavigationStack {
            List {
                ForEach(allTags) { tag in
                    HStack {
                        TagBadgeView(tag: tag)
                        Spacer()
                        if selectedTags.contains(tag) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedTags.contains(tag) {
                            selectedTags.remove(tag)
                        } else {
                            selectedTags.insert(tag)
                        }
                    }
                }
                
                Button(action: { showingNewTag = true }) {
                    Label("新建标签", systemImage: "plus")
                }
            }
            .navigationTitle("选择标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { showingTagPicker = false }
                }
            }
            .alert("新建标签", isPresented: $showingNewTag) {
                TextField("标签名称", text: $newTagName)
                Button("取消", role: .cancel) { }
                Button("确定") { addTag() }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func addTag() {
        let name = newTagName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let tag = Tag(name: name)
        modelContext.insert(tag)
        selectedTags.insert(tag)
        newTagName = ""
    }
    
    private func addItem() {
        let titleText = title.trimmingCharacters(in: .whitespaces)
        guard !titleText.isEmpty else { return }
        
        let item = TodoItem(
            title: titleText,
            notes: notes,
            list: selectedList,
            tags: Array(selectedTags),
            dueDate: hasDueDate ? dueDate : nil,
            hasTime: hasDueDate && hasTime
        )
        item.repeatType = repeatType.rawValue
        if repeatType != .none && hasRepeatEnd {
            item.repeatEndDate = repeatEndDate
        }
        
        modelContext.insert(item)
        
        // 安排通知
        if hasDueDate {
            NotificationManager.shared.scheduleNotification(for: item)
        }
        
        dismiss()
    }
}

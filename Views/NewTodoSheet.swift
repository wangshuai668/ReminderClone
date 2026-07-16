import SwiftUI
import SwiftData

/// 新建事项 Sheet
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
    
    // 独立提醒
    @State private var reminderEnabled: Bool = false
    @State private var reminderTime: Date = {
        let cal = Calendar.current
        return cal.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    }()
    
    // 新字段
    @State private var priority: Priority = .none
    @State private var isImportant: Bool = false
    @State private var estimatedMinutes: Int = 0
    @State private var energyLevel: EnergyLevel = .any
    @State private var subTaskTexts: [String] = []
    
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
                // MARK: 标题 & 备注
                Section {
                    TextField("事项标题", text: $title, axis: .vertical)
                        .font(.body)
                    TextField("备注", text: $notes, axis: .vertical)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // MARK: 优先级 & 重要
                Section {
                    Picker("优先级", selection: $priority) {
                        ForEach(Priority.allCases, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    
                    Toggle(isOn: $isImportant) {
                        Label("重要", systemImage: "exclamationmark.circle")
                            .foregroundStyle(isImportant ? .orange : .secondary)
                    }
                    
                    Picker("能量等级", selection: $energyLevel) {
                        ForEach(EnergyLevel.allCases, id: \.self) { e in
                            Text(e.rawValue).tag(e)
                        }
                    }
                    
                    HStack {
                        Label("预计耗时", systemImage: "clock")
                        Spacer()
                        Picker("", selection: $estimatedMinutes) {
                            Text("不限").tag(0)
                            Text("15分钟").tag(15)
                            Text("30分钟").tag(30)
                            Text("1小时").tag(60)
                            Text("2小时").tag(120)
                            Text("3小时").tag(180)
                            Text("4小时+").tag(240)
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                // MARK: 日期 & 重复
                Section {
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
                    
                    Toggle(isOn: $hasDueDate) {
                        Label("截止日期", systemImage: "calendar")
                    }
                    
                    if hasDueDate {
                        DatePicker(
                            "日期",
                            selection: $dueDate,
                            displayedComponents: hasTime ? [.date, .hourAndMinute] : [.date]
                        )
                        .datePickerStyle(.graphical)
                        
                        Toggle("指定时间", isOn: $hasTime)
                        
                        Picker("重复", selection: $repeatType) {
                            ForEach(RepeatType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        
                        if repeatType != .none {
                            Toggle("重复截止", isOn: $hasRepeatEnd)
                            if hasRepeatEnd {
                                DatePicker("截止", selection: $repeatEndDate,
                                           displayedComponents: .date)
                            }
                        }
                    }
                    
                    Toggle(isOn: $reminderEnabled) {
                        Label("每日提醒", systemImage: "bell")
                    }
                    
                    if reminderEnabled {
                        DatePicker("提醒时间", selection: $reminderTime,
                                   displayedComponents: .hourAndMinute)
                    }
                }
                
                // MARK: 子任务
                Section {
                    ForEach(subTaskTexts.indices, id: \.self) { i in
                        HStack {
                            Image(systemName: "circle")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            TextField("子任务 \(i + 1)", text: $subTaskTexts[i])
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                subTaskTexts.remove(at: i)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                    
                    Button(action: { subTaskTexts.append("") }) {
                        Label("添加子任务", systemImage: "plus.circle")
                    }
                } header: {
                    Label("子任务", systemImage: "checklist")
                }
                
                // MARK: 标签
                Section {
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
        item.priority = priority.rawValue
        item.isImportant = isImportant
        item.estimatedMinutes = estimatedMinutes
        item.energyLevel = energyLevel.rawValue
        item.repeatType = repeatType.rawValue
        if repeatType != .none && hasRepeatEnd {
            item.repeatEndDate = repeatEndDate
        }
        
        // 独立提醒
        item.reminderEnabled = reminderEnabled
        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: reminderTime)
        item.reminderHour = comps.hour ?? 9
        item.reminderMinute = comps.minute ?? 0
        
        // 子任务
        for st in subTaskTexts {
            let t = st.trimmingCharacters(in: .whitespaces)
            guard !t.isEmpty else { continue }
            let sub = SubTask(title: t, sortOrder: item.subTasks.count)
            sub.parentItem = item
            item.subTasks.append(sub)
        }
        
        modelContext.insert(item)
        
        Task { @MainActor in
            NotificationManager.shared.scheduleNotification(for: item)
        }
        
        dismiss()
    }
}

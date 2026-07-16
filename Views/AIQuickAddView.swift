import SwiftUI
import SwiftData

/// AI Quick Add — 自然语言创建任务
struct AIQuickAddView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var inputText = ""
    @State private var parsed: ParsedTask?
    @State private var hasParsed = false
    
    @Query(sort: \TodoList.sortOrder) private var lists: [TodoList]
    @State private var selectedList: TodoList?
    
    private let examples = [
        "明天下午3点开会",
        "周五晚上提醒我交作业",
        "每天早上8点提醒吃药",
        "下周一上午重要事项准备报告 需要2小时",
        "后天买牛奶",
        "每天晚上10点轻松整理文件",
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 输入区
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "sparkle.magnifyingglass")
                            .font(.title2)
                            .foregroundStyle(.blue)
                        Text("AI 快速创建")
                            .font(.headline)
                        Spacer()
                    }
                    
                    TextField("用自然语言描述任务...", text: $inputText, axis: .vertical)
                        .font(.body)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .lineLimit(3...6)
                    
                    Button(action: parse) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                            Text("智能解析")
                        }
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(inputText.trimmingCharacters(in: .whitespaces).isEmpty
                            ? Color.blue.opacity(0.3) : Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()
                
                // 解析结果预览
                if hasParsed, let parsed {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("解析结果", systemImage: "doc.text.magnifyingglass")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            Text(parsed.preview)
                                .font(.subheadline)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.blue.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        // 清单选择
                        if !lists.isEmpty {
                            Picker("保存到", selection: $selectedList) {
                                Text("默认清单").tag(nil as TodoList?)
                                ForEach(lists) { list in
                                    HStack {
                                        Image(systemName: list.icon)
                                        Text(list.name)
                                    }
                                    .tag(list as TodoList?)
                                }
                            }
                            .pickerStyle(.menu)
                            .font(.subheadline)
                        }
                        
                        // 保存按钮
                        Button(action: save) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                Text("保存任务")
                            }
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // 示例
                if !hasParsed {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("试试这样输入", systemImage: "lightbulb")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        
                        ForEach(examples, id: \.self) { ex in
                            Button(action: { inputText = ex }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.turn.right.small")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                    Text(ex)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                }
                                .padding(8)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle("AI 创建")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: hasParsed)
        }
        .presentationDetents([.medium, .large])
    }
    
    private func parse() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        parsed = NLParser.parse(text)
        hasParsed = true
    }
    
    private func save() {
        guard let parsed else { return }
        let item = TodoItem(
            title: parsed.title,
            notes: parsed.notes,
            list: selectedList,
            dueDate: parsed.dueDate,
            hasTime: parsed.hasTime
        )
        item.priority = parsed.priority.rawValue
        item.isImportant = parsed.isImportant
        item.estimatedMinutes = parsed.estimatedMinutes
        item.energyLevel = parsed.energyLevel.rawValue
        item.repeatType = parsed.repeatType.rawValue
        item.reminderEnabled = parsed.reminderEnabled
        item.reminderHour = parsed.reminderHour
        item.reminderMinute = parsed.reminderMinute
        
        modelContext.insert(item)
        
        Task { @MainActor in
            NotificationManager.shared.scheduleNotification(for: item)
        }
        
        dismiss()
    }
}

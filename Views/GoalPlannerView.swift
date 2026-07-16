import SwiftUI
import SwiftData

/// 目标规划师 — 输入目标，AI 自动拆分每日任务
struct GoalPlannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var goalText = ""
    @State private var category: PlanCategory = .study
    @State private var days: Int = 30
    
    @State private var plan: [PlannedTask] = []
    @State private var hasGenerated = false
    @State private var savedCount = 0
    
    @State private var showingSavedAlert = false
    
    private let dayOptions = [7, 14, 21, 30, 45, 60, 90]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 输入区
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .font(.title2)
                                .foregroundStyle(.purple)
                            Text("目标规划师")
                                .font(.headline)
                            Spacer()
                        }
                        
                        TextField("输入你的目标...\n例如：30天学会SwiftUI", text: $goalText, axis: .vertical)
                            .font(.body)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .lineLimit(3...5)
                        
                        HStack(spacing: 12) {
                            // 类别
                            Picker("类别", selection: $category) {
                                ForEach(PlanCategory.allCases, id: \.self) { c in
                                    Text(c.rawValue).tag(c)
                                }
                            }
                            .pickerStyle(.menu)
                            .font(.subheadline)
                            
                            // 天数
                            Picker("天数", selection: $days) {
                                ForEach(dayOptions, id: \.self) { d in
                                    Text("\(d)天").tag(d)
                                }
                            }
                            .pickerStyle(.menu)
                            .font(.subheadline)
                        }
                        
                        Button(action: generatePlan) {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                Text("生成计划")
                            }
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(goalText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color.purple.opacity(0.3) : Color.purple)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .disabled(goalText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal)
                    
                    if hasGenerated {
                        Divider()
                        
                        // 计划概览
                        VStack(spacing: 8) {
                            HStack {
                                Label("计划概览", systemImage: "list.clipboard")
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text("共 \(plan.count) 天")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            // 阶段摘要卡片
                            if !plan.isEmpty {
                                let weeks = (plan.count + 6) / 7
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: min(weeks, 5)), spacing: 6) {
                                    ForEach(0..<weeks, id: \.self) { w in
                                        let start = w * 7
                                        let end = min(start + 7, plan.count)
                                        VStack(spacing: 2) {
                                            Text("第\(w+1)周")
                                                .font(.caption2.weight(.semibold))
                                            Text("第\(start+1)-\(end)天")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                            Text("\(end - start)项")
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }
                                        .padding(8)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.purple.opacity(0.06))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                            
                            // 前几项预览
                            VStack(alignment: .leading, spacing: 4) {
                                Text("预览（前10项）")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                ForEach(Array(plan.prefix(10))) { task in
                                    HStack(spacing: 8) {
                                        Image(systemName: "\(task.dayOffset + 1).circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(.purple)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(task.title)
                                                .font(.subheadline)
                                            Text(task.notes)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                        if task.priority != .none {
                                            Text(task.priority.rawValue)
                                                .font(.caption2)
                                        }
                                    }
                                    .padding(6)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                if plan.count > 10 {
                                    Text("...还有 \(plan.count - 10) 项")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            // 保存按钮
                            Button(action: saveAll) {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.and.arrow.down")
                                    Text(savedCount > 0 ? "已保存 \(savedCount) 项" : "一键保存全部 \(plan.count) 项")
                                }
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(savedCount > 0 ? Color.green : Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .disabled(plan.isEmpty || savedCount > 0)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("目标规划")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: hasGenerated)
            .alert("计划已保存 ✅", isPresented: $showingSavedAlert) {
                Button("好的") { dismiss() }
            } message: {
                Text("已创建 \(savedCount) 个任务，按日期排列在待办事项中")
            }
        }
        .presentationDetents([.large])
    }
    
    private func generatePlan() {
        let text = goalText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        plan = PlanGenerator.generatePlan(goal: text, category: category, days: days)
        hasGenerated = true
        savedCount = 0
    }
    
    private func saveAll() {
        guard !plan.isEmpty else { return }
        let calendar = Calendar.current
        
        for task in plan {
            let date = calendar.startOfDay(for: task.dueDate)
            let item = TodoItem(
                title: task.title,
                notes: task.notes,
                dueDate: date,
                hasTime: false
            )
            item.priority = task.priority.rawValue
            item.estimatedMinutes = task.estimatedMinutes
            item.energyLevel = task.energyLevel.rawValue
            modelContext.insert(item)
        }
        
        savedCount = plan.count
        showingSavedAlert = true
    }
}

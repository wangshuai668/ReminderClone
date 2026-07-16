import Foundation

// MARK: - 计划模板生成器
final class PlanGenerator {
    
    /// 根据目标和天数生成任务列表
    static func generatePlan(goal: String, category: PlanCategory, days: Int) -> [PlannedTask] {
        let goalLower = goal.lowercased()
        
        // 尝试匹配已知目标
        if goalLower.contains("swiftui") || goalLower.contains("swift") && goalLower.contains("ios") {
            return swiftUIPlan(days: days)
        }
        if goalLower.contains("python") {
            return pythonPlan(days: days)
        }
        if goalLower.contains("健身") || goalLower.contains("减肥") || goalLower.contains("锻炼") {
            return fitnessPlan(days: days)
        }
        if goalLower.contains("英语") || goalLower.contains("英文") {
            return englishPlan(days: days)
        }
        if goalLower.contains("阅读") || goalLower.contains("读书") {
            return readingPlan(days: days, goal: goal)
        }
        
        // 按类别生成通用计划
        switch category {
        case .study: return genericStudyPlan(days: days, goal: goal)
        case .work: return genericWorkPlan(days: days, goal: goal)
        case .fitness: return fitnessPlan(days: days)
        case .custom: return customPlan(days: days, goal: goal)
        }
    }
    
    // MARK: - 学习 SwiftUI (30天版)
    static func swiftUIPlan(days: Int) -> [PlannedTask] {
        let fullPlan: [(String, String, EnergyLevel)] = [
            ("第1天: SwiftUI 初探", "学习 View 协议、@main 入口、预览机制", .high),
            ("第2天: Text 与 Image", "掌握 Text 样式、Image 加载、SF Symbols", .high),
            ("第3天: Stack 布局", "HStack/VStack/ZStack、alignment、spacing", .high),
            ("第4天: List 与 ScrollView", "动态列表、Section、下拉刷新", .high),
            ("第5天: @State 与绑定", "状态管理基础、$binding、双向绑定", .high),
            ("第6天: Button 与 交互", "Button 样式、Toggle、Slider、Picker", .medium),
            ("第7天: NavigationStack", "导航栏、NavigationLink、toolbar", .medium),
            ("第8天: Form 与 输入", "Form 表单、TextField、DatePicker", .medium),
            ("第9天: Sheet 与 弹窗", ".sheet、.alert、.confirmationDialog", .medium),
            ("第10天: 动画基础", "withAnimation、.animation、过渡效果", .medium),
            ("第11天: 手势识别", "TapGesture、DragGesture、LongPress", .high),
            ("第12天: @Observable", "iOS 17 可观察对象、@Bindable", .high),
            ("第13天: @Environment", "环境变量、自定义环境值", .medium),
            ("第14天: 数据流总结", "State → Binding → Observable → Environment", .high),
            ("第15天: SwiftData 入门", "@Model、@Query、ModelContainer", .high),
            ("第16天: 增删改查", "modelContext.insert/delete/save", .high),
            ("第17天: @Relationship", "一对多、级联删除、反向关系", .high),
            ("第18天: @Attribute 选项", ".unique、.externalStorage、.transformable", .medium),
            ("第19天: 排序与过滤", "SortDescriptor、Predicate、FetchDescriptor", .high),
            ("第20天: 数据迁移", "Schema 版本、MigrationPlan、轻量迁移", .medium),
            ("第21天: 项目: Todo App 搭建", "清单列表 + 事项 CRUD", .high),
            ("第22天: 项目: 标签与筛选", "多标签系统、搜索功能", .high),
            ("第23天: 项目: 通知集成", "UNUserNotificationCenter、本地通知", .medium),
            ("第24天: 项目: 日历视图", "月视图组件、日志 Calendar", .high),
            ("第25天: 项目: 多主题/深色模式", "colorScheme、自定义主题", .low),
            ("第26天: Widget 开发", "WidgetExtension、TimelineProvider", .high),
            ("第27天: 性能优化", "懒加载、diffing、减少重绘", .medium),
            ("第28天: 测试与调试", "Preview、Xcode 调试工具", .medium),
            ("第29天: 项目收尾", "修 bug、UI 打磨、空状态", .low),
            ("第30天: 总结与发布", "学习笔记整理、App Store 准备", .low),
        ]
        
        return Array(fullPlan.prefix(min(days, fullPlan.count))).enumerated().map { i, item in
            PlannedTask(
                title: item.0,
                notes: item.1,
                dayOffset: i,
                priority: i < 7 ? .high : (i < 14 ? .medium : .none),
                energyLevel: item.2,
                estimatedMinutes: 60
            )
        }
    }
    
    // MARK: - 学习 Python
    static func pythonPlan(days: Int) -> [PlannedTask] {
        let fullPlan: [(String, String)] = [
            ("第1天: Python 环境搭建", "安装 Python、IDE、第一个程序"),
            ("第2天: 变量与类型", "int/float/str/bool、类型转换"),
            ("第3天: 字符串操作", "切片、格式化、常用方法"),
            ("第4天: 列表与元组", "CRUD、解包、列表推导式"),
            ("第5天: 字典与集合", "键值操作、去重、交集并集"),
            ("第6天: 条件判断", "if/elif/else、逻辑运算符"),
            ("第7天: 循环", "for/while、break/continue、enumerate"),
            ("第8天: 函数", "定义、参数、返回值、lambda"),
            ("第9天: 文件操作", "open/read/write、with 语句"),
            ("第10天: 异常处理", "try/except/finally、自定义异常"),
            ("第11天: 模块与包", "import、pip、虚拟环境"),
            ("第12天: 面向对象", "类、继承、魔法方法"),
            ("第13天: 装饰器与生成器", "@语法、yield、迭代器"),
            ("第14天: 常用标准库", "datetime/os/json/re/collections"),
            ("第15天: 网络请求", "requests、API 调用、JSON 解析"),
            ("第16天: Web 框架入门", "Flask 路由、模板、REST API"),
            ("第17天: 数据库", "SQLite、SQLAlchemy ORM"),
            ("第18天: 数据分析", "pandas 入门、Series/DataFrame"),
            ("第19天: 数据可视化", "matplotlib、基本图表"),
            ("第20天: 自动化脚本", "os/shutil/subprocess、批量处理"),
            ("第21-25天: 项目实战", "选一个项目: Web/数据分析/爬虫/CLI工具"),
            ("第26-28天: 测试与部署", "unittest/pytest、打包发布"),
            ("第29-30天: 总结", "知识图谱、下一步方向"),
        ]
        return Array(fullPlan.prefix(min(days, fullPlan.count))).enumerated().map { i, item in
            PlannedTask(title: item.0, notes: item.1, dayOffset: i, priority: i < 5 ? .high : .medium, energyLevel: i < 10 ? .high : .medium, estimatedMinutes: 45)
        }
    }
    
    // MARK: - 健身计划
    static func fitnessPlan(days: Int) -> [PlannedTask] {
        let weeks = days / 7
        let remainder = days % 7
        var plan: [PlannedTask] = []
        let routines: [(String, String, EnergyLevel)] = [
            ("🏋️ 力量训练 - 胸肌", "杠铃卧推 4x8、哑铃飞鸟 3x12、俯卧撑 3x力竭", .high),
            ("🏃 有氧训练", "慢跑 30min 或 HIIT 20min", .high),
            ("💪 力量训练 - 背部", "引体向上 4x8、杠铃划船 4x10、坐姿划船 3x12", .high),
            ("🧘 休息/拉伸", "全身拉伸 20min、泡沫轴放松", .low),
            ("🏋️ 力量训练 - 肩部", "哑铃推举 4x10、侧平举 4x12、面拉 3x15", .high),
            ("🦵 力量训练 - 腿部", "深蹲 4x8、硬拉 4x8、腿举 3x12", .high),
            ("💪 力量训练 - 手臂", "二头弯举 4x12、三头下压 4x12、锤式弯举 3x12", .medium),
        ]
        for w in 0..<weeks {
            for (i, r) in routines.enumerated() {
                plan.append(PlannedTask(
                    title: "第\(w * 7 + i + 1)天: \(r.0)",
                    notes: r.1,
                    dayOffset: w * 7 + i,
                    priority: .high,
                    energyLevel: r.2,
                    estimatedMinutes: 45
                ))
            }
        }
        for i in 0..<remainder {
            let r = routines[i % routines.count]
            plan.append(PlannedTask(
                title: "第\(weeks * 7 + i + 1)天: \(r.0)",
                notes: r.1,
                dayOffset: weeks * 7 + i,
                priority: .medium,
                energyLevel: r.2,
                estimatedMinutes: 45
            ))
        }
        return plan
    }
    
    // MARK: - 英语学习
    static func englishPlan(days: Int) -> [PlannedTask] {
        return (0..<days).map { i in
            let week = i / 7
            let day = i % 7
            let topics = ["单词 30个", "听力 15min", "阅读 1篇", "口语练习", "语法学习", "写作练习", "复习总结"]
            let topic = topics[day % topics.count]
            return PlannedTask(
                title: "第\(i+1)天: 英语 \(topic)",
                notes: week == 0 ? "基础阶段：\(topic)" : "进阶阶段：\(topic)",
                dayOffset: i,
                priority: i < 7 ? .high : .medium,
                energyLevel: day < 3 ? .high : .medium,
                estimatedMinutes: 30
            )
        }
    }
    
    // MARK: - 阅读计划
    static func readingPlan(days: Int, goal: String) -> [PlannedTask] {
        let bookName = goal.replacingOccurrences(of: "阅读", with: "")
            .replacingOccurrences(of: "读书", with: "")
            .replacingOccurrences(of: "读", with: "")
            .trimmingCharacters(in: .whitespaces)
        let displayName = bookName.isEmpty ? "本书" : "《\(bookName)》"
        return (0..<days).map { i in
            let pages = Int.random(in: 15...30)
            return PlannedTask(
                title: "阅读 \(displayName) 第\(i+1)天",
                notes: "今日目标：阅读 \(pages) 页，记录要点",
                dayOffset: i,
                priority: .medium,
                energyLevel: i % 2 == 0 ? .high : .low,
                estimatedMinutes: pages * 2
            )
        }
    }
    
    // MARK: - 通用学习计划
    static func genericStudyPlan(days: Int, goal: String) -> [PlannedTask] {
        let short = goal.count > 20 ? String(goal.prefix(20)) + "..." : goal
        return (0..<days).map { i in
            let phase = i < days/4 ? "基础入门" : (i < days/2 ? "核心进阶" : (i < days*3/4 ? "实践应用" : "总结复盘"))
            return PlannedTask(
                title: "\(short) · 第\(i+1)天",
                notes: "阶段：\(phase)\n学习目标：完成当日学习任务，记录笔记",
                dayOffset: i,
                priority: i < 7 ? .high : .medium,
                energyLevel: .high,
                estimatedMinutes: 45
            )
        }
    }
    
    // MARK: - 通用工作计划
    static func genericWorkPlan(days: Int, goal: String) -> [PlannedTask] {
        let short = goal.count > 20 ? String(goal.prefix(20)) + "..." : goal
        return (0..<days).map { i in
            let phase = i < days/4 ? "需求分析" : (i < days/2 ? "方案设计" : (i < days*3/4 ? "执行开发" : "测试上线"))
            return PlannedTask(
                title: "\(short) · 第\(i+1)天",
                notes: "阶段：\(phase)\n今日任务：推进项目进度，记录完成情况",
                dayOffset: i,
                priority: i < 7 ? .high : .medium,
                energyLevel: i % 3 == 0 ? .high : .low,
                estimatedMinutes: 120
            )
        }
    }
    
    // MARK: - 自定义计划
    static func customPlan(days: Int, goal: String) -> [PlannedTask] {
        return (0..<days).map { i in
            PlannedTask(
                title: "\(goal) · Day \(i+1)",
                notes: "自定义目标",
                dayOffset: i,
                priority: .medium,
                energyLevel: .any,
                estimatedMinutes: 30
            )
        }
    }
}

// MARK: - 数据类型

enum PlanCategory: String, Codable, CaseIterable {
    case study = "📚 学习"
    case work = "💼 工作"
    case fitness = "💪 健身"
    case custom = "✨ 自定义"
}

struct PlannedTask: Identifiable {
    let id = UUID()
    let title: String
    let notes: String
    let dayOffset: Int
    let priority: Priority
    let energyLevel: EnergyLevel
    let estimatedMinutes: Int
    
    /// 起始日期的计算
    var dueDate: Date {
        Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
    }
}

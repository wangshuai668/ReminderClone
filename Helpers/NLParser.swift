import Foundation

// MARK: - 解析结果
struct ParsedTask {
    var title: String
    var notes: String
    var dueDate: Date?
    var hasTime: Bool
    var priority: Priority
    var isImportant: Bool
    var reminderEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var repeatType: RepeatType
    var estimatedMinutes: Int
    var energyLevel: EnergyLevel
    
    init(title: String) {
        self.title = title
        self.notes = ""
        self.dueDate = nil
        self.hasTime = false
        self.priority = .none
        self.isImportant = false
        self.reminderEnabled = false
        self.reminderHour = 9
        self.reminderMinute = 0
        self.repeatType = .none
        self.estimatedMinutes = 0
        self.energyLevel = .any
    }
}

// MARK: - 自然语言解析器
final class NLParser {
    
    /// 从自然语言解析任务
    /// "周五下午帮我提醒提交论文"
    /// → {title:"提交论文", date:周五15:00, reminder:true}
    static func parse(_ input: String) -> ParsedTask {
        var text = input.trimmingCharacters(in: .whitespaces)
        
        // 移除引导词
        text = removePrefix(text)
        
        let parsed = ParsedTask(title: text)
        
        // 逐步解析各个字段
        var result = parsed
        result = parseDateAndTime(&text, result: result)
        result = parsePriority(&text, result: result)
        result = parseReminder(&text, result: result)
        result = parseRepeat(&text, result: result)
        result = parseEnergy(&text, result: result)
        result = parseDuration(&text, result: result)
        result.title = cleanTitle(text)
        
        return result
    }
    
    // MARK: - 移除引导词
    
    private static func removePrefix(_ text: String) -> String {
        var t = text
        let prefixes = ["帮我", "请帮我", "帮我提醒", "帮我记", "提醒我", "记得", "我要", "我想"]
        for p in prefixes {
            if t.hasPrefix(p) {
                t = String(t.dropFirst(p.count)).trimmingCharacters(in: .whitespaces)
                break
            }
        }
        return t
    }
    
    // MARK: - 解析日期时间
    
    private static func parseDateAndTime(_ text: inout String, result: ParsedTask) -> ParsedTask {
        var r = result
        let calendar = Calendar.current
        let now = Date()
        
        // 尝试匹配日期
        if let (date, hasTime, matched) = extractDateTime(from: text) {
            r.dueDate = date
            r.hasTime = hasTime
            text = text.replacingOccurrences(of: matched, with: "").trimmingCharacters(in: .whitespaces)
        }
        
        // 提取时间关键词设置提醒默认时间
        if r.hasTime, let date = r.dueDate {
            // hasTime 已经在 extractDateTime 中设置了
        }
        
        return r
    }
    
    private static func extractDateTime(from text: String) -> (date: Date, hasTime: Bool, matched: String)? {
        let calendar = Calendar.current
        let now = Date()
        
        // 1. 具体日期 + 时间: "7月16日 下午3点"
        if let result = matchExactDateTime(text, calendar: calendar, now: now) {
            return result
        }
        
        // 2. 相对日期 + 时间: "明天下午3点"
        if let result = matchRelativeDateTime(text, calendar: calendar, now: now) {
            return result
        }
        
        // 3. 只有日期: "周五"
        if let result = matchDateOnly(text, calendar: calendar, now: now) {
            return result
        }
        
        // 4. 只有时间: "下午3点"
        if let result = matchTimeOnly(text, calendar: calendar, now: now) {
            return result
        }
        
        return nil
    }
    
    // 匹配 "X月X日 [周X] [上/下]午X点[X分]"
    private static func matchExactDateTime(_ text: String, calendar: Calendar, now: Date) -> (Date, Bool, String)? {
        let pattern = #"(今|明|后|大后|(\d+)月(\d+)日)?\s*(周[一二三四五六日]|星期[一二三四五六日])?\s*((早上|早晨|上午|中午|下午|晚上|半夜)?\s*(\d+)\s*点\s*(\d+)?\s*分?)?\s*"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return nil
        }
        
        let fullMatch = (text as NSString).substring(with: match.range)
        guard !fullMatch.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        
        var date: Date?
        var hour = 9, minute = 0
        var hasTime = false
        var dayOffset = 0
        
        // 日期部分
        let nsText = text as NSString
        let dayWord = match.range(at: 1).location != NSNotFound ? nsText.substring(with: match.range(at: 1)) : ""
        let monthStr = match.range(at: 2).location != NSNotFound ? nsText.substring(with: match.range(at: 2)) : ""
        let dayStr = match.range(at: 3).location != NSNotFound ? nsText.substring(with: match.range(at: 3)) : ""
        
        if !dayWord.isEmpty {
            switch dayWord {
            case "今": dayOffset = 0
            case "明": dayOffset = 1
            case "后": dayOffset = 2
            case "大后": dayOffset = 3
            default:
                if let m = Int(monthStr), let d = Int(dayStr) {
                    var comps = calendar.dateComponents([.year, .month, .day], from: now)
                    comps.month = m
                    comps.day = d
                    date = calendar.date(from: comps)
                    // 如果已经过了，明年
                    if let d = date, d < now {
                        comps.year = (comps.year ?? 2026) + 1
                        date = calendar.date(from: comps)
                    }
                }
            }
        }
        
        // 周X
        let weekStr = match.range(at: 4).location != NSNotFound ? nsText.substring(with: match.range(at: 4)) : ""
        if !weekStr.isEmpty {
            let targetWeekday = chineseWeekdayToNumber(weekStr)
            if date == nil {
                date = nextWeekday(targetWeekday, from: now, offset: dayOffset > 0 ? dayOffset - 1 : 0)
            }
        }
        
        if dayOffset > 0 && date == nil {
            date = calendar.date(byAdding: .day, value: dayOffset, to: now)
        }
        if date == nil {
            date = now
        }
        
        // 时间部分
        let periodStr = match.range(at: 6).location != NSNotFound ? nsText.substring(with: match.range(at: 6)) : ""
        let hourStr = match.range(at: 7).location != NSNotFound ? nsText.substring(with: match.range(at: 7)) : ""
        let minStr = match.range(at: 8).location != NSNotFound ? nsText.substring(with: match.range(at: 8)) : ""
        
        if !hourStr.isEmpty {
            hasTime = true
            hour = Int(hourStr) ?? 9
            minute = Int(minStr) ?? 0
            hour = adjustHourByPeriod(periodStr, hour: hour)
        }
        
        if let d = date, hasTime {
            var comps = calendar.dateComponents([.year, .month, .day], from: d)
            comps.hour = hour
            comps.minute = minute
            if let finalDate = calendar.date(from: comps) {
                return (finalDate, true, fullMatch)
            }
        } else if let d = date {
            return (d, false, fullMatch)
        }
        
        return nil
    }
    
    // 匹配 "明天下午3点" 这种
    private static func matchRelativeDateTime(_ text: String, calendar: Calendar, now: Date) -> (Date, Bool, String)? {
        // 用 matchExactDateTime 已经处理了，这个作为备选
        return nil
    }
    
    // 只匹配日期 "周五" "下周一"
    private static func matchDateOnly(_ text: String, calendar: Calendar, now: Date) -> (Date, Bool, String)? {
        let pattern = #"(今|明|后|大后|(下|这|本)?(周[一二三四五六日]|星期[一二三四五六日]))\s*"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return nil
        }
        
        let matched = (text as NSString).substring(with: match.range)
        guard !matched.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        
        let nsText = text as NSString
        let dayWord = match.range(at: 1).location != NSNotFound ? nsText.substring(with: match.range(at: 1)) : ""
        
        if !dayWord.isEmpty {
            switch dayWord {
            case "今": return (now, false, matched)
            case "明": return (calendar.date(byAdding: .day, value: 1, to: now)!, false, matched)
            case "后": return (calendar.date(byAdding: .day, value: 2, to: now)!, false, matched)
            case "大后": return (calendar.date(byAdding: .day, value: 3, to: now)!, false, matched)
            default:
                let weekStr = nsText.substring(with: match.range(at: 2))
                let prefix = match.range(at: 3).location != NSNotFound ? nsText.substring(with: match.range(at: 3)) : ""
                let weekday = chineseWeekdayToNumber(weekStr)
                let offset = prefix == "下" ? 7 : 0
                if let d = nextWeekday(weekday, from: now, offset: offset) {
                    return (d, false, matched)
                }
            }
        }
        
        return nil
    }
    
    // 只匹配时间 "下午3点" "晚上10点半"
    private static func matchTimeOnly(_ text: String, calendar: Calendar, now: Date) -> (Date, Bool, String)? {
        let pattern = #"((早上|早晨|上午|中午|下午|晚上|半夜)?\s*(\d+)\s*点\s*(\d+)?\s*分?)\s*"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return nil
        }
        
        let matched = (text as NSString).substring(with: match.range)
        let nsText = text as NSString
        let periodStr = match.range(at: 2).location != NSNotFound ? nsText.substring(with: match.range(at: 2)) : ""
        let hourStr = match.range(at: 3).location != NSNotFound ? nsText.substring(with: match.range(at: 3)) : ""
        let minStr = match.range(at: 4).location != NSNotFound ? nsText.substring(with: match.range(at: 4)) : ""
        
        guard !hourStr.isEmpty else { return nil }
        
        let hour = adjustHourByPeriod(periodStr, hour: Int(hourStr) ?? 9)
        let minute = Int(minStr) ?? 0
        
        var comps = calendar.dateComponents([.year, .month, .day], from: now)
        comps.hour = hour
        comps.minute = minute
        
        if let date = calendar.date(from: comps) {
            // 如果时间已过，推到明天
            if date <= now {
                if let next = calendar.date(byAdding: .day, value: 1, to: date) {
                    return (next, true, matched)
                }
            }
            return (date, true, matched)
        }
        
        return nil
    }
    
    // MARK: - 解析优先级
    
    private static func parsePriority(_ text: inout String, result: ParsedTask) -> ParsedTask {
        var r = result
        let highWords = ["重要", "紧急", "加急", "必须", "立刻", "马上", "优先"]
        for w in highWords {
            if text.contains(w) {
                r.priority = .high
                r.isImportant = true
                text = text.replacingOccurrences(of: w, with: "").trimmingCharacters(in: .whitespaces)
                break
            }
        }
        return r
    }
    
    // MARK: - 解析提醒
    
    private static func parseReminder(_ text: inout String, result: ParsedTask) -> ParsedTask {
        var r = result
        let reminderWords = ["提醒", "记得", "提醒我", "通知", "闹钟"]
        for w in reminderWords {
            if text.contains(w) {
                r.reminderEnabled = true
                // 如果有时间，用那个时间；否则默认早上9点
                if let date = r.dueDate {
                    let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                    r.reminderHour = comps.hour ?? 9
                    r.reminderMinute = comps.minute ?? 0
                }
                text = text.replacingOccurrences(of: w, with: "").trimmingCharacters(in: .whitespaces)
                break
            }
        }
        return r
    }
    
    // MARK: - 解析重复
    
    private static func parseRepeat(_ text: inout String, result: ParsedTask) -> ParsedTask {
        var r = result
        let patterns: [(String, RepeatType)] = [
            ("每天|每日|天天", .daily),
            ("每周|每星期", .weekly),
            ("每月|每个月", .monthly),
        ]
        for (pattern, type) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
                r.repeatType = type
                r.reminderEnabled = true
                let matched = (text as NSString).substring(with: match.range)
                text = text.replacingOccurrences(of: matched, with: "").trimmingCharacters(in: .whitespaces)
                break
            }
        }
        return r
    }
    
    // MARK: - 解析能量等级
    
    private static func parseEnergy(_ text: inout String, result: ParsedTask) -> ParsedTask {
        var r = result
        let highWords = ["费脑", "专注", "复杂", "烧脑", "深度"]
        let lowWords = ["轻松", "简单", "随手", "杂事", "例行"]
        
        for w in highWords {
            if text.contains(w) {
                r.energyLevel = .high
                text = text.replacingOccurrences(of: w, with: "").trimmingCharacters(in: .whitespaces)
                break
            }
        }
        
        if r.energyLevel == .any {
            for w in lowWords {
                if text.contains(w) {
                    r.energyLevel = .low
                    text = text.replacingOccurrences(of: w, with: "").trimmingCharacters(in: .whitespaces)
                    break
                }
            }
        }
        
        return r
    }
    
    // MARK: - 解析预计耗时
    
    private static func parseDuration(_ text: inout String, result: ParsedTask) -> ParsedTask {
        var r = result
        let pattern = #"需要?(\d+)\s*(小时|分钟|h|min)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return r
        }
        
        let nsText = text as NSString
        let numStr = nsText.substring(with: match.range(at: 1))
        let unit = nsText.substring(with: match.range(at: 2))
        let matched = nsText.substring(with: match.range)
        
        if let num = Int(numStr) {
            switch unit {
            case "小时", "h": r.estimatedMinutes = num * 60
            case "分钟", "min": r.estimatedMinutes = num
            default: break
            }
        }
        
        text = text.replacingOccurrences(of: matched, with: "").trimmingCharacters(in: .whitespaces)
        return r
    }
    
    // MARK: - 工具方法
    
    private static func cleanTitle(_ text: String) -> String {
        // 移除残留的空格、标点
        var t = text.trimmingCharacters(in: .whitespaces)
        // 移除 "的" 结尾
        if t.hasSuffix("的") { t = String(t.dropLast()) }
        // 移除多余的标点
        t = t.trimmingCharacters(in: CharacterSet(charactersIn: "，。！？,.!?；;：:"))
        return t.trimmingCharacters(in: .whitespaces)
    }
    
    private static func chineseWeekdayToNumber(_ s: String) -> Int {
        let map: [String: Int] = [
            "星期一": 2, "周二": 3, "星期三": 4,
            "星期四": 5, "星期五": 6, "星期六": 7, "星期日": 1, "星期天": 1,
            "周一": 2, "周二": 3, "周三": 4,
            "周四": 5, "周五": 6, "周六": 7, "周日": 1, "周天": 1,
        ]
        for (k, v) in map {
            if s.contains(k) { return v }
        }
        return 2
    }
    
    private static func nextWeekday(_ target: Int, from date: Date, offset: Int = 0) -> Date? {
        let calendar = Calendar.current
        let todayWeekday = calendar.component(.weekday, from: date)
        var daysToAdd = target - todayWeekday
        if daysToAdd <= 0 { daysToAdd += 7 }
        daysToAdd += offset
        return calendar.date(byAdding: .day, value: daysToAdd, to: date)
    }
    
    private static func adjustHourByPeriod(_ period: String, hour: Int) -> Int {
        switch period {
        case "早上", "早晨": return hour < 6 ? hour + 6 : min(hour, 8)
        case "上午": return hour < 8 ? hour + 8 : min(hour, 11)
        case "中午": return max(11, min(hour, 13))
        case "下午": return hour <= 12 ? hour + 12 : min(hour, 18)
        case "晚上": return hour < 6 ? hour + 18 : max(18, min(hour, 23))
        case "半夜": return max(0, min(hour, 5))
        default: return hour
        }
    }
}

// MARK: - 解析结果预览文本
extension ParsedTask {
    var preview: String {
        var parts: [String] = []
        parts.append("📝 \(title)")
        if let d = dueDate {
            let fmt = hasTime ? "MM/dd HH:mm" : "MM/dd"
            let df = DateFormatter()
            df.dateFormat = fmt
            parts.append("📅 \(df.string(from: d))")
        }
        if priority != .none {
            parts.append(priority.rawValue)
        }
        if reminderEnabled {
            parts.append("🔔 \(String(format: "%02d:%02d", reminderHour, reminderMinute))")
        }
        if repeatType != .none {
            parts.append("🔄 \(repeatType.rawValue)")
        }
        if estimatedMinutes > 0 {
            let h = estimatedMinutes / 60
            let m = estimatedMinutes % 60
            parts.append(m > 0 ? "⏱ \(h)h\(m)m" : "⏱ \(h)h")
        }
        if energyLevel != .any {
            parts.append(energyLevel.rawValue)
        }
        return parts.joined(separator: " · ")
    }
}

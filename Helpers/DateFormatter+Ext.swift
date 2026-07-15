import Foundation

extension DateFormatter {
    static let relativeDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        f.doesRelativeDateFormatting = true
        return f
    }()
    
    static let timeOnly: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()
}

extension Calendar {
    /// 开始和结束日的日期区间
    func dayRange(for date: Date) -> (start: Date, end: Date) {
        let start = startOfDay(for: date)
        let end = self.date(byAdding: .day, value: 1, to: start)!
        return (start, end)
    }
}

import SwiftUI
import SwiftData

/// 清单卡片组件 — 首页每个清单的预览卡片
struct ListCardView: View {
    let list: TodoList
    
    var body: some View {
        HStack(spacing: 16) {
            // 左侧图标
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: list.colorHex).opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: list.icon)
                    .font(.title3)
                    .foregroundStyle(Color(hex: list.colorHex))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(list.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    // 未完成计数
                    if list.incompleteCount > 0 {
                        Text("\(list.incompleteCount)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.secondary.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                
                // 预览最近事项
                if let latest = list.latestIncompleteItem {
                    Text(latest.title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else if list.items.isEmpty {
                    Text("暂无事项")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                } else {
                    Text("全部已完成 🎉")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }
}

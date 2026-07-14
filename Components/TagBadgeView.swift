import SwiftUI

/// 标签徽章组件
struct TagBadgeView: View {
    let tag: Tag
    var compact: Bool = false
    
    var body: some View {
        if compact {
            Circle()
                .fill(Color(hex: tag.colorHex))
                .frame(width: 8, height: 8)
        } else {
            Text(tag.name)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(Color(hex: tag.colorHex))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(hex: tag.colorHex).opacity(0.15))
                .clipShape(Capsule())
        }
    }
}

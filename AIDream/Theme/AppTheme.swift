import SwiftUI

// MARK: - HypeCut 设计系统：深紫黑 + 紫色强调
struct AppTheme {

    // MARK: 背景色系 (Backgrounds)
    static let bgPrimary    = Color(hex: "#0C0C0C") // 主背景深黑
    static let bgSecondary  = Color(hex: "#161418") // 深紫黑
    static let bgCard       = Color(hex: "#23252B") // 卡片背景
    static let bgSurface    = Color(hex: "#2A2633") // 浮层
    static let bgInput      = Color.white.opacity(0.04)
    static let bgButtonSec  = Color.white.opacity(0.08)

    // MARK: 核心强调色 (Accents - 紫色系)
    static let accentPrimary   = Color(hex: "#6F31D5") // 主紫色
    static let accentSecondary = Color(hex: "#A07BFF") // 淡紫辅助
    static let accentTertiary  = Color(hex: "#DBD7FF") // 超浅紫（标签/徽章）
    static let accentGlow      = Color(hex: "#6F31D5").opacity(0.4)

    // 渐变色
    static var accentGrad: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#6F31D5"), Color(hex: "#A07BFF")],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    static var accentGradH: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#6F31D5"), Color(hex: "#A07BFF")],
            startPoint: .leading, endPoint: .trailing
        )
    }

    static var accentGradV: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#6F31D5"), Color(hex: "#A07BFF")],
            startPoint: .top, endPoint: .bottom
        )
    }

    // MARK: 文本色系 (Text)
    static let textPrimary   = Color.white
    static let textSecondary = Color(hex: "#858094") // 灰紫辅助文本
    static let textMuted     = Color(hex: "#999999") // 淡灰提示文本

    // MARK: 边框 (Borders)
    static let borderSubtle  = Color(hex: "#333333") // 分割线
    static let borderAccent  = Color(hex: "#6F31D5").opacity(0.5)

    // MARK: 语义色 (Semantic)
    static let error         = Color(hex: "#F64646")
    static let success       = Color(hex: "#4CD890")

    // MARK: VIP/SVIP 特殊色
    static let vipGold       = Color(hex: "#C8A768")
    static let vipBg         = Color(hex: "#2E1C02")
    static let svipPurple    = Color(hex: "#A07BFF")
    static let svipBg        = Color(hex: "#1A1529")
}

// MARK: - 通用视图修饰符
extension View {
    func primaryBorder(cornerRadius: CGFloat = 16, active: Bool = true) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    active ? AnyShapeStyle(AppTheme.accentGrad) : AnyShapeStyle(LinearGradient(colors: [AppTheme.borderSubtle], startPoint: .top, endPoint: .bottom)),
                    lineWidth: active ? 1.5 : 0.8
                )
        )
    }

    func glassStyle(cornerRadius: CGFloat = 20) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.white.opacity(0.05))
                .blur(radius: 0.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
    }

    /// HypeCut 风格卡片：深色半透明 + 紫色细边框
    func cardStyle(cornerRadius: CGFloat = 18) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppTheme.bgCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AppTheme.borderSubtle, lineWidth: 0.5)
            )
    }
}

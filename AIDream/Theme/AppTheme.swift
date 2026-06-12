import SwiftUI

// MARK: - 新版：深邃宇宙与极光设计系统
struct AppTheme {

    // MARK: 背景色系 (Backgrounds)
    static let bgPrimary    = Color(hex: "#050505") // 纯黑背景
    static let bgSecondary  = Color(hex: "#0E1016") // 深蓝黑
    static let bgCard       = Color(hex: "#1A1D26") // 卡片背景
    static let bgSurface    = Color(hex: "#242835") // 浮层
    static let bgInput      = Color.white.opacity(0.04)
    static let bgButtonSec  = Color.white.opacity(0.08)

    // MARK: 核心强调色 (Accents - 极光蓝青色)
    static let accentPrimary = Color(hex: "#4D9FFF") // 极光蓝
    static let accentSecondary = Color(hex: "#00F2FF") // 极光青
    static let accentGlow    = Color(hex: "#4D9FFF").opacity(0.4)

    // 渐变色
    static var accentGrad: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#4D9FFF"), Color(hex: "#00F2FF")],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    static var accentGradH: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#4D9FFF"), Color(hex: "#00F2FF")],
            startPoint: .leading, endPoint: .trailing
        )
    }

    static var accentGradV: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#4D9FFF"), Color(hex: "#00F2FF")],
            startPoint: .top, endPoint: .bottom
        )
    }

    // MARK: 文本色系 (Text)
    static let textPrimary   = Color.white
    static let textSecondary = Color.white.opacity(0.65)
    static let textMuted     = Color.white.opacity(0.35)

    // MARK: 边框 (Borders)
    static let borderSubtle  = Color.white.opacity(0.12)
    static let borderAccent  = Color(hex: "#4D9FFF").opacity(0.5)

    // MARK: 语义色 (Semantic)
    static let error         = Color(hex: "#FF4D4D")
    static let success       = Color(hex: "#00E676")
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
}

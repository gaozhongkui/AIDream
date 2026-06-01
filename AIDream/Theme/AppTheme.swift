import SwiftUI

// MARK: - 黑金科技风主题系统
struct AppTheme {

    // MARK: Backgrounds
    static let bgPrimary    = Color(hex: "#090909")
    static let bgSecondary  = Color(hex: "#10101A")
    static let bgCard       = Color(hex: "#17171F")
    static let bgSurface    = Color(hex: "#1C1C28")
    static let bgInput      = Color.white.opacity(0.05)
    static let bgButtonSec  = Color.white.opacity(0.07)

    // MARK: Gold Accent
    static let goldBright   = Color(hex: "#F6C842")
    static let goldMid      = Color(hex: "#D4A82A")
    static let goldDim      = Color(hex: "#8B6A14")

    static var goldGrad: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#F6C842"), Color(hex: "#C9920A")],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
    static var goldGradH: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#F6C842"), Color(hex: "#C9920A")],
            startPoint: .leading, endPoint: .trailing
        )
    }
    static var goldGradV: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#F6C842"), Color(hex: "#C9920A")],
            startPoint: .top, endPoint: .bottom
        )
    }

    // MARK: Text
    static let textPrimary   = Color.white
    static let textSecondary = Color.white.opacity(0.55)
    static let textMuted     = Color.white.opacity(0.28)

    // MARK: Borders
    static let borderSubtle  = Color(hex: "#28282E")
    static let borderGold    = Color(hex: "#D4A82A").opacity(0.55)

    // MARK: Semantic
    static let error         = Color(hex: "#FF5A5A")
    static let goldGlow      = Color(hex: "#D4A82A").opacity(0.35)
}

// MARK: - View Modifiers
extension View {
    func goldBorder(cornerRadius: CGFloat = 16, active: Bool = true) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    active
                        ? LinearGradient(
                            colors: [Color(hex: "#F6C842"), Color(hex: "#C9920A")],
                            startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(
                            colors: [AppTheme.borderSubtle, AppTheme.borderSubtle],
                            startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: active ? 1.5 : 0.5
                )
        )
    }

    func optionStyle(selected: Bool, cornerRadius: CGFloat = 22) -> some View {
        self
            .background(
                selected
                    ? Color(hex: "#F6C842").opacity(0.1)
                    : AppTheme.bgButtonSec
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .goldBorder(cornerRadius: cornerRadius, active: selected)
    }
}

import SwiftUI

struct DiamondStoreView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var userService = UserService.shared

    // MARK: - 钻石套餐数据
    struct DiamondPackage: Identifiable {
        let id: String
        let diamonds: Int
        let price: String
        let bonus: Int
        let tag: String?
        let gradient: [Color]

        var totalDiamonds: Int { diamonds + bonus }
    }

    private let packages: [DiamondPackage] = [
        DiamondPackage(
            id: "100",
            diamonds: 100,
            price: "$0.99",
            bonus: 0,
            tag: nil,
            gradient: [Color(hex: "#3A3F5C"), Color(hex: "#2A2D40")]
        ),
        DiamondPackage(
            id: "500",
            diamonds: 500,
            price: "$4.99",
            bonus: 50,
            tag: "POPULAR",
            gradient: [Color(hex: "#2D4A7A"), Color(hex: "#1E3460")]
        ),
        DiamondPackage(
            id: "1200",
            diamonds: 1200,
            price: "$9.99",
            bonus: 200,
            tag: "BEST VALUE",
            gradient: [Color(hex: "#4A2D7A"), Color(hex: "#2E1A5E")]
        ),
        DiamondPackage(
            id: "3000",
            diamonds: 3000,
            price: "$19.99",
            bonus: 800,
            tag: "WHALE",
            gradient: [Color(hex: "#7A4A2D"), Color(hex: "#5E2E1A")]
        )
    ]

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    headerView
                        .padding(.top, 10)

                    // 余额展示卡片
                    balanceHeroCard
                        .padding(.top, 24)
                        .padding(.horizontal, 20)

                    // 订阅会员区域
                    subscriptionSection
                        .padding(.top, 28)
                        .padding(.horizontal, 20)

                    // 钻石充值套餐
                    VStack(alignment: .leading, spacing: 0) {
                        sectionTitle("RECHARGE DIAMONDS")
                            .padding(.horizontal, 24)
                            .padding(.top, 32)
                            .padding(.bottom, 16)

                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 14),
                                GridItem(.flexible(), spacing: 14)
                            ],
                            spacing: 14
                        ) {
                            ForEach(packages) { pkg in
                                packageCard(pkg)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // 底部说明
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(AppTheme.success)
                                .font(.system(size: 12))
                            Text("Secure Payment · Instant Delivery")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textMuted)
                        }

                        Text("Diamonds never expire. Use them anytime for AI generation.")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textMuted.opacity(0.6))
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 50)
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.08)))
                    .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
            }

            Spacer()

            Text("Diamond Store")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - 余额展示卡片
    private var balanceHeroCard: some View {
        ZStack {
            // 背景光效
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "#1A1D4A"),
                            Color(hex: "#0E1030"),
                            Color(hex: "#1A1D4A")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [AppTheme.accentPrimary.opacity(0.6), AppTheme.accentSecondary.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )

            // 装饰光点
            Circle()
                .fill(AppTheme.accentPrimary.opacity(0.15))
                .frame(width: 120, height: 120)
                .blur(radius: 40)
                .offset(x: 80, y: -30)

            Circle()
                .fill(AppTheme.accentSecondary.opacity(0.1))
                .frame(width: 80, height: 80)
                .blur(radius: 30)
                .offset(x: -90, y: 40)

            // 内容
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("YOUR BALANCE")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(2)
                        .foregroundColor(AppTheme.textMuted)

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("💎")
                            .font(.system(size: 28))
                        Text("\(userService.diamonds)")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundStyle(AppTheme.accentGrad)
                    }

                    Text("Diamonds")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                // 装饰钻石图标
                ZStack {
                    Circle()
                        .fill(AppTheme.accentGrad.opacity(0.15))
                        .frame(width: 64, height: 64)

                    Image(systemName: "diamond.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(AppTheme.accentGrad)
                }
            }
            .padding(24)
        }
        .shadow(color: AppTheme.accentGlow.opacity(0.3), radius: 20, y: 10)
    }

    // MARK: - 订阅会员
    private var subscriptionSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                // 左侧图标
                ZStack {
                    Circle()
                        .fill(AppTheme.accentGrad.opacity(0.2))
                        .frame(width: 52, height: 52)

                    Image(systemName: "crown.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AppTheme.accentGrad)
                }

                // 中间文字
                VStack(alignment: .leading, spacing: 4) {
                    Text("PRO MEMBERSHIP")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)

                    Text("1,000 💎 monthly + unlimited HD")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                // 右侧按钮
                Button(action: {
                    userService.setPremium(true)
                }) {
                    Text(userService.isPremium ? "Active" : "$9.99/mo")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if userService.isPremium {
                                    Color.gray.opacity(0.3)
                                } else {
                                    AppTheme.accentGradH
                                }
                            }
                        )
                        .clipShape(Capsule())
                }
                .disabled(userService.isPremium)
            }
            .padding(18)
            .glassStyle(cornerRadius: 20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(AppTheme.accentPrimary.opacity(0.25), lineWidth: 1)
            )
        }
    }

    // MARK: - 套餐卡片
    private func packageCard(_ pkg: DiamondPackage) -> some View {
        Button(action: {
            userService.addDiamonds(pkg.totalDiamonds)
        }) {
            VStack(spacing: 0) {
                // Tag
                if let tag = pkg.tag {
                    Text(tag)
                        .font(.system(size: 9, weight: .black))
                        .tracking(1.5)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(AppTheme.accentGradH)
                        )
                        .padding(.top, -10)
                        .padding(.bottom, 12)
                } else {
                    Spacer().frame(height: 16)
                }

                // Diamond amount
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("💎")
                        .font(.system(size: 16))
                    Text("\(pkg.totalDiamonds)")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 2)

                if pkg.bonus > 0 {
                    Text("+\(pkg.bonus) bonus")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppTheme.success)
                        .padding(.bottom, 10)
                } else {
                    Spacer().frame(height: 10)
                }

                // Price
                Text(pkg.price)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 16)

                // 装饰分割线
                Rectangle()
                    .fill(LinearGradient(
                        colors: [.clear, AppTheme.accentPrimary.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(height: 1)
                    .padding(.horizontal, 12)

                // 每钻单价
                let priceValue = Double(pkg.price.replacingOccurrences(of: "$", with: "")) ?? 0
                let perDiamond = priceValue / Double(pkg.totalDiamonds)
                Text("~$\(String(format: "%.3f", perDiamond))/💎")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.textMuted.opacity(0.6))
                    .padding(.top, 10)
                    .padding(.bottom, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(
                        colors: pkg.gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 分区标题
    private func sectionTitle(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppTheme.textMuted)
                .tracking(2)
            Spacer()
        }
    }
}

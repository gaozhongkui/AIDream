import SwiftUI
import StoreKit

struct DiamondStoreView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var userService = UserService.shared
    @ObservedObject var storeKit = StoreKitService.shared

    // MARK: - 钻石套餐数据
    struct DiamondPackage: Identifiable {
        let id: String
        let productID: StoreProductID
        let diamonds: Int
        let price: String      // 降级显示
        let bonus: Int
        let tag: String?
        let gradient: [Color]
        var totalDiamonds: Int { diamonds + bonus }
    }

    private let packages: [DiamondPackage] = [
        DiamondPackage(
            id: "300",
            productID: .diamonds300,
            diamonds: 300, price: "$1.99", bonus: 0, tag: nil,
            gradient: [Color(hex: "#3A3F5C").opacity(0.6), Color(hex: "#2A2D40").opacity(0.6)]
        ),
        DiamondPackage(
            id: "900",
            productID: .diamonds1000,
            diamonds: 800, price: "$4.99", bonus: 100, tag: "POPULAR",
            gradient: [Color(hex: "#2D4A7A").opacity(0.6), Color(hex: "#1E3460").opacity(0.6)]
        ),
        DiamondPackage(
            id: "2000",
            productID: .diamonds2500,
            diamonds: 1800, price: "$9.99", bonus: 200, tag: "BEST VALUE",
            gradient: [Color(hex: "#4A2D7A").opacity(0.6), Color(hex: "#2E1A5E").opacity(0.6)]
        ),
        DiamondPackage(
            id: "5000",
            productID: .diamonds6000,
            diamonds: 4000, price: "$19.99", bonus: 1000, tag: "WHALE",
            gradient: [Color(hex: "#7A4A2D").opacity(0.6), Color(hex: "#5E2E1A").opacity(0.6)]
        )
    ]

    @State private var purchasingID: String?
    @State private var showPremiumSheet = false

    var body: some View {
        GeometryReader { proxy in
            let topInset = proxy.safeAreaInsets.top > 0 ? proxy.safeAreaInsets.top : 20
            let toolbarHeight: CGFloat = 56

            ZStack(alignment: .top) {
                AppTheme.bgPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer().frame(height: topInset + toolbarHeight + 10)

                        balanceHeroCard
                            .padding(.horizontal, 20)

                        subscriptionSection
                            .padding(.top, 24)
                            .padding(.horizontal, 20)
                            .onTapGesture {
                                showPremiumSheet = true
                            }

                        VStack(alignment: .leading, spacing: 0) {
                            sectionTitle("RECHARGE DIAMONDS")
                                .padding(.horizontal, 24)
                                .padding(.top, 32)
                                .padding(.bottom, 16)

                            if storeKit.isLoadingProducts && storeKit.diamondProducts.isEmpty {
                                loadingPlaceholder
                            } else {
                                LazyVGrid(
                                    columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                                    spacing: 14
                                ) {
                                    ForEach(packages) { pkg in
                                        packageCard(pkg)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }

                        if let error = storeKit.purchaseError {
                            Text(error)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppTheme.error)
                                .padding(.top, 16)
                        }

                        Button(action: { Task { await storeKit.restorePurchases() } }) {
                            Text("Restore Purchases")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textMuted)
                        }
                        .padding(.top, 24)

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
                        .padding(.bottom, 110)
                    }
                }

                VStack(spacing: 0) {
                    headerView
                        .padding(.top, topInset)
                        .padding(.bottom, 8)
                        .background(.ultraThinMaterial)
                        .overlay(
                            Rectangle()
                                .fill(Color.white.opacity(0.12))
                                .frame(height: 0.5),
                            alignment: .bottom
                        )
                    Spacer()
                }
                .ignoresSafeArea(edges: .top)
                .zIndex(10)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showPremiumSheet) {
            PremiumView()
        }
        .alert("Purchase Error", isPresented: Binding(
            get: { storeKit.purchaseError != nil && purchasingID == nil },
            set: { if !$0 { storeKit.purchaseError = nil } }
        )) {
            Button("OK") { storeKit.purchaseError = nil }
        } message: {
            Text(storeKit.purchaseError ?? "")
        }
    }

    private var loadingPlaceholder: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
            spacing: 14
        ) {
            ForEach(0..<4) { _ in
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 180)
                    .overlay(
                        ProgressView().tint(AppTheme.accentSecondary)
                    )
            }
        }
        .padding(.horizontal, 20)
    }

    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .glassStyle(cornerRadius: 20)
            }

            Spacer()

            Text("Diamond Store")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .frame(height: 44)
    }

    private var balanceHeroCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("YOUR BALANCE")
                .font(.system(size: 11, weight: .bold))
                .tracking(2)
                .foregroundColor(AppTheme.textMuted)
            
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("💎")
                    .font(.system(size: 28))

                Text("\(userService.diamonds)")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.accentGrad)

                Spacer()

                ZStack {
                    Circle()
                        .fill(AppTheme.accentGrad.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(AppTheme.accentGrad)
                }
            }

            Text("Available for generating masterpieces")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(24)
        .background(
            ZStack {
                AppTheme.bgSecondary.opacity(0.3)
                LinearGradient(
                    colors: [AppTheme.accentPrimary.opacity(0.1), .clear],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            }
        )
        .glassStyle(cornerRadius: 24)
    }

    private var subscriptionSection: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(AppTheme.accentGrad.opacity(0.2)).frame(width: 52, height: 52)
                Image(systemName: "crown.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AppTheme.accentGrad)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("PRO MEMBERSHIP")
                    .font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                Text(userService.isPremium ? "You are a PRO member" : "Subscribe to get up to 10,000 diamonds!")
                    .font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppTheme.textMuted)
        }
        .padding(18)
        .glassStyle(cornerRadius: 20)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppTheme.accentPrimary.opacity(0.3), lineWidth: 1.2)
        )
    }

    private func packageCard(_ pkg: DiamondPackage) -> some View {
        let skProduct = storeKit.diamondProducts.first { $0.id == pkg.productID.rawValue }
        let isBuying = purchasingID == pkg.productID.rawValue

        return Button {
            if let product = skProduct {
                purchasingID = product.id
                Task {
                    _ = await storeKit.purchase(product)
                    purchasingID = nil
                }
            }
        } label: {
            VStack(spacing: 0) {
                if let tag = pkg.tag {
                    Text(tag)
                        .font(.system(size: 9, weight: .black))
                        .tracking(1.2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Capsule().fill(AppTheme.accentGradH))
                        .padding(.bottom, 8)
                } else {
                    Spacer().frame(height: 25)
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("💎").font(.system(size: 14))
                    Text("\(pkg.totalDiamonds)")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 2)

                if pkg.bonus > 0 {
                    Text("+\(pkg.bonus) bonus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.success)
                        .padding(.bottom, 12)
                } else {
                    Spacer().frame(height: 25)
                }

                Group {
                    if isBuying {
                        ProgressView().tint(.white)
                    } else {
                        Text(skProduct?.displayPrice ?? pkg.price)
                            .font(.system(size: 20, weight: .bold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
                .padding(.horizontal, 12)
                .padding(.bottom, 14)

                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 0.5)
                    .padding(.horizontal, 16)

                let priceValue = skProduct.map { NSDecimalNumber(decimal: $0.price).doubleValue } ?? (Double(pkg.price.replacingOccurrences(of: "$", with: "")) ?? 0)
                let perDiamond = priceValue / Double(pkg.totalDiamonds)
                Text("~$\(String(format: "%.3f", perDiamond))/💎")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.textMuted.opacity(0.6))
                    .padding(.top, 10)
            }
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LinearGradient(colors: pkg.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .opacity(0.4)
            )
            .glassStyle(cornerRadius: 20)
        }
        .buttonStyle(.plain)
        .disabled(isBuying || purchasingID != nil)
    }

    private func sectionTitle(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppTheme.textMuted)
                .tracking(1.5)
            Spacer()
        }
    }
}

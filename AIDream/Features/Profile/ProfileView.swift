import SwiftUI

struct ProfileView: View {
    @ObservedObject var creationService = CreationService.shared
    @ObservedObject var favoriteService = FavoriteService.shared
    @ObservedObject var userService = UserService.shared

    @State private var showPremiumSheet = false
    @State private var showDiamondStore = false
    @State private var showFavorites = false
    @State private var showHistory = false
    @State private var safariURL: URL?
    @State private var showSafari = false
    @State private var showResetAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.bgPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // 1. 紧凑型页眉：包含头像、昵称、勋章及统计
                        compactHeader.padding(.top, 24)

                        // 2. 核心权益区域：并排的卡片
                        actionCardsRow.padding(.top, 28)

                        sectionLabel(NSLocalizedString("label_studio", comment: "")).padding(.top, 32)

                        // 菜单区域
                        VStack(spacing: 0) {
                            Button(action: {
                                HapticManager.shared.impact(style: .light)
                                showFavorites = true
                            }) {
                                menuRowContent(icon: "heart.square.fill", title: NSLocalizedString("title_favorites", comment: ""))
                            }

                            Rectangle()
                                .fill(Color.white.opacity(0.05))
                                .frame(height: 1)
                                .padding(.leading, 72)

                            Button(action: {
                                HapticManager.shared.impact(style: .light)
                                showHistory = true
                            }) {
                                menuRowContent(icon: "video.badge.plus.fill", title: NSLocalizedString("title_creative_history", comment: ""))
                            }
                        }
                        .glassStyle(cornerRadius: 22)
                        .padding(.horizontal, 20)

                        sectionLabel(NSLocalizedString("label_preferences", comment: "")).padding(.top, 24)

                        VStack(spacing: 0) {
                            Button(action: {
                                HapticManager.shared.impact(style: .light)
                                sendFeedback()
                            }) {
                                menuRowContent(icon: "envelope.fill", title: NSLocalizedString("btn_feedback", comment: ""))
                            }

                            Rectangle()
                                .fill(Color.white.opacity(0.05))
                                .frame(height: 1)
                                .padding(.leading, 72)

                            Button(action: {
                                HapticManager.shared.impact(style: .light)
                                safariURL = URL(string: AIConfig.shared.privacyPolicyURL)
                                showSafari = true
                            }) {
                                menuRowContent(icon: "doc.text.fill", title: NSLocalizedString("btn_privacy", comment: ""))
                            }

                            Rectangle()
                                .fill(Color.white.opacity(0.05))
                                .frame(height: 1)
                                .padding(.leading, 72)

                            Button(action: {
                                HapticManager.shared.impact(style: .light)
                                safariURL = URL(string: AIConfig.shared.termsOfServiceURL)
                                showSafari = true
                            }) {
                                menuRowContent(icon: "scroll.fill", title: NSLocalizedString("btn_terms", comment: ""))
                            }
                        }
                        .glassStyle(cornerRadius: 22)
                        .padding(.horizontal, 20)

                        versionInfo.padding(.top, 40).padding(.bottom, 110)
                    }
                }
            }
            .navigationBarHidden(true)
            .onReceive(NotificationCenter.default.publisher(for: .dismissFavoritesView)) { _ in
                showFavorites = false
            }
            .alert(isPresented: $showResetAlert) {
                Alert(
                    title: Text(NSLocalizedString("alert_reset_title", comment: "")),
                    message: Text(NSLocalizedString("alert_reset_message", comment: "")),
                    primaryButton: .destructive(Text(NSLocalizedString("btn_confirm_reset", comment: ""))) {
                        userService.resetAllData()
                        HapticManager.shared.notification(type: .success)
                    },
                    secondaryButton: .cancel()
                )
            }
            .fullScreenCover(isPresented: $showPremiumSheet) {
                PremiumView()
            }
            .sheet(isPresented: $showSafari) {
                if let url = safariURL {
                    SafariView(url: url)
                        .ignoresSafeArea()
                }
            }
            .fullScreenCover(isPresented: $showDiamondStore) {
                DiamondStoreView()
            }
            .fullScreenCover(isPresented: $showFavorites) {
                FavoritesView()
            }
            .fullScreenCover(isPresented: $showHistory) {
                HistoryView()
            }
        }
    }

    // MARK: - Actions

    private func sendFeedback() {
        let email = "hhyteam@zhongkuitech.cn"
        let subject = "Feedback for AIDream"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let body = "\n\n--- Device Info ---\nApp Version: \(appVersion)\nSystem: \(UIDevice.current.systemVersion)"

        let mailtoString = "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"

        if let url = URL(string: mailtoString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Components

    private var compactHeader: some View {
        HStack(spacing: 16) {
            // 头像
            Button(action: {
                HapticManager.shared.impact(style: .medium)
                showPremiumSheet = true
            }) {
                ZStack {
                    Circle()
                        .fill(userService.isPremium ? AppTheme.vipGold.opacity(0.3) : AppTheme.accentGlow)
                        .frame(width: 80, height: 80)
                        .blur(radius: 12)

                    Circle()
                        .fill(AppTheme.bgCard)
                        .frame(width: 74, height: 74)
                        .overlay(
                            Circle().stroke(userService.isPremium ? AnyShapeStyle(AppTheme.vipGold) : AnyShapeStyle(AppTheme.accentGradV), lineWidth: 2)
                        )

                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(userService.isPremium ? AnyShapeStyle(AppTheme.vipGold) : AnyShapeStyle(AppTheme.accentGrad))
                }
            }
            .buttonStyle(PlainButtonStyle())

            // 信息与统计
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(NSLocalizedString("label_vision_artist", comment: ""))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    Text(userService.isPremium ? "PRO" : "FREE")
                        .font(.system(size: 10, weight: .black))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(userService.isPremium ? AppTheme.vipGold.opacity(0.2) : Color.white.opacity(0.1))
                        .cornerRadius(4)
                        .foregroundColor(userService.isPremium ? AppTheme.vipGold : .white.opacity(0.6))
                }

                HStack(spacing: 20) {
                    headerStatItem(value: "\(creationService.creations.count)", label: NSLocalizedString("label_creations", comment: ""))
                    headerStatItem(value: "\(favoriteService.favoriteVideos.count)", label: NSLocalizedString("label_likes", comment: ""))
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private func headerStatItem(value: String, label: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(value).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
            Text(label).font(.system(size: 12)).foregroundColor(AppTheme.textMuted)
        }
    }

    private var actionCardsRow: some View {
        HStack(spacing: 12) {
            // 会员卡片 (更具质感)
            Button(action: {
                HapticManager.shared.impact(style: .medium)
                showPremiumSheet = true
            }) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "crown.fill").font(.system(size: 14)).foregroundStyle(AppTheme.vipGold)
                        Spacer()
                        Image(systemName: "arrow.right").font(.system(size: 10, weight: .bold)).foregroundColor(AppTheme.vipGold.opacity(0.5))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("label_pro_membership", comment: "")).font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                        Text(userService.isPremium ? "Active" : "Upgrade").font(.system(size: 10)).foregroundColor(AppTheme.textMuted)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(AppTheme.bgCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(AppTheme.vipGold.opacity(0.2), lineWidth: 1)
                        )
                )
            }

            // 钻石余额卡片 (更像钱包)
            Button(action: {
                HapticManager.shared.impact(style: .medium)
                showDiamondStore = true
            }) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "diamond.fill").font(.system(size: 14)).foregroundStyle(AppTheme.accentGrad)
                        Spacer()
                        Text(NSLocalizedString("btn_recharge", comment: "")).font(.system(size: 10, weight: .bold)).foregroundColor(AppTheme.accentPrimary)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(userService.diamonds)").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                        Text(NSLocalizedString("label_diamonds", comment: "")).font(.system(size: 10)).foregroundColor(AppTheme.textMuted)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(AppTheme.bgCard)
                )
            }
        }
        .padding(.horizontal, 20)
    }

    private func sectionLabel(_ text: String) -> some View {
        HStack {
            Text(text.uppercased()).font(.system(size: 12, weight: .bold)).foregroundColor(AppTheme.textMuted).tracking(2)
            Spacer()
        }.padding(.horizontal, 24).padding(.bottom, 12)
    }

    private func menuRowContent(icon: String, title: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon).font(.system(size: 18)).foregroundStyle(AppTheme.accentGradH).frame(width: 40, height: 40).background(Circle().fill(Color.white.opacity(0.05)))
            Text(title).font(.system(size: 16, weight: .medium)).foregroundColor(.white.opacity(0.9))
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold)).foregroundColor(AppTheme.textMuted)
        }.padding(.horizontal, 16).padding(.vertical, 14)
    }

    private var versionInfo: some View {
        VStack(spacing: 4) {
            Text(String(format: NSLocalizedString("label_app_version_format", comment: ""), Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""))
            Text(NSLocalizedString("label_designed_for", comment: ""))
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundColor(AppTheme.textMuted.opacity(0.5))
    }
}

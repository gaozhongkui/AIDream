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

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.bgPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        profileHeader.padding(.top, 40)
                        statsRow.padding(.top, 32)

                        vipMembershipCard.padding(.top, 28)
                        diamondBalanceCard.padding(.top, 16)

                        sectionLabel(NSLocalizedString("label_studio", comment: "")).padding(.top, 40)

                        // 菜单区域
                        VStack(spacing: 0) {
                            Button(action: { showFavorites = true }) {
                                menuRowContent(icon: "heart.square.fill", title: NSLocalizedString("title_favorites", comment: ""))
                            }

                            Rectangle()
                                .fill(Color.white.opacity(0.05))
                                .frame(height: 1)
                                .padding(.leading, 72)

                            Button(action: { showHistory = true }) {
                                menuRowContent(icon: "video.badge.plus.fill", title: NSLocalizedString("title_creative_history", comment: ""))
                            }
                        }
                        .glassStyle(cornerRadius: 22)
                        .padding(.horizontal, 20)

                        sectionLabel(NSLocalizedString("label_preferences", comment: "")).padding(.top, 32)

                        VStack(spacing: 0) {
                            Button(action: {
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
                                safariURL = URL(string: AIConfig.shared.termsOfServiceURL)
                                showSafari = true
                            }) {
                                menuRowContent(icon: "scroll.fill", title: NSLocalizedString("btn_terms", comment: ""))
                            }
                        }
                        .glassStyle(cornerRadius: 22)
                        .padding(.horizontal, 20)

                        resetButton.padding(.top, 40)

                        versionInfo.padding(.top, 24).padding(.bottom, 110)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showPremiumSheet) {
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

    // MARK: - Components
    private var profileHeader: some View {
        VStack(spacing: 18) {
            Button(action: { showPremiumSheet = true }) {
                ZStack {
                    Circle()
                        .fill(userService.isPremium ? AppTheme.vipGold.opacity(0.3) : AppTheme.accentGlow)
                        .frame(width: 100, height: 100)
                        .blur(radius: 12)

                    Circle()
                        .fill(AppTheme.bgCard)
                        .frame(width: 94, height: 94)
                        .overlay(
                            Circle().stroke(userService.isPremium ? AnyShapeStyle(AppTheme.vipGold) : AnyShapeStyle(AppTheme.accentGradV), lineWidth: 2)
                        )

                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(userService.isPremium ? AnyShapeStyle(AppTheme.vipGold) : AnyShapeStyle(AppTheme.accentGrad))
                }
            }
            .buttonStyle(PlainButtonStyle())

            VStack(spacing: 8) {
                Text(NSLocalizedString("label_vision_artist", comment: ""))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                Text(userService.isPremium ? NSLocalizedString("label_pro_member", comment: "") : NSLocalizedString("label_free_member", comment: ""))
                    .font(.system(size: 10, weight: .black))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(userService.isPremium ? AppTheme.vipGold.opacity(0.2) : AppTheme.accentPrimary.opacity(0.2))
                    .cornerRadius(6)
                    .foregroundColor(userService.isPremium ? AppTheme.vipGold : .white)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(userService.isPremium ? AppTheme.vipGold.opacity(0.5) : AppTheme.accentSecondary.opacity(0.5), lineWidth: 0.5))
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(value: "\(creationService.creations.count)", label: NSLocalizedString("label_creations", comment: ""))
            statCard(value: "\(favoriteService.favoriteVideos.count)", label: NSLocalizedString("label_likes", comment: ""))
            statCard(value: "\(userService.diamonds)", label: NSLocalizedString("label_diamonds", comment: ""))
        }
        .padding(.horizontal, 20)
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 20, weight: .bold)).foregroundColor(.white)
            Text(label).font(.system(size: 11, weight: .medium)).foregroundColor(AppTheme.textMuted)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16).glassStyle(cornerRadius: 18)
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

    private var vipMembershipCard: some View {
        Button(action: { showPremiumSheet = true }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(AppTheme.vipGold.opacity(0.15)).frame(width: 46, height: 46)
                    Image(systemName: "crown.fill").font(.system(size: 20)).foregroundStyle(AppTheme.vipGold)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(NSLocalizedString("label_pro_membership", comment: "")).font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    Text(NSLocalizedString("label_unlock_premium", comment: "")).font(.system(size: 12)).foregroundColor(AppTheme.textMuted)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold)).foregroundColor(AppTheme.textMuted)
            }
            .padding(18).glassStyle(cornerRadius: 20).overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.vipGold.opacity(0.3), lineWidth: 1))
        }.padding(.horizontal, 20)
    }

    private var diamondBalanceCard: some View {
        Button(action: { showDiamondStore = true }) {
            HStack(spacing: 0) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(AppTheme.accentGrad.opacity(0.2)).frame(width: 46, height: 46)
                        Image(systemName: "diamond.fill").font(.system(size: 20)).foregroundStyle(AppTheme.accentGrad)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("label_diamond_balance", comment: "")).font(.system(size: 11, weight: .medium)).foregroundColor(AppTheme.textMuted)
                        Text("💎 \(userService.diamonds)").font(.system(size: 22, weight: .bold)).foregroundColor(.white)
                    }
                }
                Spacer()
                Text(NSLocalizedString("btn_recharge", comment: "")).font(.system(size: 14, weight: .bold)).foregroundColor(.white).padding(.horizontal, 18).padding(.vertical, 10).background(AppTheme.accentGradH).clipShape(Capsule())
            }.padding(18).glassStyle(cornerRadius: 20)
        }.padding(.horizontal, 20)
    }

    private var resetButton: some View {
        Button(action: {
            userService.addDiamonds(100)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }) {
            Text(NSLocalizedString("btn_reset_account", comment: "")).font(.system(size: 15, weight: .bold)).foregroundColor(AppTheme.textMuted).frame(maxWidth: .infinity).frame(height: 56).glassStyle(cornerRadius: 20)
        }.padding(.horizontal, 20)
    }

    private var versionInfo: some View {
        VStack(spacing: 4) {
            Text(String(format: NSLocalizedString("label_app_version_format", comment: ""), "1.0.0"))
            Text(NSLocalizedString("label_designed_for", comment: ""))
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundColor(AppTheme.textMuted.opacity(0.5))
    }
}

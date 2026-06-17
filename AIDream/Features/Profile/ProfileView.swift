import SwiftUI

struct ProfileView: View {
    @ObservedObject var creationService = CreationService.shared
    @ObservedObject var favoriteService = FavoriteService.shared
    @ObservedObject var userService = UserService.shared

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.bgPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        profileHeader.padding(.top, 40)
                        statsRow.padding(.top, 32)

                        diamondBalanceCard.padding(.top, 28)

                        sectionLabel("Studio").padding(.top, 40)

                        // 菜单区域
                        VStack(spacing: 0) {
                            // My Inspirations 跳转到收藏页
                            NavigationLink(destination: FavoritesView()) {
                                menuRowContent(icon: "heart.square.fill", title: "My Inspirations")
                            }

                            Rectangle()
                                .fill(Color.white.opacity(0.05))
                                .frame(height: 1)
                                .padding(.leading, 72)

                            // 跳转到创作历史
                            NavigationLink(destination: HistoryView()) {
                                menuRowContent(icon: "video.badge.plus.fill", title: "Creative History")
                            }

                            Rectangle()
                                .fill(Color.white.opacity(0.05))
                                .frame(height: 1)
                                .padding(.leading, 72)

                            // Diamond Store
                            NavigationLink(destination: DiamondStoreView()) {
                                menuRowContent(icon: "diamond.fill", title: "Diamond Store", trailing: "💎 \(userService.diamonds)")
                            }
                        }
                        .glassStyle(cornerRadius: 22)
                        .padding(.horizontal, 20)

                        sectionLabel("Preferences").padding(.top, 32)
                        menuSection([
                            MenuRow(icon: "doc.text.fill", title: "Privacy Policy", dest: "Privacy Policy"),
                            MenuRow(icon: "scroll.fill",   title: "Terms of Service", dest: "Terms of Service"),
                        ])

                        logoutButton.padding(.top, 40).padding(.bottom, 110)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Modern Profile Header
    private var profileHeader: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(AppTheme.accentGlow)
                    .frame(width: 100, height: 100)
                    .blur(radius: 12)

                Circle()
                    .fill(AppTheme.bgCard)
                    .frame(width: 94, height: 94)
                    .overlay(
                        Circle().stroke(AppTheme.accentGradV, lineWidth: 2)
                    )

                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(AppTheme.accentGrad)
            }

            VStack(spacing: 8) {
                Text("Vision Artist")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.accentSecondary)
                    Text(userService.isPremium ? "PRO MEMBER" : "FREE MEMBER")
                        .font(.system(size: 10, weight: .black))
                        .tracking(1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(AppTheme.accentPrimary.opacity(0.1))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppTheme.accentPrimary.opacity(0.3), lineWidth: 0.5))
            }
        }
    }

    // MARK: - Glass Stats
    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(value: "\(creationService.creations.count)", label: "Creations")
            statCard(value: "\(favoriteService.favoriteVideos.count)", label: "Likes")
            statCard(value: "\(userService.diamonds)", label: "Diamonds")
        }
        .padding(.horizontal, 20)
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .glassStyle(cornerRadius: 18)
    }

    private func sectionLabel(_ text: String) -> some View {
        HStack {
            Text(text.uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppTheme.textMuted)
                .tracking(2)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }

    // MARK: - Menu Helpers
    private struct MenuRow: Identifiable {
        var id: String { title }
        let icon: String
        let title: String
        let dest: String
    }

    private func menuSection(_ rows: [MenuRow]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { idx, row in
                NavigationLink(destination: Text(row.dest).foregroundColor(.white)) {
                    menuRowContent(icon: row.icon, title: row.title)
                }
                if idx < rows.count - 1 {
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 1)
                        .padding(.leading, 72)
                }
            }
        }
        .glassStyle(cornerRadius: 22)
        .padding(.horizontal, 20)
    }

    private func menuRowContent(icon: String, title: String, trailing: String? = nil) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(AppTheme.accentGradH)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.white.opacity(0.05)))

            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))

            Spacer()

            if let trailing = trailing {
                Text(trailing)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.accentSecondary)
                    .padding(.trailing, 4)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppTheme.textMuted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Diamond Balance Card
    private var diamondBalanceCard: some View {
        NavigationLink(destination: DiamondStoreView()) {
            HStack(spacing: 0) {
                // 左侧：钻石图标 + 余额
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accentGrad.opacity(0.2))
                            .frame(width: 46, height: 46)

                        Image(systemName: "diamond.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(AppTheme.accentGrad)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Diamond Balance")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.textMuted)
                        Text("💎 \(userService.diamonds)")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                Spacer()

                // 右侧：充值按钮
                Text("Recharge")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(AppTheme.accentGradH)
                    .clipShape(Capsule())
                    .shadow(color: AppTheme.accentGlow.opacity(0.4), radius: 6, y: 3)
            }
            .padding(18)
            .glassStyle(cornerRadius: 20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(AppTheme.accentPrimary.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
    }

    private var logoutButton: some View {
        Button(action: {
            userService.consumeDiamonds(userService.diamonds)
            userService.addDiamonds(500)
            creationService.creations.removeAll()
            favoriteService.favoriteVideos.removeAll()
            favoriteService.favoriteIds.removeAll()
        }) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 16, weight: .bold))
                Text("Reset Account")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundColor(AppTheme.textMuted)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(.ultraThinMaterial)
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal, 20)
    }
}

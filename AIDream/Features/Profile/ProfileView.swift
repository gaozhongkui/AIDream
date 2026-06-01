import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.bgPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        profileHeader.padding(.top, 32)
                        statsRow.padding(.top, 24)

                        sectionDivider.padding(.vertical, 28)

                        sectionLabel("My Creations")
                        menuSection([
                            MenuRow(icon: "video.fill",           title: "My Videos",  dest: "创作历史"),
                            MenuRow(icon: "heart.fill",           title: "Favorites",  dest: "收藏夹"),
                            MenuRow(icon: "archivebox.fill",      title: "Drafts",     dest: "草稿箱"),
                        ])

                        sectionDivider.padding(.vertical, 28)

                        sectionLabel("Account")
                        menuSection([
                            MenuRow(icon: "person.text.rectangle", title: "Profile",   dest: "个人资料"),
                            MenuRow(icon: "gearshape.fill",        title: "Settings",  dest: "系统设置"),
                        ])

                        logoutButton.padding(.top, 32).padding(.bottom, 50)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.bgCard)
                    .frame(width: 90, height: 90)
                    .overlay(
                        Circle().stroke(AppTheme.goldGradV, lineWidth: 2)
                    )
                Image(systemName: "person.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(AppTheme.goldGrad)
            }

            VStack(spacing: 6) {
                Text("AI Dream Creator")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Text("ID: 20240528")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textMuted)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(AppTheme.bgCard)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppTheme.borderSubtle, lineWidth: 0.5)
                    )
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Stats
    private var statsRow: some View {
        HStack(spacing: 10) {
            statCard(value: "0", label: "Videos")
            statCard(value: "0", label: "Favorites")
            statCard(value: "0", label: "Drafts")
        }
        .padding(.horizontal, 20)
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppTheme.goldGradH)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(AppTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AppTheme.bgCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.borderSubtle, lineWidth: 0.5)
        )
    }

    // MARK: - Section helpers
    private var sectionDivider: some View {
        Rectangle()
            .fill(AppTheme.borderSubtle)
            .frame(height: 0.5)
            .padding(.horizontal, 20)
    }

    private func sectionLabel(_ text: String) -> some View {
        HStack {
            Text(text.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppTheme.textMuted)
                .tracking(1.2)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }

    // MARK: - Menu
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
                    HStack(spacing: 14) {
                        Image(systemName: row.icon)
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.goldGradH)
                            .frame(width: 36, height: 36)
                            .background(AppTheme.goldBright.opacity(0.1))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AppTheme.goldBright.opacity(0.2), lineWidth: 0.5)
                            )

                        Text(row.title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppTheme.textPrimary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.textMuted)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }

                if idx < rows.count - 1 {
                    Rectangle()
                        .fill(AppTheme.borderSubtle)
                        .frame(height: 0.5)
                        .padding(.leading, 66)
                }
            }
        }
        .background(AppTheme.bgCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.borderSubtle, lineWidth: 0.5)
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Logout
    private var logoutButton: some View {
        Button(action: {}) {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 15))
                Text("Log Out")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(AppTheme.error)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AppTheme.error.opacity(0.07))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.error.opacity(0.2), lineWidth: 0.5)
            )
        }
        .padding(.horizontal, 20)
    }
}

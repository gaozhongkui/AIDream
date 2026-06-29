import Foundation
import SwiftUI
import Combine

// MARK: - 钻石交易记录
struct DiamondTransaction: Identifiable, Codable {
    let id: UUID
    let date: Date
    let amount: Int       // 正=充值，负=消费
    let reason: String
    let balanceAfter: Int

    var isCredit: Bool { amount > 0 }

    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

@MainActor
class UserService: ObservableObject {
    static let shared = UserService()

    @Published var diamonds: Int = 0
    @Published var isPremium: Bool = false
    @Published var transactions: [DiamondTransaction] = []

    private let diamondsKey = "com.aidream.user.diamonds"
    private let premiumKey = "com.aidream.user.premium"
    private let transactionsKey = "com.aidream.user.transactions"

    private init() {
        // 使用 Keychain 读取关键资产，若无则初始化
        let storedDiamonds = KeychainHelper.shared.readInt(key: diamondsKey)
        self.diamonds = storedDiamonds ?? 0

        // 首次安装赠送逻辑
        if storedDiamonds == nil {
            let initial = AIConfig.shared.initialDiamonds
            self.diamonds = initial
            saveDiamonds()
            logTransaction(amount: initial, reason: "Welcome gift")
        }

        self.isPremium = KeychainHelper.shared.readBool(key: premiumKey) ?? false
        loadTransactions()
    }

    func addDiamonds(_ amount: Int, reason: String = "Purchase") {
        diamonds += amount
        saveDiamonds()
        logTransaction(amount: amount, reason: reason)
    }

    func consumeDiamonds(_ amount: Int, reason: String = "AI Generation") -> Bool {
        if diamonds >= amount {
            diamonds -= amount
            saveDiamonds()
            logTransaction(amount: -amount, reason: reason)
            return true
        }
        return false
    }

    func setPremium(_ status: Bool) {
        isPremium = status
        KeychainHelper.shared.saveBool(status, key: premiumKey)
    }

    /// 清除所有本地数据与隐私标识 (App Store 合规项，适用于无账户系统)
    func resetAllData() {
        KeychainHelper.shared.delete(service: "com.aidream.auth", account: diamondsKey)
        KeychainHelper.shared.delete(service: "com.aidream.auth", account: premiumKey)
        UserDefaults.standard.removeObject(forKey: transactionsKey)

        // 清除其他业务数据
        CreationService.shared.clearAll()
        FavoriteService.shared.clearAll()

        self.diamonds = 0
        self.isPremium = false
        self.transactions = []

        // 重新给予初始赠送 (可选)
        let initial = AIConfig.shared.initialDiamonds
        self.diamonds = initial
        saveDiamonds()
        logTransaction(amount: initial, reason: "Reset reward")
    }

    // MARK: - Transaction Log
    private func logTransaction(amount: Int, reason: String) {
        let tx = DiamondTransaction(
            id: UUID(),
            date: Date(),
            amount: amount,
            reason: reason,
            balanceAfter: diamonds
        )
        transactions.insert(tx, at: 0)
        if transactions.count > 200 {
            transactions = Array(transactions.prefix(200))
        }
        saveTransactions()
    }

    private func saveDiamonds() {
        KeychainHelper.shared.saveInt(diamonds, key: diamondsKey)
    }

    private func saveTransactions() {
        if let data = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(data, forKey: transactionsKey)
        }
    }

    private func loadTransactions() {
        guard let data = UserDefaults.standard.data(forKey: transactionsKey),
              let decoded = try? JSONDecoder().decode([DiamondTransaction].self, from: data)
        else { return }
        self.transactions = decoded
    }
}

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
        self.diamonds = UserDefaults.standard.integer(forKey: diamondsKey)
        if UserDefaults.standard.object(forKey: diamondsKey) == nil {
            self.diamonds = 500
            saveDiamonds()
            logTransaction(amount: 500, reason: "Welcome gift")
        }
        self.isPremium = UserDefaults.standard.bool(forKey: premiumKey)
        loadTransactions()
    }

    func addDiamonds(_ amount: Int) {
        diamonds += amount
        saveDiamonds()
        logTransaction(amount: amount, reason: "Purchase")
    }

    func consumeDiamonds(_ amount: Int) -> Bool {
        if diamonds >= amount {
            diamonds -= amount
            saveDiamonds()
            logTransaction(amount: -amount, reason: "AI Generation")
            return true
        }
        return false
    }

    func setPremium(_ status: Bool) {
        isPremium = status
        UserDefaults.standard.set(status, forKey: premiumKey)
        if status {
            addDiamonds(1000)
        }
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
        // 只保留最近 200 条
        if transactions.count > 200 {
            transactions = Array(transactions.prefix(200))
        }
        saveTransactions()
    }

    private func saveDiamonds() {
        UserDefaults.standard.set(diamonds, forKey: diamondsKey)
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

import Foundation
import SwiftUI
import Combine

@MainActor
class UserService: ObservableObject {
    static let shared = UserService()

    @Published var diamonds: Int = 0
    @Published var isPremium: Bool = false

    private let diamondsKey = "com.aidream.user.diamonds"
    private let premiumKey = "com.aidream.user.premium"

    private init() {
        self.diamonds = UserDefaults.standard.integer(forKey: diamondsKey)
        // Default give some diamonds for new users if needed, or keep 0
        if UserDefaults.standard.object(forKey: diamondsKey) == nil {
            self.diamonds = 500 // Initial gift
            saveDiamonds()
        }
        self.isPremium = UserDefaults.standard.bool(forKey: premiumKey)
    }

    func addDiamonds(_ amount: Int) {
        diamonds += amount
        saveDiamonds()
    }

    func consumeDiamonds(_ amount: Int) -> Bool {
        if diamonds >= amount {
            diamonds -= amount
            saveDiamonds()
            return true
        }
        return false
    }

    func setPremium(_ status: Bool) {
        isPremium = status
        UserDefaults.standard.set(status, forKey: premiumKey)

        if status {
            // Subscription gift: e.g., 1000 diamonds
            addDiamonds(1000)
        }
    }

    private func saveDiamonds() {
        UserDefaults.standard.set(diamonds, forKey: diamondsKey)
    }
}

import Foundation
import StoreKit
import OSLog
import Combine

private let logger = Logger(subsystem: "com.aidream", category: "StoreKit")

// MARK: - Product ID Constants
enum StoreProductID: String, CaseIterable {
    case diamonds300  = "com.aidream.diamonds.100"  // 对应最低 $1.99 给 300 钻
    case diamonds1000 = "com.aidream.diamonds.500"
    case diamonds2500 = "com.aidream.diamonds.1200"
    case diamonds6000 = "com.aidream.diamonds.3000"
    case premiumWeekly = "com.aidream.premium.weekly"
    case premiumMonthly = "com.aidream.premium.monthly"
    case premiumLifetime = "com.aidream.premium.lifetime"

    var diamondAmount: Int {
        switch self {
        case .diamonds300:  return 300
        case .diamonds1000: return 1000
        case .diamonds2500: return 2500
        case .diamonds6000: return 6000
        case .premiumWeekly: return 500 // 周订阅每次给 500
        default: return 0
        }
    }

    var isSubscription: Bool {
        switch self {
        case .premiumWeekly, .premiumMonthly, .premiumLifetime: return true
        default: return false
        }
    }
}

// MARK: - StoreKit Service
@MainActor
final class StoreKitService: ObservableObject {
    static let shared = StoreKitService()

    @Published var diamondProducts: [Product] = []
    @Published var subscriptionProducts: [Product] = []
    @Published var isLoadingProducts = false
    @Published var isPurchasing = false
    @Published var purchaseError: String?
    @Published var productsLoaded = false

    private var transactionListener: Task<Void, Error>?

    private init() {
        transactionListener = listenForTransactions()
        Task { await loadProducts() }
    }

    deinit {
        transactionListener?.cancel()
    }

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        let allIDs = StoreProductID.allCases.map(\.rawValue)
        do {
            let products = try await Product.products(for: allIDs)

            diamondProducts = products
                .filter { !(StoreProductID(rawValue: $0.id)?.isSubscription ?? false) }
                .sorted { ($0.price as Decimal) < ($1.price as Decimal) }

            subscriptionProducts = products
                .filter { StoreProductID(rawValue: $0.id)?.isSubscription ?? false }
                .sorted { ($0.price as Decimal) < ($1.price as Decimal) }

            productsLoaded = true
        } catch {
            logger.error("Failed to load products: \(error.localizedDescription)")
            purchaseError = "Unable to connect to App Store"
        }
    }

    func purchase(_ product: Product) async -> Bool {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await handleTransaction(transaction)
                await transaction.finish()
                return true
            case .userCancelled: return false
            case .pending:
                purchaseError = "Payment pending"
                return false
            @unknown default: return false
            }
        } catch {
            purchaseError = error.localizedDescription
            return false
        }
    }

    func restorePurchases() async {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        do {
            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result {
                    await handleTransaction(transaction)
                }
            }
        } catch {
            purchaseError = "Restore failed"
        }
    }

    private func handleTransaction(_ transaction: Transaction) async {
        guard let productID = StoreProductID(rawValue: transaction.productID) else { return }

        let userService = UserService.shared

        if productID.isSubscription {
            userService.setPremium(true)
            // 如果是周订阅，给 500 钻（包含首次和续订）
            if productID == .premiumWeekly {
                userService.addDiamonds(500, reason: "Weekly Subscription Bonus")
            }
        } else {
            // 普通钻石充值
            userService.addDiamonds(productID.diamondAmount, reason: "Purchase")
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await self.handleTransaction(transaction)
                    await transaction.finish()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe): return safe
        case .unverified: throw StoreError.unverified
        }
    }

    enum StoreError: Error { case unverified }
}

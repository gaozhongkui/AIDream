import Foundation
import StoreKit
import OSLog
import Combine

private let logger = Logger(subsystem: "com.aidream", category: "StoreKit")

// MARK: - Product ID Constants
enum StoreProductID: String, CaseIterable {
    case diamonds300  = "com.aidream.diamonds.300"  // $1.99 → 300 diamonds
    case diamonds900  = "com.aidream.diamonds.900"  // $4.99 → 800 + 100 bonus = 900
    case diamonds2000 = "com.aidream.diamonds.2000" // $9.99 → 1800 + 200 bonus = 2000
    case diamonds5000 = "com.aidream.diamonds.5000" // $19.99 → 4000 + 1000 bonus = 5000
    case premiumWeekly = "com.aidream.premium.weekly"
    case premiumMonthly = "com.aidream.premium.monthly"
    case premiumLifetime = "com.aidream.premium.lifetime"

    var baseDiamonds: Int {
        switch self {
        case .diamonds300:  return 300
        case .diamonds900:  return 800
        case .diamonds2000: return 1800
        case .diamonds5000: return 4000
        case .premiumWeekly: return 1000
        case .premiumMonthly: return 3000
        case .premiumLifetime: return 30000
        }
    }

    var bonusDiamonds: Int {
        switch self {
        case .diamonds300:  return 0
        case .diamonds900:  return 100
        case .diamonds2000: return 200
        case .diamonds5000: return 1000
        default: return 0
        }
    }

    var diamondAmount: Int { baseDiamonds + bonusDiamonds }

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
    @Published var purchasedIdentifiers = Set<String>()
    @Published var isLoadingProducts = false
    @Published var isPurchasing = false
    @Published var purchaseError: String?
    @Published var productsLoaded = false

    private var transactionListener: Task<Void, Error>?

    private init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await updateCustomerProductStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    func updateCustomerProductStatus() async {
        var purchasedIds = Set<String>()

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.revocationDate == nil {
                    purchasedIds.insert(transaction.productID)
                }
            }
        }

        self.purchasedIdentifiers = purchasedIds
        UserService.shared.setPremium(!purchasedIds.isEmpty)
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
            try await AppStore.sync()
            await updateCustomerProductStatus()
        } catch {
            purchaseError = "Restore failed"
        }
    }

    private func handleTransaction(_ transaction: Transaction) async {
        guard let productID = StoreProductID(rawValue: transaction.productID) else { return }

        let userService = UserService.shared

        if productID.isSubscription {
            // 订阅发放赠送钻石 (仅在首次购买或续订时，StoreKit 2 会通过 updates 监听到)
            // 注意：实际生产中钻石赠送逻辑通常由后端校验 receipt 后发放，
            // 纯前端实现需防重。这里简单处理。
            let amount = productID.diamondAmount
            if amount > 0 {
                userService.addDiamonds(amount, reason: "\(productID.rawValue) Subscription Bonus")
            }
        } else {
            // 普通钻石充值
            userService.addDiamonds(productID.diamondAmount, reason: "Purchase")
        }

        await updateCustomerProductStatus()
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

import Foundation
import StoreKit
import OSLog

private let logger = Logger(subsystem: "com.aidream", category: "StoreKit")

// MARK: - Product ID Constants
enum StoreProductID: String, CaseIterable {
    case diamonds100  = "com.aidream.diamonds.100"
    case diamonds500  = "com.aidream.diamonds.500"
    case diamonds1200 = "com.aidream.diamonds.1200"
    case diamonds3000 = "com.aidream.diamonds.3000"
    case premiumMonthly = "com.aidream.premium.monthly"

    var diamondAmount: Int {
        switch self {
        case .diamonds100:  return 100
        case .diamonds500:  return 500
        case .diamonds1200: return 1200
        case .diamonds3000: return 3000
        case .premiumMonthly: return 0
        }
    }

    var isSubscription: Bool {
        self == .premiumMonthly
    }
}

// MARK: - StoreKit Service
@MainActor
final class StoreKitService: ObservableObject {
    static let shared = StoreKitService()

    @Published var diamondProducts: [Product] = []
    @Published var subscriptionProduct: Product?
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

    // MARK: - Load Products
    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        let allIDs = StoreProductID.allCases.map(\.rawValue)
        do {
            let products = try await Product.products(for: allIDs)

            diamondProducts = products
                .filter { !StoreProductID(rawValue: $0.id)?.isSubscription ?? false }
                .sorted { ($0.price as Decimal) < ($1.price as Decimal) }

            subscriptionProduct = products.first {
                StoreProductID(rawValue: $0.id)?.isSubscription ?? false
            }

            productsLoaded = true
            logger.info("Loaded \(self.diamondProducts.count) diamond products, subscription: \(self.subscriptionProduct != nil)")
        } catch {
            logger.error("Failed to load products: \(error.localizedDescription)")
            purchaseError = "Unable to connect to App Store"
        }
    }

    // MARK: - Purchase
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
                logger.info("Purchase succeeded: \(product.id)")
                return true

            case .userCancelled:
                logger.info("User cancelled purchase: \(product.id)")
                return false

            case .pending:
                logger.info("Purchase pending: \(product.id)")
                purchaseError = "Payment pending — will complete shortly"
                return false

            @unknown default:
                purchaseError = "Unknown purchase result"
                return false
            }
        } catch {
            logger.error("Purchase failed: \(error.localizedDescription)")
            purchaseError = error.localizedDescription
            return false
        }
    }

    // MARK: - Restore
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
            logger.info("Purchases restored")
        } catch {
            logger.error("Restore failed: \(error.localizedDescription)")
            purchaseError = "Restore failed"
        }
    }

    // MARK: - Transaction Handling
    private func handleTransaction(_ transaction: Transaction) async {
        guard let productID = StoreProductID(rawValue: transaction.productID) else {
            logger.warning("Unknown product ID: \(transaction.productID)")
            return
        }

        let userService = UserService.shared

        switch productID {
        case .diamonds100, .diamonds500, .diamonds1200, .diamonds3000:
            let amount = productID.diamondAmount
            userService.addDiamonds(amount)
            logger.info("Added \(amount) diamonds from purchase")

        case .premiumMonthly:
            userService.setPremium(true)
            logger.info("Premium subscription activated")
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

    enum StoreError: LocalizedError {
        case unverified
        var errorDescription: String? { "Transaction could not be verified" }
    }
}

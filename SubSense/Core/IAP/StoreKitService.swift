import StoreKit
import Observation

@Observable
final class StoreKitService {
    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var isPurchasing = false
    var purchaseError: String?

    private var updateListenerTask: Task<Void, Error>?

    init() {
        updateListenerTask = listenForTransactions()
        Task { await fetchProducts() }
    }

    deinit { updateListenerTask?.cancel() }

    // MARK: - Fetch products
    func fetchProducts() async {
        do {
            products = try await Product.products(for: ProductID.all)
                .sorted { $0.price < $1.price }
            await updatePurchasedStatus()
        } catch {
            print("[StoreKit] Failed to fetch products: \(error)")
        }
    }

    // MARK: - Purchase
    func purchase(_ product: Product) async throws {
        isPurchasing = true
        defer { isPurchasing = false }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedStatus()
            await transaction.finish()
        case .userCancelled:
            break
        case .pending:
            break
        @unknown default:
            break
        }
    }

    // MARK: - Restore
    func restorePurchases() async {
        try? await AppStore.sync()
        await updatePurchasedStatus()
    }

    // MARK: - Check entitlement
    var isPro: Bool {
        purchasedProductIDs.contains(ProductID.proMonthly) ||
        purchasedProductIDs.contains(ProductID.proYearly)
    }

    var monthlyProduct: Product? {
        products.first { $0.id == ProductID.proMonthly }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == ProductID.proYearly }
    }

    // MARK: - Private helpers
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if let transaction = try? self.checkVerified(result) {
                    await self.updatePurchasedStatus()
                    await transaction.finish()
                }
            }
        }
    }

    private func updatePurchasedStatus() async {
        var purchased: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                purchased.insert(transaction.productID)
            }
        }
        purchasedProductIDs = purchased
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}

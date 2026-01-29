//
//  SubscriptionManager.swift
//  MusicNote
//
//  Created by Jeremy Bastidas on 1/8/26.
//

import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {

    static let shared = SubscriptionManager()

    @Published private(set) var isPro = false
    @Published private(set) var products: [Product] = []

    private let productIDs: Set<String> = [
        "com.BlankStudio.MusicNote",
        "com.BlankStudio.MusicNote.pro.yearly"
    ]

    private init() {
        Task {
            await loadProducts()
            await refreshStatus()
            await listenForTransactions()
        }
    }

    // MARK: - Products

    func loadProducts() async {
        do {
            products = try await Product.products(for: productIDs)
            print("✅ Loaded products:", products.map { $0.id })
        } catch {
            print("❌ Failed to load products:", error)
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        if case .success(let verification) = result,
           case .verified(_) = verification {
            isPro = true
        }
    }

    // MARK: - Restore

    func restore() async {
        try? await AppStore.sync()
        await refreshStatus()
    }

    // MARK: - Status

    func refreshStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               productIDs.contains(transaction.productID) {
                isPro = true
                return
            }
        }
        isPro = false
    }

    // MARK: - Listen for updates

    private func listenForTransactions() async {
        for await update in Transaction.updates {
            if case .verified(let transaction) = update,
               productIDs.contains(transaction.productID) {
                isPro = true
            }
        }
    }
}

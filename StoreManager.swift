//
//  StoreManager.swift
//  towerlogicstrategicgame
//
//  StoreKit 2 wrapper for the four consumable point packs.
//
//  Before shipping, register these product IDs in App Store Connect as
//  CONSUMABLE in-app purchases (matching the IDs in PointBundle.all):
//      pack.small   — 50 points
//      pack.medium  — 200 points
//      pack.large   — 500 points
//      pack.huge    — 1200 points
//
//  For local development, add a `.storekit` configuration file to the scheme
//  with the same IDs so the StoreKit sheet appears during testing.
//

import Foundation
import StoreKit
import Observation

@MainActor
@Observable
final class StoreManager {
    static let shared = StoreManager()

    private static let productIDs: Set<String> = Set(PointBundle.all.map(\.id))

    private(set) var products: [Product] = []
    private(set) var isPurchasing: Bool = false
    private(set) var lastError: String? = nil

    private var updatesTask: Task<Void, Never>?

    private init() {
        // Listen for any transaction updates (e.g. from another device, Family Sharing,
        // interrupted purchases that completed later).
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(verification: result)
            }
        }
        Task { await self.load() }
    }

    // Singleton lives for app lifetime — no deinit cleanup needed.

    /// Fetches product metadata + localized prices from the App Store.
    func load() async {
        do {
            let fetched = try await Product.products(for: Self.productIDs)
            self.products = fetched.sorted { $0.price < $1.price }
        } catch {
            self.lastError = "Couldn't load store: \(error.localizedDescription)"
        }
    }

    /// Localized price (e.g. "$0.09", "₹9", "€0,09") for a bundle ID, when StoreKit
    /// has loaded products. Returns nil if not yet loaded — caller should fall back
    /// to `PointBundle.priceTag`.
    func displayPrice(for bundleID: String) -> String? {
        products.first(where: { $0.id == bundleID })?.displayPrice
    }

    /// Begin the IAP flow for a bundle. Returns true on success.
    @discardableResult
    func purchase(_ bundle: PointBundle) async -> Bool {
        guard let product = products.first(where: { $0.id == bundle.id }) else {
            lastError = "Product not available"
            return false
        }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                BazaarStore.shared.grantPersistentPoints(bundle.grant)
                await transaction.finish()
                return true
            case .userCancelled:
                return false
            case .pending:
                // Awaiting parental approval / SCA — handled when Transaction.updates fires.
                return false
            @unknown default:
                return false
            }
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    /// Re-syncs entitlements with the App Store. For consumables there's no entitlement
    /// to restore, but Apple requires the affordance for any IAP-bearing app.
    func restorePurchases() async {
        do { try await AppStore.sync() } catch {
            lastError = "Couldn't restore: \(error.localizedDescription)"
        }
    }

    // MARK: - Helpers

    private func handle(verification: VerificationResult<Transaction>) async {
        guard let transaction = try? checkVerified(verification) else { return }
        if let bundle = PointBundle.all.first(where: { $0.id == transaction.productID }) {
            BazaarStore.shared.grantPersistentPoints(bundle.grant)
        }
        await transaction.finish()
    }

    private enum StoreError: Error { case failedVerification }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreError.failedVerification
        case .verified(let payload): return payload
        }
    }
}

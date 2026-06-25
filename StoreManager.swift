//
//  StoreManager.swift
//  AntaYuga
//
//  StoreKit 2 wrapper for the three consumable Bazaar Point packs.
//
//  Before shipping, register these product IDs in App Store Connect as
//  CONSUMABLE in-app purchases (must match `PointBundle.all` in
//  BazaarStore.swift):
//
//      pack.small   →  1,000 Bazaar Points   →  Tier 1 ($0.99)
//      pack.medium  →  3,500 Bazaar Points   →  Tier 3 ($2.99)
//      pack.large   →  9,000 Bazaar Points   →  Tier 5 ($4.99)
//
//  In App Store Connect → My Apps → (your app) → Features → In-App
//  Purchases → "+" → Consumable, set:
//      • Reference Name: "Starter Bazaar Pack" / "Hero Bazaar Pack" / "Maharaja Bazaar Pack"
//      • Product ID: pack.small  /  pack.medium  /  pack.large
//      • Cleared for Sale: yes
//      • Price Tier: 1 / 3 / 5 (or whatever localizes to $0.99 / $2.99 / $4.99)
//      • Display Name + Description (any language you support)
//      • Review Screenshot (1024×1024 of the in-game bazaar)
//
//  For local development, add a `.storekit` configuration file to the
//  scheme with the same IDs so the StoreKit sheet appears during testing.
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

//
//  BazaarStore.swift
//  towerlogicstrategicgame
//
//  Bazaar points are PER-RUN (live on GameViewModel.points) — earned from
//  enemy kills and wave clears, and wiped on every reset. Nothing carries
//  between matches.
//
//  This store only persists `ownedPermanent` — a small set of one-time
//  unlocks the player can splurge on with in-run points (ownership sticks
//  even though the points themselves reset).
//

import SwiftUI
import Observation

// MARK: - Item catalogue

enum BazaarItemKind {
    case instant
    case runBuff
    case permanent
}

enum BazaarItem: String, CaseIterable, Identifiable, Codable {
    case goldPouch
    case warVeda
    case ironCache
    case sageTech
    case jyotishaBlessing
    case healersBoon
    case waveTribute
    case waveVedaTithe
    case longDefender

    var id: String { rawValue }

    var kind: BazaarItemKind {
        switch self {
        case .goldPouch, .warVeda, .ironCache, .sageTech, .jyotishaBlessing, .healersBoon:
            return .instant
        case .waveTribute, .waveVedaTithe:
            return .runBuff
        case .longDefender:
            return .permanent
        }
    }

    var displayName: String {
        switch self {
        case .goldPouch:        return "Gold Pouch"
        case .warVeda:          return "War Veda"
        case .ironCache:        return "Iron Cache"
        case .sageTech:         return "Sage's Tech"
        case .jyotishaBlessing: return "Jyotisha Blessing"
        case .healersBoon:      return "Healer's Boon"
        case .waveTribute:      return "Wave Tribute"
        case .waveVedaTithe:    return "Veda Tithe"
        case .longDefender:     return "Long Defender"
        }
    }

    var sanskritName: String {
        switch self {
        case .goldPouch:        return "Hiranya Kosha"
        case .warVeda:          return "Yuddha Veda"
        case .ironCache:        return "Loha Bhandara"
        case .sageTech:         return "Rishi Yantra"
        case .jyotishaBlessing: return "Jyotisha Aashirvada"
        case .healersBoon:      return "Aushadhi Daana"
        case .waveTribute:      return "Yuddha Daana"
        case .waveVedaTithe:    return "Veda Daana"
        case .longDefender:     return "Dirgha Rakshaka"
        }
    }

    var summary: String {
        switch self {
        case .goldPouch:        return "Instantly +400 gold"
        case .warVeda:          return "Instantly +75 veda"
        case .ironCache:        return "Instantly +100 metal"
        case .sageTech:         return "Instantly +60 tech"
        case .jyotishaBlessing: return "Instantly +80 jotisha"
        case .healersBoon:      return "Instantly +8 lives"
        case .waveTribute:      return "+30 gold every wave (this run)"
        case .waveVedaTithe:    return "+8 veda every wave (this run)"
        case .longDefender:     return "+8 starting lives every run, forever"
        }
    }

    var cost: Int {
        switch self {
        case .goldPouch:        return 30
        case .warVeda:          return 40
        case .ironCache:        return 40
        case .sageTech:         return 40
        case .jyotishaBlessing: return 60
        case .healersBoon:      return 80
        case .waveTribute:      return 100
        case .waveVedaTithe:    return 120
        case .longDefender:     return 150
        }
    }

    var icon: String {
        switch self {
        case .goldPouch:        return "bag.fill"
        case .warVeda:          return "book.closed.fill"
        case .ironCache:        return "shield.lefthalf.filled"
        case .sageTech:         return "gearshape.2.fill"
        case .jyotishaBlessing: return "sparkles"
        case .healersBoon:      return "heart.fill"
        case .waveTribute:      return "dollarsign.circle.fill"
        case .waveVedaTithe:    return "flame.fill"
        case .longDefender:     return "shield.fill"
        }
    }

    var tint: Color {
        switch self {
        case .goldPouch:        return .yellow
        case .warVeda:          return Color(red: 0.95, green: 0.55, blue: 0.20)
        case .ironCache:        return Color(red: 0.70, green: 0.72, blue: 0.78)
        case .sageTech:         return .cyan
        case .jyotishaBlessing: return Color(red: 0.80, green: 0.60, blue: 1.00)
        case .healersBoon:      return .pink
        case .waveTribute:      return .yellow
        case .waveVedaTithe:    return .orange
        case .longDefender:     return Color(red: 0.55, green: 0.85, blue: 0.55)
        }
    }
}

// MARK: - Point bundles (real-money top-ups)

/// IAP packs the player buys with cash. Points purchased here go into the
/// persistent wallet and persist across runs (unlike kill/wave points).
struct PointBundle: Identifiable, Hashable {
    let id: String
    let grant: Int
    let priceTag: String
    let label: String
    let highlight: Bool

    /// A single consumable point pack — re-purchasable any number of times.
    /// $0.99 is Apple's lowest universal price tier (Tier 1); the real
    /// localized price replaces this placeholder once StoreKit loads the
    /// product from App Store Connect.
    static let all: [PointBundle] = [
        PointBundle(id: "pack.small", grant: 250, priceTag: "$0.99", label: "Starter Pack", highlight: true)
    ]
}

// MARK: - Persistent store (permanent perks + IAP-purchased wallet)

@Observable
final class BazaarStore {
    static let shared = BazaarStore()

    private static let ownedKey  = "bazaar.owned.v1"
    private static let walletKey = "bazaar.persistentPoints.v1"

    private(set) var ownedPermanent: Set<BazaarItem>

    /// Points purchased with real money. Carries across runs.
    /// (Per-run earnings live on GameViewModel.points and reset each game.)
    private(set) var persistentPoints: Int

    private init() {
        if let arr = UserDefaults.standard.array(forKey: Self.ownedKey) as? [String] {
            self.ownedPermanent = Set(arr.compactMap(BazaarItem.init(rawValue:)))
                .filter { $0.kind == .permanent }
        } else {
            self.ownedPermanent = []
        }
        self.persistentPoints = UserDefaults.standard.integer(forKey: Self.walletKey)
    }

    func ownsPermanent(_ item: BazaarItem) -> Bool { ownedPermanent.contains(item) }

    /// Caller is responsible for deducting points from the per-run wallet first.
    func recordPermanent(_ item: BazaarItem) {
        guard item.kind == .permanent else { return }
        ownedPermanent.insert(item)
        UserDefaults.standard.set(Array(ownedPermanent).map(\.rawValue), forKey: Self.ownedKey)
    }

    /// Add IAP-granted points to the persistent wallet.
    func grantPersistentPoints(_ amount: Int) {
        guard amount > 0 else { return }
        persistentPoints += amount
        UserDefaults.standard.set(persistentPoints, forKey: Self.walletKey)
    }

    /// Deduct up to `amount` from the persistent wallet. Returns the amount actually drained.
    @discardableResult
    func drainPersistent(_ amount: Int) -> Int {
        let take = min(amount, persistentPoints)
        if take > 0 {
            persistentPoints -= take
            UserDefaults.standard.set(persistentPoints, forKey: Self.walletKey)
        }
        return take
    }

    // MARK: - Permanent-perk effects

    var bonusStartingLives: Int { ownsPermanent(.longDefender) ? 8 : 0 }
}

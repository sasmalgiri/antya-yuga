//
//  BazaarStore.swift
//  AntaYuga
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

// MARK: - Graphics quality

/// Player-selectable rendering quality. `.full` runs the original tower
/// animations (30 fps timeline, blendModes, glow shadows on every ring /
/// stone / sigil). `.optimized` halves the frame rate and drops the most
/// expensive composites — fewer GPU cycles per frame, still readable.
enum GraphicsQuality: String, CaseIterable, Identifiable, Codable {
    case full
    case optimized

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .full:      return "Full Animations"
        case .optimized: return "Optimized"
        }
    }

    var summary: String {
        switch self {
        case .full:      return "All glow / blend / shadow effects, 30 fps tower timeline."
        case .optimized: return "Trimmed blends + shadows, 15 fps tower timeline. Smoother on older devices."
        }
    }

    var symbol: String {
        switch self {
        case .full:      return "sparkles"
        case .optimized: return "bolt.fill"
        }
    }

    var tint: Color {
        switch self {
        case .full:      return .yellow
        case .optimized: return .cyan
        }
    }
}

@Observable
final class GraphicsSettings {
    static let shared = GraphicsSettings()
    private static let key = "graphics.quality.v1"

    var quality: GraphicsQuality {
        didSet {
            UserDefaults.standard.set(quality.rawValue, forKey: Self.key)
        }
    }

    /// Convenience flags read by the render code.
    var isFull: Bool { quality == .full }
    var isOptimized: Bool { quality == .optimized }

    private init() {
        if let raw = UserDefaults.standard.string(forKey: Self.key),
           let q = GraphicsQuality(rawValue: raw) {
            self.quality = q
        } else {
            // Default to optimized — safer on older hardware. Players who
            // want the original eye-candy can flip to .full on the title
            // screen at any time.
            self.quality = .optimized
        }
    }
}

// MARK: - Difficulty

/// Three difficulty modes the player picks on race-select. ONLY resource
/// production scales — the enemy curve, HP, damage, and drop math are
/// identical across modes. Easier modes give the player more breathing
/// room to experiment without changing the gameplay shape.
enum GameDifficulty: String, CaseIterable, Identifiable, Codable {
    case easy
    case intermediate
    case hard

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .easy:         return "Easy"
        case .intermediate: return "Intermediate"
        case .hard:         return "Hard"
        }
    }

    var summary: String {
        switch self {
        case .easy:         return "Resources flow 2× faster. Forgiving — best for first runs."
        case .intermediate: return "Resources flow 1.5× faster. Tight but fair."
        case .hard:         return "Default. Resources at 1×. The Anta as it was written."
        }
    }

    /// Building production rate multiplier. Combat is unchanged.
    var productionMultiplier: Double {
        switch self {
        case .easy:         return 2.0
        case .intermediate: return 1.5
        case .hard:         return 1.0
        }
    }

    var symbol: String {
        switch self {
        case .easy:         return "leaf.fill"
        case .intermediate: return "scalemass.fill"
        case .hard:         return "flame.fill"
        }
    }

    var tint: Color {
        switch self {
        case .easy:         return .green
        case .intermediate: return .yellow
        case .hard:         return .red
        }
    }
}

// MARK: - Item catalogue

enum BazaarItemKind {
    case instant
    case runBuff
    case permanent
}

enum BazaarItem: String, CaseIterable, Identifiable, Codable {
    case goldPouch
    case goldVault          // 100 pts → 3,500 gold  (35 g/pt)
    case goldTreasury       // 500 pts → 20,000 gold (40 g/pt)
    case goldHoard          // 1000 pts → 50,000 gold (50 g/pt)
    case akshayaPatra       // 100 pts → 2.5k gold + 1.6k of every other resource
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
        case .goldPouch, .goldVault, .goldTreasury, .goldHoard, .akshayaPatra,
             .warVeda, .ironCache, .sageTech, .jyotishaBlessing, .healersBoon:
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
        case .goldVault:        return "Gold Vault"
        case .goldTreasury:     return "Gold Treasury"
        case .goldHoard:        return "Gold Hoard"
        case .akshayaPatra:     return "Akshaya Patra"
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
        case .goldVault:        return "Hiranya Bhandara"
        case .goldTreasury:     return "Hiranya Nidhi"
        case .goldHoard:        return "Hiranya Sagara"
        case .akshayaPatra:     return "Akshaya Patra"   // the Mahabharata's inexhaustible vessel
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
        case .goldVault:        return "Instantly +3,500 gold (premium rate)"
        case .goldTreasury:     return "Instantly +20,000 gold (better rate)"
        case .goldHoard:        return "Instantly +50,000 gold (best rate)"
        case .akshayaPatra:     return "Instantly +2,500 g + 1,600 of every other resource"
        case .warVeda:          return "Instantly +75 veda"
        case .ironCache:        return "Instantly +100 metal"
        case .sageTech:         return "Instantly +60 tech"
        case .jyotishaBlessing: return "Instantly +80 jotisha"
        case .healersBoon:      return "Instantly +25 lives"
        case .waveTribute:      return "+2000 gold at the start of every wave (this run)"
        case .waveVedaTithe:    return "+30 veda at the start of every wave (this run)"
        case .longDefender:     return "+25 starting lives every run, forever"
        }
    }

    var cost: Int {
        switch self {
        case .goldPouch:        return 30
        case .goldVault:        return 100   // 100 pts → 3,500 gold (35 g/pt)
        case .goldTreasury:     return 500   // 500 pts → 20,000 gold (40 g/pt)
        case .goldHoard:        return 1000  // 1,000 pts → 50,000 gold (50 g/pt — best deal)
        case .akshayaPatra:     return 100   // 100 pts → 2.5k g + 1.6k of every other resource
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
        case .goldVault:        return "lock.fill"
        case .goldTreasury:     return "archivebox.fill"
        case .goldHoard:        return "crown.fill"
        case .akshayaPatra:     return "cup.and.saucer.fill"
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
        case .goldVault:        return .yellow
        case .goldTreasury:     return .yellow
        case .goldHoard:        return .yellow
        case .akshayaPatra:     return Color(red: 0.95, green: 0.55, blue: 0.20)
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

    /// Three consumable point packs with increasing value-per-dollar.
    /// Each pack is re-purchasable any number of times. Placeholder prices
    /// match Apple's standard tiers; StoreKit overrides with the player's
    /// real localized price at runtime.
    ///
    /// Value scaling rewards the upsell:
    ///   Starter:  1000 / 0.99 ≈ 1010 pts/$
    ///   Hero:     3500 / 2.99 ≈ 1170 pts/$
    ///   Maharaja: 9000 / 4.99 ≈ 1804 pts/$
    static let all: [PointBundle] = [
        PointBundle(id: "pack.small",  grant: 1000, priceTag: "$0.99", label: "Starter",   highlight: false),
        PointBundle(id: "pack.medium", grant: 3500, priceTag: "$2.99", label: "Hero",      highlight: true),
        PointBundle(id: "pack.large",  grant: 9000, priceTag: "$4.99", label: "Maharaja",  highlight: false)
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

    var bonusStartingLives: Int { ownsPermanent(.longDefender) ? 25 : 0 }
}

// MARK: - First-time hints

/// Tutorial hints shown the first time a player encounters a new game
/// element. Each hint's rawValue is persisted in UserDefaults — once
/// dismissed, that hint never reappears, even across runs or app launches.
enum GameHint: String, CaseIterable, Identifiable {
    // Core onboarding
    case firstWaveStart       // first time a wave actually begins
    case firstBuildSlot       // first opening of a tower/building menu
    case firstAuraUnlock      // Treta yug — heal aura available
    case firstShieldAura      // Dvapara yug — shield aura available

    // Economy
    case firstResourceWave    // Resource Wave banner appearance
    case firstBazaarPoint     // earned the first Bazaar point of the run

    // Endgame
    case sudarshanArrived     // Dvapara unlocked, Sudarshan centre tower appeared
    case kaliYugaArrived      // Wave 24 boss enters the field
    case amritaKalashReady    // score ≥ Kalash threshold for the first time
    case rahuEclipse          // Rahu devours the Kalash → empowered phase
    case empoweredBoss        // empowered Kali Yuga spawned
    case parijataAvailable    // Parijata Briksha unlocked
    case kalashRevealed       // first time the Amrit Kalash flashes inside the boss
    case sudarshanInDanger    // Sudarshan HP first dipped below 75%

    // UI features added recently
    case quickBuildBar        // first time the quick-build HUD row is visible
    case autoStartToggle      // first time the Auto toggle is visible
    case autoAuraToggle       // first time the Aura toggle is visible
    case wallButton           // first time the Wall button is visible
    case godModeUnlock        // first time the God Mode button becomes usable (W8)
    case relocateTower        // first time the TowerMenu's Relocate tile is rendered
    case speedToggle          // first time the speed toggle is tapped
    case pauseButton          // first time the pause button is tapped
    case holdToCharge         // first time the Sudarshan Feed button appears
    case bossInfoCard         // first time a boss info card appears
    case longPressForInfo     // very first turn — teach the universal "press to learn" gesture

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstWaveStart:     return "Defend the Path"
        case .firstBuildSlot:     return "Build to Survive"
        case .firstAuraUnlock:    return "Heal Aura Unlocked"
        case .firstShieldAura:    return "Shield Aura Unlocked"
        case .firstResourceWave:  return "Resource Wave!"
        case .firstBazaarPoint:   return "Bazaar Points"
        case .sudarshanArrived:   return "The Sudarshan Awakens"
        case .kaliYugaArrived:    return "Kali Yuga Approaches"
        case .amritaKalashReady:  return "Amrit Kalash Ready"
        case .rahuEclipse:        return "Rahu's Eclipse"
        case .empoweredBoss:      return "Kali Yuga Reborn"
        case .parijataAvailable:  return "Parijata Briksha"
        case .kalashRevealed:     return "Strike the Kalash"
        case .sudarshanInDanger:  return "Heal the Sudarshan"
        case .quickBuildBar:      return "Quick-Build Bar"
        case .autoStartToggle:    return "Auto-Start Waves"
        case .autoAuraToggle:     return "Auto-Buy Auras"
        case .wallButton:         return "Wall Defence"
        case .godModeUnlock:      return "Pralay Unlocked"
        case .relocateTower:      return "Relocate a Tower"
        case .speedToggle:        return "Speed up the Game"
        case .pauseButton:        return "Pause to Plan"
        case .holdToCharge:       return "Hold to Charge"
        case .bossInfoCard:       return "Boss Info Card"
        case .longPressForInfo:   return "Long-Press to Learn"
        }
    }

    var body: String {
        switch self {
        case .firstWaveStart:
            return "Enemies follow the marked path toward the centre. Tap an empty slot to place defences before they break through."
        case .firstBuildSlot:
            return "Towers (left tab) attack — Buildings (right tab) generate resources. Spend gold first; rarer resources unlock higher tiers."
        case .firstAuraUnlock:
            return "Tap any tower to toggle a Heal Aura. It restores nearby towers under fire. Up to three tiers."
        case .firstShieldAura:
            return "A new Shield Aura now toggles on towers — it dampens incoming damage in its radius. Stack with Heal Aura on key defenders."
        case .firstResourceWave:
            return "Every seventh wave, enemies drop bonus resources. A great moment to splurge on upgrades."
        case .firstBazaarPoint:
            return "Bazaar points spawn from kills and wave clears. Tap the storefront in the top bar to spend on instant boosts, run-buffs, or permanent perks."
        case .sudarshanArrived:
            return "The Sudarshan Chakra has appeared at the centre. Tap it to feed resources — once charged AND Kali Yuga arrives, it ignites."
        case .kaliYugaArrived:
            return "The final boss has entered the field. Keep your towers alive and finish charging the Sudarshan — only the chakra can fell him."
        case .amritaKalashReady:
            return "Your score has earned an Amrit Kalash. Tap it from the bottom bar to instantly restore lives — saves you in a pinch."
        case .rahuEclipse:
            return "Rahu has swallowed the Kalash. Kali Yuga drinks the nectar and rises again, regenerating between strikes."
        case .empoweredBoss:
            return "The empowered Kali Yuga regenerates HP every second. Charge the Trimurti to hit him — and watch the Sudarshan's own HP."
        case .parijataAvailable:
            return "Plant the Parijata Briksha on any open slot. The wish-tree grants every resource at once — your fastest path to charging the Trimurti."
        case .kalashRevealed:
            return "The Amrit Kalash inside his body flashes when you hit him. The chip damage is landing — keep charging."
        case .sudarshanInDanger:
            return "The Sudarshan tower is wounded. Use the Heal Sudarshan button before it falls — losing the relic ends the run."
        case .quickBuildBar:
            return "The row of tower & building icons in the HUD is the quick-build bar. Tap an icon to ARM it, then tap any empty slot to drop that defence in one tap. Tap the icon again to disarm."
        case .autoStartToggle:
            return "Auto: when on, the next wave starts automatically after a short countdown. Tap the countdown badge to cancel just that one timer."
        case .autoAuraToggle:
            return "Aura: when on, every tower auto-upgrades its Heal then Shield aura between waves if you can afford the next tier. Saves taps in the late game."
        case .wallButton:
            return "Wall: pays 600g+80j+80v to fully heal every tower AND grant a 1,200-HP shield to each — lasts the current wave. Use it before a tough boss wave."
        case .godModeUnlock:
            return "Pralay unlocks at Wave 8! The cosmic dissolution — for 12 seconds every resource building fires divine beams at enemies. Premium cost: 3,500g + 400m + 300t + 400j + 400v. A real panic button."
        case .relocateTower:
            return "Tap a tower → Relocate. The tower keeps its HP, kills, auras, and stones — only its slot changes. T1 relocate is FREE; higher tiers cost a small fee."
        case .speedToggle:
            return "Speed cycle: 1× → 2× → 4× → 8× → 1×. Speeds up the simulation for grinding mid-waves. Visual cues stay synced — physics is rate-capped to stay accurate."
        case .pauseButton:
            return "Pause freezes the game while still letting you tap towers and slots to plan. Resume to continue. Great for emergencies."
        case .holdToCharge:
            return "The Feed button on the Sudarshan can be HELD — it auto-taps every 0.35 s while you keep your finger down. Saves you 8 separate taps to fully charge."
        case .bossInfoCard:
            return "When a boss spawns, an info card appears top-right for 6 seconds showing its weakness. Tap the boss enemy any time to bring it back."
        case .longPressForInfo:
            return "PRO TIP — long-press (hold for half a second) ANY visible element to read its story: lives, score, race pill, resource & stone pills, towers, buildings, the central Sudarshan, even the Pralay button. Info banners are SUPPRESSED while a wave is running so they don't cover the fight — between waves they pop the moment you long-press. " +
            "ALSO NEW: every divine-path tower you build adds +25 max HP to the central relic. Each divine-tower kill on a boss earns a divine point that empowers the Parijata Briksha (dormant until your first divine tower). Pralay's cost rises 1.75× per use — the last burn is the most expensive. The 📖 Guide button in the HUD has the full reference."
        }
    }

    var icon: String {
        switch self {
        case .firstWaveStart:     return "flag.checkered"
        case .firstBuildSlot:     return "hammer.fill"
        case .firstAuraUnlock:    return "cross.case.fill"
        case .firstShieldAura:    return "shield.lefthalf.filled"
        case .firstResourceWave:  return "sparkles"
        case .firstBazaarPoint:   return "storefront.fill"
        case .sudarshanArrived:   return "circle.hexagongrid.fill"
        case .kaliYugaArrived:    return "exclamationmark.triangle.fill"
        case .amritaKalashReady:  return "drop.fill"
        case .rahuEclipse:        return "moon.fill"
        case .empoweredBoss:      return "flame.fill"
        case .parijataAvailable:  return "tree.fill"
        case .kalashRevealed:     return "trophy.fill"
        case .sudarshanInDanger:  return "cross.case.fill"
        case .quickBuildBar:      return "burst.fill"
        case .autoStartToggle:    return "play.square.fill"
        case .autoAuraToggle:     return "cross.case.fill"
        case .wallButton:         return "shield.lefthalf.filled"
        case .godModeUnlock:      return "sparkles"
        case .relocateTower:      return "arrow.up.and.down.and.arrow.left.and.right"
        case .speedToggle:        return "forward.fill"
        case .pauseButton:        return "pause.fill"
        case .holdToCharge:       return "circle.hexagongrid.fill"
        case .bossInfoCard:       return "exclamationmark.bubble.fill"
        case .longPressForInfo:   return "hand.tap.fill"
        }
    }

    var tint: Color {
        switch self {
        case .firstWaveStart:     return .cyan
        case .firstBuildSlot:     return .yellow
        case .firstAuraUnlock:    return .pink
        case .firstShieldAura:    return Color(red: 0.55, green: 0.85, blue: 0.55)
        case .firstResourceWave:  return .yellow
        case .firstBazaarPoint:   return Color(red: 0.78, green: 0.52, blue: 0.95)
        case .sudarshanArrived:   return .yellow
        case .kaliYugaArrived:    return .red
        case .amritaKalashReady:  return .cyan
        case .rahuEclipse:        return Color(red: 0.55, green: 0.30, blue: 0.78)
        case .empoweredBoss:      return .orange
        case .parijataAvailable:  return Color(red: 0.45, green: 0.95, blue: 0.55)
        case .kalashRevealed:     return .yellow
        case .sudarshanInDanger:  return .blue
        case .quickBuildBar:      return .orange
        case .autoStartToggle:    return .cyan
        case .autoAuraToggle:     return Color(red: 0.30, green: 0.95, blue: 0.55)
        case .wallButton:         return .green
        case .godModeUnlock:      return Color(red: 1.0, green: 0.85, blue: 0.25)
        case .relocateTower:      return .cyan
        case .speedToggle:        return .orange
        case .pauseButton:        return .green
        case .holdToCharge:       return .yellow
        case .bossInfoCard:       return .red
        case .longPressForInfo:   return .cyan
        }
    }
}

@Observable
final class HintsStore {
    static let shared = HintsStore()

    private static let key = "hints.seen.v1"

    /// Hints the player has already dismissed (never shows again).
    private var seen: Set<String>

    /// The hint currently displayed. nil means no hint is on screen.
    var active: GameHint? = nil

    /// Queue for hints triggered while another is on screen — drained on dismiss.
    private var pending: [GameHint] = []

    private init() {
        if let arr = UserDefaults.standard.array(forKey: Self.key) as? [String] {
            self.seen = Set(arr)
        } else {
            self.seen = []
        }
    }

    /// Returns true if this is the very first time the hint has been triggered
    /// (and therefore was queued/shown). Subsequent calls return false.
    @discardableResult
    func trigger(_ hint: GameHint) -> Bool {
        guard !seen.contains(hint.rawValue) else { return false }
        // Mark it seen immediately so re-triggers within the same frame don't
        // queue duplicates. UserDefaults persists synchronously but is cheap.
        seen.insert(hint.rawValue)
        UserDefaults.standard.set(Array(seen), forKey: Self.key)
        if active == nil {
            active = hint
        } else if !pending.contains(hint) {
            pending.append(hint)
        }
        return true
    }

    /// Dismiss the active hint and advance the queue.
    func dismiss() {
        active = nil
        if !pending.isEmpty {
            active = pending.removeFirst()
        }
    }

    /// Re-show every hint on next trigger — for a debug toggle if ever needed.
    func resetAll() {
        seen.removeAll()
        UserDefaults.standard.removeObject(forKey: Self.key)
    }
}

/// Universal tooltip manager — long-pressing any interactive UI element
/// summons a brief informational banner explaining what it does. Unlike
/// HintsStore (one-shot first-time hints), tooltips can be re-summoned
/// every time the player asks.
@Observable
final class TooltipManager {
    static let shared = TooltipManager()

    /// Currently visible tooltip. nil means nothing on screen.
    var active: TooltipPayload? = nil
    /// Timer in seconds before auto-dismiss.
    private var dismissTimer: TimeInterval = 0
    /// When true, `show()` becomes a no-op AND any currently visible
    /// tooltip is cleared. Set by the GameViewModel during active waves
    /// so info banners don't block the player's view of the battlefield.
    var suppressed: Bool = false {
        didSet {
            if suppressed { active = nil; dismissTimer = 0 }
        }
    }

    /// Minimum on-screen time so even one-word tooltips can be read.
    private static let minDismiss: TimeInterval = 6.0
    /// Hard cap so the player isn't stuck with a banner blocking gameplay.
    private static let maxDismiss: TimeInterval = 18.0
    /// Generous reading speed — about 165 wpm = 2.75 words/sec. Tuned
    /// toward "comfortable reading" rather than "skim", since tooltips
    /// often contain numeric breakdowns the player needs to absorb.
    private static let wordsPerSecond: Double = 2.75

    /// Show a tooltip with the given title + body text. The on-screen time
    /// scales with how much text there is to read — short pills get the
    /// minimum 6 s, dense story-style bodies get up to 18 s. Tap dismisses
    /// early via `dismiss()` regardless. NO-OP while `suppressed` (waves).
    func show(title: String, body: String,
              icon: String = "info.circle.fill",
              tint: Color = .cyan,
              maxDuration: TimeInterval? = nil) {
        guard !suppressed else { return }
        active = TooltipPayload(title: title, body: body, icon: icon, tint: tint)
        let wordCount = (title + " " + body)
            .split(whereSeparator: { $0.isWhitespace })
            .count
        let readingTime = Double(wordCount) / Self.wordsPerSecond
        var dismiss = min(Self.maxDismiss, max(Self.minDismiss, readingTime))
        // Caller-supplied hard cap — e.g. fast-paced overlays that
        // shouldn't linger across a wave.
        if let cap = maxDuration { dismiss = min(dismiss, cap) }
        dismissTimer = dismiss
    }

    /// Drive the auto-dismiss from the game tick (or any periodic update).
    func tick(_ dt: TimeInterval) {
        guard dismissTimer > 0 else { return }
        dismissTimer = max(0, dismissTimer - dt)
        if dismissTimer == 0 { active = nil }
    }

    /// Tap-to-dismiss.
    func dismiss() {
        active = nil
        dismissTimer = 0
    }
}

struct TooltipPayload {
    let title: String
    let body: String
    let icon: String
    let tint: Color
}

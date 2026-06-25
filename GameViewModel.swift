//
//  GameViewModel.swift
//  AntaYuga
//
//  Tower defence with Indian dynasties, multi-resource economy,
//  resource-generating buildings, and astra evolution paths.
//

import SwiftUI
import Observation

// MARK: - Resource

enum ResourceKind: String, CaseIterable, Identifiable {
    case gold, metal, tech, jotisha, veda

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gold:    return "Gold"
        case .metal:   return "Metal"
        case .tech:    return "Tech"
        case .jotisha: return "Jotisha"
        case .veda:    return "Veda"
        }
    }

    var symbol: String {
        switch self {
        case .gold:    return "dollarsign.circle.fill"
        case .metal:   return "gearshape.fill"
        case .tech:    return "cpu.fill"
        case .jotisha: return "moon.stars.fill"
        case .veda:    return "book.closed.fill"
        }
    }

    var color: Color {
        switch self {
        case .gold:    return .yellow
        case .metal:   return Color(red: 0.78, green: 0.78, blue: 0.85)
        case .tech:    return .cyan
        case .jotisha: return .purple
        case .veda:    return .orange
        }
    }
}

struct Resources: Equatable {
    var gold: Int = 0
    var metal: Int = 0
    var tech: Int = 0
    var jotisha: Int = 0
    var veda: Int = 0

    func amount(_ kind: ResourceKind) -> Int {
        switch kind {
        case .gold:    return gold
        case .metal:   return metal
        case .tech:    return tech
        case .jotisha: return jotisha
        case .veda:    return veda
        }
    }

    mutating func add(_ kind: ResourceKind, _ value: Int) {
        switch kind {
        case .gold:    gold += value
        case .metal:   metal += value
        case .tech:    tech += value
        case .jotisha: jotisha += value
        case .veda:    veda += value
        }
    }

    static func +(lhs: Resources, rhs: Resources) -> Resources {
        Resources(
            gold: lhs.gold + rhs.gold,
            metal: lhs.metal + rhs.metal,
            tech: lhs.tech + rhs.tech,
            jotisha: lhs.jotisha + rhs.jotisha,
            veda: lhs.veda + rhs.veda
        )
    }

    static func -(lhs: Resources, rhs: Resources) -> Resources {
        Resources(
            gold: lhs.gold - rhs.gold,
            metal: lhs.metal - rhs.metal,
            tech: lhs.tech - rhs.tech,
            jotisha: lhs.jotisha - rhs.jotisha,
            veda: lhs.veda - rhs.veda
        )
    }

    func scaled(by factor: Double) -> Resources {
        Resources(
            gold:    Int((Double(gold) * factor).rounded()),
            metal:   Int((Double(metal) * factor).rounded()),
            tech:    Int((Double(tech) * factor).rounded()),
            jotisha: Int((Double(jotisha) * factor).rounded()),
            veda:    Int((Double(veda) * factor).rounded())
        )
    }

    func canAfford(_ cost: Resources) -> Bool {
        gold >= cost.gold && metal >= cost.metal && tech >= cost.tech &&
        jotisha >= cost.jotisha && veda >= cost.veda
    }

    var nonZeroEntries: [(ResourceKind, Int)] {
        var result: [(ResourceKind, Int)] = []
        if gold != 0    { result.append((.gold, gold)) }
        if metal != 0   { result.append((.metal, metal)) }
        if tech != 0    { result.append((.tech, tech)) }
        if jotisha != 0 { result.append((.jotisha, jotisha)) }
        if veda != 0    { result.append((.veda, veda)) }
        return result
    }
}

// MARK: - Race

enum Race: String, CaseIterable, Identifiable {
    case raghuvansh
    case maurya
    case gupta
    case pratihara
    case rashtrakuta
    case pal
    case chola
    case sen
    case ahom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .raghuvansh:  return "Raghuvansh"
        case .maurya:      return "Maurya"
        case .gupta:       return "Gupta"
        case .pratihara:   return "Pratihara"
        case .rashtrakuta: return "Rashtrakuta"
        case .pal:         return "Pal"
        case .chola:       return "Chola"
        case .sen:         return "Sen"
        case .ahom:        return "Ahom"
        }
    }

    var dynasty: String {
        switch self {
        case .raghuvansh:  return "Solar Dynasty"
        case .maurya:      return "Mauryan Empire"
        case .gupta:       return "Gupta Empire"
        case .pratihara:   return "Gurjara-Pratihara"
        case .rashtrakuta: return "Rashtrakuta Empire"
        case .pal:         return "Pala Empire"
        case .chola:       return "Chola Empire"
        case .sen:         return "Sena of Bengal"
        case .ahom:        return "Ahom Kingdom"
        }
    }

    var description: String {
        switch self {
        case .raghuvansh:  return "Solar warriors of Ayodhya, lineage of Lord Rama"
        case .maurya:      return "Imperial conquerors of Bharatvarsha"
        case .gupta:       return "Golden Age of science, math, and astronomy"
        case .pratihara:   return "Western shield-bearers, frontier defenders"
        case .rashtrakuta: return "Temple builders of the Deccan"
        case .pal:         return "Patrons of dharma, knowledge, and craft"
        case .chola:       return "Maritime emperors, masters of the seas"
        case .sen:         return "Strategists of Bengal, masters of war science"
        case .ahom:        return "Unconquered hill kingdom of the northeast"
        }
    }

    var trait: String {
        switch self {
        case .raghuvansh:  return "+25% damage · +50% damage to bosses"
        case .maurya:      return "+25% fire rate · +30% projectile speed"
        case .gupta:       return "+20% damage · all towers reveal invisible"
        case .pratihara:   return "+25% range · +30% tower HP"
        case .rashtrakuta: return "+15% damage & fire rate · −25% building cost"
        case .pal:         return "−10% gold cost · −25% stone cost"
        case .chola:       return "+20% fire rate · +1% kill rewards"
        case .sen:         return "+20% range · +1 chain target on chain astras"
        case .ahom:        return "+20% range · +25% aura range · towers regen 4.5 HP/s in waves"
        }
    }

    var bonusGen: String {
        switch self {
        case .raghuvansh:  return "+30% Veda generation"
        case .maurya:      return "+40% Metal generation"
        case .gupta:       return "+40% Tech generation"
        case .pratihara:   return "+30% Gold generation"
        case .rashtrakuta: return "+30% Metal generation"
        case .pal:         return "+40% Jotisha generation"
        case .chola:       return "+25% Gold generation"
        case .sen:         return "+20% all resource generation"
        case .ahom:        return "+30% Veda generation"
        }
    }

    var startingResources: Resources {
        // Floor: every empire starts with at least 240 gold so no race feels
        // crippled out of the gate. Races above 240 keep their original edge.
        switch self {
        case .raghuvansh:  return Resources(gold: 240, metal: 20, tech: 0,  jotisha: 10, veda: 10)
        case .maurya:      return Resources(gold: 240, metal: 45, tech: 0,  jotisha: 10, veda: 0)
        case .gupta:       return Resources(gold: 240, metal: 15, tech: 35, jotisha: 10, veda: 5)
        case .pratihara:   return Resources(gold: 260, metal: 20, tech: 0,  jotisha: 10, veda: 0)
        case .rashtrakuta: return Resources(gold: 240, metal: 35, tech: 10, jotisha: 10, veda: 5)
        // Pal — the wealthy patron, gold-and-jotisha heavy.
        case .pal:         return Resources(gold: 360, metal: 25, tech: 25, jotisha: 45, veda: 15)
        case .chola:       return Resources(gold: 250, metal: 20, tech: 0,  jotisha: 10, veda: 0)
        // Sen — the scholar's all-rounder.
        case .sen:         return Resources(gold: 260, metal: 25, tech: 35, jotisha: 20, veda: 10)
        case .ahom:        return Resources(gold: 240, metal: 20, tech: 0,  jotisha: 10, veda: 25)
        }
    }

    /// Race-specific bonus starting lives — beginner-friendly cushion for the
    /// patron / scholar races. Stacks with BazaarStore.bonusStartingLives.
    var bonusStartingLives: Int {
        switch self {
        case .sen:  return 16
        case .pal:  return 10
        default:    return 0
        }
    }

    /// Marks races that the race-select screen highlights with a green
    /// "Beginner-friendly" badge. Disabled — every race is presented as
    /// an equal pick now, the player is left to read each race's signature
    /// and choose for themselves.
    var isBeginnerFriendly: Bool { false }

    var damageMultiplier: Double {
        switch self {
        case .raghuvansh:  return 1.25
        case .gupta:       return 1.20
        case .rashtrakuta: return 1.15
        default:           return 1.0
        }
    }

    var rangeMultiplier: CGFloat {
        switch self {
        case .pratihara:   return 1.25
        case .sen, .ahom:  return 1.20
        default:           return 1.0
        }
    }

    var goldCostMultiplier: Double { self == .pal ? 0.90 : 1.0 }

    var fireRateMultiplier: Double {
        switch self {
        case .maurya:      return 1.25
        case .chola:       return 1.20
        case .rashtrakuta: return 1.15
        default:           return 1.0
        }
    }

    func genMultiplier(for kind: ResourceKind) -> Double {
        switch (self, kind) {
        case (.raghuvansh,  .veda):    return 1.30
        case (.maurya,      .metal):   return 1.40
        case (.gupta,       .tech):    return 1.40
        case (.pratihara,   .gold):    return 1.30
        case (.rashtrakuta, .metal):   return 1.30
        case (.pal,         .jotisha): return 1.40
        case (.chola,       .gold):    return 1.25   // dialled back from 1.40 as part of Chola rebalance
        case (.sen,         _):        return 1.20  // generalist scholar — every resource
        case (.ahom,        .veda):    return 1.30
        default: return 1.0
        }
    }

    var color: Color {
        switch self {
        case .raghuvansh:  return .orange
        case .maurya:      return .green
        case .gupta:       return .yellow
        case .pratihara:   return .red
        case .rashtrakuta: return .purple
        case .pal:         return Color(red: 0.78, green: 0.55, blue: 0.20)
        case .chola:       return .cyan
        case .sen:         return .blue
        case .ahom:        return Color(red: 0.20, green: 0.65, blue: 0.35)
        }
    }

    var symbol: String {
        switch self {
        case .raghuvansh:  return "sun.max.fill"
        case .maurya:      return "crown.fill"
        case .gupta:       return "atom"
        case .pratihara:   return "shield.checkered"
        case .rashtrakuta: return "hammer.fill"
        case .pal:         return "book.fill"
        case .chola:       return "water.waves"
        case .sen:         return "shield.fill"
        case .ahom:        return "tree.fill"
        }
    }

    // MARK: - Signature mechanics (one unique ability per race)

    /// Multiplier applied on top of base damage when hitting boss-tier enemies.
    var bossDamageBonus: Double { self == .raghuvansh ? 1.50 : 1.0 }

    /// Multiplier applied to projectile speed at creation.
    var projectileSpeedMultiplier: CGFloat { self == .maurya ? 1.30 : 1.0 }

    /// If true, every tower can target invisible enemies without a sensor tower.
    var revealsInvisible: Bool { self == .gupta }

    /// Multiplier on tower starting / max HP.
    var towerHPMultiplier: Double { self == .pratihara ? 1.30 : 1.0 }

    /// Multiplier on building gold/resource cost (both placement and upgrade).
    var buildingCostMultiplier: Double { self == .rashtrakuta ? 0.75 : 1.0 }

    /// Multiplier on stone purchase + upgrade cost.
    var stoneCostMultiplier: Double { self == .pal ? 0.75 : 1.0 }

    /// Multiplier on gold and Bazaar points earned per enemy kill.
    /// Now a token +1% — Chola's edge comes from fire rate + gold gen,
    /// the kill reward is just a tiny maritime-trader flavour bump.
    var killRewardMultiplier: Double { self == .chola ? 1.01 : 1.0 }

    /// Extra chain targets added to chain-type astras (Aindrastra, Naga Pasha).
    var bonusChainTargets: Int { self == .sen ? 1 : 0 }

    /// Tower HP regenerated per second while a wave is active. Ahom forest
    /// spirits' signature — bumped post-aura-nerf so it's a real defensive
    /// edge instead of cosmetic trickle. Stacks with Sanjivani / Lakshman Rekha.
    var towerRegenPerSec: Double { self == .ahom ? 4.5 : 0 }

    /// Ahom forest spirits also extend the reach of heal + shield auras by
    /// +25%, so a single Sanjivani / Lakshman Rekha tower blankets a wider
    /// stretch of the path. Pairs naturally with the regen signature to make
    /// Ahom the dedicated defensive-grind empire.
    var auraRangeMultiplier: CGFloat { self == .ahom ? 1.25 : 1.0 }
}

// MARK: - Age

enum Age: Int, CaseIterable, Identifiable {
    case ancient = 0
    case middle  = 1
    case modern  = 2

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .ancient: return "Satya Yuga"
        case .middle:  return "Treta Yuga"
        case .modern:  return "Dvapara Yuga"
        }
    }

    var shortName: String {
        switch self {
        case .ancient: return "Satya"
        case .middle:  return "Treta"
        case .modern:  return "Dvapara"
        }
    }

    var unlockWave: Int {
        switch self {
        case .ancient: return 0
        case .middle:  return 3   // T2 astras open at W3 (was W6)
        case .modern:  return 6   // T3 + T4 astras open at W6 (was W13)
        }
    }

    var color: Color {
        switch self {
        case .ancient: return .orange
        case .middle:  return .yellow
        case .modern:  return .cyan
        }
    }

    var symbol: String {
        switch self {
        case .ancient: return "leaf.fill"
        case .middle:  return "shield.lefthalf.filled"
        case .modern:  return "sparkles"
        }
    }
}

// MARK: - Damage Type

enum DamageType: String {
    case physical, fire, water, ice, divine
}

// MARK: - Power Stones

enum StoneKind: String, CaseIterable, Identifiable {
    case chuni       // Ruby — power
    case panna       // Emerald — speed
    case nila        // Blue Sapphire — range
    case raktamukhi  // Red-faced Sapphire — all stats

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chuni:      return "Chuni"
        case .panna:      return "Panna"
        case .nila:       return "Nila"
        case .raktamukhi: return "Raktamukhi"
        }
    }

    var sanskritName: String {
        switch self {
        case .chuni:      return "Manikya"
        case .panna:      return "Marakata"
        case .nila:       return "Nilamani"
        case .raktamukhi: return "Rakta-Nila"
        }
    }

    var tagline: String {
        switch self {
        case .chuni:      return "+Damage"
        case .panna:      return "+Fire Rate"
        case .nila:       return "+Range"
        case .raktamukhi: return "+All Stats"
        }
    }

    var color: Color {
        switch self {
        case .chuni:      return Color(red: 0.95, green: 0.10, blue: 0.25)
        case .panna:      return Color(red: 0.05, green: 0.75, blue: 0.30)
        case .nila:       return Color(red: 0.15, green: 0.30, blue: 0.95)
        case .raktamukhi: return Color(red: 0.85, green: 0.05, blue: 0.55)
        }
    }

    var symbol: String {
        switch self {
        case .chuni:      return "diamond.fill"
        case .panna:      return "leaf.fill"
        case .nila:       return "drop.triangle.fill"
        case .raktamukhi: return "sparkles"
        }
    }

    func cost(forLevel level: Int) -> Resources {
        let l = max(1, min(3, level))
        switch self {
        case .chuni:
            switch l {
            case 1: return Resources(gold: 60)
            case 2: return Resources(gold: 120, metal: 30)
            default: return Resources(gold: 240, metal: 60)
            }
        case .panna:
            switch l {
            case 1: return Resources(gold: 70)
            case 2: return Resources(gold: 140, tech: 30)
            default: return Resources(gold: 280, tech: 60)
            }
        case .nila:
            switch l {
            case 1: return Resources(gold: 80, metal: 20)
            case 2: return Resources(gold: 160, metal: 40, tech: 20)
            default: return Resources(gold: 320, metal: 80, tech: 40)
            }
        case .raktamukhi:
            switch l {
            case 1: return Resources(gold: 150, metal: 30, tech: 30, jotisha: 20, veda: 10)
            case 2: return Resources(gold: 300, metal: 60, tech: 60, jotisha: 40, veda: 20)
            default: return Resources(gold: 600, metal: 120, tech: 120, jotisha: 80, veda: 50)
            }
        }
    }

    func damageMultiplier(level: Int) -> Double {
        switch self {
        case .chuni:      return 1.0 + 0.20 * Double(level)
        case .raktamukhi: return 1.0 + 0.10 * Double(level)
        default: return 1.0
        }
    }

    func fireRateMultiplier(level: Int) -> Double {
        switch self {
        case .panna:      return 1.0 + 0.15 * Double(level)
        case .raktamukhi: return 1.0 + 0.10 * Double(level)
        default: return 1.0
        }
    }

    func rangeMultiplier(level: Int) -> CGFloat {
        switch self {
        case .nila:       return 1.0 + 0.15 * CGFloat(level)
        case .raktamukhi: return 1.0 + 0.10 * CGFloat(level)
        default: return 1.0
        }
    }
}

struct Stone {
    let kind: StoneKind
    var level: Int = 1

    var displayName: String { "\(kind.displayName) L\(level)" }
}

// MARK: - Tower Path & Astra

enum TowerPath: String, CaseIterable, Identifiable {
    case arrow, fire, water, ice, divine
    case maya        // illusion / phantom-arrow path (4 tiers)
    case drishti     // sensory
    case sanjivani   // healer
    case rekha       // barrier

    var id: String { rawValue }

    var pathName: String {
        switch self {
        case .arrow:     return "Archer"
        case .fire:      return "Fire"
        case .water:     return "Water"
        case .ice:       return "Ice"
        case .divine:    return "Divine"
        case .maya:      return "Maya"
        case .drishti:   return "Sensory"
        case .sanjivani: return "Healer"
        case .rekha:     return "Barrier"
        }
    }

    var isOffensive: Bool {
        switch self {
        case .drishti, .sanjivani, .rekha: return false
        default: return true
        }
    }

    var pathColor: Color {
        switch self {
        case .arrow:     return .brown
        case .fire:      return .orange
        case .water:     return .blue
        case .ice:       return .cyan
        case .divine:    return .purple
        case .maya:      return Color(red: 0.55, green: 0.30, blue: 0.95)  // illusion violet
        case .drishti:   return Color(red: 0.95, green: 0.85, blue: 0.20)
        case .sanjivani: return Color(red: 0.30, green: 0.95, blue: 0.55) // healing green
        case .rekha:     return Color(red: 0.95, green: 0.55, blue: 0.85) // protective magenta
        }
    }

    var astras: [TowerKind] {
        switch self {
        // 4-tier paths — the three astra families that culminate in the
        // T4 "divine ultimate". T3 is a new intermediate astra that bridges
        // T2 and T4 so the player has another upgrade to chase before the
        // wave-8-to-10 ultimate.
        case .arrow:     return [.dart, .aindrastra, .shaktiAstra, .sudarshanaChakra]
        case .fire:      return [.agneyastra, .suryastra, .rudraAstra, .brahmashirsha]
        case .divine:    return [.trishul, .vajrastra, .narayanaAstra, .pashupatastra]
        // Maya path — 4-tier illusion line (Maya → Ganga → Anjalik → Brahmasira)
        case .maya:      return [.mayaAstra, .gangaAstra, .anjalikaAstra, .brahmasiraAstra]
        // 3-tier paths — utility and elemental families.
        case .water:     return [.varunastra, .nagaPasha, .garudastra]
        case .ice:       return [.sheetastra, .twashtar, .mohiniAstra]
        case .drishti:   return [.bala, .atibala, .divyaDrishti]
        case .sanjivani: return [.aushadhi, .sanjivaniBooti, .amritKalash]
        case .rekha:     return [.surakshaRekha, .lakshmanRekha, .vajraKavach]
        }
    }
}

enum TowerKind: String, CaseIterable, Identifiable {
    case dart, aindrastra, shaktiAstra, sudarshanaChakra
    case agneyastra, suryastra, rudraAstra, brahmashirsha
    case varunastra, nagaPasha, garudastra
    case sheetastra, twashtar, mohiniAstra
    case trishul, vajrastra, narayanaAstra, pashupatastra
    case mayaAstra, gangaAstra, anjalikaAstra, brahmasiraAstra  // illusion 4-tier
    case bala, atibala, divyaDrishti                    // sensory
    case aushadhi, sanjivaniBooti, amritKalash          // healer
    case surakshaRekha, lakshmanRekha, vajraKavach      // barrier

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dart:              return "Dart"
        case .aindrastra:        return "Aindra Astra"
        case .shaktiAstra:       return "Shakti Astra"
        case .sudarshanaChakra:  return "Sudarshana Chakra"
        case .agneyastra:        return "Agneyastra"
        case .suryastra:         return "Suryastra"
        case .rudraAstra:        return "Rudra Astra"
        case .brahmashirsha:     return "Bhambhrastra"
        case .varunastra:        return "Varunastra"
        case .nagaPasha:         return "Naga Pasha"
        case .garudastra:        return "Garudastra"
        case .sheetastra:        return "Sheetastra"
        case .twashtar:          return "Twashtar"
        case .mohiniAstra:       return "Mohini Astra"
        case .trishul:           return "Trishul"
        case .vajrastra:         return "Vajrastra"
        case .narayanaAstra:     return "Narayana Astra"
        case .pashupatastra:     return "Pashupatastra"
        case .mayaAstra:         return "Maya Astra"
        case .gangaAstra:        return "Ganga Astra"
        case .anjalikaAstra:     return "Anjalika Astra"
        case .brahmasiraAstra:   return "Brahmasira Astra"
        case .bala:              return "Bala"
        case .atibala:           return "Atibala"
        case .divyaDrishti:      return "Divya Drishti"
        case .aushadhi:          return "Aushadhi"
        case .sanjivaniBooti:    return "Sanjivani"
        case .amritKalash:       return "Amrit Kalash"
        case .surakshaRekha:     return "Suraksha Rekha"
        case .lakshmanRekha:     return "Lakshman Rekha"
        case .vajraKavach:       return "Vajra Kavach"
        }
    }

    var tagline: String {
        switch self {
        case .dart:              return "Rapid darts"
        case .aindrastra:        return "Indra's chain bow"
        case .shaktiAstra:       return "Karna's piercing shakti"
        case .sudarshanaChakra:  return "Vishnu's splash disc"
        case .agneyastra:        return "Fire — burn DoT"
        case .suryastra:         return "Sun — heavy burn"
        case .rudraAstra:        return "Rudra's wrath flame"
        case .brahmashirsha:     return "Divine inferno"
        case .varunastra:        return "Water — slow"
        case .nagaPasha:         return "Snake noose chain"
        case .garudastra:        return "Garuda's wind splash"
        case .sheetastra:        return "Ice — freeze"
        case .twashtar:          return "Long freeze"
        case .mohiniAstra:       return "Mass freeze AoE"
        case .trishul:           return "Shiva's trident"
        case .vajrastra:         return "Indra's thunderbolt"
        case .narayanaAstra:     return "Vishnu's arrow storm"
        case .pashupatastra:     return "Shiva's wrath"
        case .mayaAstra:         return "Illusion arrows"
        case .gangaAstra:        return "Sacred river flow"
        case .anjalikaAstra:     return "Arjuna's piercer"
        case .brahmasiraAstra:   return "Brahma's three-headed astra"
        case .bala:              return "Detect invisible"
        case .atibala:           return "Wider detection"
        case .divyaDrishti:      return "Sees all"
        case .aushadhi:          return "Heal nearby"
        case .sanjivaniBooti:    return "Strong heal"
        case .amritKalash:       return "Divine restoration"
        case .surakshaRekha:     return "Shield aura"
        case .lakshmanRekha:     return "Stronger shield"
        case .vajraKavach:       return "Diamond shield"
        }
    }

    var path: TowerPath {
        for p in TowerPath.allCases where p.astras.contains(self) {
            return p
        }
        return .arrow
    }

    var tier: Int {
        (path.astras.firstIndex(of: self) ?? 0) + 1
    }

    var requiredAge: Age {
        // Per-kind overrides for selectively-late astras. Even though
        // these sit in their path's first slot (which would default to
        // .ancient), they unlock later by lore + balance design:
        //   • Trishul (Shiva's trident) → Dvapara only
        //   • Agneyastra / Sheetastra (fire & ice T1) → Treta only
        switch self {
        case .trishul:                       return .modern
        case .agneyastra, .sheetastra:       return .middle
        case .mayaAstra:                     return .modern   // entire Maya path is Dvapara-only
        default: break
        }
        switch tier {
        case 2:           return .middle
        case 3, 4:        return .modern   // T4 ultimates share the modern gate; cost gates them further
        default:          return .ancient
        }
    }

    var cost: Resources {
        switch self {
        // Tier 1 — keep accessible
        case .dart:              return Resources(gold: 35)   // cheapest T1 — encourages early swarm-clear
        case .agneyastra:        return Resources(gold: 80)
        case .varunastra:        return Resources(gold: 90)
        case .sheetastra:        return Resources(gold: 100)
        case .trishul:           return Resources(gold: 280, metal: 60, jotisha: 30)  // Dvapara-gated premium T1
        case .bala:              return Resources(gold: 110, jotisha: 12)
        case .aushadhi:          return Resources(gold: 160, jotisha: 30)
        case .surakshaRekha:     return Resources(gold: 210, metal: 60)
        // Tier 2 — steeper (~+30% gold)
        case .aindrastra:        return Resources(gold: 170, tech: 35)
        case .suryastra:         return Resources(gold: 210, jotisha: 40)
        case .nagaPasha:         return Resources(gold: 220, metal: 40)
        case .twashtar:          return Resources(gold: 240, jotisha: 40)
        case .vajrastra:         return Resources(gold: 190, metal: 35, veda: 18)
        case .atibala:           return Resources(gold: 235, jotisha: 40, veda: 20)
        case .sanjivaniBooti:    return Resources(gold: 360, jotisha: 90, veda: 60)
        case .lakshmanRekha:     return Resources(gold: 440, metal: 140, veda: 70)
        // Tier 3 — premium intermediate astras (for arrow/fire/divine paths).
        // Strong but not endgame-defining; price tuned for ~W6-W8 reach.
        case .shaktiAstra:       return Resources(gold: 750,  metal: 180, tech: 100, veda: 50)
        case .rudraAstra:        return Resources(gold: 850,  jotisha: 220, veda: 100)
        case .narayanaAstra:     return Resources(gold: 950,  metal: 260, jotisha: 200, veda: 200)
        // T3 utility/elemental (3-tier paths)
        case .garudastra:        return Resources(gold: 430, metal: 100, jotisha: 60)
        case .mohiniAstra:       return Resources(gold: 460, jotisha: 100, veda: 60)
        case .divyaDrishti:      return Resources(gold: 460, jotisha: 100, veda: 75)
        case .amritKalash:       return Resources(gold: 700, jotisha: 150, veda: 180)
        case .vajraKavach:       return Resources(gold: 820, metal: 280, veda: 150)
        // Tier 4 — divine ultimates. The three apex astras (Sudarshana
        // Chakra, Brahmashirsha, Pashupatastra) demand a premium that's
        // only reachable W8-W10 even for a player with full economy.
        // Massive cost + massive range — they're the run-winners.
        case .sudarshanaChakra:  return Resources(gold: 3500, metal: 700, tech: 500, veda: 400)
        case .brahmashirsha:     return Resources(gold: 4000, jotisha: 800, veda: 700)
        case .pashupatastra:     return Resources(gold: 5000, metal: 1000, jotisha: 800, veda: 1000)
        // Maya path
        case .mayaAstra:         return Resources(gold: 110, tech: 20)
        case .gangaAstra:        return Resources(gold: 260, tech: 50, jotisha: 30)
        case .anjalikaAstra:     return Resources(gold: 800, metal: 180, tech: 120, jotisha: 60)
        case .brahmasiraAstra:   return Resources(gold: 3000, metal: 600, tech: 400, jotisha: 300, veda: 300)
        }
    }

    var baseDamage: Double {
        switch self {
        case .dart:              return 7
        case .aindrastra:        return 22
        case .shaktiAstra:       return 80   // T3 arrow intermediate — chain-fire
        // Sudarshana Chakra — arrow T4 divine ultimate. Vishnu's discus.
        case .sudarshanaChakra:  return 800   // T4 arrow — rapid splash disc (low per-hit, very fast reload)
        case .agneyastra:        return 14
        case .suryastra:         return 32
        case .rudraAstra:        return 110  // T3 fire intermediate — Rudra's wrath
        // Brahmashirsha — fire T4 divine ultimate. The Brahmastra family.
        case .brahmashirsha:     return 900   // T4 fire — heavy direct + the burn DoT (see burnDPS)
        case .varunastra:        return 10
        case .nagaPasha:         return 26
        case .garudastra:        return 62
        case .sheetastra:        return 12
        case .twashtar:          return 30
        case .mohiniAstra:       return 70
        // Divine path follows a clean T1 → T4 progression that ends at
        // Pashupatastra (1000). Each step roughly doubles raw damage but
        // also slows reload, so DPS climbs at a controlled pace.
        case .trishul:           return 220   // T1 divine — Dvapara-gated premium opener
        case .vajrastra:         return 420   // T2 — Indra's thunderbolt
        case .narayanaAstra:     return 700   // T3 — Vishnu's arrow storm
        // Pashupatastra — divine T4 ultimate. Apex of the run.
        case .pashupatastra:     return 1000
        // Maya path — illusion arrows
        // Maya path is Dvapara-only across all 4 tiers, so each step needs
        // to land like a Dvapara-tier astra, not a Satya-era one. Previous
        // values (12 / 38 / 130 / 400) read as a T1-through-T3 progression —
        // the new curve scales each tier into proper Dvapara territory.
        case .mayaAstra:         return 50    // was 12 — T1 of a late-game path
        case .gangaAstra:        return 150   // was 38
        case .anjalikaAstra:     return 420   // was 130 — piercing T3
        case .brahmasiraAstra:   return 950   // T4 maya — three-headed astra, big splash
        case .bala, .atibala, .divyaDrishti: return 0
        case .aushadhi, .sanjivaniBooti, .amritKalash: return 0  // healers: heal/sec defined separately
        case .surakshaRekha, .lakshmanRekha, .vajraKavach: return 0
        }
    }

    var baseFireInterval: TimeInterval {
        switch self {
        case .dart:              return 0.35
        case .aindrastra:        return 0.65
        case .shaktiAstra:       return 0.55   // T3 arrow — fast chain
        case .sudarshanaChakra:  return 1.10   // T4 — RAPID spinning disc: ~727 DPS
        case .agneyastra:        return 0.70
        case .suryastra:         return 0.80
        case .rudraAstra:        return 1.10   // T3 fire — moderate cadence
        case .brahmashirsha:     return 1.50   // T4 — apocalyptic cadence: 600 DPS + 60 burn DPS = ~720 effective
        case .varunastra:        return 0.80
        case .nagaPasha:         return 0.85
        case .garudastra:        return 1.10
        case .sheetastra:        return 1.00
        case .twashtar:          return 1.05
        case .mohiniAstra:       return 1.50
        case .trishul:           return 0.90
        case .vajrastra:         return 1.00
        case .narayanaAstra:     return 1.40   // T3 divine — moderate
        case .pashupatastra:     return 1.40   // T4 — slowest single, biggest hit: ~714 DPS
        // Maya path
        case .mayaAstra:         return 0.45
        case .gangaAstra:        return 0.75
        case .anjalikaAstra:     return 1.00
        case .brahmasiraAstra:   return 1.35   // T4 — three-headed astra: ~703 DPS
        case .bala, .atibala, .divyaDrishti: return 1.0
        case .aushadhi, .sanjivaniBooti, .amritKalash: return 1.0
        case .surakshaRekha, .lakshmanRekha, .vajraKavach: return 1.0
        }
    }

    var baseRange: CGFloat {
        switch self {
        case .dart:              return 100
        case .aindrastra:        return 140
        case .shaktiAstra:       return 200   // T3 arrow intermediate
        case .sudarshanaChakra:  return 1500  // T4 — full screen sweep
        case .agneyastra:        return 115
        case .suryastra:         return 135
        case .rudraAstra:        return 195   // T3 fire intermediate
        case .brahmashirsha:     return 1500  // T4 — full screen sweep
        case .varunastra:        return 125
        case .nagaPasha:         return 145
        case .garudastra:        return 175
        case .sheetastra:        return 115
        case .twashtar:          return 140
        case .mohiniAstra:       return 170
        case .trishul:           return 220    // longer reach to match its new Dvapara cost
        case .vajrastra:         return 170
        case .narayanaAstra:     return 230   // T3 divine intermediate
        case .pashupatastra:     return 1500  // T4 — full screen sweep
        // Maya path
        case .mayaAstra:         return 200    // was 130
        case .gangaAstra:        return 260    // was 180
        case .anjalikaAstra:     return 360    // was 240 — piercer reaches
        case .brahmasiraAstra:   return 1500   // was 320 — full-field, matches other T4 ultimates
        case .bala:              return 150  // detection range
        case .atibala:           return 220
        case .divyaDrishti:      return 380
        case .aushadhi:          return 110  // heal aura range
        case .sanjivaniBooti:    return 150
        case .amritKalash:       return 190
        case .surakshaRekha:     return 120  // shield aura range
        case .lakshmanRekha:     return 160
        case .vajraKavach:       return 190
        }
    }

    var projectileSpeed: CGFloat {
        switch self {
        case .dart:              return 720
        case .aindrastra:        return 900
        case .shaktiAstra:       return 950
        case .sudarshanaChakra:  return 900
        case .agneyastra:        return 520
        case .suryastra:         return 560
        case .rudraAstra:        return 580
        case .brahmashirsha:     return 500
        case .varunastra:        return 560
        case .nagaPasha:         return 530
        case .garudastra:        return 540
        case .sheetastra:        return 530
        case .twashtar:          return 540
        case .mohiniAstra:       return 500
        case .trishul:           return 760
        case .vajrastra:         return 1000
        case .narayanaAstra:     return 880
        case .pashupatastra:     return 900
        // Maya path
        case .mayaAstra:         return 780
        case .gangaAstra:        return 700
        case .anjalikaAstra:     return 850
        case .brahmasiraAstra:   return 820
        case .bala, .atibala, .divyaDrishti: return 0
        case .aushadhi, .sanjivaniBooti, .amritKalash: return 0
        case .surakshaRekha, .lakshmanRekha, .vajraKavach: return 0
        }
    }

    var splashRadius: CGFloat? {
        switch self {
        // T4 divine ultimates — full-area sweep with wide splash so they
        // cleave whole groups.
        case .sudarshanaChakra: return 150
        case .brahmashirsha:    return 180
        case .pashupatastra:    return 220
        // Maya / Ganga path — sacred river overflows + three-headed astra
        // explodes. Splash scales with tier so the late Maya astras really
        // feel like Dvapara-era weapons.
        case .gangaAstra:       return 100   // T2 river splash
        case .anjalikaAstra:    return 140   // T3 piercer shock-splash
        case .brahmasiraAstra:  return 240   // T4 three-headed explosion
        // T3 intermediate astras — moderate splash.
        case .rudraAstra:       return 95
        case .narayanaAstra:    return 110
        case .garudastra:       return 80
        case .mohiniAstra:      return 70
        default:                return nil
        }
    }

    var burnDPS: Double {
        switch self {
        case .agneyastra:    return 9
        case .suryastra:     return 20
        case .rudraAstra:    return 35      // T3 fire intermediate — heavy DoT
        // Brahmashirsha (T4 ultimate) — DoT removed; pure direct damage.
        default: return 0
        }
    }

    var burnDuration: TimeInterval {
        switch self {
        case .agneyastra:    return 3.0
        case .suryastra:     return 4.0
        case .rudraAstra:    return 4.5
        default: return 0
        }
    }

    var slowFactor: CGFloat {
        switch self {
        case .varunastra: return 0.5
        case .nagaPasha:  return 0.3
        case .garudastra: return 0.45
        default:          return 1.0
        }
    }

    var slowDuration: TimeInterval {
        switch self {
        case .varunastra: return 2.5
        case .nagaPasha:  return 4.0
        case .garudastra: return 3.0
        default:          return 0
        }
    }

    var freezeDuration: TimeInterval {
        switch self {
        case .sheetastra:  return 0.85
        case .twashtar:    return 1.6
        case .mohiniAstra: return 2.5
        default:           return 0
        }
    }

    var chainTargets: Int {
        switch self {
        case .aindrastra: return 2
        case .shaktiAstra: return 3       // T3 arrow intermediate — stronger chain
        case .nagaPasha:  return 2
        // Maya T1 fires phantom-arrow duplicates — illusion theme made literal.
        case .mayaAstra:  return 2
        default:          return 0
        }
    }

    var color: Color {
        switch self {
        case .dart:              return .brown
        case .aindrastra:        return .yellow
        case .shaktiAstra:       return Color(red: 1.0, green: 0.75, blue: 0.10)   // bright gold
        case .sudarshanaChakra:  return .orange
        case .agneyastra:        return .orange
        case .suryastra:         return Color(red: 1.0, green: 0.55, blue: 0.0)
        case .rudraAstra:        return Color(red: 0.85, green: 0.20, blue: 0.10)  // deep ember red
        case .brahmashirsha:     return .red
        case .varunastra:        return .blue
        case .nagaPasha:         return .green
        case .garudastra:        return .mint
        case .sheetastra:        return .cyan
        case .twashtar:          return Color(red: 0.6, green: 0.85, blue: 1.0)
        case .mohiniAstra:       return Color(red: 0.7, green: 0.6, blue: 1.0)
        case .trishul:           return .indigo
        case .vajrastra:         return Color(red: 1.0, green: 0.8, blue: 0.2)
        case .narayanaAstra:     return Color(red: 0.45, green: 0.30, blue: 0.95)  // royal purple
        case .pashupatastra:     return Color(red: 0.85, green: 0.15, blue: 0.95)
        // Maya path — illusion-violet gradient by tier
        case .mayaAstra:         return Color(red: 0.65, green: 0.45, blue: 0.95)
        case .gangaAstra:        return Color(red: 0.50, green: 0.85, blue: 0.95)
        case .anjalikaAstra:     return Color(red: 0.45, green: 0.30, blue: 0.85)
        case .brahmasiraAstra:   return Color(red: 0.70, green: 0.20, blue: 0.95)
        case .bala:              return Color(red: 0.95, green: 0.85, blue: 0.20)
        case .atibala:           return Color(red: 1.0, green: 0.75, blue: 0.0)
        case .divyaDrishti:      return Color(red: 1.0, green: 0.95, blue: 0.55)
        case .aushadhi:          return Color(red: 0.30, green: 0.95, blue: 0.55)
        case .sanjivaniBooti:    return Color(red: 0.20, green: 0.85, blue: 0.45)
        case .amritKalash:       return Color(red: 0.55, green: 1.0, blue: 0.70)
        case .surakshaRekha:     return Color(red: 0.95, green: 0.55, blue: 0.85)
        case .lakshmanRekha:     return Color(red: 0.95, green: 0.40, blue: 0.75)
        case .vajraKavach:       return Color(red: 0.85, green: 0.30, blue: 0.95)
        }
    }

    var symbol: String {
        switch self {
        case .dart:              return "scope"
        case .aindrastra:        return "bolt.horizontal.fill"
        case .shaktiAstra:       return "bolt.horizontal.circle.fill"
        case .sudarshanaChakra:  return "circle.dotted"
        case .agneyastra:        return "flame.fill"
        case .suryastra:         return "sun.max.fill"
        case .rudraAstra:        return "flame.circle.fill"
        case .brahmashirsha:     return "sun.dust.fill"
        case .varunastra:        return "drop.fill"
        case .nagaPasha:         return "link"
        case .garudastra:        return "wind"
        case .sheetastra:        return "snowflake"
        case .twashtar:          return "snowflake.circle.fill"
        case .mohiniAstra:       return "sparkle"
        case .trishul:           return "arrow.up"
        case .vajrastra:         return "bolt.shield.fill"
        case .narayanaAstra:     return "rays"
        case .pashupatastra:     return "eye.fill"
        // Maya path
        case .mayaAstra:         return "wand.and.stars"
        case .gangaAstra:        return "drop.triangle.fill"
        case .anjalikaAstra:     return "arrow.up.and.line.horizontal.and.arrow.down"
        case .brahmasiraAstra:   return "sparkles"
        case .bala:              return "eye"
        case .atibala:           return "eye.fill"
        case .divyaDrishti:      return "eye.trianglebadge.exclamationmark.fill"
        case .aushadhi:          return "leaf.fill"
        case .sanjivaniBooti:    return "leaf.circle.fill"
        case .amritKalash:       return "drop.degreesign.fill"
        case .surakshaRekha:     return "shield.lefthalf.filled"
        case .lakshmanRekha:     return "shield.fill"
        case .vajraKavach:       return "shield.righthalf.filled"
        }
    }

    var damageType: DamageType {
        switch path {
        case .arrow:     return .physical
        case .fire:      return .fire
        case .water:     return .water
        case .ice:       return .ice
        case .divine:    return .divine
        case .maya:      return .divine     // illusion arrows treated as divine
        case .drishti:   return .physical
        case .sanjivani: return .physical
        case .rekha:     return .physical
        }
    }

    // Healer rate
    var healPerSec: Double {
        switch self {
        case .aushadhi:       return 60
        case .sanjivaniBooti: return 200
        case .amritKalash:    return 500
        default: return 0
        }
    }

    // Barrier damage reduction (0..1 = portion reduced)
    var damageReduction: Double {
        switch self {
        case .surakshaRekha: return 0.45
        case .lakshmanRekha: return 0.72
        case .vajraKavach:   return 0.88
        default: return 0
        }
    }
}

// MARK: - Building

enum BuildingKind: String, CaseIterable, Identifiable {
    case goldMine
    case metalFoundry
    case techLab
    case jotishaObservatory
    case vedaGurukul
    /// Parijata Briksha — the divine wish-fulfilling tree. Unlocked once the
    /// Sudarshan endgame begins; generates every resource at once at a huge
    /// rate, but costs a hefty premium up-front.
    case parijata

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .goldMine:           return "Gold Mine"
        case .metalFoundry:       return "Foundry"
        case .techLab:            return "Tech Lab"
        case .jotishaObservatory: return "Observatory"
        case .vedaGurukul:        return "Gurukul"
        case .parijata:           return "Parijata Briksha"
        }
    }

    var sanskritName: String {
        switch self {
        case .goldMine:           return "Suvarna Khan"
        case .metalFoundry:       return "Loh Shala"
        case .techLab:            return "Vijnan Bhavan"
        case .jotishaObservatory: return "Vedh Shala"
        case .vedaGurukul:        return "Gurukul"
        case .parijata:           return "Parijata Vriksha"
        }
    }

    /// Primary resource — Parijata returns gold as a fallback but actually
    /// produces ALL five every tick (handled in generateResources).
    var resource: ResourceKind {
        switch self {
        case .goldMine:           return .gold
        case .metalFoundry:       return .metal
        case .techLab:            return .tech
        case .jotishaObservatory: return .jotisha
        case .vedaGurukul:        return .veda
        case .parijata:           return .gold
        }
    }

    var cost: Resources {
        switch self {
        case .goldMine:           return Resources(gold: 60)
        case .metalFoundry:       return Resources(gold: 80)
        case .techLab:            return Resources(gold: 100, metal: 20)
        case .jotishaObservatory: return Resources(gold: 120, tech: 20)
        case .vedaGurukul:        return Resources(gold: 140, jotisha: 20)
        case .parijata:           return Resources(gold: 2500, metal: 200, tech: 200, jotisha: 200, veda: 200)
        }
    }

    var baseGenPerSec: Double {
        switch self {
        // Bumped across the board so the steeper Sudarshan/Trimurti charge
        // costs and divine-ultimate prices are reachable without spamming
        // production buildings.
        case .goldMine:           return 1.8
        case .metalFoundry:       return 1.0
        case .techLab:            return 0.65
        case .jotishaObservatory: return 1.1
        case .vedaGurukul:        return 1.1
        case .parijata:           return 4.0   // applied to EVERY resource per tick
        }
    }

    var symbol: String {
        switch self {
        case .goldMine:           return "hammer.fill"
        case .metalFoundry:       return "flame.circle.fill"
        case .techLab:            return "cpu.fill"
        case .jotishaObservatory: return "moon.stars.fill"
        case .vedaGurukul:        return "book.closed.fill"
        case .parijata:           return "tree.fill"
        }
    }

    var color: Color {
        switch self {
        case .parijata: return Color(red: 0.45, green: 0.95, blue: 0.55)  // divine green-gold
        default: return resource.color
        }
    }

    /// True if this building is only available during the Sudarshan endgame.
    var requiresEndgame: Bool { self == .parijata }

    /// Maximum upgrade level for this building kind. Gold Mine reaches a
    /// premium 4th tier (massive 12× production at a steep cost); the
    /// other buildings cap at 3 to keep the economy curve readable.
    var maxLevel: Int {
        switch self {
        case .goldMine: return 4
        default:        return 3
        }
    }
}

// MARK: - Entities

struct Tower: Identifiable {
    let id = UUID()
    /// Mutable so the player can relocate a tower into a different empty
    /// slot via the TowerMenu — its position follows the new slot.
    var slotIndex: Int
    var position: CGPoint
    let path: TowerPath
    var tier: Int = 1
    var fireCooldown: TimeInterval = 0
    var stone: Stone? = nil
    /// Seconds remaining on the attached stone's temporary power-up. When
    /// this hits 0 the stone is auto-removed from the tower. Set by
    /// `attachStone` / `upgradeStone` based on the kind + level.
    var stoneTimer: TimeInterval = 0
    /// Original duration the stone was attached/upgraded with — for UI
    /// progress-bar math.
    var stoneTimerTotal: TimeInterval = 0
    var hp: Double = 2000
    var maxHP: Double = 2000
    /// 0 = no heal aura, 1-3 = upgrade tier of the heal aura.
    /// L1 unlocks at Treta Yug; each upgrade re-applies a resource cost.
    var healAuraLevel: Int = 0
    /// 0 = no shield aura, 1-3 = upgrade tier.
    /// L1 unlocks at Dvapara Yug; each upgrade re-applies a resource cost.
    var shieldAuraLevel: Int = 0

    /// Lifetime kill count for this tower. Each kill grants +1 flat
    /// "veteran power" added to base damage on every subsequent hit, so
    /// veteran defenders become meaningfully stronger over a wave.
    var kills: Int = 0
    /// Damage bonus a veteran tower carries (Double(kills) * 1.0).
    var veteranPower: Double { Double(kills) }
    /// Lifetime BOSS kills landed by this tower. Each boss kill stacks a
    /// permanent +12% damage multiplier on this tower specifically, plus
    /// a one-time +50 maxHP infusion. The cash loot from the boss goes
    /// straight to the player's gold stock, not the tower.
    var bossKills: Int = 0
    /// Multiplicative damage stack from boss-kill loot. Each boss kill
    /// adds +12%, so 5 boss kills ≈ 1.76× damage on this tower forever.
    var bossPowerMultiplier: Double { 1.0 + 0.12 * Double(bossKills) }
    /// Special-attack charges dropped by bosses on death. Each charge =
    /// the tower's NEXT projectile deals heavy bonus damage (configured
    /// per boss kind). Consumed on fire.
    var specialCharges: Int = 0

    /// Per-wave wall shield — absorbed before HP. Set by `activateWall()`,
    /// cleared at wave end. While > 0 the tower also visually pulses with
    /// a protective ring.
    var wallShield: Double = 0

    /// Number of complete waves this tower has survived. Each survived wave
    /// grants a permanent +12% max-HP bump so veterans become noticeably
    /// tougher than freshly-placed replacements.
    var wavesSurvived: Int = 0

    var kind: TowerKind {
        path.astras[max(0, min(tier - 1, path.astras.count - 1))]
    }

    var nextAstra: TowerKind? {
        guard tier < path.astras.count else { return nil }
        return path.astras[tier]
    }

    var requiredAgeForNextTier: Age? {
        switch tier {
        case 1: return .middle
        case 2: return .modern
        case 3: return .modern   // T3 → T4 still modern; cost is the real gate
        default: return nil
        }
    }

    var upgradeCost: Resources {
        nextAstra?.cost ?? Resources()
    }

    var sellValue: Resources {
        var total = Resources()
        for i in 0..<tier {
            total = total + path.astras[i].cost
        }
        return total.scaled(by: 0.5)
    }
}

struct Building: Identifiable {
    let id = UUID()
    let slotIndex: Int
    let position: CGPoint
    let kind: BuildingKind
    var level: Int = 1
    var partial: Double = 0  // fractional accumulator
    /// Buildings can be smashed by tower-attacking bosses. Lower than tower HP
    /// (200) because mines aren't built for combat — losing a maxed mine to a
    /// Vritra or Kali Yuga is the explicit cost of poor placement.
    var hp: Double = 120
    var maxHP: Double = 120

    /// Per-tier production multipliers. For 3-level buildings (everything
    /// except Gold Mine): L1=1.0, L2=2.5, L3=5.5 (the existing curve).
    /// Gold Mine gets a NEW intermediate L3=3.8 inserted between L2 and the
    /// old cap (now L4=5.5). Final production at max is unchanged from
    /// before — the extra step is a soft cost gate, not a power buff.
    static let levelMultipliers: [Double] = [0, 1.0, 2.5, 3.8, 5.5]
    var genPerSec: Double {
        // 3-level buildings cap at L3=5.5×; clamp them to that index even
        // though the multipliers array has 5 entries.
        let cap = kind.maxLevel
        let lvl = min(level, cap)
        // For the 3-level buildings, L3 needs to land on the 5.5× slot
        // (the last entry), not the new 3.8× intermediate.
        let idx: Int
        if cap == 4 {
            idx = lvl                           // gold-mine: direct mapping
        } else {
            idx = (lvl == 3) ? 4 : lvl          // 3-level: L3 → 5.5 slot
        }
        return kind.baseGenPerSec * Self.levelMultipliers[idx]
    }

    /// Cost multiplier applied to the building's base cost when upgrading
    /// FROM level `lvl`. Gold Mine's extra middle step has its own cost so
    /// the total to-max isn't an absurd jump — just a real cost for the
    /// extra ground covered.
    static func upgradeCostMultiplier(fromLevel lvl: Int, maxLevel: Int) -> Double {
        if maxLevel == 4 {
            // Gold mine — steep climb, with both the middle and final
            // upgrades being premium investments. The new L3 middle tier
            // costs as much as the old final upgrade did, and the apex
            // L3→L4 step is the real luxury at 1,284 g.
            switch lvl {
            case 1: return 4.2   // L1 → L2  (252 g)
            case 2: return 11.2  // L2 → L3  (672 g)
            case 3: return 21.4  // L3 → L4  (1,284 g — apex)
            default: return 0
            }
        } else {
            // 3-level buildings — unchanged original cost curve.
            switch lvl {
            case 1: return 2.1   // L1 → L2
            case 2: return 2.8   // L2 → L3
            default: return 0
            }
        }
    }

    var upgradeCost: Resources {
        kind.cost.scaled(by: Self.upgradeCostMultiplier(fromLevel: level,
                                                        maxLevel: kind.maxLevel))
    }

    var sellValue: Resources {
        // 50% refund on total spent (base + every upgrade) — keeps the
        // refund ratio constant as the building levels up.
        var spent = kind.cost
        if level > 1 {
            for lvl in 1..<level {
                spent = spent + kind.cost.scaled(by: Self.upgradeCostMultiplier(fromLevel: lvl, maxLevel: kind.maxLevel))
            }
        }
        return spent.scaled(by: 0.5)
    }
}

// MARK: - Difficulty scaling

enum Difficulty {
    /// HP scaling — gentle 1-2, then +38% per 2 waves. Tuned for the
    /// 16-wave arc so the W16 endgame lands around 9× base HP instead of
    /// the unkillable 17× the steeper 1.50 base produced on a longer
    /// timeline.
    static func hpMultiplier(wave: Int) -> Double {
        if wave <= 2 { return 1.0 }
        let tier = (wave - 2) / 2
        return pow(1.38, Double(tier))
    }
    /// Speed: +18% every 3 waves, capped at 1.85× — slightly higher cap
    /// now that the arc runs 16 waves so late-wave fodder still bites with
    /// real pace pressure.
    static func speedMultiplier(wave: Int) -> CGFloat {
        let tier = max(0, (wave - 1) / 3)
        return min(1.85, pow(1.18, CGFloat(tier)))
    }
    /// Boss tower damage: +33% per 3-wave step. Tuned for the 16-wave arc
    /// so a W16 Ravana hits ~4× base instead of 6.4× — still enough to
    /// crack a fresh L1 tower in 2 hits, but a maxed tower can survive
    /// long enough for healers/Rekha aura to do their job.
    static func bossDamageMultiplier(wave: Int) -> Double {
        let tier = max(0, (wave - 1) / 3)
        return pow(1.33, Double(tier))
    }
    /// Spawn interval shortens fast.
    static func spawnInterval(baseWave n: Int) -> TimeInterval {
        max(0.12, 0.80 - Double(n) * 0.055)
    }
}

struct Enemy: Identifiable {
    let id = UUID()
    let kind: EnemyKind
    var hp: Double
    /// Mutable so Kali Yuga can permanently grow his cap each time he
    /// consumes a tower. Other enemies never change it after spawn.
    var maxHP: Double
    var distance: CGFloat
    var position: CGPoint
    var heading: CGPoint

    var burnRemaining: TimeInterval = 0
    var burnDPS: Double = 0
    var slowRemaining: TimeInterval = 0
    var slowFactor: CGFloat = 1.0
    var detected: Bool = false
    var attackCooldown: TimeInterval = 0
    var freezeRemaining: TimeInterval = 0
    /// Cumulative time spent frozen in the current streak — when this
    /// exceeds the cap, the enemy thaws and gains brief immunity so it
    /// can't be locked in place forever.
    var freezeStreak: TimeInterval = 0
    /// While > 0, incoming freezes are ignored (chill immunity).
    var freezeImmunity: TimeInterval = 0

    // Wave-scaled stats
    var speedMultiplier: CGFloat = 1.0
    var towerDamageOverride: Double = 0  // 0 = use kind default

    /// Empowered Kali Yuga only — when the player lands an attack the Amrit
    /// Kalash inside his body flashes into view for a brief window. Decays to 0.
    var kalashReveal: TimeInterval = 0
    /// Empowered Kali Yuga only — regenerates this much HP/sec while > 0.
    var regenPerSec: Double = 0

    /// Number of player towers/buildings this enemy has destroyed. Drives the
    /// "blood rage" empowerment — every kill grants +25% damage to its next
    /// attacks, capped to keep bosses from one-shotting late towers.
    var towerKills: Int = 0
}

struct Projectile: Identifiable {
    let id = UUID()
    var position: CGPoint
    var heading: CGPoint = CGPoint(x: 1, y: 0)
    let targetID: UUID
    let damage: Double
    let speed: CGFloat
    let splashRadius: CGFloat?
    let color: Color
    let burnDPS: Double
    let burnDuration: TimeInterval
    let slowFactor: CGFloat
    let slowDuration: TimeInterval
    let freezeDuration: TimeInterval
    let chainTargets: Int
    let damageType: DamageType
    let sourceTier: Int          // 1, 2, or 3 — for visual variation
    let sourceKind: TowerKind    // so projectile can render the astra's head shape
    let sourceTowerID: UUID?     // for attributing kills back to the firing tower
}

/// Cinematic muzzle-flash burst at a tower position when it fires.
/// Ages out over ~0.25s to fade.
struct FireFlash: Identifiable {
    let id = UUID()
    let position: CGPoint
    let color: Color
    let damageType: DamageType
    /// Tower tier at the moment of firing — drives the flash size,
    /// spike count, and shockwave-ring intensity in TowerFireFlash.
    let tier: Int
    /// Which astra fired. Used by the flash renderer to overlay astra-
    /// specific Sanskrit glyphs (श्री on Sudarshana Chakra,
    /// भम्भ्र on Bhambhrastra, ॐ on Pashupatastra, etc.).
    let sourceKind: TowerKind
    var age: TimeInterval = 0
    static let lifetime: TimeInterval = 0.30
}

/// Floating damage number that pops off an enemy on hit and drifts upward.
struct DamageNumber: Identifiable {
    let id = UUID()
    let value: Int
    let position: CGPoint
    let color: Color
    let isCrit: Bool
    var age: TimeInterval = 0
    static let lifetime: TimeInterval = 0.65
}

/// A jagged "lightning" bolt drawn from a boss enemy to a tower it just hit.
/// Renders for a short flash then fades out.
struct BossAttackFlash: Identifiable {
    let id = UUID()
    let from: CGPoint
    let to: CGPoint
    let color: Color
    var age: TimeInterval = 0
    static let lifetime: TimeInterval = 0.35
}

struct BuildSlot: Identifiable {
    let id = UUID()
    let index: Int
    let position: CGPoint
}

// MARK: - Enemy

enum EnemyKind: String, CaseIterable {
    case pishacha, rakshasa, daitya, asura, vetala, mahishasura, ravana
    case mayavi      // invisible scout
    case indrajit    // invisible boss (Ravana's son, master of illusion)
    // Resource bearers — tough, slow, drop big resource rewards if killed
    case lobhaYaksha     // gold bearer
    case lohaAsura       // metal bearer
    case yantraPishacha  // tech bearer
    case taraDevi        // jotisha bearer
    case rishiAtma       // veda bearer
    // Stone bearer — drops a random power stone (Chuni/Panna/Nila/Raktamukhi)
    // on kill so the player can attach/upgrade stones without dipping into
    // gold/metal/tech reserves. Spawns 1-2 per wave.
    case maniMurta
    // Specialist demons — each demands a different astra mix
    case raktabija       // heavy regen; only non-physical damage works
    case tarakasura      // armored boss; fire + water bounce off
    case bhasmasura      // fire incarnate; melts towers, fire-immune
    case vritra          // drought serpent; water + ice useless
    case putana          // disguised demoness; only divine damage works
    case kaliYuga       // FINAL BOSS — only the Sudarshan Chakra can kill it

    var displayName: String {
        switch self {
        case .pishacha:       return "Pishacha"
        case .rakshasa:       return "Rakshasa"
        case .daitya:         return "Daitya"
        case .asura:          return "Asura"
        case .vetala:         return "Vetala"
        case .mahishasura:    return "Mahishasura"
        case .ravana:         return "Ravana"
        case .mayavi:         return "Mayavi"
        case .indrajit:       return "Indrajit"
        case .lobhaYaksha:    return "Lobha Yaksha"
        case .lohaAsura:      return "Loha Asura"
        case .yantraPishacha: return "Yantra Pishacha"
        case .taraDevi:       return "Tara Devi"
        case .rishiAtma:      return "Rishi Atma"
        case .maniMurta:      return "Mani Murta"
        case .raktabija:      return "Raktabija"
        case .tarakasura:     return "Tarakasura"
        case .bhasmasura:     return "Bhasmasura"
        case .vritra:         return "Vritra"
        case .putana:         return "Putana"
        case .kaliYuga:      return "Kali Yuga"
        }
    }

    var maxHP: Double {
        // Bumped again — another +20% across the board to keep the runaway
        // late-game defence honest. Kali Yuga's HP stays fixed (chakra
        // timing). Kill rewards (gold + bazaar points) bumped in lockstep
        // so harder kills pay more.
        switch self {
        case .pishacha:    return 133      // 111 → 133  (+20%)
        case .rakshasa:    return 352      // 293 → 352
        case .daitya:      return 826      // 688 → 826
        case .asura:       return 1466     // 1222 → 1466
        case .vetala:      return 929      // 774 → 929
        case .mayavi:      return 605      // 504 → 605
        case .mahishasura: return 4000     // moderate softening — first boss is challenging but not insurmountable for T1 darts
        case .indrajit:    return 10648
        case .tarakasura:  return 7098
        case .bhasmasura:  return 2400     // moderate softening — still demanding at W3 but killable with focus fire
        case .raktabija:   return 4309     // 3591 → 4309
        case .putana:      return 3930     // 3275 → 3930
        case .vritra:      return 12655    // 10546 → 12655
        case .ravana:      return 21618    // 18015 → 21618
        case .lobhaYaksha:    return 2814  // 2345 → 2814
        case .lohaAsura:      return 4276  // 3563 → 4276
        case .yantraPishacha: return 2476  // 2063 → 2476
        case .taraDevi:       return 3151  // 2626 → 3151
        case .rishiAtma:      return 5176  // 4313 → 5176
        case .maniMurta:      return 1850  // stone bearer — tanky but soloable
        case .kaliYuga:       return 600000 // bumped to 600k. Neither chakra alone NOR Durga alone NOR central retaliation alone can fell him — every weapon has to land.
        }
    }

    var speed: CGFloat {
        switch self {
        case .pishacha:    return 95
        case .rakshasa:    return 72
        case .daitya:      return 46
        case .asura:       return 62
        case .vetala:      return 68
        case .mahishasura: return 38
        case .ravana:      return 34
        case .mayavi:      return 85
        case .indrajit:    return 40
        case .lobhaYaksha:    return 40
        case .lohaAsura:      return 35
        case .yantraPishacha: return 50
        case .taraDevi:       return 45
        case .rishiAtma:      return 38
        case .maniMurta:      return 42
        case .raktabija:      return 50
        case .tarakasura:     return 36
        case .bhasmasura:     return 60
        case .vritra:         return 32
        case .putana:         return 55
        case .kaliYuga:      return 22   // slow shambling apex; only moves when path is clear
        }
    }

    /// Boss-tier flag — used for race signature damage bonuses.
    var isBoss: Bool {
        switch self {
        case .mahishasura, .ravana, .indrajit, .tarakasura, .vritra, .kaliYuga: return true
        default: return false
        }
    }

    /// True for any enemy worth pinning a boss-info card on (includes the
    /// specialist non-isBoss demons that have unique mechanics).
    var isCardWorthy: Bool {
        switch self {
        case .mahishasura, .ravana, .indrajit, .tarakasura, .vritra, .kaliYuga,
             .bhasmasura, .raktabija, .putana:
            return true
        default: return false
        }
    }

    /// Short one-line description of what makes this enemy dangerous.
    var speciality: String {
        switch self {
        case .mahishasura: return "Heavy charging bull-demon, huge HP pool"
        case .ravana:      return "Ten-headed king, terror aura slows tower reload"
        case .indrajit:    return "Sorcerer-prince, 25% illusion miss below 50% HP"
        case .tarakasura:  return "Adamantine armor — ignores hits below 35 damage"
        case .vritra:      return "Drought serpent — halts production buildings nearby"
        case .bhasmasura:  return "Fire-immune zealot, ash aura reverts towers to T1"
        case .raktabija:   return "Blood demon, immune to physical damage"
        case .putana:      return "Cursed nursemaid, only divine weapons kill her"
        case .kaliYuga:    return "The Final Age incarnate — only Sudarshan Chakra kills him"
        default:           return ""
        }
    }

    /// What weakness the player should exploit. One short actionable line.
    var weakness: String {
        switch self {
        case .mahishasura: return "Any sustained DPS — focus-fire to drop him fast"
        case .ravana:      return "Divine astras only (Trishul / Vajrastra / Pashupatastra)"
        case .indrajit:    return "Burst him before he hits 50% HP, or accept misses"
        case .tarakasura:  return "T2+ astras OR T1 + a damage stone (Chuni / Hira)"
        case .vritra:      return "Spread mines, kill him before drought drains income"
        case .bhasmasura:  return "Any non-fire damage (physical / water / ice / divine)"
        case .raktabija:   return "Elemental or divine — never plain physical"
        case .putana:      return "Trishul / Vajrastra / Pashupatastra ONLY"
        case .kaliYuga:    return "Charge the Sudarshan Chakra and bait him into its burn"
        default:           return ""
        }
    }

    /// Sanskrit (Devanagari) entry dialog the boss roars on spawn.
    /// Empty for non-bosses.
    var entryDialog: String {
        switch self {
        case .mahishasura: return "त्रैलोक्ये कोऽपि मां जेतुं न शक्नोति!"
        case .ravana:      return "लङ्केश्वरोऽहम् — कः मे सम्मुखे तिष्ठेत्?"
        case .indrajit:    return "मायया त्वां वञ्चयिष्यामि!"
        case .tarakasura:  return "मम कवचं वज्रादपि कठिनम्!"
        case .vritra:      return "वृष्टिं विना मरिष्यन्ति तव यन्त्राणि!"
        case .bhasmasura:  return "स्पर्शेन भस्म करिष्यामि सर्वम्!"
        case .raktabija:   return "रक्तबिन्दुतो जन्म — मां हन्तुं न शक्यम्!"
        case .putana:      return "विषेण मम स्तन्यं — मधुरं मरणम्!"
        case .kaliYuga:    return "कलिः अहम् — धर्मस्य अन्तः समागतः!"
        default:           return ""
        }
    }

    /// English translation paired with the entry dialog.
    var entryTranslation: String {
        switch self {
        case .mahishasura: return "“No one in the three worlds can defeat me!”"
        case .ravana:      return "“I am the king of Lanka — who dares stand before me?”"
        case .indrajit:    return "“My illusions shall deceive you!”"
        case .tarakasura:  return "“My armor is harder than thunderbolts!”"
        case .vritra:      return "“Without rain, your machines shall perish!”"
        case .bhasmasura:  return "“At my touch I shall reduce all to ash!”"
        case .raktabija:   return "“Every drop births another — I cannot be slain!”"
        case .putana:      return "“My milk is poison — a sweet death awaits!”"
        case .kaliYuga:    return "“I am Kali Yuga — the end of dharma has come!”"
        default:           return ""
        }
    }

    /// Bazaar points granted for killing this enemy. Per-run currency; resets at game over.
    var bazaarPointReward: Int {
        // Bumped +30% in lockstep with the HP increase so harder kills pay
        // proportionally more — keeps the bazaar economy matching the new
        // enemy power curve.
        switch self {
        case .pishacha:       return 1     // 1 → 1 (rounded floor)
        case .rakshasa:       return 2     // 1 → 2
        case .daitya:         return 3     // 2 → 3
        case .asura:          return 4     // 3 → 4
        case .vetala:         return 3     // 2 → 3
        case .mahishasura:    return 46    // 35 → 46
        case .ravana:         return 117   // 90 → 117
        case .mayavi:         return 4     // 3 → 4
        case .indrajit:       return 72    // 55 → 72
        case .lobhaYaksha:    return 5     // 4 → 5
        case .lohaAsura:      return 7     // 5 → 7
        case .yantraPishacha: return 5     // 4 → 5
        case .taraDevi:       return 7     // 5 → 7
        case .rishiAtma:      return 7     // 5 → 7
        case .maniMurta:      return 8     // stone bearer — pays in bazaar pts too
        case .raktabija:      return 29    // 22 → 29
        case .tarakasura:     return 65    // 50 → 65
        case .bhasmasura:     return 23    // 18 → 23
        case .vritra:         return 91    // 70 → 91
        case .putana:         return 36    // 28 → 36
        case .kaliYuga:       return 520   // 400 → 520 (victory reward)
        }
    }

    var reward: Int {
        // Gold drop on kill — +30% across the board to match the new
        // HP curve. Player needs the extra income to fund the steeper
        // age-upgrade and gold-mine costs introduced this session.
        switch self {
        case .pishacha:    return 7        // 5 → 7
        case .rakshasa:    return 14       // 11 → 14
        case .daitya:      return 33       // 25 → 33
        case .asura:       return 55       // 42 → 55
        case .vetala:      return 39       // 30 → 39
        case .mahishasura: return 416      // 320 → 416
        case .ravana:      return 1170     // 900 → 1170
        case .mayavi:      return 52       // 40 → 52
        case .indrajit:    return 806      // 620 → 806
        case .lobhaYaksha:    return 72    // 55 → 72
        case .lohaAsura:      return 91    // 70 → 91
        case .yantraPishacha: return 65    // 50 → 65
        case .taraDevi:       return 85    // 65 → 85
        case .rishiAtma:      return 98    // 75 → 98
        case .maniMurta:      return 110   // stone bearer
        case .raktabija:      return 286   // 220 → 286
        case .tarakasura:     return 650   // 500 → 650
        case .bhasmasura:     return 221   // 170 → 221
        case .vritra:         return 936   // 720 → 936
        case .putana:         return 338   // 260 → 338
        case .kaliYuga:       return 4550  // 3500 → 4550 (huge victory drop)
        }
    }

    var radius: CGFloat {
        switch self {
        case .pishacha:    return 13
        case .rakshasa:    return 17
        case .daitya:      return 22
        case .asura:       return 25
        case .vetala:      return 18
        case .mahishasura: return 32
        case .ravana:      return 40
        case .mayavi:      return 16
        case .indrajit:    return 30
        case .lobhaYaksha:    return 22
        case .lohaAsura:      return 26
        case .yantraPishacha: return 20
        case .taraDevi:       return 23
        case .rishiAtma:      return 28
        case .maniMurta:      return 28
        case .raktabija:      return 24
        case .tarakasura:     return 34
        case .bhasmasura:     return 22
        case .vritra:         return 36
        case .putana:         return 24
        case .kaliYuga:      return 50   // visually massive
        }
    }

    var color: Color {
        switch self {
        case .pishacha:    return .yellow
        case .rakshasa:    return .red
        case .daitya:      return .purple
        case .asura:       return Color(red: 0.95, green: 0.15, blue: 0.4)
        case .vetala:      return Color(red: 0.7, green: 0.7, blue: 0.9)
        case .mahishasura: return .pink
        case .ravana:      return Color(red: 0.95, green: 0.35, blue: 0.05)
        case .mayavi:      return Color(red: 0.55, green: 0.85, blue: 0.85)
        case .indrajit:    return Color(red: 0.50, green: 0.30, blue: 0.85)
        case .lobhaYaksha:    return .yellow
        case .lohaAsura:      return Color(red: 0.78, green: 0.78, blue: 0.85)
        case .yantraPishacha: return .cyan
        case .taraDevi:       return .purple
        case .rishiAtma:      return .orange
        case .maniMurta:      return Color(red: 0.85, green: 0.25, blue: 0.55)  // ruby-pink — gem coloured
        case .raktabija:      return Color(red: 0.65, green: 0.05, blue: 0.10)   // blood-red
        case .tarakasura:     return Color(red: 0.55, green: 0.25, blue: 0.10)   // rust armour
        case .bhasmasura:     return Color(red: 0.35, green: 0.30, blue: 0.30)   // charcoal ash
        case .vritra:         return Color(red: 0.10, green: 0.30, blue: 0.30)   // serpent teal
        case .putana:         return Color(red: 0.30, green: 0.65, blue: 0.30)   // poison green
        case .kaliYuga:      return Color(red: 0.08, green: 0.05, blue: 0.18)   // void black
        }
    }

    var symbol: String {
        switch self {
        case .pishacha:    return "ant.fill"
        case .rakshasa:    return "figure.walk"
        case .daitya:      return "figure.stand"
        case .asura:       return "person.fill"
        case .vetala:      return "moon.stars.fill"
        case .mahishasura: return "pawprint.fill"
        case .ravana:      return "crown.fill"
        case .mayavi:      return "questionmark.diamond.fill"
        case .indrajit:    return "moon.haze.fill"
        case .lobhaYaksha:    return "dollarsign.circle.fill"
        case .lohaAsura:      return "gearshape.fill"
        case .yantraPishacha: return "cpu.fill"
        case .taraDevi:       return "moon.stars.fill"
        case .rishiAtma:      return "book.closed.fill"
        case .maniMurta:      return "diamond.fill"
        case .raktabija:      return "drop.fill"
        case .tarakasura:     return "shield.lefthalf.filled"
        case .bhasmasura:     return "flame.circle.fill"
        case .vritra:         return "cloud.bolt.rain.fill"
        case .putana:         return "leaf.fill"
        case .kaliYuga:      return "crown.fill"
        }
    }

    var regenPerSec: Double {
        switch self {
        case .vetala:    return 10
        case .raktabija: return 8   // signature: heavy blood regeneration
        // Kali Yuga heals while burning. Doubled to 500 HP/sec so even a
        // fully-divine chakra (3135 DPS) is only 2635 net — 228 s to kill
        // alone. The player MUST stack Durga strikes (18k per fire on 8s
        // cooldown) AND the central tower's 80px retaliation (600 DPS ×
        // (1 + 0.25 × alive divine)) to close the gap inside 100-120 s.
        case .kaliYuga:  return 500
        default:         return 0
        }
    }

    var immunities: Set<DamageType> {
        switch self {
        case .pishacha:    return []
        case .rakshasa:    return [.fire]
        case .daitya:      return [.ice]
        case .asura:       return [.physical]
        case .vetala:      return [.ice, .water]
        case .mahishasura: return [.fire, .ice]                            // tougher: fire + ice immune
        case .ravana:      return [.fire, .ice, .water, .physical]         // only divine works
        case .mayavi:      return []
        case .indrajit:    return [.physical, .fire]
        case .lobhaYaksha:    return [.water]              // pure greed quenches fire/ice but loathes water
        case .lohaAsura:      return [.physical, .fire]    // iron-armored
        case .yantraPishacha: return [.ice]                // machine — frozen circuits resist
        case .taraDevi:       return [.fire]               // starlight unburnt
        case .rishiAtma:      return [.physical]           // saintly soul, unphysical
        case .maniMurta:      return []                    // no immunities
        case .raktabija:      return [.physical]           // blood demon — every drop spawns more; only elemental/divine works
        case .tarakasura:     return [.fire, .water]       // forged armour quenches both
        case .bhasmasura:     return [.fire]               // fire incarnate
        case .vritra:         return [.water, .ice]        // serpent of drought; embodies absence of water
        case .putana:         return [.physical, .fire, .water, .ice]  // only divine touch slays her
        case .kaliYuga:      return [.physical, .fire, .water, .ice]  // realistically only the chakra kills him
        }
    }

    var isInvisible: Bool {
        switch self {
        case .mayavi, .indrajit: return true
        default: return false
        }
    }

    var attacksTowers: Bool {
        switch self {
        case .mahishasura, .ravana, .indrajit, .tarakasura, .vritra,
             .bhasmasura, .putana, .kaliYuga: return true
        default: return false
        }
    }

    var towerDamage: Double {
        // Tower HP base jumped 10× (200 → 2000) so enemy bites scale ~5–6×
        // to keep boss attacks meaningful. Buildings are now invulnerable
        // to boss attacks, so this is purely the tower-melee value.
        switch self {
        case .mahishasura: return 280
        case .ravana:      return 620
        case .indrajit:    return 430
        case .tarakasura:  return 370
        case .vritra:      return 520
        case .bhasmasura:  return 230
        case .putana:      return 240   // siphon scales with damage
        case .kaliYuga:    return 960   // doubled (was 480) — every tower swallowed costs the player far more
        default: return 0
        }
    }

    var attackInterval: TimeInterval {
        switch self {
        case .mahishasura: return 1.0
        case .ravana:      return 0.8
        case .indrajit:    return 0.7
        case .tarakasura:  return 0.9
        case .vritra:      return 0.8
        case .bhasmasura:  return 1.1
        case .putana:      return 1.0
        case .kaliYuga:   return 1.0
        default: return 0
        }
    }

    /// Bonus resource drop when killed (in addition to gold reward)
    var resourceDrop: Resources {
        switch self {
        case .lobhaYaksha:    return Resources(gold: 200)
        case .lohaAsura:      return Resources(metal: 90)
        case .yantraPishacha: return Resources(tech: 70)
        case .taraDevi:       return Resources(jotisha: 80)
        case .rishiAtma:      return Resources(veda: 60)
        default: return Resources()
        }
    }

    var isResourceBearer: Bool {
        switch self {
        case .lobhaYaksha, .lohaAsura, .yantraPishacha, .taraDevi, .rishiAtma: return true
        default: return false
        }
    }

    /// True for the stone-bearer. Treated like the resource bearers in
    /// wave-scaling (not duplicated by path size) but drops a random
    /// power stone into the player's inventory instead of resources.
    var isStoneBearer: Bool { self == .maniMurta }
}

// MARK: - View Model

@Observable
final class GameViewModel {
    var race: Race? = nil
    var stock: Resources = Resources()

    /// Player's per-run inventory of power stones harvested from killing
    /// Mani Murta enemies. When attaching or upgrading a stone, the
    /// inventory is consumed first (bypassing the gold/metal/tech cost) —
    /// only when inventory is empty does the resource cost apply.
    /// Persists for the current run, reset on game restart.
    var stoneInventory: [StoneKind: Int] = [:]

    /// How many stones of `kind` the player currently holds.
    func stoneCount(_ kind: StoneKind) -> Int { stoneInventory[kind] ?? 0 }

    /// The central tower's HP pool. Every breaching enemy chips it down,
    /// scaled by their breach-damage and the wave they came from. Reaches 0
    /// = game over. Wider than the old "lives" framing so late-wave enemies
    /// can credibly threaten the central tower over several breaches without
    /// any single one being an instant kill.
    var lives: Int = 60
    /// Maximum HP of the central tower at the start of a fresh run. Used by
    /// the relic HP bar.
    var maxLives: Int = 60
    /// Brief timer (seconds) that drives the Sudarshan relic hit-flash animation.
    var relicHitFlash: TimeInterval = 0
    var score: Int = 0
    var wave: Int = 0
    var isWaveActive: Bool = false

    // MARK: - Adaptive wave difficulty
    //
    // The deeper enemies pushed in the prior wave, the easier the player's
    // defence was holding the line — and the steeper the next wave ramps to
    // restore tension. Inversely, if the player flattens every enemy near
    // spawn, the next wave is sent with the same baseline so the player
    // isn't punished for stacking towers well. Tracked as a non-decaying
    // multiplier so winning ground stays won.
    /// Running multiplier applied to enemy HP and tower-damage at spawn.
    /// Capped at 2.4× so the game can punish a snowballing defence harder —
    /// stacks with Difficulty.hpMultiplier (already 9× by W16). At the cap
    /// a runaway player still faces a real ramp, but the cap prevents an
    /// unkillable spiral.
    var adaptivePowerMultiplier: Double = 1.0
    /// Sum of (distance / pathLength) for every non-boss enemy that was
    /// killed-or-breached during the current wave.
    private var waveProgressSum: CGFloat = 0
    /// Number of samples in `waveProgressSum`.
    private var waveProgressCount: Int = 0
    /// Highest fraction of the path any non-boss enemy reached during the
    /// current wave (0..1). If by wave end this is below the "near central
    /// tower" threshold (0.8), the next wave's enemy power gets a flat
    /// bump even if average kill depth was already mid-range.
    private var deepestEnemyFraction: CGFloat = 0
    /// Threshold beyond which an enemy is considered to be "near the
    /// central tower". Below this means defence is dominant enough that
    /// the next wave should ramp up.
    static let nearCentralTowerFraction: CGFloat = 0.80
    /// Time-of-spawn (relative to wave start) recorded against each enemy id,
    /// so when it dies we can compute its lifetime and grow the time-to-kill
    /// histogram for adaptive scaling.
    private var enemySpawnTime: [UUID: TimeInterval] = [:]
    /// Cumulative lifetime (seconds) of non-boss enemies killed during this
    /// wave. Combined with `waveKillCount` to compute average time-to-kill.
    private var waveKillTimeSum: TimeInterval = 0
    /// How many non-boss enemies were killed during this wave (used for the
    /// time-to-kill average).
    private var waveKillCount: Int = 0
    /// Seconds elapsed since the current wave began (zeroed at startNextWave,
    /// advanced from the game loop tick).
    private var waveElapsed: TimeInterval = 0
    var isGameOver: Bool = false
    var newAgeBanner: Age? = nil
    /// Briefly visible at the start of every 7th wave so the player knows
    /// dynamic resource bearers are inbound.
    var resourceWaveBanner: Bool = false
    private var lastSeenAge: Age = .ancient

    var towers: [Tower] = []
    var buildings: [Building] = []
    var enemies: [Enemy] = []

    /// Active boss-entry dialog overlay. Drops the screen into a brief
    /// dramatic moment when a card-worthy boss spawns. Nil = no overlay.
    var bossDialog: (kind: EnemyKind, timer: TimeInterval)? = nil

    /// Boss info card visibility. Set to >0 when a boss spawns or the
    /// player taps a boss enemy; decays in the game tick. When it hits 0
    /// the sticky-note card disappears so it doesn't clutter the field.
    var bossInfoCardTimer: TimeInterval = 0
    /// Which enemy ID owns the currently-visible boss info card. Lets the
    /// card persist focus on the boss the player tapped, even if multiple
    /// bosses are on screen.
    var bossInfoCardEnemyID: UUID? = nil
    /// How long a boss info card stays visible after being triggered.
    static let bossInfoCardLifetime: TimeInterval = 6.0

    /// Tapping a boss enemy or fresh-spawn brings its info card back up
    /// for `bossInfoCardLifetime` seconds.
    func showBossInfoCard(enemyID: UUID) {
        bossInfoCardEnemyID = enemyID
        bossInfoCardTimer = Self.bossInfoCardLifetime
    }
    /// Which boss kinds have already declared their entry this run — used
    /// to fire each dialog exactly once.
    private var seenBossDialogs: Set<EnemyKind> = []
    /// How long the dialog stays on screen.
    static let bossDialogLifetime: TimeInterval = 3.2
    var projectiles: [Projectile] = []
    var fireFlashes: [FireFlash] = []
    var damageNumbers: [DamageNumber] = []
    var slots: [BuildSlot] = []

    // MARK: - UX assists (tap-minimisation toggles + memory)

    /// When true, the next wave auto-starts after `autoStartCountdown`
    /// seconds once the current wave completes. Cancelable by tapping
    /// the countdown badge.
    var autoStartWave: Bool = false
    /// Seconds remaining in the auto-start countdown. > 0 = visible badge.
    var autoStartCountdown: TimeInterval = 0
    /// Length of the auto-start countdown in seconds — long enough to
    /// plan a placement, short enough to feel snappy.
    static let autoStartCountdownLength: TimeInterval = 3.0

    /// When set, tapping a build slot bypasses the BuildMenu and constructs
    /// this tower path directly. Tap the same icon in the quick-build bar
    /// again to disarm. Persists across slot placements so the player can
    /// drop a row of identical towers with a single tap each.
    var armedQuickBuildPath: TowerPath? = nil

    /// Same pattern as `armedQuickBuildPath` but for resource buildings.
    /// Only one of (tower / building) can be armed at a time — setting one
    /// clears the other so the player isn't surprised by which one places.
    var armedQuickBuildBuilding: BuildingKind? = nil

    /// Arms a tower path for one-tap placement and disarms any building.
    func armQuickBuildTower(_ path: TowerPath?) {
        armedQuickBuildPath = path
        if path != nil { armedQuickBuildBuilding = nil }
    }

    /// Arms a building for one-tap placement and disarms any tower.
    func armQuickBuildBuilding(_ kind: BuildingKind?) {
        armedQuickBuildBuilding = kind
        if kind != nil { armedQuickBuildPath = nil }
    }

    /// Most recently built tower path. Used by the quick-build bar to
    /// pre-highlight a sensible default.
    var lastBuiltPath: TowerPath? = nil

    /// When true, any tower that can afford the next heal-aura tier
    /// auto-upgrades at wave start. Same for shield aura.
    var autoBuyAura: Bool = false

    // MARK: - God Mode (resource buildings attack briefly)
    //
    // Tap → for `godModeDuration` seconds, every resource building also
    // fires projectiles at nearby enemies. Heavy mid/late-game panic
    // button — gated to W8+ because it's powerful enough to clear a
    // bottleneck wave on its own. Premium cost so it's a real choice.
    var godModeTimer: TimeInterval = 0
    /// Per-building fire cooldown while god-mode is active. Keyed by
    /// building UUID so each one fires on its own cadence.
    var godModeBuildingCooldown: [UUID: TimeInterval] = [:]
    static let godModeDuration: TimeInterval = 12.0
    static let godModeUnlockWave: Int = 8
    /// Base Pralay cost (first activation). Every subsequent activation
    /// multiplies the cost by `godModeCostEscalation` — the LAST attack of
    /// the run is therefore the most expensive. Tuned so 1 use is cheap-
    /// ish, 2 is expensive, 3 is "save the run" territory, 4+ is mythic.
    static let godModeActivationCost = Resources(gold: 7000, metal: 800, tech: 600, jotisha: 800, veda: 800)
    /// Multiplier applied per prior use — 1.75× compounds steeply:
    /// use 1 = 1.00×, use 2 = 1.75×, use 3 = 3.06×, use 4 = 5.36×, use 5 = 9.38×.
    static let godModeCostEscalation: Double = 1.75
    /// Per-shot damage from a god-mode building — heavy enough to clear
    /// fodder in 1-2 hits and bleed bosses fast.
    static let godModeBuildingDamage: Double = 240
    static let godModeBuildingFireInterval: TimeInterval = 0.4
    static let godModeBuildingRange: CGFloat = 320

    /// How many times Pralay has already been triggered this run. Drives
    /// the escalating activation cost.
    var godModeUses: Int = 0

    /// Resource cost of the NEXT Pralay activation, given the number of
    /// previous uses this run. View layer reads this for the button label.
    var nextGodModeCost: Resources {
        Self.godModeActivationCost.scaled(by: pow(Self.godModeCostEscalation, Double(godModeUses)))
    }

    var isGodModeActive: Bool { godModeTimer > 0 }

    func canActivateGodMode() -> Bool {
        guard !isGodModeActive else { return false }
        guard wave >= Self.godModeUnlockWave else { return false }
        return stock.canAfford(nextGodModeCost)
    }

    func activateGodMode() {
        guard canActivateGodMode() else { return }
        stock = stock - nextGodModeCost
        godModeUses += 1
        godModeTimer = Self.godModeDuration
        godModeBuildingCooldown.removeAll(keepingCapacity: true)
        SoundEngine.shared.playAgeUnlocked()
    }

    // MARK: - Wall (one-wave emergency defence)
    //
    // Tapping the Wall HUD button consumes resources, fully heals every
    // tower, and grants a damage-absorbing shield (wallShield) to each
    // for the rest of the current wave. The shield expires at wave end.
    // Designed for "oh no this wave is brutal" moments — a panic button
    // with a real cost that turns the tide for one wave.
    var wallActiveThisWave: Bool = false
    /// One-time cost to activate the wall. Premium resources so the
    /// player can't spam it every wave — has to be saved for clutch moments.
    // MARK: - Sudarshan burst (partial-charge offensive discharge)
    //
    // The fully-charged Sudarshan chakra is reserved for Kali Yuga, but
    // the player can also tap a "Burst" button to spend a portion of the
    // current charge on an instant area-damage shockwave against mid-game
    // bosses (Mahishasura, Ravana, etc. — Kali Yuga is immune).
    //
    /// Minimum charge fraction required to fire a burst.
    static let sudarshanBurstMinCharge: Double = 0.20
    /// Charge fraction consumed per burst.
    static let sudarshanBurstCost: Double = 0.20
    /// Burst damage applied to every non-Kali-Yuga enemy on screen, scaled
    /// by the chakra's current charge at fire time.
    static let sudarshanBurstDamageMax: Double = 25000

    /// True if the player can fire a burst right now.
    func canFireSudarshanBurst() -> Bool {
        sudarshanPhase == .charging
        && sudarshanCharge >= Self.sudarshanBurstMinCharge
    }

    /// Discharge a partial-charge burst — deals area damage to every
    /// non-Kali-Yuga enemy, scaled by the chakra's current charge.
    /// Returns true if the burst fired.
    @discardableResult
    func fireSudarshanBurst() -> Bool {
        guard canFireSudarshanBurst() else { return false }
        let dmg = Self.sudarshanBurstDamageMax * sudarshanCharge
        sudarshanCharge = max(0, sudarshanCharge - Self.sudarshanBurstCost)
        for i in enemies.indices where enemies[i].hp > 0 {
            if enemies[i].kind == .kaliYuga { continue }
            enemies[i].hp -= dmg
            bossAttackFlashes.append(BossAttackFlash(
                from: sudarshanPosition,
                to: enemies[i].position,
                color: Color(red: 1.0, green: 0.85, blue: 0.20)
            ))
        }
        SoundEngine.shared.playAgeUnlocked()
        HapticsEngine.shared.bossKilled()
        return true
    }

    /// HP-equivalent shield granted to every tower when the wall fires.
    /// Bumped to 5000 so a late-wave boss strike (~3000-4000 dmg) can't
    /// rip through the shield in a single hit.
    static let wallShieldAmount: Double = 5000

    /// Per-stone wall duration. Higher-tier stones buy more wall-seconds.
    /// Chuni cheapest (10 s), Raktamukhi premium (25 s).
    static func wallDuration(for kind: StoneKind) -> TimeInterval {
        switch kind {
        case .chuni:      return 10
        case .panna:      return 14
        case .nila:       return 18
        case .raktamukhi: return 28
        }
    }

    /// Stone-priority order — when the player taps Wall, the highest-tier
    /// stone available is consumed automatically so the longest possible
    /// wall fires from a single tap.
    private static let wallStonePriority: [StoneKind] = [.raktamukhi, .nila, .panna, .chuni]

    /// Picks the best stone the player currently owns for wall activation,
    /// or nil if inventory is empty.
    func bestWallStone() -> StoneKind? {
        Self.wallStonePriority.first(where: { stoneCount($0) > 0 })
    }

    /// Wall remaining seconds — 0 means inactive. Decays in the update tick.
    /// Replaces the old wave-long flag so wall is now a TIMED ability.
    var wallTimer: TimeInterval = 0
    /// Original duration the wall was activated with (for progress-bar math).
    var wallActivationDuration: TimeInterval? = nil

    /// True if a wall can be activated right now: not already running, has
    /// at least one tower to protect, and at least one stone in inventory.
    func canActivateWall() -> Bool {
        guard wallTimer <= 0 else { return false }
        guard !towers.isEmpty else { return false }
        return bestWallStone() != nil
    }

    /// Consume the best available stone, fully heal every tower, and grant
    /// the wall shield. Wall duration is determined by the stone kind used.
    func activateWall() {
        guard wallTimer <= 0 else { return }
        guard !towers.isEmpty else { return }
        guard let kind = bestWallStone() else { return }
        stoneInventory[kind, default: 0] -= 1
        let dur = Self.wallDuration(for: kind)
        wallTimer = dur
        wallActivationDuration = dur
        wallActiveThisWave = true
        for i in towers.indices {
            towers[i].hp = towers[i].maxHP
            towers[i].wallShield = Self.wallShieldAmount
        }
        SoundEngine.shared.playBuildPlaced()
    }

    /// Apply incoming damage to a tower — wall shield absorbs first, then HP.
    /// All damage-to-tower call sites go through this helper so wall
    /// behaviour is consistent everywhere.
    func applyTowerDamage(index ti: Int, amount: Double) {
        guard ti >= 0, ti < towers.count, amount > 0 else { return }
        var remaining = amount
        if towers[ti].wallShield > 0 {
            let absorbed = min(towers[ti].wallShield, remaining)
            towers[ti].wallShield -= absorbed
            remaining -= absorbed
        }
        if remaining > 0 {
            towers[ti].hp -= remaining
        }
    }

    // Per-tick effect tracking — read by the view layer to draw auras and bolts.
    var protectedTowerIDs: Set<UUID> = []
    var healedTowerIDs: Set<UUID> = []
    var bossAttackFlashes: [BossAttackFlash] = []
    /// Towers under Raktabija's blood-grip (stop firing). Persists for the
    /// rest of the current wave once a tower is taken — cleared on
    /// wave-completion / reset.
    var controlledTowerIDs: Set<UUID> = []
    /// Towers currently inside Bhasmasura's ash aura (stats revert to T1).
    /// Recomputed every tick.
    var debuffedTowerIDs: Set<UUID> = []
    /// Towers currently being drained by Putana (transient one-tick flag for visuals).
    var drainedTowerIDs: Set<UUID> = []
    /// Towers inside an alive Ravana's terror aura — reload 50% slower.
    var terrorTowerIDs: Set<UUID> = []
    /// Buildings inside an alive Vritra's drought aura — stop producing resources.
    var droughtBuildingIDs: Set<UUID> = []

    // MARK: - Sudarshan Chakra endgame

    enum SudarshanPhase: Int {
        case inactive       // pre-Dvapara
        case charging       // center tower visible, player feeds resources
        case matured        // chakra spinning, Kali Yuga walks the path
        case rahuEclipse    // Kali Yuga first death → Rahu devours the Amrit Kalash
        case empoweredBoss  // Kali Yuga reborn + Trimurti combined-astra charge phase
        case victory        // empowered Kali Yuga finally falls
    }

    var sudarshanPhase: SudarshanPhase = .inactive
    /// 0..1 charge progress while .charging
    var sudarshanCharge: Double = 0
    /// 0..1 charge progress for the Trimurti combined astra during empowered phase
    var trimurtiCharge: Double = 0
    /// Rahu eclipse animation timer (seconds left in .rahuEclipse)
    var rahuTimer: TimeInterval = 0
    static let rahuLifetime: TimeInterval = 2.5
    /// Center tower world position (lazily set when phase enters .charging)
    var sudarshanPosition: CGPoint = .zero
    /// Rotation angle for the chakra visual (driven by SwiftUI)
    var chakraAngle: Double = 0
    /// Convenience accessor for the on-field Kali Yuga (the final boss).
    var finalBoss: Enemy? { enemies.first(where: { $0.kind == .kaliYuga }) }

    /// Trimurti tap cost — uniform across every resource so the row reads
    /// `gold = metal = tech = jotisha = veda`. 6 taps fills the meter →
    /// 600 of every resource total per full charge.
    static let trimurtiTapCost = Resources(gold: 100, metal: 100, tech: 100, jotisha: 100, veda: 100)
    static let trimurtiTapProgress: Double = 0.167   // 6 taps fills the meter
    /// Bonus chip damage applied to the empowered boss on every charge tap
    /// so the player feels each contribution land. Tuned to overcome the
    /// empowered Kali Yuga's 250 HP/sec regen across a typical 6-tap arc.
    static let trimurtiTapChipDamage: Double = 4500

    /// HP pool for the Sudarshan center tower itself — only attackable once
    /// every other defence has fallen during the empowered phase.
    var sudarshanHP: Double = 600
    var sudarshanMaxHP: Double = 600

    /// Resources required per Sudarshan charge tap. 8 taps fills the meter.
    /// Full charge = 28 000 gold + 12 000 of each other resource.
    ///
    /// Sized against the realistic 16-wave budget: 3 × L3 gold mines
    /// (~21 k g) + Wave Tribute Bazaar perk (~20 k g) + enemy drops/wave
    /// bonus (~26 k g) gives ~67 k gold to spend across the run. That's
    /// enough to land a full charge AND fund the defensive towers without
    /// the player needing to skip almost every other purchase, but only if
    /// they commit to economy infrastructure early — i.e. it still demands
    /// strategy. Same logic applies to the secondary resources, each of
    /// which now needs ~2 dedicated L3 producers to fund the full charge.
    static let sudarshanTapCost = Resources(gold: 3500, metal: 1500, tech: 1500, jotisha: 1500, veda: 1500)
    static let sudarshanTapProgress: Double = 0.125

    private(set) var pathPoints: [CGPoint] = []
    private(set) var pathLength: CGFloat = 0
    private var segmentLengths: [CGFloat] = []

    /// Multiplier applied to every enemy's effective movement speed.
    /// iPhone uses a shorter, tighter spiral than iPad/Mac so enemies would
    /// otherwise reach the Sudarshan much faster — this scale slows them
    /// down on compact devices so the player has time to react/build.
    /// Tuned to ~35% so each enemy spends meaningful seconds on the short
    /// path before reaching the relic.
    private(set) var devicePathSpeedScale: CGFloat = 1.0

    var selectedSlotIndex: Int? = nil
    var selectedTowerID: UUID? = nil
    var selectedBuildingID: UUID? = nil

    /// Run-buff Bazaar items that are active for the current run only.
    /// Instant items aren't tracked here — they apply immediately on purchase.
    var activeBazaarPerks: Set<BazaarItem> = []

    /// Bazaar points earned during the current run only. Resets every game.
    var points: Int = 0

    /// Difficulty mode chosen at race-select time. ONLY affects building
    /// resource production rate — combat math (HP, damage, drops) is the
    /// same on every mode so the player's skill is the only ramp.
    var difficulty: GameDifficulty = .hard

    /// Divine points — earned when a DIVINE-PATH tower (Trishul / Vajrastra
    /// / Narayana / Pashupatastra) lands the killing blow on a boss. They
    /// don't buy anything directly; instead they EMPOWER the Parijata
    /// Briksha. The wish-tree is inactive (production halted) until the
    /// player has placed at least one divine tower AND landed at least one
    /// divine-tower boss kill — then every divine point compounds the
    /// Parijata's universal production rate.
    var divinePoints: Int = 0

    /// Has the player placed at least one tower on the divine path? Drives
    /// the Parijata's "inactive vs active" state.
    var hasDivineTower: Bool {
        towers.contains(where: { $0.path == .divine })
    }

    /// Number of distinct DIVINE-PATH astra KINDS currently alive on the
    /// field. The four divine kinds are Trishul / Vajrastra / Narayana /
    /// Pashupatastra. Kept for analytics; the दुर्गा-Strike now demands
    /// specific T4 ULTIMATES (see `hasTrimurtiCombination`).
    var distinctDivineKindsAlive: Int {
        var seen = Set<TowerKind>()
        for t in towers where t.path == .divine && t.hp > 0 {
            seen.insert(t.kind)
        }
        return seen.count
    }

    /// The three apex astras whose convergence sounds the दुर्गा shankha:
    ///   • Sudarshana Chakra (arrow T4) — REQUIRED
    ///   • Pashupatastra    (divine T4) — REQUIRED
    ///   • Bhambhrastra (fire T4) OR Brahmasira Astra (maya T4) — EITHER
    /// All three roles must have at least ONE alive tower of the matching
    /// kind. Each pairing "batch" pools its damage into the strike.
    var trimurtiContributorKinds: [TowerKind] {
        var roles: [TowerKind] = []
        let alive: Set<TowerKind> = Set(towers.filter { $0.hp > 0 }.map { $0.kind })
        if alive.contains(.sudarshanaChakra) { roles.append(.sudarshanaChakra) }
        if alive.contains(.pashupatastra)    { roles.append(.pashupatastra) }
        if alive.contains(.brahmashirsha)    { roles.append(.brahmashirsha) }
        else if alive.contains(.brahmasiraAstra) { roles.append(.brahmasiraAstra) }
        return roles
    }

    /// True when ALL three Trimurti roles are filled (Sudarshana,
    /// Pashupatastra, and Bhambhrastra OR Brahmasira). Triggers the
    /// flagship दुर्गा combined-strike on Kali Yuga.
    var hasTrimurtiCombination: Bool { trimurtiContributorKinds.count >= 3 }

    // MARK: - Kali Yuga minion summon

    /// Seconds until Kali Yuga can summon his next batch of asura escorts.
    /// Ticks in the main update loop while he's alive on the field.
    var kaliMinionSummonCooldown: TimeInterval = 0
    /// Cooldown between successive minion summons.
    static let kaliMinionSummonInterval: TimeInterval = 10.0
    /// How many minions Kali spawns per summon. Mixed kinds so each batch
    /// presents a varied threat to nearby towers.
    static let kaliMinionsPerSummon: Int = 3

    /// Per-tick minion summon. Kali yells up a batch of asura helpers —
    /// Rakshasa lieutenants + Vetala risen-dead + Asura heavies — at his
    /// current position, ready to fight nearby towers. The summons make
    /// the relic march genuinely dangerous instead of a solo show.
    private func runKaliMinions(dt: TimeInterval) {
        guard let kaliIdx = enemies.firstIndex(where: { $0.kind == .kaliYuga && $0.hp > 0 }) else {
            // No Kali alive — reset the timer so a respawn doesn't double-pop.
            kaliMinionSummonCooldown = Self.kaliMinionSummonInterval
            return
        }
        kaliMinionSummonCooldown = max(0, kaliMinionSummonCooldown - dt)
        guard kaliMinionSummonCooldown <= 0 else { return }
        kaliMinionSummonCooldown = Self.kaliMinionSummonInterval
        let kaliPos = enemies[kaliIdx].position
        let kaliDist = enemies[kaliIdx].distance
        let kinds: [EnemyKind] = [.rakshasa, .vetala, .asura]
        for i in 0..<Self.kaliMinionsPerSummon {
            spawnKaliMinion(kind: kinds[i % kinds.count],
                            at: kaliPos,
                            pathDistance: kaliDist)
        }
        SoundEngine.shared.playEnemyDeath(kind: .kaliYuga)
        HapticsEngine.shared.bossKilled()
    }

    /// Spawns one minion at a specific point on the path (the slot Kali
    /// currently holds) so they're already inside the player's defence
    /// line and threaten towers immediately. Uses the same scaling math
    /// as `spawnEnemy` so the minions don't trivialise the wave.
    private func spawnKaliMinion(kind: EnemyKind,
                                  at position: CGPoint,
                                  pathDistance: CGFloat) {
        let adaptive = adaptivePowerMultiplier
        let ageMult = ageEnemyPowerMultiplier
        let divineBalance = divineBalancePowerMultiplier
        let hpMult = Difficulty.hpMultiplier(wave: wave)
            * pathDifficultyScale * adaptive * ageMult * divineBalance
        let scaledHP = kind.maxHP * hpMult
        let scaledTowerDmg = kind.towerDamage
            * Difficulty.bossDamageMultiplier(wave: wave)
            * adaptive * ageMult * divineBalance
        let (_, dir) = pointAndDirection(at: min(pathDistance, pathLength))
        var e = Enemy(
            kind: kind, hp: scaledHP, maxHP: scaledHP,
            distance: pathDistance, position: position, heading: dir
        )
        e.speedMultiplier = Difficulty.speedMultiplier(wave: wave)
        e.towerDamageOverride = scaledTowerDmg
        enemies.append(e)
    }

    /// Seconds remaining before the Durga combined strike can be fired
    /// again. Tick in the main update loop.
    var trimurtiStrikeCooldown: TimeInterval = 0
    /// Total cooldown between consecutive Durga strikes.
    static let trimurtiStrikeCooldownTotal: TimeInterval = 8.0
    /// Damage MULTIPLIER applied to the SUM of contributing T4 ultimates'
    /// damage. With Sudarshana(800) + Pashupatastra(1000) + Bhambhrastra(900),
    /// base sum = 2700 → ×2 = 5400 per strike (before stones/auras/etc.).
    /// Roles whose damage is higher in any given run pump this proportionally.
    static let trimurtiStrikeMultiplier: Double = 2.0
    /// Last-strike total damage, surfaced so the indicator pill can read it.
    var lastTrimurtiStrikeDamage: Double = 0

    /// Animation envelope for the in-flight Durga strike. While active the
    /// view layer draws the converging beams + Durga symbol on Kali.
    /// Long lifetime so the cinematic Sanskrit reveal has room to breathe.
    /// Three phases share this envelope:
    ///   0.00 – 0.30  beams shoot in from the three divine towers
    ///   0.30 – 0.65  energy gathers + दुर्गा writes itself letter by letter
    ///   0.65 – 1.00  shockwave bursts outward and flame ring fades
    var trimurtiStrikeTimer: TimeInterval = 0
    var trimurtiStrikeTarget: CGPoint = .zero
    var trimurtiStrikeOrigins: [CGPoint] = []
    static let trimurtiStrikeLifetime: TimeInterval = 3.0

    /// Can the दुर्गा-Strike fire right now? Requires the three Trimurti
    /// T4 roles alive, AT LEAST ONE enemy on the field (any wave, any
    /// kind — not just Kali), and a fresh cooldown.
    var canFireTrimurtiStrike: Bool {
        hasTrimurtiCombination
            && enemies.contains(where: { $0.hp > 0 })
            && trimurtiStrikeCooldown <= 0
            && trimurtiStrikeTimer <= 0
    }

    /// Fires the flagship दुर्गा combined strike. Picks ONE tower per
    /// required T4 role (Sudarshana, Pashupatastra, Bhambhrastra-or-
    /// Brahmasira), sums each role's effective damage, multiplies by 3,
    /// and lands the total as a single point-impact on the toughest
    /// enemy on the field (Kali Yuga if he's around, else the highest-
    /// HP enemy). Three beams converge from those origins, paint the
    /// Sanskrit "दुर्गा" syllable on the target, and detonate.
    /// Returns true if triggered.
    @discardableResult
    func fireTrimurtiStrike() -> Bool {
        guard canFireTrimurtiStrike else { return false }
        // Pick target: Kali Yuga if present, else the enemy with the most
        // HP on the field (so the strike chunks the worst threat).
        let targetIdx: Int? = {
            if let kali = enemies.firstIndex(where: { $0.kind == .kaliYuga && $0.hp > 0 }) {
                return kali
            }
            return enemies.indices
                .filter { enemies[$0].hp > 0 }
                .max(by: { enemies[$0].hp < enemies[$1].hp })
        }()
        guard let kaliIdx = targetIdx else { return false }
        // For each Trimurti role, pick the single strongest alive tower
        // and read its FULL effective damage (stones + auras + race +
        // boss-slayer + veteran). Each role contributes a "batch" of
        // power that gets pooled at the target.
        let roles = trimurtiContributorKinds
        guard roles.count >= 3 else { return false }
        var origins: [CGPoint] = []
        var totalRawDamage: Double = 0
        for roleKind in roles {
            // Strongest alive tower of this role kind.
            let bestTower = towers
                .filter { $0.kind == roleKind && $0.hp > 0 }
                .max(by: { damage(of: $0) < damage(of: $1) })
            guard let tower = bestTower else { return false }
            origins.append(tower.position)
            totalRawDamage += damage(of: tower)
        }
        let total = totalRawDamage * Self.trimurtiStrikeMultiplier
        lastTrimurtiStrikeDamage = total
        let target = enemies[kaliIdx].position
        trimurtiStrikeOrigins = origins
        trimurtiStrikeTarget = target
        trimurtiStrikeTimer = Self.trimurtiStrikeLifetime
        trimurtiStrikeCooldown = Self.trimurtiStrikeCooldownTotal
        // Deal damage to Kali AND any enemy in his immediate cluster.
        for i in enemies.indices where enemies[i].hp > 0 {
            let d = hypot(enemies[i].position.x - target.x,
                          enemies[i].position.y - target.y)
            if d < 100 {
                enemies[i].hp -= total
            }
        }
        // Sound the शंख (shankha / conch shell) — the temple call when
        // the three divine powers converge.
        SoundEngine.shared.playShankha()
        HapticsEngine.shared.bossKilled()
        return true
    }

    /// Per-tick cooldown + envelope ticker for the Durga strike. ALSO
    /// auto-fires the strike whenever the player has three distinct divine
    /// astra kinds alive AND Kali Yuga is on the field AND the cooldown
    /// has expired — no manual button required. The Trimurti acts the
    /// moment the cosmic conditions align.
    private func runTrimurtiStrike(dt: TimeInterval) {
        if trimurtiStrikeCooldown > 0 {
            trimurtiStrikeCooldown = max(0, trimurtiStrikeCooldown - dt)
        }
        if trimurtiStrikeTimer > 0 {
            trimurtiStrikeTimer = max(0, trimurtiStrikeTimer - dt)
        }
        // Auto-fire: combined power triggers on its own as soon as the
        // cooldown clears and the divine line is whole.
        if canFireTrimurtiStrike {
            _ = fireTrimurtiStrike()
        }
    }

    /// Cumulative count of divine-path towers EVER built this run (does NOT
    /// decrement on sell or death). Drives the "balance bump" on enemy
    /// power — every divine investment makes the next waves harder so
    /// stacking the divine line isn't free.
    var divineTowersBuiltThisRun: Int = 0

    /// Enemy-power bonus from the player's divine investment. Each divine
    /// tower built this run adds +6% enemy HP & damage on top of the
    /// adaptive + age multipliers. Caps at +60% so the curve doesn't
    /// runaway in a divine-heavy build.
    var divineBalancePowerMultiplier: Double {
        min(1.60, 1.0 + 0.06 * Double(divineTowersBuiltThisRun))
    }

    /// Parijata global production multiplier. Inactive (returns 0 to mean
    /// "no output") until a divine tower exists AND a boss has been
    /// felled by one. Each divine point adds +12% — so 10 divine kills
    /// roughly DOUBLES every resource the Parijata pulls in.
    var parijataProductionMultiplier: Double {
        guard hasDivineTower else { return 0 }
        return 1.0 + Double(divinePoints) * 0.12
    }

    /// Total spendable points = per-run earnings + IAP-purchased persistent wallet.
    var availablePoints: Int { points + BazaarStore.shared.persistentPoints }

    private var lastUpdate: TimeInterval? = nil
    private var spawnQueue: [(EnemyKind, TimeInterval)] = []
    private var spawnTimer: TimeInterval = 0
    private var bannerTimer: TimeInterval = 0
    private var resourceBannerTimer: TimeInterval = 0

    // MARK: - Race / setup

    func selectRace(_ race: Race) {
        self.race = race
        stock = race.startingResources
        lives = 60 + BazaarStore.shared.bonusStartingLives + race.bonusStartingLives
        maxLives = lives
        relicHitFlash = 0
        activeBazaarPerks.removeAll()
        points = 0
        // Teach the universal "long-press to learn" gesture on the very
        // first run. Persistent (UserDefaults) — fires once forever.
        HintsStore.shared.trigger(.longPressForInfo)
        // Defensive: reset any lingering endgame state from a previous run
        // that might have skipped fullReset (e.g., race-change without a
        // game-over). reset() is the canonical clear; selectRace just
        // covers the residual case.
        sudarshanPhase = .inactive
        sudarshanCharge = 0
        trimurtiCharge = 0
        rahuTimer = 0
        sudarshanHP = sudarshanMaxHP
        // Background music disabled — was: SoundEngine.shared.setMusicAge(.ancient)
        SoundEngine.shared.stopMusic()
        // Sudarshan is now available across the entire run — the player can
        // start charging it from W1 if they can afford the cost.
        beginSudarshanPhase()
    }


    var unlockedAge: Age = .ancient

    var currentAge: Age { unlockedAge }

    func isUnlocked(_ age: Age) -> Bool { age.rawValue <= unlockedAge.rawValue }

    func ageUpgradeCost(to age: Age) -> Resources {
        switch age {
        case .ancient: return Resources()
        // Treta — middle yug. Doubled again: ~5× the original price so the
        // T2-astra + heal-aura unlock is a hefty economic commitment that
        // requires a small mine economy + a few wave clears before reach.
        case .middle:  return Resources(gold: 1000, metal: 400, jotisha: 200, veda: 50)
        // Dvapara — modern yug. Doubled again: ~6× the original price.
        // Unlocks T3 intermediate astras AND the T4 ultimates, so this is
        // by far the run's biggest single purchase — typically funded
        // mid-wave-7 onward only.
        case .modern:  return Resources(gold: 3000, metal: 1000, tech: 600, jotisha: 400, veda: 500)
        }
    }

    var nextAgeToPurchase: Age? {
        switch unlockedAge {
        case .ancient: return .middle
        case .middle:  return .modern
        case .modern:  return nil
        }
    }

    func canPurchaseNextAge() -> Bool {
        guard let next = nextAgeToPurchase else { return false }
        return stock.canAfford(ageUpgradeCost(to: next))
    }

    func purchaseNextAge() {
        guard let next = nextAgeToPurchase else { return }
        let cost = ageUpgradeCost(to: next)
        guard stock.canAfford(cost) else { return }
        stock = stock - cost
        unlockedAge = next
        newAgeBanner = next
        bannerTimer = 3.0
        lastSeenAge = next
        // Sudarshan now begins at race-select (not Dvapara unlock).
        // Aura unlocks: heal aura at Treta (.middle), shield aura at Dvapara (.modern).
        switch next {
        case .middle:  HintsStore.shared.trigger(.firstAuraUnlock)
        case .modern:  HintsStore.shared.trigger(.firstShieldAura)
        default:       break
        }
        SoundEngine.shared.playAgeUnlocked()
        // Background music disabled — was: SoundEngine.shared.setMusicAge(next)
    }

    // MARK: - Sudarshan Chakra endgame logic

    private func beginSudarshanPhase() {
        sudarshanPhase = .charging
        sudarshanCharge = 0
        sudarshanHP = sudarshanMaxHP
        // Place the relic in open space just past the end of the path, in
        // the direction enemies were moving. That way Kali Yuga reaches it
        // by following the path he was already on, and the player can drop
        // towers in the corridor to defend it.
        sudarshanPosition = computeSudarshanPosition()
        HintsStore.shared.trigger(.sudarshanArrived)
    }

    private func computeSudarshanPosition() -> CGPoint {
        // The path now terminates at screen-centre, so the Sudarshan sits
        // exactly there — visible to the player as the heart of the map.
        if let end = pathPoints.last {
            return end
        }
        if lastConfiguredSize.width > 0 && lastConfiguredSize.height > 0 {
            return CGPoint(x: lastConfiguredSize.width / 2,
                           y: lastConfiguredSize.height / 2)
        }
        return CGPoint(x: 512, y: 384)
    }

    /// Returns true if the tap was accepted (had resources, advanced charge).
    /// Feeding is valid in BOTH .charging (priming the chakra before W12) and
    /// .matured (topping it back up while it burns Kali Yuga and drains itself).
    @discardableResult
    func tapSudarshan() -> Bool {
        guard sudarshanPhase == .charging || sudarshanPhase == .matured else { return false }
        // Don't burn resources on a full meter.
        guard sudarshanCharge < 1.0 else { return false }
        let cost = Self.sudarshanTapCost
        guard stock.canAfford(cost) else { return false }
        stock = stock - cost
        sudarshanCharge = min(1.0, sudarshanCharge + Self.sudarshanTapProgress)
        SoundEngine.shared.playBuildPlaced()
        tryMatureIfReady()
        return true
    }

    /// Charge meter is full AND the final boss is on the field → mature.
    private func tryMatureIfReady() {
        guard sudarshanPhase == .charging,
              sudarshanCharge >= 1.0,
              finalBoss != nil else { return }
        matureSudarshan()
    }

    private func matureSudarshan() {
        sudarshanPhase = .matured
        // Towers stay on the field — Kali Yuga has to fight through every
        // defence the player built on his way to the centre. Each tower he
        // pauses to destroy is more time the chakra (and any still-firing
        // towers) burn his HP. The slow, dramatic march was the explicit
        // design intent — earlier versions assimilated towers into the
        // chakra, which was anti-climactic.
        selectedTowerID = nil
        SoundEngine.shared.playAgeUnlocked()
    }

    /// Per-tick chakra logic. While .matured the chakra blasts every enemy on
    /// screen, with bonus damage to the final boss. Victory is detected in
    /// cleanupEnemies when Kali Yuga's HP drops to zero.
    /// The chakra also DRAINS its own charge while burning — once empty it
    /// stops dealing damage until the player feeds the relic again. Forces a
    /// constant push-pull between Kali Yuga's tower-consuming march and the
    /// player's gold-feeding upkeep.
    private func runSudarshanPhase(dt: TimeInterval) {
        guard sudarshanPhase == .matured else { return }
        chakraAngle = (chakraAngle + dt * 320).truncatingRemainder(dividingBy: 360)
        // No charge → no burn. Player must tap "Feed" to restore the chakra.
        guard sudarshanCharge > 0 else { return }
        // Chakra DPS: a base burn rate (1100) AMPLIFIED by every currently
        // alive divine-path tower. Each one channels +15% more divine fury
        // through the chakra — so the player who invests in the divine
        // line gets a meaningfully faster Kali-Yuga finish.
        let aliveDivine = towers.filter { $0.path == .divine && $0.hp > 0 }.count
        let divineMult = 1.0 + Self.divineTowerChakraBoost * Double(aliveDivine)
        let baseDPS = 1100.0 * divineMult
        for i in enemies.indices where enemies[i].hp > 0 {
            let mult = enemies[i].kind == .kaliYuga ? 1.5 : 1.0
            enemies[i].hp -= baseDPS * mult * dt
        }
        // Drain ~1.4% / sec while burning — a full 100% bar lasts ~70 s, just
        // long enough to finish a clean, undisturbed Kali Yuga. If he keeps
        // eating towers (growing HP) the player MUST keep tapping Feed to
        // top the chakra up. Hits zero → guard above stops the burn.
        sudarshanCharge = max(0, sudarshanCharge - Self.chakraBurnDrainPerSec * dt)
    }

    /// Per-second drain of the chakra charge while it's actively burning
    /// during .matured. Tuned so a full bar lasts ~70 s if untouched.
    static let chakraBurnDrainPerSec: Double = 1.0 / 70.0

    /// Ages the Rahu eclipse and, when it ends, respawns Kali Yuga in an
    /// empowered form for the final showdown.
    private func runRahuPhase(dt: TimeInterval) {
        guard sudarshanPhase == .rahuEclipse else { return }
        rahuTimer -= dt
        if rahuTimer <= 0 {
            sudarshanPhase = .empoweredBoss
            trimurtiCharge = 0
            // Empowered respawn — Akashvani announces the Trimurti astra and
            // Kali Yuga rises stronger. Only the Trimurti's final discharge
            // can fell him now; tower projectiles do nothing.
            // Tuned so a clean ~2 Trimurti charge cycles (≈ 60-90 s climax)
            // finish him: chip (4500 × 6) + fire (55 000) = 82 000 / cycle,
            // minus ~15 000 regen during the cycle = 67 000 net.
            // 145 000 HP / 67 000 ≈ 2.16 cycles. Tense but not a slog.
            let empoweredHP = 145000.0
            var e = Enemy(kind: .kaliYuga,
                          hp: empoweredHP,
                          maxHP: empoweredHP,
                          distance: 0,
                          position: pathPoints.first ?? .zero,
                          heading: CGPoint(x: 1, y: 0))
            e.towerDamageOverride = 180
            e.regenPerSec = 500
            enemies.append(e)
            HintsStore.shared.trigger(.empoweredBoss)
            HintsStore.shared.trigger(.parijataAvailable)
        }
    }

    /// Player taps to feed the Trimurti combined astra (Sudarshan + Brahmastra
    /// + Trishul) during the .empoweredBoss phase. 8 taps fills the meter.
    @discardableResult
    func tapTrimurti() -> Bool {
        guard sudarshanPhase == .empoweredBoss else { return false }
        // At max charge taps stop costing — player must press "Fire" instead.
        guard trimurtiCharge < 1.0 else { return false }
        let cost = Self.trimurtiTapCost
        guard stock.canAfford(cost) else { return false }
        stock = stock - cost
        trimurtiCharge = min(1.0, trimurtiCharge + Self.trimurtiTapProgress)
        // Each tap also chips the boss so the player feels immediate impact,
        // and forces the Kalash inside his body into view for ~1.5s.
        for i in enemies.indices where enemies[i].kind == .kaliYuga {
            enemies[i].hp -= Self.trimurtiTapChipDamage
            enemies[i].kalashReveal = 1.6
        }
        SoundEngine.shared.playBuildPlaced()
        return true
    }

    /// Resources required per Sudarshan-heal tap during the empowered phase.
    /// Restores `sudarshanHealAmount` HP to the centre tower. Players must
    /// balance these against Trimurti charge taps — both pull the same purse.
    static let sudarshanHealCost = Resources(gold: 200, metal: 20, tech: 20, jotisha: 20, veda: 20)
    static let sudarshanHealAmount: Double = 120

    /// Whether the player can currently spend resources to heal the Sudarshan.
    /// True only during the empowered-boss phase and when the tower has been
    /// dented (full-HP heal would just waste resources).
    var canHealSudarshan: Bool {
        sudarshanPhase == .empoweredBoss && sudarshanHP < sudarshanMaxHP
    }

    /// Player-triggered Sudarshan-centre heal during the empowered showdown.
    /// Returns true if the heal landed (resources deducted, HP raised).
    @discardableResult
    func healSudarshan() -> Bool {
        guard sudarshanPhase == .empoweredBoss else { return false }
        guard sudarshanHP < sudarshanMaxHP else { return false }
        let cost = Self.sudarshanHealCost
        guard stock.canAfford(cost) else { return false }
        stock = stock - cost
        sudarshanHP = min(sudarshanMaxHP, sudarshanHP + Self.sudarshanHealAmount)
        SoundEngine.shared.playBuildPlaced()
        return true
    }

    /// Player-triggered Trimurti discharge — only valid at full charge.
    /// The empowered Kali Yuga takes a massive but NOT auto-kill hit; if
    /// the player chipped him hard with taps, one fire finishes him off.
    /// Otherwise the meter resets to 0 and they keep charging.
    @discardableResult
    func fireTrimurtiManually() -> Bool {
        guard sudarshanPhase == .empoweredBoss else { return false }
        guard trimurtiCharge >= 1.0 else { return false }
        trimurtiCharge = 0
        // Trimurti astra — definitive kill. The combined wrath of Brahma,
        // Vishnu, and Maheshwara doesn't leave Kali Yuga any HP to regen.
        // Setting HP to 0 directly means no second escape and no second cycle.
        for i in enemies.indices where enemies[i].kind == .kaliYuga {
            enemies[i].hp = 0
            enemies[i].kalashReveal = 2.2
        }
        SoundEngine.shared.playAgeUnlocked()
        HapticsEngine.shared.bossKilled()
        return true
    }

    private var lastConfiguredSize: CGSize = .zero

    /// Reconfigure path + slots for a new device size. Existing towers/buildings
    /// are repositioned (or removed if their slot index no longer exists).
    func reconfigure(size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        // Skip if size hasn't changed meaningfully
        if abs(lastConfiguredSize.width - size.width) < 5
            && abs(lastConfiguredSize.height - size.height) < 5 { return }
        lastConfiguredSize = size

        let w = size.width
        let h = size.height
        let isLarge = min(w, h) > 600
        pathPoints = isLarge ? Self.largePath(w: w, h: h) : Self.compactPath(w: w, h: h)
        segmentLengths = (0..<(pathPoints.count - 1)).map { i in distance(pathPoints[i], pathPoints[i + 1]) }
        pathLength = segmentLengths.reduce(0, +)
        // iPhone's tightened spiral runs ~70% the length of the iPad path;
        // slow enemies to ~70% of base speed so total time-on-path matches.
        devicePathSpeedScale = isLarge ? 1.0 : 0.35
        slots = computeSlots(size: size, isLarge: isLarge)
        // The Sudarshan relic sits just past the path end from W1 — the
        // visual "goal" enemies are marching toward. Recomputed whenever
        // the path is rebuilt (orientation change, race switch, etc.).
        sudarshanPosition = computeSudarshanPosition()

        // Reposition existing towers/buildings to new slot positions (drop orphans)
        towers = towers.compactMap { t in
            guard let slot = slots.first(where: { $0.index == t.slotIndex }) else { return nil }
            var updated = Tower(slotIndex: t.slotIndex, position: slot.position, path: t.path)
            updated.tier = t.tier
            updated.fireCooldown = t.fireCooldown
            updated.stone = t.stone
            updated.hp = t.hp
            updated.maxHP = t.maxHP
            updated.healAuraLevel = t.healAuraLevel
            updated.shieldAuraLevel = t.shieldAuraLevel
            updated.kills = t.kills
            updated.wavesSurvived = t.wavesSurvived
            updated.wallShield = t.wallShield
            updated.stoneTimer = t.stoneTimer
            updated.stoneTimerTotal = t.stoneTimerTotal
            return updated
        }
        buildings = buildings.compactMap { b in
            guard let slot = slots.first(where: { $0.index == b.slotIndex }) else { return nil }
            var updated = Building(slotIndex: b.slotIndex, position: slot.position, kind: b.kind)
            updated.level = b.level
            updated.partial = b.partial
            updated.hp = b.hp
            updated.maxHP = b.maxHP
            return updated
        }
    }

    func configure(size: CGSize) {
        guard pathPoints.isEmpty, size.width > 0, size.height > 0 else { return }
        lastConfiguredSize = size

        let w = size.width
        let h = size.height
        // Larger devices get a more elaborate path with more turns
        let isLarge = min(w, h) > 600  // iPad-ish
        let raw: [CGPoint] = isLarge ? Self.largePath(w: w, h: h) : Self.compactPath(w: w, h: h)

        pathPoints = raw
        segmentLengths = (0..<(raw.count - 1)).map { i in distance(raw[i], raw[i + 1]) }
        pathLength = segmentLengths.reduce(0, +)
        devicePathSpeedScale = isLarge ? 1.0 : 0.35
        slots = computeSlots(size: size, isLarge: isLarge)
        // Position the Sudarshan relic at path end from W1.
        sudarshanPosition = computeSudarshanPosition()
    }

    // Both paths now spiral inward from a screen edge and terminate at the
    // Sudarshan at screen-centre. The Sudarshan is the visible goal — the
    // enemies are visibly marching toward the relic at the heart of the map.

    private static func compactPath(w: CGFloat, h: CGFloat) -> [CGPoint] {
        // Tightened bounds (0.20–0.80 horizontally, 0.22–0.82 vertically)
        // shrink the iPhone map so the play area sits lower on screen and
        // leaves visible margin around the slot grid.
        [
            CGPoint(x: -10,       y: h * 0.22),        // enter top-left edge
            CGPoint(x: w * 0.80,  y: h * 0.22),        // hug top
            CGPoint(x: w * 0.80,  y: h * 0.82),        // down right side
            CGPoint(x: w * 0.20,  y: h * 0.82),        // along bottom
            CGPoint(x: w * 0.20,  y: h * 0.40),        // up left side (inset)
            CGPoint(x: w * 0.68,  y: h * 0.40),        // inward turn
            CGPoint(x: w * 0.68,  y: h * 0.68),        // down
            CGPoint(x: w * 0.50,  y: h * 0.68),        // approach centre
            CGPoint(x: w * 0.50,  y: h * 0.52)         // arrive at Sudarshan
        ]
    }

    private static func largePath(w: CGFloat, h: CGFloat) -> [CGPoint] {
        // iPad: an extra spiral loop before arriving at the centre.
        [
            CGPoint(x: -10,       y: h * 0.10),        // enter top-left
            CGPoint(x: w * 0.92,  y: h * 0.10),
            CGPoint(x: w * 0.92,  y: h * 0.90),
            CGPoint(x: w * 0.08,  y: h * 0.90),
            CGPoint(x: w * 0.08,  y: h * 0.25),
            CGPoint(x: w * 0.78,  y: h * 0.25),
            CGPoint(x: w * 0.78,  y: h * 0.75),
            CGPoint(x: w * 0.22,  y: h * 0.75),
            CGPoint(x: w * 0.22,  y: h * 0.40),
            CGPoint(x: w * 0.64,  y: h * 0.40),
            CGPoint(x: w * 0.64,  y: h * 0.60),
            CGPoint(x: w * 0.50,  y: h * 0.60),
            CGPoint(x: w * 0.50,  y: h * 0.50)         // arrive at Sudarshan
        ]
    }

    private func computeSlots(size: CGSize, isLarge: Bool) -> [BuildSlot] {
        var result: [BuildSlot] = []
        var idx = 0
        // iPhone (compact) packs MUCH tighter so the playable density
        // matches (or exceeds) iPad. Tower visuals shrink to ~36 px in
        // lockstep (see the iPhone branch in TowerArtView).
        let step: CGFloat = isLarge ? 95 : 48
        // Three rows per side on iPhone — inner / mid / outer — for max
        // tower density along the path.
        let offsets: [CGFloat] = isLarge
            ? [60, -60, 125, -125]
            : [32, -32, 64, -64, 96, -96]
        let topMargin: CGFloat = isLarge ? 110 : 78
        let bottomMargin: CGFloat = isLarge ? 130 : 98
        let minSlotDistance: CGFloat = isLarge ? 60 : 34   // very tight on iPhone
        // Reserved clear zone around the central (Sudarshan) tower so the
        // cross/cardinal layout (HP bar above, Feed right, Burst left,
        // charge label below) renders without overlapping build slots.
        let sudarshanReservedRadius: CGFloat = isLarge ? 130 : 70
        let sudarshanCentre = computeSudarshanPosition()
        // Reserve only the precise rectangles where the BottomBar buttons
        // sit — Next Wave (bottom-left) + age-upgrade (bottom-left) +
        // God Mode (bottom-right). Everything else, including the bottom
        // strip of build slots, stays placeable + tappable.
        let nextWaveReserveRect = CGRect(
            x: 0,
            y: size.height - 70,
            width: 180,
            height: 70
        )
        let ageUpgradeReserveRect = CGRect(
            x: 0,
            y: size.height - 130,
            width: 220,
            height: 60
        )
        let godModeReserveRect = CGRect(
            x: size.width - 100,
            y: size.height - 110,
            width: 100,
            height: 110
        )
        let inReservedZone: (CGPoint) -> Bool = { pos in
            if hypot(pos.x - sudarshanCentre.x, pos.y - sudarshanCentre.y) < sudarshanReservedRadius {
                return true
            }
            if nextWaveReserveRect.contains(pos) { return true }
            if ageUpgradeReserveRect.contains(pos) { return true }
            if godModeReserveRect.contains(pos) { return true }
            return false
        }
        let pathClearance: CGFloat = isLarge ? 32 : 22
        let edgePadding: CGFloat = isLarge ? 30 : 20
        var d: CGFloat = step / 2
        while d < pathLength - 20 {
            let (pt, dir) = pointAndDirection(at: d)
            let normal = CGPoint(x: -dir.y, y: dir.x)
            for off in offsets {
                let pos = CGPoint(x: pt.x + normal.x * off, y: pt.y + normal.y * off)
                guard pos.x > edgePadding, pos.x < size.width - edgePadding,
                      pos.y > topMargin, pos.y < size.height - bottomMargin else { continue }
                // Reject if too close to path
                if overlapsPath(pos, threshold: pathClearance) { continue }
                // Reject if too close to the central Sudarshan tower (clears
                // the four cardinal "around the relic" slots so info banners
                // render in clean rows).
                if inReservedZone(pos) { continue }
                // Reject if too close to existing slot (prevents visual overlap)
                let crowded = result.contains { existing in
                    hypot(existing.position.x - pos.x, existing.position.y - pos.y) < minSlotDistance
                }
                if crowded { continue }
                result.append(BuildSlot(index: idx, position: pos))
                idx += 1
            }
            d += step
        }

        // Edge-band pass: fill the bottom strip and the left/right margins
        // with extra grid slots so the player has placement options at the
        // perimeter, not only adjacent to the path itself. iPhone uses a
        // much tighter cadence than iPad.
        let edgeStepX: CGFloat = isLarge ? 90 : 48
        let edgeStepY: CGFloat = isLarge ? 78 : 46
        let leftEdgeMax: CGFloat = isLarge ? 110 : 70
        let rightEdgeMin: CGFloat = size.width - (isLarge ? 110 : 70)

        // Bottom-strip slot pass removed — the user found it visually
        // crowded with the BottomBar buttons in the bottom corners. Path-
        // adjacent slots + the left/right edge columns are enough.

        // Left and right edge columns — vertical strips not already filled.
        var sideY = topMargin
        while sideY < size.height - bottomMargin {
            for x in [edgeStepX * 0.5, size.width - edgeStepX * 0.5] {
                let pos = CGPoint(x: x, y: sideY)
                let inSideBand = pos.x < leftEdgeMax || pos.x > rightEdgeMin
                guard inSideBand,
                      pos.y > topMargin, pos.y < size.height - bottomMargin else { continue }
                if overlapsPath(pos, threshold: isLarge ? 36 : 24) { continue }
                if inReservedZone(pos) { continue }
                let crowded = result.contains { existing in
                    hypot(existing.position.x - pos.x, existing.position.y - pos.y) < minSlotDistance
                }
                if crowded { continue }
                result.append(BuildSlot(index: idx, position: pos))
                idx += 1
            }
            sideY += edgeStepY
        }

        return result
    }

    // Returns true if point is within `threshold` distance of any path segment
    private func overlapsPath(_ point: CGPoint, threshold: CGFloat) -> Bool {
        for i in 0..<(pathPoints.count - 1) {
            let a = pathPoints[i]
            let b = pathPoints[i + 1]
            if distanceToSegment(point, a: a, b: b) < threshold {
                return true
            }
        }
        return false
    }

    private func distanceToSegment(_ p: CGPoint, a: CGPoint, b: CGPoint) -> CGFloat {
        let dx = b.x - a.x, dy = b.y - a.y
        let segLen2 = dx * dx + dy * dy
        if segLen2 <= 0.0001 { return hypot(p.x - a.x, p.y - a.y) }
        var t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / segLen2
        t = max(0, min(1, t))
        let projX = a.x + t * dx
        let projY = a.y + t * dy
        return hypot(p.x - projX, p.y - projY)
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }

    private func pointAndDirection(at d: CGFloat) -> (CGPoint, CGPoint) {
        var remaining = max(0, min(d, pathLength))
        for i in 0..<segmentLengths.count {
            let seg = segmentLengths[i]
            if remaining <= seg || i == segmentLengths.count - 1 {
                let a = pathPoints[i]
                let b = pathPoints[i + 1]
                let t = seg <= 0 ? 0 : remaining / seg
                let p = CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
                let len = max(0.0001, seg)
                let dir = CGPoint(x: (b.x - a.x) / len, y: (b.y - a.y) / len)
                return (p, dir)
            }
            remaining -= seg
        }
        let last = pathPoints.last ?? .zero
        return (last, CGPoint(x: 1, y: 0))
    }

    // MARK: - Effective stats (with race bonuses)

    /// Stats fall back to the path's tier-1 astra while a tower is engulfed
    /// in Bhasmasura's ash aura.
    private func effectiveKind(of tower: Tower) -> TowerKind {
        debuffedTowerIDs.contains(tower.id) ? tower.path.astras[0] : tower.kind
    }

    func damage(of tower: Tower) -> Double {
        var d = effectiveKind(of: tower).baseDamage * (race?.damageMultiplier ?? 1.0)
        if let s = tower.stone {
            d *= s.kind.damageMultiplier(level: s.level)
        }
        // Veteran bonus: every kill the tower has scored adds 0.1 flat damage.
        d += tower.veteranPower
        // Boss-slayer bonus — each boss the tower has personally felled
        // stacks +12% damage on this tower forever. The "loot" of the
        // kill literally feeds the tower's power.
        d *= tower.bossPowerMultiplier
        // "Rise to the threat" — Pashupatastra (the final attack tower) gets
        // angrier as the threat scales. Every active card-worthy boss on the
        // field adds +25% damage, every empowerment-stack a boss has carries
        // its own +10%. Caps at 3× so it stays balanced.
        if tower.kind == .pashupatastra {
            var bonus = 1.0
            for e in enemies where e.kind.isCardWorthy && e.hp > 0 {
                bonus += 0.25
                bonus += Double(e.towerKills) * 0.10
            }
            d *= min(3.0, bonus)
        }
        return d
    }

    func fireInterval(of tower: Tower) -> TimeInterval {
        var raceMult = race?.fireRateMultiplier ?? 1.0
        if let s = tower.stone {
            raceMult *= s.kind.fireRateMultiplier(level: s.level)
        }
        var interval = effectiveKind(of: tower).baseFireInterval / raceMult
        // Ravana terror aura — reload 50% slower.
        if terrorTowerIDs.contains(tower.id) { interval *= 1.5 }
        return interval
    }

    func range(of tower: Tower) -> CGFloat {
        var r = effectiveKind(of: tower).baseRange * (race?.rangeMultiplier ?? 1.0)
        if let s = tower.stone {
            r *= s.kind.rangeMultiplier(level: s.level)
        }
        return r
    }

    /// How many divine T3 ultimates are already standing on the field.
    /// Drives the escalating-cost ladder on subsequent divine commitments
    /// so the player can't just spam Pashupatastras.
    var divineUltimateCount: Int {
        towers.filter {
            let k = $0.kind
            return k == .sudarshanaChakra
                || k == .brahmashirsha
                || k == .pashupatastra
        }.count
    }

    /// Cost multiplier applied when buying / upgrading-into the next divine
    /// ultimate. Steep stepped ladder — every additional divine you already
    /// own makes the next one dramatically more expensive, so committing to
    /// a single divine and supporting it is meaningfully cheaper than trying
    /// to stack two or three. Stops the run being auto-piloted on divine spam.
    var divineEscalation: Double {
        switch divineUltimateCount {
        case 0:  return 1.5    // first divine: +50%
        case 1:  return 2.5    // second: +150%
        case 2:  return 4.0    // third: +300%
        case 3:  return 6.0    // fourth: +500%
        default: return 9.0    // fifth+: +800%
        }
    }

    private var divineUltimateKinds: Set<TowerKind> {
        [.sudarshanaChakra, .brahmashirsha, .pashupatastra]
    }

    func effectiveCost(of kind: TowerKind) -> Resources {
        var c = kind.cost
        if let mult = race?.goldCostMultiplier, mult != 1.0 {
            c.gold = Int((Double(c.gold) * mult).rounded())
        }
        // Escalating-cost ladder for divine ultimates — every new one is
        // dramatically pricier than the last.
        if divineUltimateKinds.contains(kind), divineEscalation > 1.0 {
            c = c.scaled(by: divineEscalation)
        }
        return c
    }

    func effectiveUpgradeCost(of tower: Tower) -> Resources {
        guard let next = tower.nextAstra else { return Resources() }
        return effectiveCost(of: next)
    }

    func effectiveSellValue(of tower: Tower) -> Resources {
        // Sum effective tier-by-tier costs at 50%
        var total = Resources()
        for i in 0..<tower.tier {
            total = total + effectiveCost(of: tower.path.astras[i])
        }
        return total.scaled(by: 0.5)
    }

    // MARK: - Wave control

    func startNextWave() {
        guard !isWaveActive, !isGameOver else { return }
        // Cap progression at Kali Yuga's wave — the run only ends through the
        // proper endgame arc (chakra → Rahu → empowered → victory). If the
        // player killed Kali Yuga with towers before Sudarshan matured,
        // pressing "next wave" re-spawns him on the same boss wave so the
        // resolution actually plays out.
        if wave >= Self.kaliYugaArrivalWave && sudarshanPhase != .victory {
            let hasBoss = enemies.contains(where: { $0.kind == .kaliYuga })
            if !hasBoss {
                spawnQueue = buildWave(Self.kaliYugaArrivalWave)
                spawnTimer = 0
                isWaveActive = true
                SoundEngine.shared.playWaveStart()
            }
            return
        }
        wave += 1
        isWaveActive = true
        autoStartCountdown = 0
        // Suppress info-banner tooltips during the wave — they cover the
        // play field and break the player's focus. Re-enabled when the
        // wave clears (checkWaveCompletion).
        TooltipManager.shared.suppressed = true
        spawnQueue = buildWave(wave)
        spawnTimer = 0
        // Bazaar run-buff payouts — granted at wave START so the player has
        // the resources up front to spend on this wave's defence (towers,
        // upgrades, stones), instead of receiving them once the wave is
        // already done. Matches the "every wave" promise on the shop card.
        if activeBazaarPerks.contains(.waveTribute)   { stock.gold += 2000 }
        if activeBazaarPerks.contains(.waveVedaTithe) { stock.veda += 30 }
        // Reset per-wave time-to-kill telemetry — the adaptive scaling at the
        // end of the wave reads these accumulators to decide whether the next
        // wave needs more power.
        waveElapsed = 0
        waveKillTimeSum = 0
        waveKillCount = 0
        deepestEnemyFraction = 0
        enemySpawnTime.removeAll(keepingCapacity: true)
        // Resource Wave banner (every 7th wave from W7 onward)
        if wave % 7 == 0 && wave >= 7 {
            resourceWaveBanner = true
            resourceBannerTimer = 2.8
            HintsStore.shared.trigger(.firstResourceWave)
        }
        if wave == 1 { HintsStore.shared.trigger(.firstWaveStart) }
        if wave == Self.kaliYugaArrivalWave { HintsStore.shared.trigger(.kaliYugaArrived) }
        SoundEngine.shared.playWaveStart()
    }

    /// The total number of pre-endgame waves before Kali Yuga arrives.
    /// Decreasing this here cascades through the rest of the wave brackets
    /// and the "Awaiting Kali Yuga · Wave X" UI label. Bumped 12 → 14 so
    /// the player has two extra ramp waves to stack divine towers and
    /// charge the chakra before the End Age.
    static let kaliYugaArrivalWave: Int = 14

    private func buildWave(_ n: Int) -> [(EnemyKind, TimeInterval)] {
        var list: [(EnemyKind, TimeInterval)] = []
        let interval = Difficulty.spawnInterval(baseWave: n)

        // Boon wave every 7 — only W7 in the 14-wave arc, but the cadence
        // is preserved in case the constant grows again.
        if n % 7 == 0 && n >= 7 && n < Self.kaliYugaArrivalWave {
            return scaleWaveByPath(buildBoonWave(n))
        }

        // 10-wave arc — every enemy debuts before Kali Yuga; constant pressure:
        //   W1    intro pishacha + rakshasa
        //   W2    + Daitya, Mahishasura cameo
        //   W3    Bhasmasura debut + Mahishasura
        //   W4    Vetala + Mayavi + Raktabija + Putana debut
        //   W5    Tarakasura + Indrajit debut
        //   W6    Ravana cameo + Bhasmasura
        //   W7    Boon (Resource) wave
        //   W8-W11  Late-game pressure (each wave adds a boss + new threat)
        //   W12   KALI YUGA
        switch n {
        // Early-game pressure — wave counts bumped so W1-W4 actually
        // test the player's opening defence instead of being a free intro.
        // Floor every wave at >=40 enemies so no wave feels like a free
        // pass. Early waves are fodder-heavy, late waves keep the elite
        // mix but with a thicker rakshasa/daitya escort.
        case 1:
            for _ in 0..<32 { list.append((.pishacha, interval)) }
            for _ in 0..<8  { list.append((.rakshasa, interval + 0.10)) }

        case 2:
            for _ in 0..<28 { list.append((.pishacha, interval)) }
            for _ in 0..<8  { list.append((.rakshasa, interval)) }
            for _ in 0..<5  { list.append((.daitya, interval + 0.18)) }
            list.append((.mahishasura, 1.5))

        case 3:
            // W3 — single Bhasmasura cameo (was 3) since the player only
            // has T1 dart + varunastra. Mahishasura escort kept.
            for _ in 0..<22 { list.append((.pishacha, interval)) }
            for _ in 0..<10 { list.append((.rakshasa, interval)) }
            for _ in 0..<6  { list.append((.daitya, interval + 0.18)) }
            list.append((.bhasmasura, interval + 0.18))
            list.append((.mahishasura, 1.3))

        case 4:
            // W4 — no Putana yet (she's divine-immune-only and the player
            // doesn't have a divine option in Satya/Treta). She debuts
            // later once Dvapara is realistically open.
            for _ in 0..<20 { list.append((.pishacha, interval)) }
            for _ in 0..<11 { list.append((.rakshasa, interval)) }
            for _ in 0..<6  { list.append((.daitya, interval + 0.15)) }
            for _ in 0..<5  { list.append((.vetala, interval + 0.15)) }
            for _ in 0..<6  { list.append((.mayavi, interval + 0.10)) }
            list.append((.raktabija, interval + 0.25))
            list.append((.maniMurta, 1.8))   // first stone harvest

        // Late-wave philosophy: boss-led pressure, but with a thicker
        // fodder escort so total count stays >=40.
        case 5:
            for _ in 0..<18 { list.append((.pishacha, interval)) }
            for _ in 0..<10 { list.append((.rakshasa, interval)) }
            for _ in 0..<5  { list.append((.daitya, interval)) }
            for _ in 0..<4  { list.append((.vetala, interval + 0.12)) }
            for _ in 0..<3  { list.append((.asura, interval + 0.18)) }
            list.append((.tarakasura, 1.4))
            list.append((.indrajit, 1.7))

        case 6:
            for _ in 0..<18 { list.append((.pishacha, interval)) }
            for _ in 0..<10 { list.append((.rakshasa, interval)) }
            for _ in 0..<6  { list.append((.daitya, interval)) }
            for _ in 0..<4  { list.append((.vetala, interval + 0.12)) }
            for _ in 0..<3  { list.append((.asura, interval + 0.16)) }
            list.append((.ravana, 1.3))
            list.append((.bhasmasura, 1.5))
            list.append((.mahishasura, 1.7))

        // case 7 handled above (boon wave)

        case 8:
            for _ in 0..<14 { list.append((.pishacha, interval)) }
            for _ in 0..<10 { list.append((.rakshasa, interval)) }
            for _ in 0..<7  { list.append((.daitya, interval)) }
            for _ in 0..<5  { list.append((.vetala, interval + 0.12)) }
            for _ in 0..<5  { list.append((.asura, interval + 0.16)) }
            list.append((.vritra, 1.2))
            list.append((.mahishasura, 1.3))
            list.append((.raktabija, 1.5))
            list.append((.tarakasura, 1.7))

        case 9:
            // Pre-boss crescendo — every signature appears, fodder dialed
            // back so the screen stays readable.
            for _ in 0..<15 { list.append((.pishacha, interval)) }
            for _ in 0..<10 { list.append((.rakshasa, interval)) }
            for _ in 0..<7  { list.append((.daitya, interval)) }
            for _ in 0..<6  { list.append((.vetala, interval + 0.12)) }
            for _ in 0..<5  { list.append((.asura, interval + 0.16)) }
            list.append((.mahishasura, 1.1))
            list.append((.ravana, 1.2))
            list.append((.tarakasura, 1.3))
            list.append((.indrajit, 1.4))
            list.append((.bhasmasura, 1.5))
            list.append((.vritra, 1.5))
            list.append((.raktabija, 1.6))
            list.append((.putana, 1.7))
            // Twin-Ravana finale — late-W9 bookend, "the tide breaks".
            list.append((.ravana, 1.6))

        case 10:
            // W10 — twin Ravanas + Putana drain on a tight elite escort.
            for _ in 0..<15 { list.append((.pishacha, interval)) }
            for _ in 0..<10 { list.append((.rakshasa, interval)) }
            for _ in 0..<7  { list.append((.daitya, interval)) }
            for _ in 0..<6  { list.append((.vetala, interval + 0.12)) }
            for _ in 0..<5  { list.append((.asura, interval + 0.16)) }
            list.append((.ravana, 1.2))
            list.append((.ravana, 1.5))
            list.append((.putana, 1.5))
            list.append((.bhasmasura, 1.6))
            list.append((.tarakasura, 1.7))

        case 11:
            // W11 — second-to-last pre-boss wave. Every signature appears.
            for _ in 0..<18 { list.append((.pishacha, interval)) }
            for _ in 0..<12 { list.append((.rakshasa, interval)) }
            for _ in 0..<10 { list.append((.daitya, interval)) }
            for _ in 0..<7  { list.append((.vetala, interval + 0.10)) }
            for _ in 0..<6  { list.append((.asura, interval + 0.14)) }
            for _ in 0..<6  { list.append((.mayavi, interval + 0.10)) }
            list.append((.mahishasura, 1.0))
            list.append((.ravana, 1.1))
            list.append((.indrajit, 1.2))
            list.append((.tarakasura, 1.3))
            list.append((.bhasmasura, 1.4))
            list.append((.vritra, 1.5))
            list.append((.raktabija, 1.6))
            list.append((.putana, 1.7))

        case 12:
            // W12 — boss-rush escalation. Doubled mid-boss pressure so
            // the player feels the Anta closing in.
            for _ in 0..<18 { list.append((.pishacha, interval)) }
            for _ in 0..<12 { list.append((.rakshasa, interval)) }
            for _ in 0..<10 { list.append((.daitya, interval)) }
            for _ in 0..<8  { list.append((.vetala, interval + 0.10)) }
            for _ in 0..<6  { list.append((.asura, interval + 0.14)) }
            for _ in 0..<6  { list.append((.mayavi, interval + 0.10)) }
            list.append((.mahishasura, 1.0))
            list.append((.mahishasura, 1.3))
            list.append((.ravana, 1.1))
            list.append((.indrajit, 1.2))
            list.append((.tarakasura, 1.4))
            list.append((.bhasmasura, 1.4))
            list.append((.vritra, 1.5))
            list.append((.raktabija, 1.6))
            list.append((.putana, 1.7))
            list.append((.putana, 1.8))

        case 13:
            // W13 — last stand BEFORE Kali Yuga. The biggest non-boss wave
            // in the run. Triple Ravanas, twin Vritras, the works. Forces
            // the player to commit their T4 ultimates and divine line.
            for _ in 0..<20 { list.append((.pishacha, interval)) }
            for _ in 0..<14 { list.append((.rakshasa, interval)) }
            for _ in 0..<12 { list.append((.daitya, interval)) }
            for _ in 0..<10 { list.append((.vetala, interval + 0.10)) }
            for _ in 0..<8  { list.append((.asura, interval + 0.14)) }
            for _ in 0..<8  { list.append((.mayavi, interval + 0.10)) }
            list.append((.ravana, 1.0))
            list.append((.ravana, 1.2))
            list.append((.ravana, 1.4))
            list.append((.vritra, 1.1))
            list.append((.vritra, 1.5))
            list.append((.bhasmasura, 1.2))
            list.append((.bhasmasura, 1.6))
            list.append((.indrajit, 1.3))
            list.append((.tarakasura, 1.4))
            list.append((.raktabija, 1.5))
            list.append((.putana, 1.6))

        default:
            // W14: Kali Yuga debuts — only one ever spawned.
            if n == Self.kaliYugaArrivalWave,
               !enemies.contains(where: { $0.kind == .kaliYuga }) {
                list.append((.kaliYuga, 0.6))
            }
            // Heavy escort so the final wave still hits the >=40 floor.
            for _ in 0..<20 { list.append((.pishacha, interval)) }
            for _ in 0..<12 { list.append((.rakshasa, interval)) }
            for _ in 0..<7  { list.append((.daitya, interval)) }
            for _ in 0..<5  { list.append((.mayavi, interval + 0.10)) }
        }

        // Age-locked elite spawns — each Yug unlock adds a tougher mob
        // mix to every subsequent wave. Treta brings +1 Raktabija; Dvapara
        // brings +1 Vritra. Skipped on Kali Yuga and on waves that already
        // include the same elite (so a W11 boss-rush isn't tripled).
        if n != Self.kaliYugaArrivalWave {
            if unlockedAge.rawValue >= Age.middle.rawValue,
               !list.contains(where: { $0.0 == .raktabija }) {
                list.append((.raktabija, 1.8))
            }
            if unlockedAge.rawValue >= Age.modern.rawValue,
               !list.contains(where: { $0.0 == .vritra }) {
                list.append((.vritra, 1.9))
            }
        }

        // Append stone bearers in W3+ for the bespoke wave lists. Counts
        // bumped so the player banks plenty of stones for both attach AND
        // upgrade across multiple towers.
        //   W3-W5 → 2 bearers • W6-W9 → 3 bearers • W10-W11 → 4 bearers
        if n >= 3 && n != Self.kaliYugaArrivalWave {
            let bearerCount: Int
            switch n {
            case 3...5:  bearerCount = 2
            case 6...9:  bearerCount = 3
            default:     bearerCount = 4
            }
            // Subtract any already-inline maniMurta in the bespoke list so
            // we don't double-stack on W4 (which already adds one).
            let inline = list.filter { $0.0 == .maniMurta }.count
            let extra = max(0, bearerCount - inline)
            for _ in 0..<extra { list.append((.maniMurta, 1.7)) }
        }
        return scaleWaveByPath(list)
    }

    /// Multiplies enemy COUNTS proportional to path length. Big iPad maps
    /// give players more slots + more time to fire — so they need more
    /// enemies to challenge equivalently. Each entry is duplicated according
    /// to ceil(pathDifficultyScale). Bosses kept singleton.
    private func scaleWaveByPath(_ list: [(EnemyKind, TimeInterval)]) -> [(EnemyKind, TimeInterval)] {
        let scale = pathDifficultyScale
        guard scale > 1.0 else { return list }
        // Per-kind multiplier: bosses stay at 1, others scale up
        var scaled: [(EnemyKind, TimeInterval)] = []
        for (kind, intv) in list {
            // Bosses and bearers should NOT multiply — they are special spawns
            if kind.attacksTowers || kind.isResourceBearer || kind.isStoneBearer {
                scaled.append((kind, intv))
                continue
            }
            // Fractional duplication: floor + probabilistic remainder
            let mult = scale
            let whole = Int(mult)
            let frac = mult - Double(whole)
            let total = whole + (Double.random(in: 0..<1) < frac ? 1 : 0)
            for _ in 0..<max(1, total) {
                scaled.append((kind, intv))
            }
        }
        return scaled
    }

    // Boon Wave: 1-3 resource bearers (chosen by tier) + small fodder
    // Bearers are tanky and have targeted immunities — players need diverse damage to clear them
    private func buildBoonWave(_ n: Int) -> [(EnemyKind, TimeInterval)] {
        var list: [(EnemyKind, TimeInterval)] = []
        let interval = Difficulty.spawnInterval(baseWave: n)

        // Fodder mob to keep pressure — boon waves now hit the same 40-floor
        // as every other wave so the relief doesn't feel like a free clear.
        let p = 20 + n
        let r = 10 + (n / 4)
        let d = 5 + (n / 5)
        for _ in 0..<p { list.append((.pishacha, interval + 0.05)) }
        for _ in 0..<r { list.append((.rakshasa, interval + 0.10)) }
        for _ in 0..<d { list.append((.daitya, interval + 0.15)) }

        // Dynamic resource bearers — count scales with wave, and the
        // *mix* is weighted by which resources the player is shortest on.
        let totalBearers = min(10, 2 + n / 7)   // W7: 3, W14: 4, W21: 5 … capped at 10
        for kind in dynamicResourceBearers(count: totalBearers) {
            list.append((kind, 1.8))
        }

        return list
    }

    /// Returns `count` bearer kinds, weighted by the inverse of the player's
    /// current stock for that bearer's resource — so the resource you're
    /// shortest on is most likely to spawn. Smoothed by a +25 floor so even
    /// a flush wallet still has *some* chance of every bearer appearing.
    private func dynamicResourceBearers(count: Int) -> [EnemyKind] {
        struct Bearer { let kind: EnemyKind; let resource: ResourceKind }
        let table: [Bearer] = [
            Bearer(kind: .lobhaYaksha,    resource: .gold),
            Bearer(kind: .lohaAsura,      resource: .metal),
            Bearer(kind: .yantraPishacha, resource: .tech),
            Bearer(kind: .taraDevi,       resource: .jotisha),
            Bearer(kind: .rishiAtma,      resource: .veda)
        ]
        let weights = table.map { b -> Double in
            // Lower stock → higher weight. +25 floor avoids div-by-zero
            // and dampens swings when you're sitting on small piles.
            1.0 / (Double(stock.amount(b.resource)) + 25.0)
        }
        let total = weights.reduce(0, +)
        var picks: [EnemyKind] = []
        picks.reserveCapacity(count)
        // Guard: `Double.random(in: 0..<x)` requires x > 0. Weights are always
        // positive (1/(stock+25)) so total is always positive in practice, but
        // we defend against a future change that could zero them out.
        // The bearer table is statically defined with 5 entries, but use
        // safe-fallback unwraps to remove the force-unwrap risk entirely.
        let fallbackKind: EnemyKind = table.first?.kind ?? .lobhaYaksha
        guard total > 0 else {
            for _ in 0..<count {
                picks.append(table.randomElement()?.kind ?? fallbackKind)
            }
            return picks
        }
        for _ in 0..<count {
            var r = Double.random(in: 0..<total)
            var picked = false
            for (i, w) in weights.enumerated() {
                r -= w
                if r <= 0 {
                    picks.append(table[i].kind)
                    picked = true
                    break
                }
            }
            // Floating-point safety net: if rounding ate the remainder,
            // fall back to the last (highest-cumulative) bearer.
            if !picked {
                picks.append(table.last?.kind ?? fallbackKind)
            }
        }
        return picks
    }

    // MARK: - Slot occupancy

    func isSlotOccupied(_ slotIndex: Int) -> Bool {
        towers.contains(where: { $0.slotIndex == slotIndex }) ||
        buildings.contains(where: { $0.slotIndex == slotIndex })
    }

    // MARK: - Tower management

    // MARK: Progressive same-kind placement cost
    //
    // The Nth tower of a given path (or Nth building of a kind) costs more
    // than the first — a soft anti-spam tax. Curve gives the FIRST TWO of a
    // kind at base cost so the natural early-game strategy of dropping a
    // pair of cheap darts (or a pair of gold mines) isn't punished. From
    // the third onward, cost climbs 1.25× per additional copy, capped at
    // 2.50×.
    //   1st & 2nd: 1.00×   3rd: 1.25×   4th: 1.56×   5th: 1.95×
    //   6th: 2.44×   7th+: 2.50× cap

    /// Number of towers currently on the field that share `path`.
    func ownedTowerCount(of path: TowerPath) -> Int {
        towers.filter { $0.path == path }.count
    }

    /// Number of resource buildings currently on the field of this kind.
    func ownedBuildingCount(of kind: BuildingKind) -> Int {
        buildings.filter { $0.kind == kind }.count
    }

    /// Compound multiplier applied to the next-of-kind TOWER placement
    /// cost. Free pair preserved (the first two same-path towers cost
    /// base), then a steep 1.55× ramp per additional copy. Cap raised to
    /// 12× so the 8th+ tower of a kind is genuinely punishing.
    ///   1st-2nd: 1.00×  3rd: 1.55×  4th: 2.40×  5th: 3.72×
    ///   6th: 5.77×  7th: 8.94×  8th+: 12.00×
    static func sameKindCostMultiplier(existing: Int) -> Double {
        let n = max(0, existing - 1)  // first 2 are free; 3rd starts ramp
        return min(12.0, pow(1.55, Double(n)))
    }

    /// Compound multiplier for the next-of-kind RESOURCE BUILDING. No
    /// free pair, aggressive 1.90× ramp per additional copy, cap raised
    /// to 16× so stacking five gold mines is a real run-defining cost.
    ///   1st: 1.00× • 2nd: 1.90× • 3rd: 3.61× • 4th: 6.86×
    ///   5th: 13.03× • 6th+: 16.00×
    static func buildingSameKindCostMultiplier(existing: Int) -> Double {
        min(16.0, pow(1.90, Double(max(0, existing))))
    }

    /// What it will actually cost to build the NEXT tower on this path,
    /// accounting for race discounts, divine escalation (already inside
    /// `effectiveCost`), and the progressive same-kind tax.
    func nextTowerPlacementCost(for path: TowerPath) -> Resources {
        let base = effectiveCost(of: path.astras[0])
        let mult = Self.sameKindCostMultiplier(existing: ownedTowerCount(of: path))
        return mult == 1.0 ? base : base.scaled(by: mult)
    }

    /// What it will actually cost to place the NEXT building of this kind.
    /// Uses the steeper building-specific curve so stacking the same
    /// resource building gets expensive fast.
    func nextBuildingPlacementCost(for kind: BuildingKind) -> Resources {
        let base = effectiveBuildingCost(kind.cost)
        let mult = Self.buildingSameKindCostMultiplier(existing: ownedBuildingCount(of: kind))
        return mult == 1.0 ? base : base.scaled(by: mult)
    }

    /// True if the path's T1 astra is unlocked at the player's current age.
    /// Per-kind overrides on `requiredAge` push Agneyastra/Sheetastra to
    /// Treta, Trishul + all Maya tiers to Dvapara — those paths now
    /// correctly stay locked until the matching yug.
    func isPathAgeUnlocked(_ path: TowerPath) -> Bool {
        isUnlocked(path.astras[0].requiredAge)
    }

    func canAffordPath(_ path: TowerPath) -> Bool {
        isPathAgeUnlocked(path) && stock.canAfford(nextTowerPlacementCost(for: path))
    }

    func buildTower(at slotIndex: Int, path: TowerPath) {
        guard let slot = slots.first(where: { $0.index == slotIndex }),
              !isSlotOccupied(slotIndex) else { return }
        // Hard age guard — defensive: even if the UI somehow lets a
        // build through (e.g. quick-build bar), the model refuses to
        // place an age-locked path.
        guard isPathAgeUnlocked(path) else { return }
        let cost = nextTowerPlacementCost(for: path)
        guard stock.canAfford(cost) else { return }
        stock = stock - cost
        var tower = Tower(slotIndex: slotIndex, position: slot.position, path: path)
        // Pratihara signature: +30% tower HP.
        let hpMult = race?.towerHPMultiplier ?? 1.0
        tower.maxHP *= hpMult
        tower.hp = tower.maxHP
        towers.append(tower)
        // Divine guardian bond — every tower on the DIVINE path (Trishul →
        // Vajrastra → Narayana → Pashupatastra) shares strength with the
        // central Sudarshan relic. Placing one permanently bumps the
        // relic's max HP AND current HP by `divineTowerLifeBoost`, so the
        // central tower's power literally scales with the divine forces
        // protecting it. The asura host ALSO grows in response (+6% per
        // divine build, capped at +60%) to keep the curve balanced — the
        // divine line is powerful but not free.
        if path == .divine {
            maxLives += Self.divineTowerLifeBoost
            lives += Self.divineTowerLifeBoost
            divineTowersBuiltThisRun += 1
        }
        selectedSlotIndex = nil
        // Remember this path so the quick-build bar can default to it next
        // time the player opens the build menu, even after restart.
        lastBuiltPath = path
        SoundEngine.shared.playBuildPlaced()
    }

    /// Bonus gold the player receives for every boss the slayer-tower
    /// fells — also tallied on the tower's `bossLootGold` counter so the
    /// player can see which defender earns the most.
    static let towerBossLootGold: Int = 250
    /// Permanent +HP / +maxHP granted to the central Sudarshan relic per
    /// divine tower built. Stacks once per build (selling/sacrificing the
    /// divine tower does NOT refund — the bond persists).
    static let divineTowerLifeBoost: Int = 40
    /// HP/sec passive regen the central relic receives per CURRENTLY ALIVE
    /// divine tower. Dynamic — losing a divine tower drops the regen.
    static let divineTowerRegenPerSec: Double = 3.0
    /// Chakra DPS multiplier bump per CURRENTLY ALIVE divine tower. 4
    /// living divines = +60% chakra burn.
    static let divineTowerChakraBoost: Double = 0.15
    /// Damage Kali Yuga deals to the central relic per bite (before rage).
    /// Tuned so 4+ divine towers can nearly stalemate the bite via regen.
    ///   0 divine  →   22 dmg / 1.0 s = 22 dps. Base 60 lives → 2.7 s
    ///   2 divine  →   22 dps, 60+80 = 140 HP, 6 regen → 8.75 s
    ///   4 divine  →   22 dps, 220 HP, 12 regen → 22 s
    ///   6 divine  →   22 dps, 300 HP, 18 regen → 75 s (effectively safe)
    static let kaliCentralRelicBite: Double = 22.0

    func canUpgrade(tower: Tower) -> Bool {
        guard let nextAge = tower.requiredAgeForNextTier else { return false }
        return isUnlocked(nextAge) && stock.canAfford(effectiveUpgradeCost(of: tower))
    }

    func upgradeTower(id: UUID) {
        guard let i = towers.firstIndex(where: { $0.id == id }) else { return }
        guard canUpgrade(tower: towers[i]) else { return }
        stock = stock - effectiveUpgradeCost(of: towers[i])
        towers[i].tier += 1
        // Upgrading the astra also reforges the platform — +50% max HP per
        // tier step, fully topping the current HP so the upgrade visibly
        // hardens the tower (T1→T2 = +50%, T2→T3 = another +50% on the
        // already-larger pool).
        towers[i].maxHP *= 1.5
        towers[i].hp = towers[i].maxHP
    }

    func sellTower(id: UUID) {
        guard let i = towers.firstIndex(where: { $0.id == id }) else { return }
        stock = stock + effectiveSellValue(of: towers[i])
        // Refund the attached stone as STONES (half of consumed, rounded
        // down) — matches the stone-only economy. L1 = 0, L2/L3 = 1 back.
        if let stone = towers[i].stone {
            let refund = stone.level / 2
            if refund > 0 {
                stoneInventory[stone.kind, default: 0] += refund
            }
        }
        towers.remove(at: i)
        selectedTowerID = nil
    }

    /// Demolish the tower at the given id and open the build picker for its
    /// slot so the player can place a fresh tower (or resource building) in
    /// the same spot. Resource buildings cannot be replaced this way — that
    /// is intentional: the player should never accidentally lose a productive
    /// generator while reshuffling defences.
    func replaceTower(id: UUID) {
        guard let i = towers.firstIndex(where: { $0.id == id }) else { return }
        let slotIndex = towers[i].slotIndex
        sellTower(id: id)
        selectedTowerID = nil
        selectedBuildingID = nil
        selectedSlotIndex = slotIndex
    }

    // MARK: - Relocate (move a tower to a different empty slot)

    /// While set, the next tap on an empty build slot moves this tower's
    /// position to that slot — preserving tier, stones, auras, HP, kills,
    /// and wave-survival bonuses. Relocation costs resources scaled to the
    /// tower's current tier (see `relocateCost(for:)`).
    var relocatingTowerID: UUID? = nil

    /// Tiered relocation fee — free for fresh towers, expensive for the
    /// late-game astras the player has invested in. T1 relocates are
    /// completely free so a new player can freely reshuffle their opening
    /// placements without economic friction.
    ///   • T1: FREE (zero resources).
    ///   • T2: gold + ~18% of every non-gold resource of the T2 astra cost.
    ///   • T3: 30% of the T3 astra cost across every resource.
    /// Returns Resources (zero-initialised channels skipped automatically
    /// by the canAfford check, so no special-casing is needed downstream).
    func relocateCost(for tower: Tower) -> Resources {
        let base = effectiveCost(of: tower.kind)
        switch tower.tier {
        case 1:
            // Free — reshuffling a basic dart / agneyastra / etc. is part
            // of learning placement and shouldn't cost anything.
            return Resources()
        case 2:
            return Resources(
                gold:    Int((Double(base.gold)    * 0.20).rounded()),
                metal:   Int((Double(base.metal)   * 0.18).rounded()),
                tech:    Int((Double(base.tech)    * 0.18).rounded()),
                jotisha: Int((Double(base.jotisha) * 0.18).rounded()),
                veda:    Int((Double(base.veda)    * 0.18).rounded())
            )
        default:
            // T3 (and any future tier) — full-mix tax, scales with the
            // astra's astronomical late-game cost.
            return base.scaled(by: 0.30)
        }
    }

    /// True if the player can afford to relocate this tower right now.
    func canAffordRelocate(_ tower: Tower) -> Bool {
        stock.canAfford(relocateCost(for: tower))
    }

    /// Begin a relocate. Closes any open menu so the field is uncluttered
    /// while the player picks the destination slot. No resources are
    /// debited yet — the fee is taken only when the player taps an empty
    /// slot in `confirmRelocate(toSlotIndex:)`. Returns false if the tower
    /// can't be afforded.
    @discardableResult
    func startRelocate(towerID: UUID) -> Bool {
        guard let tower = towers.first(where: { $0.id == towerID }) else { return false }
        guard canAffordRelocate(tower) else { return false }
        relocatingTowerID = towerID
        selectedTowerID = nil
        selectedBuildingID = nil
        selectedSlotIndex = nil
        // Disarm both quick-build slots so a tap on a slot moves the tower
        // rather than placing something new on top.
        armedQuickBuildPath = nil
        armedQuickBuildBuilding = nil
        return true
    }

    /// Cancels an in-flight relocation without moving the tower.
    func cancelRelocate() {
        relocatingTowerID = nil
    }

    /// Move the in-flight relocating tower to the given empty slot. No-op
    /// if the slot is occupied, no relocation is in progress, or the
    /// player can no longer afford the fee (rare — resources changed
    /// between startRelocate and the slot tap).
    func confirmRelocate(toSlotIndex slotIndex: Int) {
        guard let id = relocatingTowerID,
              let ti = towers.firstIndex(where: { $0.id == id }),
              let slot = slots.first(where: { $0.index == slotIndex }),
              !isSlotOccupied(slotIndex) else {
            relocatingTowerID = nil
            return
        }
        // Re-check affordability — resources may have drained while the
        // player was deciding where to put the tower.
        let cost = relocateCost(for: towers[ti])
        guard stock.canAfford(cost) else {
            relocatingTowerID = nil
            return
        }
        stock = stock - cost
        // Mutate in place — preserves HP, kills, auras, stones, etc.
        towers[ti].slotIndex = slotIndex
        towers[ti].position = slot.position
        relocatingTowerID = nil
        SoundEngine.shared.playBuildPlaced()
    }

    // MARK: - Stone management

    // MARK: - Tower auras (heal + shield, 4 upgrade tiers each)
    //
    // L4 = "Lakshman Rekha" — the mythic protective line Lakshman drew
    // around Sita. Massive heal/shield numbers, premium cost. A maxed-out
    // tower with both auras at L4 is virtually indestructible — saved for
    // late-game key chokepoints.

    static let maxAuraLevel: Int = 4

    /// Per-tier heal-rate and range (index by level, 0 = inactive). L4
    /// (Sanjivani) is strong but no longer out-heals a focused boss attack
    /// — late-game towers can still die if left alone.
    static let healAuraRate:  [Double]  = [0, 10,  20,  32,  48]
    static let healAuraRange: [CGFloat] = [0, 100, 130, 165, 200]
    /// Per-tier shield reduction and range. L4 (Lakshman Rekha) now caps at
    /// 70% reduction so a properly invested aura genuinely keeps towers alive
    /// through focused boss damage — paired with steeper aura upgrade costs.
    static let shieldAuraReduction: [Double]  = [0, 0.25, 0.40, 0.55, 0.70]
    static let shieldAuraRangeTier: [CGFloat] = [0, 100,  130,  165,  200]

    /// Costs to go from level N to level N+1.
    static let healAuraUpgradeCost: [Resources] = [
        Resources(),                                              // L0 placeholder
        Resources(jotisha: 80,  veda: 15),                        // 0 → 1
        Resources(jotisha: 150, veda: 40),                        // 1 → 2
        Resources(gold: 200, jotisha: 240, veda: 70),             // 2 → 3
        Resources(gold: 700, jotisha: 460, veda: 180)             // 3 → 4 · Sanjivani peak
    ]
    static let shieldAuraUpgradeCost: [Resources] = [
        Resources(),
        Resources(jotisha: 15, veda: 80),                         // 0 → 1
        Resources(jotisha: 40, veda: 150),                        // 1 → 2
        Resources(gold: 200, jotisha: 70, veda: 240),             // 2 → 3
        Resources(gold: 700, jotisha: 180, veda: 460)             // 3 → 4 · Lakshman Rekha
    ]

    func nextHealAuraCost(for tower: Tower) -> Resources {
        let next = tower.healAuraLevel + 1
        guard next <= Self.maxAuraLevel else { return Resources() }
        return Self.healAuraUpgradeCost[next]
    }

    func nextShieldAuraCost(for tower: Tower) -> Resources {
        let next = tower.shieldAuraLevel + 1
        guard next <= Self.maxAuraLevel else { return Resources() }
        return Self.shieldAuraUpgradeCost[next]
    }

    /// How many towers across the pivot's ENTIRE path sit at the same
    /// heal-aura tier — they'll all advance together. So a Dart's heal
    /// aura also lifts every Aindrastra, Shakti, and Sudarshana on the
    /// arrow path that share the same starting aura level.
    func healAuraMassCount(pivot: Tower) -> Int {
        towers.filter {
            $0.path == pivot.path && $0.healAuraLevel == pivot.healAuraLevel
        }.count
    }

    /// How many same-path same-tier shield-aura towers will move together.
    func shieldAuraMassCount(pivot: Tower) -> Int {
        towers.filter {
            $0.path == pivot.path && $0.shieldAuraLevel == pivot.shieldAuraLevel
        }.count
    }

    /// Total cost to bump the heal-aura tier on every same-path same-tier
    /// tower — `per-tower cost × count`.
    func massHealAuraCost(for tower: Tower) -> Resources {
        nextHealAuraCost(for: tower).scaled(by: Double(healAuraMassCount(pivot: tower)))
    }

    /// Total cost to bump the shield-aura tier on every same-path same-
    /// tier tower — `per-tower cost × count`.
    func massShieldAuraCost(for tower: Tower) -> Resources {
        nextShieldAuraCost(for: tower).scaled(by: Double(shieldAuraMassCount(pivot: tower)))
    }

    func canUpgradeHealAura(on tower: Tower) -> Bool {
        guard isUnlocked(.middle) else { return false }
        guard tower.healAuraLevel < Self.maxAuraLevel else { return false }
        return stock.canAfford(massHealAuraCost(for: tower))
    }

    func canUpgradeShieldAura(on tower: Tower) -> Bool {
        guard isUnlocked(.modern) else { return false }
        guard tower.shieldAuraLevel < Self.maxAuraLevel else { return false }
        return stock.canAfford(massShieldAuraCost(for: tower))
    }

    func upgradeHealAura(towerID: UUID) {
        guard let pivot = towers.first(where: { $0.id == towerID }) else { return }
        guard canUpgradeHealAura(on: pivot) else { return }
        let total = massHealAuraCost(for: pivot)
        stock = stock - total
        let pivotPath = pivot.path
        let pivotLevel = pivot.healAuraLevel
        for i in towers.indices where towers[i].path == pivotPath
            && towers[i].healAuraLevel == pivotLevel {
            towers[i].healAuraLevel += 1
        }
    }

    func upgradeShieldAura(towerID: UUID) {
        guard let pivot = towers.first(where: { $0.id == towerID }) else { return }
        guard canUpgradeShieldAura(on: pivot) else { return }
        let total = massShieldAuraCost(for: pivot)
        stock = stock - total
        let pivotPath = pivot.path
        let pivotLevel = pivot.shieldAuraLevel
        for i in towers.indices where towers[i].path == pivotPath
            && towers[i].shieldAuraLevel == pivotLevel {
            towers[i].shieldAuraLevel += 1
        }
    }

    /// Pal signature: −25% stone cost (both attach and upgrade).
    func effectiveStoneCost(_ cost: Resources) -> Resources {
        let m = race?.stoneCostMultiplier ?? 1.0
        return m == 1.0 ? cost : cost.scaled(by: m)
    }

    /// Per-stone-level tower power-up duration. Stones now apply a TIMED
    /// buff on the tower (same model as the wall) — higher level = longer
    /// boost. Tuned so a freshly-attached L1 stone lasts ~30 s and a
    /// maxed L3 Raktamukhi runs nearly 2 minutes.
    static func towerStoneDuration(for kind: StoneKind, level: Int) -> TimeInterval {
        let base: TimeInterval = {
            switch kind {
            case .chuni:      return 20
            case .panna:      return 24
            case .nila:       return 28
            case .raktamukhi: return 40
            }
        }()
        // Level scaling: L1 = 1.0×, L2 = 1.8×, L3 = 3.0×
        let levelMult: Double = [1.0, 1.0, 1.8, 3.0][max(0, min(3, level))]
        return base * levelMult
    }

    /// How many towers of the pivot's astra kind currently have NO stone
    /// attached — the mass-attach will fit a stone on each of them.
    func stoneAttachTargetCount(pivot: Tower) -> Int {
        towers.filter { $0.kind == pivot.kind && $0.stone == nil }.count
    }

    /// How many towers of the pivot's astra kind share the same stone kind
    /// AND level — the mass-upgrade lifts all of those a tier together.
    func stoneUpgradeTargetCount(pivot: Tower) -> Int {
        guard let s = pivot.stone else { return 0 }
        return towers.filter {
            $0.kind == pivot.kind
                && $0.stone?.kind == s.kind
                && $0.stone?.level == s.level
        }.count
    }

    func attachStone(towerID: UUID, kind: StoneKind) {
        guard let pivot = towers.first(where: { $0.id == towerID }) else { return }
        guard pivot.stone == nil else { return }
        // SINGLE-STONE mass-attach: spend ONE stone from inventory and
        // socket it into EVERY empty same-kind slot. The stone's blessing
        // covers all defenders of the same astra.
        guard stoneCount(kind) > 0,
              stoneAttachTargetCount(pivot: pivot) > 0 else { return }
        stoneInventory[kind, default: 0] -= 1
        let dur = Self.towerStoneDuration(for: kind, level: 1)
        let pivotKind = pivot.kind
        for i in towers.indices where towers[i].kind == pivotKind && towers[i].stone == nil {
            towers[i].stone = Stone(kind: kind, level: 1)
            towers[i].stoneTimer = dur
            towers[i].stoneTimerTotal = dur
        }
        SoundEngine.shared.playBuildPlaced()
    }

    func canUpgradeStone(_ tower: Tower) -> Bool {
        guard let s = tower.stone, s.level < 3 else { return false }
        // Single same-kind stone lifts every matching socket together.
        return stoneCount(s.kind) > 0
    }

    func upgradeStone(towerID: UUID) {
        guard let pivot = towers.first(where: { $0.id == towerID }),
              let s = pivot.stone, s.level < 3 else { return }
        guard stoneCount(s.kind) > 0 else { return }
        stoneInventory[s.kind, default: 0] -= 1
        let newLevel = s.level + 1
        let dur = Self.towerStoneDuration(for: s.kind, level: newLevel)
        let pivotKind = pivot.kind
        let pivotStoneKind = s.kind
        let pivotStoneLevel = s.level
        for i in towers.indices where towers[i].kind == pivotKind
            && towers[i].stone?.kind == pivotStoneKind
            && towers[i].stone?.level == pivotStoneLevel {
            guard var st = towers[i].stone else { continue }
            st.level = newLevel
            towers[i].stone = st
            towers[i].stoneTimer = dur
            towers[i].stoneTimerTotal = dur
        }
    }

    // MARK: - Buy stones with gold

    /// Per-kind gold price for buying a single stone of that kind from the
    /// stone shop. Chuni cheapest, Raktamukhi most expensive (since it
    /// boosts every stat). Tuned so the player can afford 1-2 stone buys
    /// every couple of waves without it being trivial.
    static func goldPriceForStone(_ kind: StoneKind) -> Int {
        switch kind {
        case .chuni:      return 350    // damage
        case .panna:      return 400    // fire rate
        case .nila:       return 500    // range
        case .raktamukhi: return 1200   // all stats
        }
    }

    func canBuyStone(_ kind: StoneKind) -> Bool {
        stock.gold >= Self.goldPriceForStone(kind)
    }

    /// Convert gold into a stone of `kind` (added to inventory). Returns
    /// true if the purchase succeeded.
    @discardableResult
    func buyStone(_ kind: StoneKind) -> Bool {
        let price = Self.goldPriceForStone(kind)
        guard stock.gold >= price else { return false }
        stock.gold -= price
        stoneInventory[kind, default: 0] += 1
        SoundEngine.shared.playBuildPlaced()
        return true
    }

    func removeStone(towerID: UUID) {
        guard let i = towers.firstIndex(where: { $0.id == towerID }),
              let s = towers[i].stone else { return }
        // Stones are stone-only now, so refund STONES (half of the count
        // consumed, rounded down). L1 = 0, L2 = 1, L3 = 1 stone back.
        let spentStones = s.level
        let refund = spentStones / 2
        if refund > 0 {
            stoneInventory[s.kind, default: 0] += refund
        }
        towers[i].stone = nil
        towers[i].stoneTimer = 0
        towers[i].stoneTimerTotal = 0
    }

    // MARK: - Building management

    /// Rashtrakuta signature: −25% building cost.
    func effectiveBuildingCost(_ cost: Resources) -> Resources {
        let m = race?.buildingCostMultiplier ?? 1.0
        return m == 1.0 ? cost : cost.scaled(by: m)
    }

    func canAffordBuilding(_ kind: BuildingKind) -> Bool {
        stock.canAfford(nextBuildingPlacementCost(for: kind))
    }

    func placeBuilding(at slotIndex: Int, kind: BuildingKind) {
        guard let slot = slots.first(where: { $0.index == slotIndex }),
              !isSlotOccupied(slotIndex) else { return }
        // Parijata Briksha: once-per-run wish-tree, locked until W11.
        if kind == .parijata {
            guard wave >= 11 else { return }
            guard !buildings.contains(where: { $0.kind == .parijata }) else { return }
        }
        let cost = nextBuildingPlacementCost(for: kind)
        guard stock.canAfford(cost) else { return }
        stock = stock - cost
        buildings.append(Building(slotIndex: slotIndex, position: slot.position, kind: kind))
        selectedSlotIndex = nil
        SoundEngine.shared.playBuildPlaced()
    }

    func canUpgradeBuilding(_ b: Building) -> Bool {
        b.level < b.kind.maxLevel && stock.canAfford(effectiveBuildingCost(b.upgradeCost))
    }

    func upgradeBuilding(id: UUID) {
        guard let i = buildings.firstIndex(where: { $0.id == id }) else { return }
        guard canUpgradeBuilding(buildings[i]) else { return }
        stock = stock - effectiveBuildingCost(buildings[i].upgradeCost)
        buildings[i].level += 1
    }

    func sellBuilding(id: UUID) {
        guard let i = buildings.firstIndex(where: { $0.id == id }) else { return }
        stock = stock + buildings[i].sellValue
        buildings.remove(at: i)
        selectedBuildingID = nil
    }

    func deselectAll() {
        selectedSlotIndex = nil
        selectedTowerID = nil
        selectedBuildingID = nil
    }

    // MARK: - Game loop

    var isPaused: Bool = false
    /// Multiplied into dt each tick. Cycles 1× → 2× → 4× → 8× → 1×.
    var gameSpeed: Double = 1.0

    /// Available speed steps the toggle cycles through. Doubled-up jumps
    /// (1, 2, 4, 8) so the player can blast through grinding mid-waves
    /// without losing fine control on slower tiers.
    static let gameSpeedSteps: [Double] = [1.0, 2.0, 4.0, 8.0]

    func toggleGameSpeed() {
        let steps = Self.gameSpeedSteps
        // Find the next step strictly greater than current; wrap to 1× at top.
        if let next = steps.first(where: { $0 > gameSpeed + 0.01 }) {
            gameSpeed = next
        } else {
            gameSpeed = steps.first ?? 1.0
        }
    }

    /// Cancels an in-flight auto-start countdown without disabling the
    /// toggle itself — the next wave-end will start a fresh countdown.
    func cancelAutoStartCountdown() {
        autoStartCountdown = 0
    }

    /// Player-driven pause toggle. While true, all gameplay systems (waves,
    /// enemies, projectiles, production) freeze, but the player can still
    /// open tower/build menus and sell/upgrade/rebuild at leisure.
    func togglePause() {
        isPaused.toggle()
    }

    /// True while the player has any build/upgrade menu open. Pauses waves
    /// and resource production so the player can think tactically without
    /// the field marching on. UI animations still tick on wall-clock.
    var isInteractionPaused: Bool {
        selectedSlotIndex != nil
            || selectedTowerID != nil
            || selectedBuildingID != nil
    }

    func update(now: TimeInterval) {
        guard !isGameOver, race != nil else { return }
        // While paused (e.g. Bazaar open, or a tower/build menu is open),
        // drop the clock so resume starts from dt=0.
        if isPaused || isInteractionPaused {
            lastUpdate = nil
            return
        }

        let rawDt: TimeInterval
        if let last = lastUpdate {
            rawDt = min(0.05, now - last)
        } else {
            rawDt = 0
        }
        lastUpdate = now
        guard rawDt > 0 else { return }
        // Apply 1×–4× fast-forward to the gameplay clock (UI animations keep
        // their wall-clock cadence). Capped at 0.16 s/tick so a slow frame
        // at 4× doesn't yank physics by a quarter-second.
        let dt = min(0.16, rawDt * gameSpeed)

        if bannerTimer > 0 {
            bannerTimer -= dt
            if bannerTimer <= 0 { newAgeBanner = nil }
        }
        if resourceBannerTimer > 0 {
            resourceBannerTimer -= dt
            if resourceBannerTimer <= 0 { resourceWaveBanner = false }
        }
        if relicHitFlash > 0 {
            relicHitFlash = max(0, relicHitFlash - dt)
        }
        // Auto-start countdown — when the previous wave ended and the
        // player has the toggle on, tick down and launch the next wave at 0.
        if autoStartCountdown > 0 {
            autoStartCountdown = max(0, autoStartCountdown - dt)
            if autoStartCountdown == 0 && !isWaveActive {
                startNextWave()
            }
        }
        // Boss-entry dialog auto-dismisses
        if var dlg = bossDialog {
            dlg.timer -= dt
            if dlg.timer <= 0 {
                bossDialog = nil
            } else {
                bossDialog = dlg
            }
        }
        // Boss info card decays on the wall-clock so it doesn't linger
        // after the bossDialog. Hits 0 → card hidden until player taps a boss.
        if bossInfoCardTimer > 0 {
            bossInfoCardTimer = max(0, bossInfoCardTimer - dt)
            if bossInfoCardTimer == 0 { bossInfoCardEnemyID = nil }
        }

        if isWaveActive { waveElapsed += dt }
        generateResources(dt: dt)
        spawnTick(dt: dt)
        updateEnemies(dt: dt)
        updateFireFlashes(dt: dt)
        updateBossAttackFlashes(dt: dt)
        updateDamageNumbers(dt: dt)
        runDetection()
        runHealers(dt: dt)
        runShieldTracking()
        runEnemyAbilities()
        runRaceRegen(dt: dt)
        runDivineGuardianRegen(dt: dt)
        runTrimurtiStrike(dt: dt)
        runKaliMinions(dt: dt)
        bossAttackTowers(dt: dt)
        runGodMode(dt: dt)
        runWallTimer(dt: dt)
        runTowerStoneTimers(dt: dt)
        // Tooltip auto-dismiss timer ticks even during pauses so the
        // banner doesn't get stuck on the field.
        TooltipManager.shared.tick(dt)
        runSudarshanPhase(dt: dt)
        runRahuPhase(dt: dt)
        tryMatureIfReady()
        fireTowers(dt: dt, now: now)
        moveProjectiles(dt: dt)
        cleanupEnemies()
        cleanupTowers()
        checkWaveCompletion()
        checkGameOver()
    }

    private func generateResources(dt: TimeInterval) {
        // Buildings only produce during active waves (work-time only) — except
        // through the entire Sudarshan endgame (matured chakra → Rahu eclipse
        // → empowered boss), where the player NEEDS resources to charge the
        // Trimurti. Production runs 24/7 at 3× rate across those phases so
        // the dead Rahu-eclipse window isn't pure downtime.
        let endgameOpen = sudarshanPhase == .matured
                       || sudarshanPhase == .rahuEclipse
                       || sudarshanPhase == .empoweredBoss
        guard isWaveActive || endgameOpen else { return }
        let endgameBoost = endgameOpen ? 3.0 : 1.0
        // Difficulty production scaler — Easy doubles building income,
        // Intermediate 1.5×, Hard 1×. Combat numbers untouched.
        let difficultyMult = difficulty.productionMultiplier
        for i in buildings.indices {
            // Vritra drought aura halts production entirely.
            if droughtBuildingIDs.contains(buildings[i].id) { continue }
            if buildings[i].kind == .parijata {
                // Divine wish-tree: produces every resource at the per-sec
                // rate, BUT it's inactive (mult = 0) until the player has
                // placed at least one divine-path tower. Once empowered,
                // every divine point (earned by divine-tower boss kills)
                // adds +12% to the wish-tree's output. The tree stays
                // race-neutral — its gift is universal.
                let divineMult = parijataProductionMultiplier
                guard divineMult > 0 else { continue }
                buildings[i].partial += buildings[i].genPerSec * divineMult * endgameBoost * difficultyMult * dt
                if buildings[i].partial >= 1 {
                    let whole = Int(buildings[i].partial)
                    buildings[i].partial -= Double(whole)
                    for r in ResourceKind.allCases { stock.add(r, whole) }
                }
                continue
            }
            let mult = (race?.genMultiplier(for: buildings[i].kind.resource) ?? 1.0) * endgameBoost * difficultyMult
            buildings[i].partial += buildings[i].genPerSec * mult * dt
            if buildings[i].partial >= 1 {
                let whole = Int(buildings[i].partial)
                buildings[i].partial -= Double(whole)
                stock.add(buildings[i].kind.resource, whole)
            }
        }
    }

    private func spawnTick(dt: TimeInterval) {
        guard isWaveActive, !spawnQueue.isEmpty else { return }
        spawnTimer -= dt
        if spawnTimer <= 0 {
            let (kind, interval) = spawnQueue.removeFirst()
            spawnEnemy(kind: kind)
            spawnTimer = interval
        }
    }

    /// Bigger map = longer path + more slots = scale HP proportionally so
    /// killing enemies on iPad takes the same player effort as on iPhone.
    /// Baseline: iPhone-14 sized path (~1500px). Capped at 1.40× so big
    /// iPad maps don't double the fodder counts after the late-wave
    /// quality-over-quantity tune.
    var pathDifficultyScale: Double {
        min(1.40, max(1.0, Double(pathLength) / 1500.0))
    }

    /// Per-age enemy power multiplier. The deeper the Yug the player has
    /// unlocked, the tougher the enemies — so advancing to Treta/Dvapara
    /// is a real strategic choice (you get T2/T3+ astras, but the enemy
    /// curve also climbs to force tower upgrades).
    var ageEnemyPowerMultiplier: Double {
        switch unlockedAge {
        case .ancient: return 1.0
        case .middle:  return 1.20   // Treta — +20% enemy HP/damage from next wave
        case .modern:  return 1.50   // Dvapara — +50% enemy HP/damage from next wave
        }
    }

    private func spawnEnemy(kind: EnemyKind) {
        let (pt, dir) = pointAndDirection(at: 0)
        // Kali Yuga uses his hand-balanced HP / damage values verbatim — the
        // wave-multiplier (≈ 600× at W48) would otherwise put him in the
        // tens-of-millions of HP and the chakra could never kill him.
        let useScaling = (kind != .kaliYuga)
        // Adaptive multiplier ramps non-boss HP + tower-damage every wave the
        // player chokes enemies near spawn. Kali Yuga is opt-out to keep his
        // bespoke HP curve intact.
        let adaptive = useScaling ? adaptivePowerMultiplier : 1.0
        // Age scaler — kicks in the instant the player advances their Yug.
        let ageMult = useScaling ? ageEnemyPowerMultiplier : 1.0
        // Divine balance bump — the asura host learns from divine resistance.
        // Each divine-path tower the player has ever built makes their army
        // +6% stronger (capped at +60%). Keeps the divine line a real
        // strategic CHOICE, not a one-sided buff.
        let divineBalance = useScaling ? divineBalancePowerMultiplier : 1.0
        let hpMult = useScaling
            ? Difficulty.hpMultiplier(wave: wave) * pathDifficultyScale * adaptive * ageMult * divineBalance
            : 1.0
        let scaledHP = kind.maxHP * hpMult
        let scaledTowerDmg = useScaling
            ? kind.towerDamage * Difficulty.bossDamageMultiplier(wave: wave) * adaptive * ageMult * divineBalance
            : kind.towerDamage
        var e = Enemy(
            kind: kind, hp: scaledHP, maxHP: scaledHP,
            distance: 0, position: pt, heading: dir
        )
        e.speedMultiplier = useScaling ? Difficulty.speedMultiplier(wave: wave) : 1.0
        e.towerDamageOverride = scaledTowerDmg
        // Stamp spawn time for non-boss kinds so cleanupEnemies can record
        // how long each lived. Bosses are exempt from the time-to-kill
        // sampling to keep the average representative of trash clearance.
        if !kind.isBoss && kind != .kaliYuga {
            enemySpawnTime[e.id] = waveElapsed
        }
        enemies.append(e)
        // Boss-entry dialog — only fire the first time per run for each kind,
        // so repeat appearances don't spam the screen.
        if kind.isCardWorthy && !seenBossDialogs.contains(kind) {
            seenBossDialogs.insert(kind)
            bossDialog = (kind: kind, timer: Self.bossDialogLifetime)
        }
        // Boss info-card pops up briefly on every spawn (not just the first
        // for the kind). Player can re-summon by tapping the boss.
        if kind.isCardWorthy {
            showBossInfoCard(enemyID: e.id)
        }
        // If the player already fully charged Sudarshan before the boss
        // arrived, mature it now — otherwise the chakra would sit idle.
        if kind == .kaliYuga {
            tryMatureIfReady()
        }
    }

    private func updateEnemies(dt: TimeInterval) {
        for i in enemies.indices {
            if enemies[i].burnRemaining > 0 {
                enemies[i].hp -= enemies[i].burnDPS * dt
                enemies[i].burnRemaining -= dt
                if enemies[i].burnRemaining <= 0 { enemies[i].burnDPS = 0 }
            }
            if enemies[i].slowRemaining > 0 {
                enemies[i].slowRemaining -= dt
                if enemies[i].slowRemaining <= 0 { enemies[i].slowFactor = 1.0 }
            }
            if enemies[i].freezeRemaining > 0 {
                enemies[i].freezeRemaining -= dt
                enemies[i].freezeStreak += dt
                // Anti-stall: after 3 s of continuous freeze, force-thaw
                // and grant 1.5 s of chill immunity so the enemy can move.
                if enemies[i].freezeStreak > 3.0 {
                    enemies[i].freezeRemaining = 0
                    enemies[i].freezeStreak = 0
                    enemies[i].freezeImmunity = 1.5
                } else {
                    continue
                }
            } else {
                enemies[i].freezeStreak = 0
            }
            if enemies[i].freezeImmunity > 0 {
                enemies[i].freezeImmunity = max(0, enemies[i].freezeImmunity - dt)
            }
            let regen = enemies[i].kind.regenPerSec + enemies[i].regenPerSec
            if regen > 0, enemies[i].hp > 0 {
                enemies[i].hp = min(enemies[i].maxHP, enemies[i].hp + regen * dt)
            }
            if enemies[i].kalashReveal > 0 {
                enemies[i].kalashReveal = max(0, enemies[i].kalashReveal - dt)
            }
            // Kali Yuga is path-gated: he stays put as long as any tower is
            // within his attack reach. Only advances after killing the tower.
            var effectiveSpeed = enemies[i].kind.speed * enemies[i].slowFactor * enemies[i].speedMultiplier
                                 * CGFloat(rageMultiplier(of: enemies[i]))
                                 * devicePathSpeedScale
            // Empowered Kali Yuga abandons the path when every defence has
            // fallen OR he reaches the path end OR (sticky) he's already
            // wandered far off the path. The third clause prevents him
            // teleporting back if the player rebuilds a tower while he's
            // mid-divert. Guard against an uninitialised sudarshanPosition.
            let reachedEnd = enemies[i].kind == .kaliYuga
                && enemies[i].distance >= pathLength - 1
            let defencesGone = towers.isEmpty && buildings.isEmpty
            let offPath: Bool = {
                guard enemies[i].kind == .kaliYuga else { return false }
                let (pathPt, _) = pointAndDirection(at: min(enemies[i].distance, pathLength))
                return hypot(enemies[i].position.x - pathPt.x,
                             enemies[i].position.y - pathPt.y) > 40
            }()
            if enemies[i].kind == .kaliYuga,
               sudarshanPhase == .empoweredBoss,
               (defencesGone || reachedEnd || offPath),
               sudarshanPosition.x > 0 || sudarshanPosition.y > 0 {
                let dx = sudarshanPosition.x - enemies[i].position.x
                let dy = sudarshanPosition.y - enemies[i].position.y
                let dist = hypot(dx, dy)
                if dist > 30 {
                    let v: CGFloat = 28 * enemies[i].slowFactor
                    enemies[i].position.x += (dx / dist) * v * CGFloat(dt)
                    enemies[i].position.y += (dy / dist) * v * CGFloat(dt)
                    enemies[i].heading = CGPoint(x: dx / dist, y: dy / dist)
                }
                continue   // skip normal path advance & wrap
            }
            if enemies[i].kind == .kaliYuga {
                // Path-gate radius MUST be <= the bossAttackTowers radius (70)
                // or he'd freeze in front of a tower he can't reach to hit.
                // Only ATTACKABLE targets gate his march — buildings are
                // invulnerable to bosses, so stopping next to a gold mine
                // would otherwise freeze him forever.
                let reach: CGFloat = 70
                let nearTower = towers.contains { t in
                    hypot(t.position.x - enemies[i].position.x,
                          t.position.y - enemies[i].position.y) < reach
                }
                if nearTower { effectiveSpeed = 0 }
            }
            enemies[i].distance += effectiveSpeed * CGFloat(dt)
            if enemies[i].distance >= pathLength {
                enemies[i].distance = pathLength
                // Kali Yuga doesn't despawn at path end during the active
                // endgame phases — matured (so the chakra can finish him)
                // or empoweredBoss (so the divert branch carries him on to
                // the Sudarshan). The force-die only applies when he reaches
                // the end while Sudarshan is still charging.
                let activeEndgame = enemies[i].kind == .kaliYuga
                    && (sudarshanPhase == .matured
                        || sudarshanPhase == .empoweredBoss)
                if !activeEndgame {
                    enemies[i].hp = 0
                }
            }
            let (pt, dir) = pointAndDirection(at: enemies[i].distance)
            enemies[i].position = pt
            enemies[i].heading = dir
        }
    }

    private func fireTowers(dt: TimeInterval, now: TimeInterval) {
        for i in towers.indices {
            guard towers[i].path.isOffensive else { continue }
            // Raktabija blood-grip: towers under control don't fire at enemies.
            // In late waves (W7+) they turn against the player — handled by a
            // separate pass after the normal fire loop. Early waves (≤W6) the
            // tower is just disabled.
            if controlledTowerIDs.contains(towers[i].id) { continue }
            towers[i].fireCooldown += dt
            let interval = fireInterval(of: towers[i])
            guard towers[i].fireCooldown >= interval else { continue }
            if let target = pickTarget(for: towers[i]) {
                // Bhasmasura ash debuff: while inside an ash aura the tower
                // reverts to its tier-1 astra for all projectile properties.
                let k: TowerKind = debuffedTowerIDs.contains(towers[i].id)
                    ? towers[i].path.astras[0]
                    : towers[i].kind
                let dx = target.position.x - towers[i].position.x
                let dy = target.position.y - towers[i].position.y
                let len = max(0.0001, hypot(dx, dy))
                let heading = CGPoint(x: dx / len, y: dy / len)
                // SPECIAL-ATTACK consumption — if the tower has a boss-
                // dropped charge, the NEXT projectile deals 4× damage and
                // uses up one charge. Players who groom a boss-slayer get
                // a literal "boss astra" for each boss they finished.
                var shotDamage = damage(of: towers[i])
                if towers[i].specialCharges > 0 {
                    shotDamage *= 4.0
                    towers[i].specialCharges -= 1
                }
                let p = Projectile(
                    position: towers[i].position,
                    heading: heading,
                    targetID: target.id,
                    damage: shotDamage,
                    speed: k.projectileSpeed * (race?.projectileSpeedMultiplier ?? 1.0),
                    splashRadius: k.splashRadius,
                    color: k.color,
                    burnDPS: k.burnDPS,
                    burnDuration: k.burnDuration,
                    slowFactor: k.slowFactor,
                    slowDuration: k.slowDuration,
                    freezeDuration: k.freezeDuration,
                    // Sen signature: +1 chain target on existing chain astras.
                    chainTargets: k.chainTargets > 0
                        ? k.chainTargets + (race?.bonusChainTargets ?? 0)
                        : 0,
                    damageType: k.damageType,
                    sourceTier: towers[i].tier,
                    sourceKind: k,
                    sourceTowerID: towers[i].id
                )
                projectiles.append(p)
                towers[i].fireCooldown = 0
                // Cinematic muzzle flash at tower position
                fireFlashes.append(FireFlash(position: towers[i].position,
                                              color: k.color,
                                              damageType: k.damageType,
                                              tier: towers[i].tier,
                                              sourceKind: k))
                SoundEngine.shared.playFire(for: k, now: now)
                HapticsEngine.shared.towerFire()
            }
        }
        // --- Corrupted-tower pass: from W7 onward, Raktabija-controlled
        // towers turn on the player and shoot at their friendly neighbours
        // and resource buildings. Adds a real "lose the wave by inaction"
        // pressure to the late game.
        if wave >= 7 && !controlledTowerIDs.isEmpty {
            corruptedTowerFire(dt: dt, now: now)
        }
    }

    /// Each Raktabija-controlled tower picks its nearest non-controlled tower
    /// or resource building and fires at it using its own astra stats. Damage
    /// halved — they're sabotaging from inside, not unleashing full might.
    private func corruptedTowerFire(dt: TimeInterval, now: TimeInterval) {
        for i in towers.indices where controlledTowerIDs.contains(towers[i].id) {
            guard towers[i].path.isOffensive else { continue }
            towers[i].fireCooldown += dt
            let interval = fireInterval(of: towers[i]) * 1.4   // a bit slower than normal
            guard towers[i].fireCooldown >= interval else { continue }
            let range = self.range(of: towers[i])
            // Pick the nearest friendly tower in range. Resource buildings
            // are exempt — corrupted towers can no longer smash mines either.
            var bestTowerIdx: Int? = nil
            var bestDist: CGFloat = range
            for (ti, t) in towers.enumerated() where ti != i && !controlledTowerIDs.contains(t.id) {
                let d = hypot(t.position.x - towers[i].position.x,
                              t.position.y - towers[i].position.y)
                if d < bestDist {
                    bestDist = d
                    bestTowerIdx = ti
                }
            }
            guard bestTowerIdx != nil else { continue }
            let dmg = damage(of: towers[i]) * 0.5
            let targetPos: CGPoint
            if let ti = bestTowerIdx {
                let beforeHP = towers[ti].hp
                applyTowerDamage(index: ti, amount: dmg)
                targetPos = towers[ti].position
                if beforeHP > 0 && towers[ti].hp <= 0 {
                    // The controlled tower "kills" a friendly tower —
                    // credit it to any Raktabija nearby so its rage grows.
                    creditNearbyRaktabija(at: towers[i].position)
                }
            } else { continue }
            towers[i].fireCooldown = 0
            // Visual: red blood beam to the friendly target
            bossAttackFlashes.append(BossAttackFlash(
                from: towers[i].position,
                to: targetPos,
                color: Color(red: 0.9, green: 0.1, blue: 0.1)
            ))
            SoundEngine.shared.playFire(for: towers[i].kind, now: now)
        }
    }

    /// When a corrupted tower destroys a friendly, the nearest live Raktabija
    /// gets credit for the kill (drives its rage multiplier).
    private func creditNearbyRaktabija(at point: CGPoint) {
        var nearestIdx: Int? = nil
        var bestDist: CGFloat = .greatestFiniteMagnitude
        for (ei, e) in enemies.enumerated() where e.kind == .raktabija && e.hp > 0 {
            let d = hypot(e.position.x - point.x, e.position.y - point.y)
            if d < bestDist { bestDist = d; nearestIdx = ei }
        }
        if let n = nearestIdx { enemies[n].towerKills += 1 }
    }

    /// Age muzzle flashes; remove expired
    /// Hard caps on transient effect arrays — SwiftUI redraws every entry
    /// every frame, so an unbounded stack of in-flight effects melts the
    /// CPU. The caps drop the OLDEST entries first whenever spawned
    /// effects exceed the cap, which keeps the visual density readable
    /// while preventing the death spiral.
    static let maxFireFlashesOnScreen = 30
    static let maxBossAttackFlashesOnScreen = 16
    static let maxDamageNumbersOnScreen = 24


    private func updateFireFlashes(dt: TimeInterval) {
        for i in fireFlashes.indices { fireFlashes[i].age += dt }
        fireFlashes.removeAll { $0.age >= FireFlash.lifetime }
        if fireFlashes.count > Self.maxFireFlashesOnScreen {
            fireFlashes.removeFirst(fireFlashes.count - Self.maxFireFlashesOnScreen)
        }
    }

    private func updateBossAttackFlashes(dt: TimeInterval) {
        for i in bossAttackFlashes.indices { bossAttackFlashes[i].age += dt }
        bossAttackFlashes.removeAll { $0.age >= BossAttackFlash.lifetime }
        if bossAttackFlashes.count > Self.maxBossAttackFlashesOnScreen {
            bossAttackFlashes.removeFirst(bossAttackFlashes.count - Self.maxBossAttackFlashesOnScreen)
        }
    }

    private func updateDamageNumbers(dt: TimeInterval) {
        for i in damageNumbers.indices { damageNumbers[i].age += dt }
        damageNumbers.removeAll { $0.age >= DamageNumber.lifetime }
    }

    private func pickTarget(for tower: Tower) -> Enemy? {
        var best: Enemy? = nil
        var bestDistance: CGFloat = -1
        let r = range(of: tower)
        let raceSeesInvisible = race?.revealsInvisible == true
        for e in enemies where e.hp > 0 {
            // Invisible enemies must be detected to be targetable
            // (Gupta signature bypasses this for every tower.)
            if e.kind.isInvisible && !e.detected && !raceSeesInvisible { continue }
            let d = hypot(e.position.x - tower.position.x, e.position.y - tower.position.y)
            if d <= r, e.distance > bestDistance {
                bestDistance = e.distance
                best = e
            }
        }
        return best
    }

    // Detection pass: sensory towers reveal invisible enemies in range
    private func runDetection() {
        // Reset detection each frame
        for i in enemies.indices where enemies[i].kind.isInvisible {
            enemies[i].detected = false
        }
        let sensors = towers.filter { $0.path == .drishti }
        guard !sensors.isEmpty else { return }
        for i in enemies.indices where enemies[i].kind.isInvisible {
            for s in sensors {
                let r = range(of: s)
                let d = hypot(enemies[i].position.x - s.position.x,
                              enemies[i].position.y - s.position.y)
                if d <= r {
                    enemies[i].detected = true
                    break
                }
            }
        }
    }

    // Bosses that destroy towers (with barrier DR applied)
    /// God-mode pass — while `godModeTimer > 0`, every resource building
    /// fires a divine projectile at the nearest enemy in range on its own
    /// cooldown. Auto-disables when the timer hits 0.
    /// Tower-stone timer tick — every attached stone runs down on the
    /// wall-clock and the stone auto-removes itself when the timer hits 0.
    /// Mirrors the wall mechanic so the player thinks of stones as a
    /// timed buff, not a permanent upgrade.
    private func runTowerStoneTimers(dt: TimeInterval) {
        for i in towers.indices where towers[i].stone != nil {
            // Safeguard: if a stone exists but its timer is 0 from corrupt
            // state (e.g. a legacy save), refresh to the stone's L1 base
            // duration so it eventually expires rather than persisting forever.
            if towers[i].stoneTimer <= 0 {
                if let s = towers[i].stone {
                    let dur = Self.towerStoneDuration(for: s.kind, level: s.level)
                    towers[i].stoneTimer = dur
                    towers[i].stoneTimerTotal = dur
                }
                continue
            }
            towers[i].stoneTimer = max(0, towers[i].stoneTimer - dt)
            if towers[i].stoneTimer == 0 {
                towers[i].stone = nil
                towers[i].stoneTimerTotal = 0
            }
        }
    }

    /// Wall timer tick — decays the active wall and clears every tower's
    /// `wallShield` the moment it expires. Wall activation is stone-driven
    /// so the timer is the only thing keeping the protection alive.
    private func runWallTimer(dt: TimeInterval) {
        guard wallTimer > 0 else { return }
        wallTimer = max(0, wallTimer - dt)
        if wallTimer == 0 {
            for i in towers.indices {
                towers[i].wallShield = 0
            }
            wallActiveThisWave = false
            wallActivationDuration = nil
        }
    }

    private func runGodMode(dt: TimeInterval) {
        guard godModeTimer > 0 else { return }
        godModeTimer = max(0, godModeTimer - dt)
        let dmg = Self.godModeBuildingDamage
        let range = Self.godModeBuildingRange
        let interval = Self.godModeBuildingFireInterval
        for b in buildings {
            // Per-building cooldown so each one fires independently.
            var cd = godModeBuildingCooldown[b.id] ?? 0
            cd -= dt
            if cd > 0 {
                godModeBuildingCooldown[b.id] = cd
                continue
            }
            // Pick the nearest enemy in range (excluding bosses-only-killable-by-chakra).
            var bestIdx: Int? = nil
            var bestDist: CGFloat = range
            for (i, e) in enemies.enumerated() where e.hp > 0 {
                if e.kind == .kaliYuga { continue }
                let d = hypot(e.position.x - b.position.x, e.position.y - b.position.y)
                if d < bestDist {
                    bestDist = d
                    bestIdx = i
                }
            }
            guard let ti = bestIdx else { continue }
            // Apply divine damage directly — no projectile travel, instant beam.
            enemies[ti].hp -= dmg
            bossAttackFlashes.append(BossAttackFlash(
                from: b.position,
                to: enemies[ti].position,
                color: Color(red: 1.0, green: 0.85, blue: 0.20)
            ))
            godModeBuildingCooldown[b.id] = interval
        }
        if godModeTimer == 0 {
            godModeBuildingCooldown.removeAll(keepingCapacity: true)
        }
    }

    private func bossAttackTowers(dt: TimeInterval) {
        for i in enemies.indices where enemies[i].kind.attacksTowers {
            enemies[i].attackCooldown -= dt
            if enemies[i].attackCooldown > 0 { continue }
            let attackRadius: CGFloat = 70
            // Bosses no longer smash resource buildings — mines and gurukuls
            // are economy infrastructure and shouldn't be a casualty of poor
            // placement. Only player towers are valid melee targets.
            var nearestTowerIdx: Int? = nil
            var nearestDist: CGFloat = attackRadius
            for (ti, t) in towers.enumerated() {
                let d = hypot(t.position.x - enemies[i].position.x,
                              t.position.y - enemies[i].position.y)
                if d < nearestDist {
                    nearestDist = d
                    nearestTowerIdx = ti
                }
            }
            if let ti = nearestTowerIdx {
                let dr = barrierReduction(at: towers[ti].position)
                let baseDmg = enemies[i].towerDamageOverride > 0
                    ? enemies[i].towerDamageOverride
                    : enemies[i].kind.towerDamage
                let dmg = baseDmg * (1.0 - dr) * rageMultiplier(of: enemies[i])
                let beforeHP = towers[ti].hp
                applyTowerDamage(index: ti, amount: dmg)
                enemies[i].attackCooldown = enemies[i].kind.attackInterval
                bossAttackFlashes.append(BossAttackFlash(
                    from: enemies[i].position,
                    to: towers[ti].position,
                    color: enemies[i].kind.color
                ))
                // Blood-rage credit: this attack just destroyed a tower
                if beforeHP > 0 && towers[ti].hp <= 0 {
                    enemies[i].towerKills += 1
                    // Kali Yuga literally CONSUMES the tower he just destroyed.
                    // Each consumed tower permanently grows his cap (+8% maxHP),
                    // heals him to full of that new cap, and bumps his per-hit
                    // damage by 12%. The longer the player lets him chew through
                    // their defence, the harder he hits the next one — forcing
                    // the player to keep the chakra fed and burning.
                    if enemies[i].kind == .kaliYuga {
                        let oldMax = enemies[i].maxHP
                        let newMax = oldMax * 1.08
                        enemies[i].maxHP = newMax
                        enemies[i].hp = newMax            // full restore to new cap
                        let curDmg = enemies[i].towerDamageOverride > 0
                            ? enemies[i].towerDamageOverride
                            : enemies[i].kind.towerDamage
                        enemies[i].towerDamageOverride = curDmg * 1.12
                        enemies[i].kalashReveal = 1.0     // re-use the reveal flash
                        HapticsEngine.shared.bossKilled()
                    }
                }
                // Putana siphons life from the tower she strikes.
                if enemies[i].kind == .putana {
                    let cap = enemies[i].maxHP
                    enemies[i].hp = min(cap, enemies[i].hp + dmg)
                    drainedTowerIDs.insert(towers[ti].id)
                }
            } else if enemies[i].kind == .kaliYuga,
                      sudarshanPhase != .inactive {
                // Kali Yuga has reached the centre — once he's within reach of
                // the Sudarshan relic he gnaws on it directly. Tuned LOW
                // (~22 base, scaled by rage) so each bite represents a
                // dramatic-but-not-instant chip. The relic's surviva time
                // vs. the chakra's burn time is the real balance lever.
                let d = hypot(sudarshanPosition.x - enemies[i].position.x,
                              sudarshanPosition.y - enemies[i].position.y)
                if d < 80 {
                    let dmg = Int((Self.kaliCentralRelicBite
                                   * rageMultiplier(of: enemies[i])).rounded())
                    let before = lives
                    lives = max(0, lives - dmg)
                    if before >= maxLives * 3 / 4 && lives < maxLives * 3 / 4 {
                        HintsStore.shared.trigger(.sudarshanInDanger)
                    }
                    enemies[i].attackCooldown = enemies[i].kind.attackInterval
                    bossAttackFlashes.append(BossAttackFlash(
                        from: enemies[i].position,
                        to: sudarshanPosition,
                        color: enemies[i].kind.color
                    ))
                    relicHitFlash = 0.45
                    if lives <= 0 && !isGameOver {
                        isGameOver = true
                        SoundEngine.shared.playGameOver()
                        HapticsEngine.shared.gameOver()
                    }
                }
            }
        }
    }

    // Highest damage reduction available from any Rekha tower covering this
    // position, OR from any tower that has the shield-aura mode activated.
    private func barrierReduction(at point: CGPoint) -> Double {
        var best = 0.0
        for t in towers where t.path == .rekha {
            let r = range(of: t)
            let d = hypot(t.position.x - point.x, t.position.y - point.y)
            if d <= r {
                best = max(best, t.kind.damageReduction)
            }
        }
        let auraMult = race?.auraRangeMultiplier ?? 1.0
        for t in towers where t.shieldAuraLevel > 0 {
            let tierRange = Self.shieldAuraRangeTier[t.shieldAuraLevel] * auraMult
            let d = hypot(t.position.x - point.x, t.position.y - point.y)
            if d <= tierRange {
                best = max(best, Self.shieldAuraReduction[t.shieldAuraLevel])
            }
        }
        return best
    }

    // Healers regenerate HP of any tower in range (during wave)
    /// Ahom signature: passive tower HP regeneration while a wave is active.
    private func runRaceRegen(dt: TimeInterval) {
        guard isWaveActive else { return }
        let regen = race?.towerRegenPerSec ?? 0
        guard regen > 0 else { return }
        for i in towers.indices where towers[i].hp < towers[i].maxHP {
            towers[i].hp = min(towers[i].maxHP, towers[i].hp + regen * dt)
        }
    }

    /// Central relic passive regen — each CURRENTLY ALIVE divine-path tower
    /// (Trishul → Vajrastra → Narayana → Pashupatastra) heals the relic at
    /// `divineTowerRegenPerSec` HP/sec. Only runs during waves so the heal
    /// is a battlefield effect, not idle income.
    private func runDivineGuardianRegen(dt: TimeInterval) {
        guard isWaveActive else { return }
        if lives < maxLives {
            let aliveDivine = towers.filter { $0.path == .divine && $0.hp > 0 }.count
            if aliveDivine > 0 {
                let regen = Self.divineTowerRegenPerSec * Double(aliveDivine)
                let pool = pendingLifeRegen + regen * dt
                let whole = Int(pool)
                pendingLifeRegen = pool - Double(whole)
                if whole > 0 {
                    lives = min(maxLives, lives + whole)
                }
            }
        }
        // Central-tower passive retaliation has been REMOVED.
        // Bosses (and Kali) no longer take auto-damage from the relic's
        // 80-pt halo — the central tower fights back only when the player
        // explicitly activates it (Sudarshana Chakra burst, or the matured
        // chakra burn during the Kali fight). This keeps towers + active
        // play as the only damage source.
    }

    /// Base DPS the central relic deals to ANY enemy standing within 80px
    /// of it, regardless of chakra charge or game phase. Multiplied by
    /// `(1 + 0.25 × aliveDivineTowerCount)`.
    static let centralTowerRetaliationPerSec: Double = 600.0

    /// Fractional life-regen accumulator so 3 HP/sec divine regen doesn't
    /// get lost to integer truncation on the per-tick update.
    private var pendingLifeRegen: Double = 0

    private func runHealers(dt: TimeInterval) {
        healedTowerIDs.removeAll(keepingCapacity: true)
        guard isWaveActive else { return }
        let healers = towers.filter { $0.path == .sanjivani }
        let auraSources = towers.filter { $0.healAuraLevel > 0 }
        guard !healers.isEmpty || !auraSources.isEmpty else { return }
        for i in towers.indices {
            guard towers[i].hp < towers[i].maxHP else { continue }
            var bestRate = 0.0
            // Dedicated Sanjivani towers (legacy path, still works if any exist)
            for h in healers {
                let r = range(of: h)
                let d = hypot(h.position.x - towers[i].position.x,
                              h.position.y - towers[i].position.y)
                if d <= r {
                    bestRate = max(bestRate, h.kind.healPerSec)
                }
            }
            // Per-tower heal aura — tier 1/2/3/4 stats. Ahom forest-spirit
            // signature extends the radius by +25%.
            let auraMult = race?.auraRangeMultiplier ?? 1.0
            for h in auraSources where h.id != towers[i].id {
                let tierRange = Self.healAuraRange[h.healAuraLevel] * auraMult
                let d = hypot(h.position.x - towers[i].position.x,
                              h.position.y - towers[i].position.y)
                if d <= tierRange {
                    bestRate = max(bestRate, Self.healAuraRate[h.healAuraLevel])
                }
            }
            if bestRate > 0 {
                towers[i].hp = min(towers[i].maxHP, towers[i].hp + bestRate * dt)
                healedTowerIDs.insert(towers[i].id)
            }
        }
    }

    /// Specialist enemy abilities — Raktabija (control + spread), Bhasmasura (ash
    /// debuff that reverts tower stats to T1 while in range). Putana's drain is
    /// applied inside bossAttackTowers when she hits a tower.
    private func runEnemyAbilities() {
        // --- Raktabija blood-grip: only towers near a LIVE Raktabija are
        // controlled, recomputed every tick (used to persist for the whole
        // wave — too punishing). Once Raktabija moves away or dies, the
        // grip releases and towers fire again. Spread from adjacent
        // controlled towers still applies so a cluster can chain briefly.
        var newControlled: Set<UUID> = []
        let raktas = enemies.filter { $0.kind == .raktabija && $0.hp > 0 }
        let raktaReach: CGFloat = 70
        let bloodSpread: CGFloat = 55
        for r in raktas {
            for t in towers where !newControlled.contains(t.id) && !protectedTowerIDs.contains(t.id) {
                let d = hypot(r.position.x - t.position.x, r.position.y - t.position.y)
                if d < raktaReach { newControlled.insert(t.id) }
            }
        }
        // Spread from already-controlled-this-tick towers — only matters
        // while Raktabija is still alive and seeding the grip.
        if !newControlled.isEmpty {
            let alreadyControlled = towers.filter { newControlled.contains($0.id) }
            for src in alreadyControlled {
                for t in towers where !newControlled.contains(t.id) && !protectedTowerIDs.contains(t.id) {
                    let d = hypot(src.position.x - t.position.x, src.position.y - t.position.y)
                    if d < bloodSpread { newControlled.insert(t.id) }
                }
            }
        }
        if newControlled != controlledTowerIDs {
            controlledTowerIDs = newControlled
        }

        // --- Bhasmasura ash aura: any tower within 110px of an alive Bhasmasura
        // has its stats reduced to its path's tier-1 astra. Recomputed every tick.
        var newDebuffed: Set<UUID> = []
        let bhasmas = enemies.filter { $0.kind == .bhasmasura && $0.hp > 0 }
        let ashRadius: CGFloat = 95   // softened from 110
        if !bhasmas.isEmpty {
            for t in towers {
                for b in bhasmas {
                    let d = hypot(b.position.x - t.position.x, b.position.y - t.position.y)
                    if d < ashRadius { newDebuffed.insert(t.id); break }
                }
            }
        }
        if newDebuffed != debuffedTowerIDs {
            debuffedTowerIDs = newDebuffed
        }

        // Drained set is transient — reset here, populated in bossAttackTowers.
        if !drainedTowerIDs.isEmpty { drainedTowerIDs.removeAll() }

        // --- Ravana terror aura: nearby towers reload 50% slower.
        var newTerror: Set<UUID> = []
        let ravanas = enemies.filter { $0.kind == .ravana && $0.hp > 0 }
        let terrorReach: CGFloat = 100   // softened from 120 — targeted intimidation, not blanket
        if !ravanas.isEmpty {
            for t in towers {
                for r in ravanas {
                    let d = hypot(r.position.x - t.position.x, r.position.y - t.position.y)
                    if d < terrorReach { newTerror.insert(t.id); break }
                }
            }
        }
        if newTerror != terrorTowerIDs { terrorTowerIDs = newTerror }

        // --- Vritra drought aura: nearby buildings stop generating.
        var newDrought: Set<UUID> = []
        let vritras = enemies.filter { $0.kind == .vritra && $0.hp > 0 }
        let droughtReach: CGFloat = 140
        if !vritras.isEmpty {
            for b in buildings {
                for v in vritras {
                    let d = hypot(v.position.x - b.position.x, v.position.y - b.position.y)
                    if d < droughtReach { newDrought.insert(b.id); break }
                }
            }
        }
        if newDrought != droughtBuildingIDs { droughtBuildingIDs = newDrought }
    }

    /// Mahishasura berserker rage — at <50% HP gains +40% speed and tower-damage.
    func rageMultiplier(of enemy: Enemy) -> Double {
        // Base rage: Mahishasura goes berserk below 50% HP
        var m = (enemy.kind == .mahishasura && enemy.hp < enemy.maxHP * 0.5)
                ? 1.4 : 1.0
        // Blood-rage empowerment — every player tower / building this enemy
        // has destroyed adds +25% damage, capped at +150% (4 kills worth) so
        // late-game bosses can't one-shot a Pratihara fortress.
        if enemy.towerKills > 0 {
            m *= min(2.5, 1.0 + Double(enemy.towerKills) * 0.25)
        }
        return m
    }

    /// Tracks which towers currently sit inside a Rekha barrier's aura.
    /// Read by the view layer to draw the shield shimmer.
    private func runShieldTracking() {
        protectedTowerIDs.removeAll(keepingCapacity: true)
        let shields = towers.filter { $0.path == .rekha }
        guard !shields.isEmpty else { return }
        for t in towers {
            for s in shields where s.id != t.id {
                let r = range(of: s)
                let d = hypot(s.position.x - t.position.x,
                              s.position.y - t.position.y)
                if d <= r {
                    protectedTowerIDs.insert(t.id)
                    break
                }
            }
        }
    }

    private func cleanupTowers() {
        towers.removeAll { $0.hp <= 0 }
        buildings.removeAll { $0.hp <= 0 }
    }

    private func moveProjectiles(dt: TimeInterval) {
        var remaining: [Projectile] = []
        remaining.reserveCapacity(projectiles.count)
        for var p in projectiles {
            guard let target = enemies.first(where: { $0.id == p.targetID && $0.hp > 0 }) else {
                continue
            }
            let dx = target.position.x - p.position.x
            let dy = target.position.y - p.position.y
            let dist = hypot(dx, dy)
            let step = p.speed * CGFloat(dt)
            // Treat an overlap (dist == 0) as an immediate hit so we never
            // divide by zero on the dx/dist normalisation below.
            if dist <= step || dist == 0 {
                applyHit(at: target.position, projectile: p, primaryTargetID: target.id)
            } else {
                p.position.x += dx / dist * step
                p.position.y += dy / dist * step
                p.heading = CGPoint(x: dx / dist, y: dy / dist)
                remaining.append(p)
            }
        }
        projectiles = remaining
    }

    private func applyHit(at point: CGPoint, projectile: Projectile, primaryTargetID: UUID) {
        if let radius = projectile.splashRadius {
            for i in enemies.indices {
                let d = hypot(enemies[i].position.x - point.x, enemies[i].position.y - point.y)
                if d <= radius {
                    let falloff = max(0.5, 1.0 - Double(d / radius) * 0.5)
                    applyEffects(index: i, damage: projectile.damage * falloff, projectile: projectile)
                }
            }
        } else if let i = enemies.firstIndex(where: { $0.id == primaryTargetID }) {
            applyEffects(index: i, damage: projectile.damage, projectile: projectile)
            if projectile.chainTargets > 0 {
                chain(from: i, hops: projectile.chainTargets, projectile: projectile,
                      visited: [primaryTargetID])
            }
        }
    }

    private func applyEffects(index: Int, damage: Double, projectile: Projectile) {
        let immune = enemies[index].kind.immunities.contains(projectile.damageType)
        // Raghuvansh signature: +50% damage to bosses.
        let bossMult = enemies[index].kind.isBoss ? (race?.bossDamageBonus ?? 1.0) : 1.0
        var actualDamage = immune ? 0 : damage * bossMult
        // Kali Yuga can ONLY be killed by the Sudarshan Chakra (matured-phase
        // burn) or the Trimurti astra (charge taps + final fire). Towers can
        // soften him, but their projectiles do no HP damage — the chakra is
        // the only thing that finishes him.
        if enemies[index].kind == .kaliYuga {
            actualDamage = 0
        }
        let wasBossHit = enemies[index].kind.isBoss
        // Tarakasura adamantine armor — ignore single hits below 35 damage.
        // Forces T2+ astras (or T1 + a Chuni stone) to hurt him.
        if enemies[index].kind == .tarakasura, actualDamage > 0, actualDamage < 35 {
            actualDamage = 0
        }
        // Indrajit illusion — at <50% HP, 25% chance any incoming hit misses.
        if enemies[index].kind == .indrajit,
           enemies[index].hp < enemies[index].maxHP * 0.5,
           Double.random(in: 0..<1) < 0.25 {
            actualDamage = 0
        }
        let hpBefore = enemies[index].hp
        enemies[index].hp -= actualDamage
        // Veteran bonus: if this hit killed the enemy, credit the source tower
        // so its damage curve grows over time, and harden its plating a bit —
        // +6 max HP per kill (also tops up current HP by the same amount so
        // mid-wave growth is felt immediately rather than waiting for heals).
        if hpBefore > 0, enemies[index].hp <= 0, actualDamage > 0,
           let sourceID = projectile.sourceTowerID,
           let ti = towers.firstIndex(where: { $0.id == sourceID }) {
            towers[ti].kills += 1
            let killedKind = enemies[index].kind
            // The KILLING blow on a boss is a BIG payoff for this specific
            // tower: it gets a +50 maxHP infusion, +1 boss-slayer stack
            // (= permanent +12% damage on that tower), and a chunk of
            // bonus gold marked as battlefield loot.
            let hpGain: Double = killedKind.isCardWorthy ? 50.0 : 6.0
            towers[ti].maxHP += hpGain
            towers[ti].hp = min(towers[ti].maxHP, towers[ti].hp + hpGain)
            if killedKind.isCardWorthy {
                towers[ti].bossKills += 1
                // Battle loot — bonus gold goes straight to the player's
                // stock (the tower has no use for cash itself).
                stock.gold += Self.towerBossLootGold
                // Boss death also drops a SPECIAL ATTACK charge into the
                // slayer tower's reserve — see specialCharges.
                towers[ti].specialCharges += 1
            }
            // DIVINE POINTS — a divine-path tower (Trishul / Vajrastra /
            // Narayana / Pashupatastra) finishing off a card-worthy boss
            // empowers the Parijata Briksha. Each point boosts the
            // wish-tree's universal production by +12%.
            if towers[ti].path == .divine, killedKind.isCardWorthy {
                divinePoints += 1
            }
        }

        // Empowered Kali Yuga: the Amrit Kalash inside his ribs flashes
        // visible on any hit. Players need that visual cue to know they're
        // landing meaningful damage on the boss.
        if enemies[index].kind == .kaliYuga,
           sudarshanPhase == .empoweredBoss,
           actualDamage >= 1 {
            enemies[index].kalashReveal = 1.4
            HintsStore.shared.trigger(.kalashRevealed)
        }

        // Floating damage number — caps the array so it never grows unbounded.
        if actualDamage >= 1 {
            damageNumbers.append(DamageNumber(
                value: Int(actualDamage.rounded()),
                position: enemies[index].position,
                color: projectile.color,
                isCrit: wasBossHit && bossMult > 1.0
            ))
            if damageNumbers.count > Self.maxDamageNumbersOnScreen {
                damageNumbers.removeFirst(damageNumbers.count - Self.maxDamageNumbersOnScreen)
            }
        }

        if !immune {
            if projectile.burnDuration > 0 {
                enemies[index].burnRemaining = max(enemies[index].burnRemaining, projectile.burnDuration)
                enemies[index].burnDPS = max(enemies[index].burnDPS, projectile.burnDPS)
            }
            if projectile.slowDuration > 0 {
                enemies[index].slowRemaining = max(enemies[index].slowRemaining, projectile.slowDuration)
                enemies[index].slowFactor = min(enemies[index].slowFactor, projectile.slowFactor)
            }
            if projectile.freezeDuration > 0 {
                // Skip re-freeze while the enemy has chill immunity from a
                // forced thaw — prevents permanently-frozen path stalls.
                if enemies[index].freezeImmunity <= 0 {
                    enemies[index].freezeRemaining = max(enemies[index].freezeRemaining, projectile.freezeDuration)
                }
            }
        }

    }

    private func chain(from sourceIdx: Int, hops: Int, projectile: Projectile, visited: Set<UUID>) {
        var seen = visited
        var current = sourceIdx
        var remainingHops = hops
        let chainRange: CGFloat = 140
        while remainingHops > 0 {
            let src = enemies[current].position
            var nextIdx: Int? = nil
            var bestDist: CGFloat = chainRange
            for i in enemies.indices where !seen.contains(enemies[i].id) && enemies[i].hp > 0 {
                let d = hypot(enemies[i].position.x - src.x, enemies[i].position.y - src.y)
                if d <= bestDist {
                    bestDist = d
                    nextIdx = i
                }
            }
            guard let n = nextIdx else { break }
            applyEffects(index: n, damage: projectile.damage * 0.65, projectile: projectile)
            seen.insert(enemies[n].id)
            current = n
            remainingHops -= 1
        }
    }

    /// Damage dealt to the central tower when this enemy breaches the path.
    /// Bumped across the board so each breach lands as a real threat —
    /// late-wave bosses can now one-shot the central tower if the player
    /// fails to intercept, forcing active defence rather than "let one
    /// through, eat the chip damage". Multiplied by a wave factor in
    /// `breachDamage(for:)`.
    private func livesCost(for kind: EnemyKind) -> Int {
        switch kind {
        case .mahishasura: return 20   // start boss — anchor value the user asked for
        case .bhasmasura:  return 15
        case .raktabija:   return 15
        case .putana:      return 15
        case .indrajit:    return 25
        case .tarakasura:  return 25
        case .vritra:      return 30
        case .ravana:      return 33
        case .kaliYuga:    return 80   // catastrophic — chakra him first
        default:           return 3    // pishacha / rakshasa / daitya / asura / vetala / mayavi / bearers
        }
    }

    /// Wave-scaled breach damage. The further into the run, the more weight
    /// each breach carries on the central tower — so even a stream of fodder
    /// late-game can credibly burn the tower down. Curve: 1.0× at W1, 1.4×
    /// at W5, 2.0× at W10, 2.8× at W15, 3.0× cap.
    /// Formula: min(3.0, 1.0 + (wave-1) × 0.13).
    private func breachDamage(for enemy: Enemy) -> Int {
        // Steeper per-wave climb (0.18 vs 0.13) so the shorter 12-wave arc
        // still lands at the same ~3.0× cap by the late game.
        let waveFactor = min(3.0, 1.0 + Double(max(0, wave - 1)) * 0.18)
        // Wounded-boss bonus: bosses become MORE dangerous as they take
        // damage — at full HP they breach for the base value, at 0% HP
        // (just about to die) they breach for 1.6× the base. Encourages
        // the player to actually finish bosses rather than just maim
        // them and let them push through.
        var bossBonus: Double = 1.0
        if enemy.kind.isBoss && enemy.maxHP > 0 {
            let hpFrac = max(0.0, min(1.0, enemy.hp / enemy.maxHP))
            // 1.00 at full HP, 1.60 at zero HP. Linear interpolation.
            bossBonus = 1.0 + (1.0 - hpFrac) * 0.60
        }
        let raw = Double(livesCost(for: enemy.kind)) * waveFactor * bossBonus
        return max(1, Int(raw.rounded()))
    }

    private func cleanupEnemies() {
        var lifeLoss = 0
        var scoreGain = 0
        var pointGain = 0
        var drops = Resources()
        // Chola signature: +50% gold and Bazaar points per kill.
        let rewardMult = race?.killRewardMultiplier ?? 1.0
        for e in enemies where e.hp <= 0 {
            // Adaptive-difficulty sampling: bosses and Kali Yuga are excluded
            // (they're one-off threats that distort the average). Every other
            // dead enemy contributes its kill-fraction AND its time-alive so
            // the next wave can be tuned to the speed *and* depth the player
            // is holding the line at.
            if !e.kind.isBoss && e.kind != .kaliYuga {
                if pathLength > 0 {
                    let frac = min(1.0, max(0.0, e.distance / pathLength))
                    waveProgressSum += frac
                    waveProgressCount += 1
                    // Track the single deepest non-boss enemy too — drives the
                    // "no-one-reached-near-the-tower" rule in checkWaveCompletion.
                    if frac > deepestEnemyFraction { deepestEnemyFraction = frac }
                }
                // Only credit time-to-kill on actual kills (not breaches at
                // path-end), because a breach means the player did NOT kill
                // it quickly — including those would skew the average down.
                if e.distance < pathLength, let spawnT = enemySpawnTime[e.id] {
                    waveKillTimeSum += max(0, waveElapsed - spawnT)
                    waveKillCount += 1
                }
            }
            enemySpawnTime.removeValue(forKey: e.id)
            if e.distance >= pathLength {
                // Central-tower damage. Per-enemy base plus a wave-scaled
                // multiplier — late-wave breaches carry far more weight,
                // which is what allows a strong wave to actually kill the
                // central tower even if the player keeps small enemies
                // bleeding through.
                lifeLoss += breachDamage(for: e)
            } else {
                // Adaptive-power reward bonus — when enemies are scaled up
                // by the adaptive multiplier (because the player's defence
                // is dominant), gold + bazaar points scale by the same
                // amount. Player faces 2.4× tougher enemies → earns 2.4×
                // more, so a runaway run gets meaningful Bazaar-purchase
                // power as the trade-off.
                let powerBonus = adaptivePowerMultiplier
                let goldReward = Int((Double(e.kind.reward) * rewardMult * powerBonus).rounded())
                drops.gold += goldReward
                scoreGain += goldReward
                let ptReward = Int((Double(e.kind.bazaarPointReward) * rewardMult * powerBonus).rounded())
                pointGain += ptReward
                // Bonus resource drop (resource bearers reward big)
                drops = drops + e.kind.resourceDrop
                // Stone drop — Mani Murta gives one random power stone.
                if e.kind.isStoneBearer {
                    let allStones: [StoneKind] = StoneKind.allCases
                    let drop = allStones.randomElement() ?? .chuni
                    stoneInventory[drop, default: 0] += 1
                }
                // Kind-specific death sound; bosses also trigger a victory sloka.
                SoundEngine.shared.playEnemyDeath(kind: e.kind)
                if e.kind.isBoss {
                    HapticsEngine.shared.bossKilled()
                } else {
                    HapticsEngine.shared.enemyKilled()
                }
                // Kali Yuga falls — but Rahu may intervene.
                if e.kind == .kaliYuga {
                    // Single-phase endgame: the Sudarshan Chakra is the only
                    // thing that can fell Kali Yuga, and when it does, that's
                    // victory. The earlier Rahu eclipse → empowered → Trimurti
                    // chain was cut for simplicity — fewer phases, fewer bugs,
                    // a more focused climax.
                    if sudarshanPhase == .matured {
                        sudarshanPhase = .victory
                        HapticsEngine.shared.victory()
                    }
                }
            }
        }
        if lifeLoss > 0 {
            lives -= lifeLoss
            // Trigger the relic hit-flash visualisation.
            relicHitFlash = 0.45
        }
        if scoreGain > 0 {
            let crossedKalash = score < Self.amritaKalashCost
                                && (score + scoreGain) >= Self.amritaKalashCost
            score += scoreGain
            if crossedKalash { HintsStore.shared.trigger(.amritaKalashReady) }
        }
        if pointGain > 0 {
            let firstPoint = points == 0
            points += pointGain
            if firstPoint { HintsStore.shared.trigger(.firstBazaarPoint) }
        }
        stock = stock + drops
        enemies.removeAll { $0.hp <= 0 }
    }

    private func checkWaveCompletion() {
        guard isWaveActive, spawnQueue.isEmpty, enemies.isEmpty else { return }
        isWaveActive = false
        // Wave done — info tooltips work again between waves.
        TooltipManager.shared.suppressed = false
        // Stingy wave bonus
        let bonus = 12 + wave * 3
        stock.gold += bonus
        let scoreBefore = score
        score += bonus
        if scoreBefore < Self.amritaKalashCost && score >= Self.amritaKalashCost {
            HintsStore.shared.trigger(.amritaKalashReady)
        }
        // (Run-buff payouts moved to wave START in startNextWave so the
        // player has the resources to spend BEFORE the wave begins.)
        // Per-run Bazaar points: 3 per wave, +3 every 5 waves, +10 every 10 waves.
        // Resets on game over with the rest of the run state.
        var wavePts = 3
        if wave % 5 == 0  { wavePts += 3 }
        if wave % 10 == 0 { wavePts += 10 }
        points += wavePts
        // Towers fully restored between waves, and seasoned defenders harden
        // permanently: +12% max-HP for every wave survived. Counter the
        // adaptive enemy ramp so a tower that held its ground last wave is
        // tangibly tougher when the next wave hits. Wall shield is now a
        // wall-clock TIMED buff — only clear it if the wall has already
        // expired; otherwise the stone the player just spent would be
        // wasted by a wave ending early.
        for i in towers.indices {
            towers[i].wavesSurvived += 1
            towers[i].maxHP *= 1.12
            towers[i].hp = towers[i].maxHP
            if wallTimer <= 0 {
                towers[i].wallShield = 0
            }
        }
        if wallTimer <= 0 {
            wallActiveThisWave = false
        }
        // Auto-buy aura pass — opt-in via the UX toggle. Upgrades heal aura
        // first (cheap, jotisha-heavy) then shield aura, and keeps going as
        // long as the player can afford the next tier. Capped per tower per
        // wave to one of each kind so a flush wallet can't auto-burn its
        // entire reserve into auras in a single tick.
        if autoBuyAura {
            for i in towers.indices {
                if canUpgradeHealAura(on: towers[i]) {
                    upgradeHealAura(towerID: towers[i].id)
                }
                if canUpgradeShieldAura(on: towers[i]) {
                    upgradeShieldAura(towerID: towers[i].id)
                }
            }
        }
        // Auto-start countdown for the next wave (opt-in). Suppressed
        // once Kali Yuga has been defeated (victory) or while the
        // empowered-boss / Rahu eclipse phases drive their own pacing —
        // we don't want a stale countdown ticking under a victory screen.
        let suppressAuto: Bool = {
            if isGameOver { return true }
            switch sudarshanPhase {
            case .victory, .empoweredBoss, .rahuEclipse, .matured: return true
            default: return false
            }
        }()
        if autoStartWave && !suppressAuto {
            autoStartCountdown = Self.autoStartCountdownLength
        }

        // Adaptive difficulty rebalance — gentle ramp + active decay so the
        // multiplier never spikes the player into a sudden wall.
        //   • Both signals "easy" (fast kills + held at spawn): +12% (was 20%)
        //   • Defence leaking (avg depth > 0.8):                  −10%
        //   • Mid-zone (0.5 ≤ depth ≤ 0.8):                       −3% gentle
        //     decay so the multiplier slowly relaxes when the player is
        //     genuinely challenged but still surviving. Prevents the cap
        //     becoming a permanent ceiling that kills momentum.
        let killCount = waveKillCount
        let progressCount = waveProgressCount
        if progressCount > 0 || killCount > 0 {
            let avgDepth = progressCount > 0
                ? Double(waveProgressSum) / Double(progressCount)
                : 1.0   // no samples → assume bad, don't ramp
            let avgKillTime = killCount > 0
                ? waveKillTimeSum / Double(killCount)
                : .greatestFiniteMagnitude
            // "Fast" kill threshold scales with wave so trash mobs in W10
            // aren't expected to die as fast as the 2-HP fodder of W1.
            // 1.2s baseline + 0.15s per wave, capped at 4s.
            let fastThreshold = min(4.0, 1.2 + 0.15 * Double(wave))
            let killedFast = avgKillTime <= fastThreshold
            let heldNearSpawn = avgDepth < 0.5
            if killedFast && heldNearSpawn {
                // Defence is dominant on BOTH signals → gentle +12% bump
                // so reaching the 2.4× cap takes ~8 dominant waves
                // instead of ~5. Softer climb means no sudden walls.
                adaptivePowerMultiplier = min(2.4, adaptivePowerMultiplier * 1.12)
            } else if avgDepth > 0.8 {
                // Defence is leaking — ease back.
                adaptivePowerMultiplier = max(1.0, adaptivePowerMultiplier * 0.90)
            } else {
                // Mid-zone: player is actively challenged. Apply a slow
                // 3% decay so the difficulty doesn't lock at the cap once
                // the run gets hard. Keeps interest alive on long runs.
                adaptivePowerMultiplier = max(1.0, adaptivePowerMultiplier * 0.97)
            }
        }
        // Layered rule on top of the avg-based logic above: if NO enemy
        // this wave even got near the central tower (deepest fraction
        // below 0.8), the defence has surplus headroom and the next wave
        // should bite harder. Softened to +8% so it doesn't compound the
        // primary +12% bump into a sudden ~21% per-wave jump.
        if deepestEnemyFraction < Self.nearCentralTowerFraction {
            adaptivePowerMultiplier = min(2.4, adaptivePowerMultiplier * 1.08)
        }
        waveProgressSum = 0
        waveProgressCount = 0
        deepestEnemyFraction = 0
        waveKillTimeSum = 0
        waveKillCount = 0
        enemySpawnTime.removeAll(keepingCapacity: true)
        // Raktabija's grip releases between waves; debuff/drain are tick-recomputed.
        controlledTowerIDs.removeAll()
        SoundEngine.shared.playWaveClear()
    }

    private func checkGameOver() {
        if lives <= 0 {
            lives = 0
            if !isGameOver {
                isGameOver = true
                SoundEngine.shared.playGameOver()
                HapticsEngine.shared.gameOver()
            }
        }
    }

    // MARK: - Bazaar purchases

    enum BazaarPurchaseResult {
        case success
        case notEnoughPoints
        case alreadyActive
        case alreadyOwned
    }

    /// Spend Bazaar points to apply an item's effect. Instant items grant the
    /// effect now and are re-buyable; run buffs activate for the rest of the
    /// current run; permanent items unlock cross-run bonuses.
    // MARK: - Amrita Kalash (life-revival relic)

    /// Threshold of *run score* needed for the Amrita Kalash to appear and
    /// be used. Score is the cyan star pill in the HUD next to the heart —
    /// it accumulates from every enemy kill and wave-clear bonus.
    static let amritaKalashCost = 2000
    /// HP restored to the central tower when the Kalash is consumed.
    /// Scaled to the new 60-base pool — gives a meaningful ≈2 full pools'
    /// worth of restoration so triggering it can genuinely turn a losing
    /// run around.
    static let amritaKalashLifeGain = 130

    var canUseAmritaKalash: Bool { score >= Self.amritaKalashCost }

    /// Spends `amritaKalashCost` points of run-score and restores
    /// `amritaKalashLifeGain` lives. The Kalash icon is visible only while
    /// the player's score is at or above the threshold.
    @discardableResult
    func useAmritaKalash() -> Bool {
        guard score >= Self.amritaKalashCost else { return false }
        score -= Self.amritaKalashCost
        lives += Self.amritaKalashLifeGain
        // Keep the HP-bar denominator in sync so the relic display reads
        // "63/63" instead of a stale "63/18".
        maxLives = max(maxLives, lives)
        SoundEngine.shared.playAmritaKalash()
        HapticsEngine.shared.amritaKalashUsed()
        return true
    }

    @discardableResult
    func buyBazaarItem(_ item: BazaarItem) -> BazaarPurchaseResult {
        let store = BazaarStore.shared
        switch item.kind {
        case .instant:
            guard payPoints(item.cost) else { return .notEnoughPoints }
            applyInstantBazaar(item)
            return .success
        case .runBuff:
            guard !activeBazaarPerks.contains(item) else { return .alreadyActive }
            guard payPoints(item.cost) else { return .notEnoughPoints }
            activeBazaarPerks.insert(item)
            return .success
        case .permanent:
            guard !store.ownsPermanent(item) else { return .alreadyOwned }
            guard payPoints(item.cost) else { return .notEnoughPoints }
            store.recordPermanent(item)
            return .success
        }
    }

    /// Spend points. Drains the per-run wallet first, then the IAP-purchased
    /// persistent wallet. Returns false if the total isn't enough (no partial
    /// deduction in that case).
    @discardableResult
    private func payPoints(_ cost: Int) -> Bool {
        // Defensive: zero is a no-op; negative would be a refund bug.
        guard cost > 0 else { return cost == 0 }
        guard availablePoints >= cost else { return false }
        let fromRun = min(points, cost)
        points -= fromRun
        let remainder = cost - fromRun
        if remainder > 0 {
            BazaarStore.shared.drainPersistent(remainder)
        }
        return true
    }

    private func applyInstantBazaar(_ item: BazaarItem) {
        switch item {
        case .goldPouch:        stock.gold += 400
        case .goldVault:        stock.gold += 3500
        case .goldTreasury:     stock.gold += 20000
        case .goldHoard:        stock.gold += 50000
        case .akshayaPatra:
            // The inexhaustible vessel — 2.5k gold + 1.6k of every other
            // resource in a single tap.
            stock.gold += 2500
            stock.metal += 1600
            stock.tech += 1600
            stock.jotisha += 1600
            stock.veda += 1600
        case .warVeda:          stock.veda += 75
        case .ironCache:        stock.metal += 100
        case .sageTech:         stock.tech += 60
        case .jyotishaBlessing: stock.jotisha += 80
        case .healersBoon:
            lives += 25
            maxLives = max(maxLives, lives)
        default: break
        }
    }

    // MARK: - Reset

    func reset() {
        if let r = race {
            stock = r.startingResources
        } else {
            stock = Resources()
        }
        lives = 60 + BazaarStore.shared.bonusStartingLives + (race?.bonusStartingLives ?? 0)
        maxLives = lives
        relicHitFlash = 0
        activeBazaarPerks.removeAll()
        points = 0
        divinePoints = 0
        divineTowersBuiltThisRun = 0
        godModeUses = 0
        score = 0
        wave = 0
        isWaveActive = false
        // Durga strike state
        trimurtiStrikeCooldown = 0
        trimurtiStrikeTimer = 0
        trimurtiStrikeOrigins.removeAll()
        // Fresh run — tooltips work again from the title screen on.
        TooltipManager.shared.suppressed = false
        adaptivePowerMultiplier = 1.0
        waveProgressSum = 0
        waveProgressCount = 0
        waveKillTimeSum = 0
        waveKillCount = 0
        waveElapsed = 0
        deepestEnemyFraction = 0
        enemySpawnTime.removeAll()
        autoStartCountdown = 0
        armedQuickBuildPath = nil
        armedQuickBuildBuilding = nil
        relocatingTowerID = nil
        wallActiveThisWave = false
        wallActivationDuration = nil
        godModeTimer = 0
        godModeBuildingCooldown.removeAll()
        stoneInventory.removeAll()
        wallTimer = 0
        // autoStartWave / autoBuyAura / lastBuiltPath persist across resets —
        // they're player preferences, not run state.
        isGameOver = false
        bossDialog = nil
        bossInfoCardTimer = 0
        bossInfoCardEnemyID = nil
        seenBossDialogs.removeAll()
        newAgeBanner = nil
        resourceWaveBanner = false
        resourceBannerTimer = 0
        lastSeenAge = .ancient
        unlockedAge = .ancient
        towers.removeAll()
        buildings.removeAll()
        enemies.removeAll()
        projectiles.removeAll()
        fireFlashes.removeAll()
        damageNumbers.removeAll()
        bossAttackFlashes.removeAll()
        protectedTowerIDs.removeAll()
        healedTowerIDs.removeAll()
        controlledTowerIDs.removeAll()
        debuffedTowerIDs.removeAll()
        drainedTowerIDs.removeAll()
        terrorTowerIDs.removeAll()
        droughtBuildingIDs.removeAll()
        sudarshanPhase = .inactive
        sudarshanCharge = 0
        trimurtiCharge = 0
        rahuTimer = 0
        chakraAngle = 0
        sudarshanHP = sudarshanMaxHP
        selectedSlotIndex = nil
        selectedTowerID = nil
        selectedBuildingID = nil
        lastUpdate = nil
        spawnQueue.removeAll()
        spawnTimer = 0
        bannerTimer = 0
    }

    func fullReset() {
        race = nil
        reset()
    }
}

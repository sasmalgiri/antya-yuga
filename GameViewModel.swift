//
//  GameViewModel.swift
//  towerlogicstrategicgame
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
        case .chola:       return "+20% fire rate · +50% kill rewards"
        case .sen:         return "+20% range · +1 chain target on chain astras"
        case .ahom:        return "+20% range · towers regen 1.5 HP/s in waves"
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
        case .chola:       return "+40% Gold generation"
        case .sen:         return "+20% all resource generation"
        case .ahom:        return "+30% Veda generation"
        }
    }

    var startingResources: Resources {
        switch self {
        case .raghuvansh:  return Resources(gold: 200, metal: 20, tech: 0,  jotisha: 10, veda: 10)
        case .maurya:      return Resources(gold: 200, metal: 45, tech: 0,  jotisha: 10, veda: 0)
        case .gupta:       return Resources(gold: 200, metal: 15, tech: 35, jotisha: 10, veda: 5)
        case .pratihara:   return Resources(gold: 260, metal: 20, tech: 0,  jotisha: 10, veda: 0)
        case .rashtrakuta: return Resources(gold: 200, metal: 35, tech: 10, jotisha: 10, veda: 5)
        // Pal — the wealthy patron, a beginner-friendly start.
        case .pal:         return Resources(gold: 360, metal: 25, tech: 25, jotisha: 45, veda: 15)
        case .chola:       return Resources(gold: 250, metal: 20, tech: 0,  jotisha: 10, veda: 0)
        // Sen — the scholar's all-rounder, also tuned for new players.
        case .sen:         return Resources(gold: 260, metal: 25, tech: 35, jotisha: 20, veda: 10)
        case .ahom:        return Resources(gold: 200, metal: 20, tech: 0,  jotisha: 10, veda: 25)
        }
    }

    /// Race-specific bonus starting lives — beginner-friendly cushion for the
    /// patron / scholar races. Stacks with BazaarStore.bonusStartingLives.
    var bonusStartingLives: Int {
        switch self {
        case .sen:  return 5
        case .pal:  return 3
        default:    return 0
        }
    }

    /// Marks races that the race-select screen highlights with a green
    /// "Beginner-friendly" badge.
    var isBeginnerFriendly: Bool { self == .sen || self == .pal }

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
        case (.chola,       .gold):    return 1.40
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
    var killRewardMultiplier: Double { self == .chola ? 1.50 : 1.0 }

    /// Extra chain targets added to chain-type astras (Aindrastra, Naga Pasha).
    var bonusChainTargets: Int { self == .sen ? 1 : 0 }

    /// Tower HP regenerated per second while a wave is active.
    var towerRegenPerSec: Double { self == .ahom ? 1.5 : 0 }
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
        case .middle:  return 6
        case .modern:  return 13
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
        case .drishti:   return Color(red: 0.95, green: 0.85, blue: 0.20)
        case .sanjivani: return Color(red: 0.30, green: 0.95, blue: 0.55) // healing green
        case .rekha:     return Color(red: 0.95, green: 0.55, blue: 0.85) // protective magenta
        }
    }

    var astras: [TowerKind] {
        switch self {
        case .arrow:     return [.dart, .aindrastra, .sudarshanaChakra]
        case .fire:      return [.agneyastra, .suryastra, .brahmashirsha]
        case .water:     return [.varunastra, .nagaPasha, .garudastra]
        case .ice:       return [.sheetastra, .twashtar, .mohiniAstra]
        case .divine:    return [.trishul, .vajrastra, .pashupatastra]
        case .drishti:   return [.bala, .atibala, .divyaDrishti]
        case .sanjivani: return [.aushadhi, .sanjivaniBooti, .amritKalash]
        case .rekha:     return [.surakshaRekha, .lakshmanRekha, .vajraKavach]
        }
    }
}

enum TowerKind: String, CaseIterable, Identifiable {
    case dart, aindrastra, sudarshanaChakra
    case agneyastra, suryastra, brahmashirsha
    case varunastra, nagaPasha, garudastra
    case sheetastra, twashtar, mohiniAstra
    case trishul, vajrastra, pashupatastra
    case bala, atibala, divyaDrishti                    // sensory
    case aushadhi, sanjivaniBooti, amritKalash          // healer
    case surakshaRekha, lakshmanRekha, vajraKavach      // barrier

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dart:              return "Dart"
        case .aindrastra:        return "Aindra Astra"
        case .sudarshanaChakra:  return "Sudarshana Chakra"
        case .agneyastra:        return "Agneyastra"
        case .suryastra:         return "Suryastra"
        case .brahmashirsha:     return "Brahmashirsha"
        case .varunastra:        return "Varunastra"
        case .nagaPasha:         return "Naga Pasha"
        case .garudastra:        return "Garudastra"
        case .sheetastra:        return "Sheetastra"
        case .twashtar:          return "Twashtar"
        case .mohiniAstra:       return "Mohini Astra"
        case .trishul:           return "Trishul"
        case .vajrastra:         return "Vajrastra"
        case .pashupatastra:     return "Pashupatastra"
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
        case .sudarshanaChakra:  return "Vishnu's splash disc"
        case .agneyastra:        return "Fire — burn DoT"
        case .suryastra:         return "Sun — heavy burn"
        case .brahmashirsha:     return "Divine inferno"
        case .varunastra:        return "Water — slow"
        case .nagaPasha:         return "Snake noose chain"
        case .garudastra:        return "Garuda's wind splash"
        case .sheetastra:        return "Ice — freeze"
        case .twashtar:          return "Long freeze"
        case .mohiniAstra:       return "Mass freeze AoE"
        case .trishul:           return "Shiva's trident"
        case .vajrastra:         return "Indra's thunderbolt"
        case .pashupatastra:     return "Shiva's wrath"
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
        switch tier {
        case 2:  return .middle
        case 3:  return .modern
        default: return .ancient
        }
    }

    var cost: Resources {
        switch self {
        // Tier 1 — keep accessible
        case .dart:              return Resources(gold: 55)
        case .agneyastra:        return Resources(gold: 80)
        case .varunastra:        return Resources(gold: 90)
        case .sheetastra:        return Resources(gold: 100)
        case .trishul:           return Resources(gold: 120, metal: 18)
        case .bala:              return Resources(gold: 110, jotisha: 12)
        case .aushadhi:          return Resources(gold: 100, jotisha: 18)
        case .surakshaRekha:     return Resources(gold: 130, metal: 35)
        // Tier 2 — steeper (~+30% gold)
        case .aindrastra:        return Resources(gold: 170, tech: 35)
        case .suryastra:         return Resources(gold: 210, jotisha: 40)
        case .nagaPasha:         return Resources(gold: 220, metal: 40)
        case .twashtar:          return Resources(gold: 240, jotisha: 40)
        case .vajrastra:         return Resources(gold: 290, metal: 55, veda: 30)
        case .atibala:           return Resources(gold: 235, jotisha: 40, veda: 20)
        case .sanjivaniBooti:    return Resources(gold: 230, jotisha: 50, veda: 30)
        case .lakshmanRekha:     return Resources(gold: 290, metal: 80, veda: 30)
        // Tier 3 — premium (~+40-50%)
        case .sudarshanaChakra:  return Resources(gold: 380, metal: 90, tech: 60, veda: 35)
        case .brahmashirsha:     return Resources(gold: 460, jotisha: 100, veda: 75)
        case .garudastra:        return Resources(gold: 430, metal: 100, jotisha: 60)
        case .mohiniAstra:       return Resources(gold: 460, jotisha: 100, veda: 60)
        case .pashupatastra:     return Resources(gold: 600, metal: 140, jotisha: 100, veda: 110)
        case .divyaDrishti:      return Resources(gold: 460, jotisha: 100, veda: 75)
        case .amritKalash:       return Resources(gold: 480, jotisha: 90, veda: 110)
        case .vajraKavach:       return Resources(gold: 560, metal: 170, veda: 85)
        }
    }

    var baseDamage: Double {
        switch self {
        case .dart:              return 7
        case .aindrastra:        return 22
        case .sudarshanaChakra:  return 55
        case .agneyastra:        return 14
        case .suryastra:         return 32
        case .brahmashirsha:     return 75
        case .varunastra:        return 10
        case .nagaPasha:         return 26
        case .garudastra:        return 62
        case .sheetastra:        return 12
        case .twashtar:          return 30
        case .mohiniAstra:       return 70
        case .trishul:           return 28
        case .vajrastra:         return 70
        case .pashupatastra:     return 280
        case .bala, .atibala, .divyaDrishti: return 0
        case .aushadhi, .sanjivaniBooti, .amritKalash: return 0  // healers: heal/sec defined separately
        case .surakshaRekha, .lakshmanRekha, .vajraKavach: return 0
        }
    }

    var baseFireInterval: TimeInterval {
        switch self {
        case .dart:              return 0.35
        case .aindrastra:        return 0.65
        case .sudarshanaChakra:  return 0.85
        case .agneyastra:        return 0.70
        case .suryastra:         return 0.80
        case .brahmashirsha:     return 1.40
        case .varunastra:        return 0.80
        case .nagaPasha:         return 0.85
        case .garudastra:        return 1.10
        case .sheetastra:        return 1.00
        case .twashtar:          return 1.05
        case .mohiniAstra:       return 1.50
        case .trishul:           return 0.90
        case .vajrastra:         return 1.00
        case .pashupatastra:     return 1.80
        case .bala, .atibala, .divyaDrishti: return 1.0
        case .aushadhi, .sanjivaniBooti, .amritKalash: return 1.0
        case .surakshaRekha, .lakshmanRekha, .vajraKavach: return 1.0
        }
    }

    var baseRange: CGFloat {
        switch self {
        case .dart:              return 100
        case .aindrastra:        return 140
        case .sudarshanaChakra:  return 170
        case .agneyastra:        return 115
        case .suryastra:         return 135
        case .brahmashirsha:     return 170
        case .varunastra:        return 125
        case .nagaPasha:         return 145
        case .garudastra:        return 175
        case .sheetastra:        return 115
        case .twashtar:          return 140
        case .mohiniAstra:       return 170
        case .trishul:           return 130
        case .vajrastra:         return 170
        case .pashupatastra:     return 210
        case .bala:              return 150  // detection range
        case .atibala:           return 220
        case .divyaDrishti:      return 380
        case .aushadhi:          return 90   // heal aura range
        case .sanjivaniBooti:    return 120
        case .amritKalash:       return 160
        case .surakshaRekha:     return 100  // shield aura range
        case .lakshmanRekha:     return 130
        case .vajraKavach:       return 160
        }
    }

    var projectileSpeed: CGFloat {
        switch self {
        case .dart:              return 720
        case .aindrastra:        return 900
        case .sudarshanaChakra:  return 820
        case .agneyastra:        return 520
        case .suryastra:         return 560
        case .brahmashirsha:     return 460
        case .varunastra:        return 560
        case .nagaPasha:         return 530
        case .garudastra:        return 540
        case .sheetastra:        return 530
        case .twashtar:          return 540
        case .mohiniAstra:       return 500
        case .trishul:           return 760
        case .vajrastra:         return 1000
        case .pashupatastra:     return 820
        case .bala, .atibala, .divyaDrishti: return 0
        case .aushadhi, .sanjivaniBooti, .amritKalash: return 0
        case .surakshaRekha, .lakshmanRekha, .vajraKavach: return 0
        }
    }

    var splashRadius: CGFloat? {
        switch self {
        case .sudarshanaChakra: return 70
        case .brahmashirsha:    return 90
        case .garudastra:       return 80
        case .mohiniAstra:      return 70
        default:                return nil
        }
    }

    var burnDPS: Double {
        switch self {
        case .agneyastra:    return 9
        case .suryastra:     return 20
        case .brahmashirsha: return 35
        default: return 0
        }
    }

    var burnDuration: TimeInterval {
        switch self {
        case .agneyastra:    return 3.0
        case .suryastra:     return 4.0
        case .brahmashirsha: return 5.0
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
        case .nagaPasha:  return 2
        default:          return 0
        }
    }

    var color: Color {
        switch self {
        case .dart:              return .brown
        case .aindrastra:        return .yellow
        case .sudarshanaChakra:  return .orange
        case .agneyastra:        return .orange
        case .suryastra:         return Color(red: 1.0, green: 0.55, blue: 0.0)
        case .brahmashirsha:     return .red
        case .varunastra:        return .blue
        case .nagaPasha:         return .green
        case .garudastra:        return .mint
        case .sheetastra:        return .cyan
        case .twashtar:          return Color(red: 0.6, green: 0.85, blue: 1.0)
        case .mohiniAstra:       return Color(red: 0.7, green: 0.6, blue: 1.0)
        case .trishul:           return .indigo
        case .vajrastra:         return Color(red: 1.0, green: 0.8, blue: 0.2)
        case .pashupatastra:     return Color(red: 0.85, green: 0.15, blue: 0.95)
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
        case .sudarshanaChakra:  return "circle.dotted"
        case .agneyastra:        return "flame.fill"
        case .suryastra:         return "sun.max.fill"
        case .brahmashirsha:     return "sun.dust.fill"
        case .varunastra:        return "drop.fill"
        case .nagaPasha:         return "link"
        case .garudastra:        return "wind"
        case .sheetastra:        return "snowflake"
        case .twashtar:          return "snowflake.circle.fill"
        case .mohiniAstra:       return "sparkle"
        case .trishul:           return "arrow.up"
        case .vajrastra:         return "bolt.shield.fill"
        case .pashupatastra:     return "eye.fill"
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
        case .drishti:   return .physical
        case .sanjivani: return .physical
        case .rekha:     return .physical
        }
    }

    // Healer rate
    var healPerSec: Double {
        switch self {
        case .aushadhi:       return 8
        case .sanjivaniBooti: return 18
        case .amritKalash:    return 32
        default: return 0
        }
    }

    // Barrier damage reduction (0..1 = portion reduced)
    var damageReduction: Double {
        switch self {
        case .surakshaRekha: return 0.35
        case .lakshmanRekha: return 0.55
        case .vajraKavach:   return 0.75
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

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .goldMine:           return "Gold Mine"
        case .metalFoundry:       return "Foundry"
        case .techLab:            return "Tech Lab"
        case .jotishaObservatory: return "Observatory"
        case .vedaGurukul:        return "Gurukul"
        }
    }

    var sanskritName: String {
        switch self {
        case .goldMine:           return "Suvarna Khan"
        case .metalFoundry:       return "Loh Shala"
        case .techLab:            return "Vijnan Bhavan"
        case .jotishaObservatory: return "Vedh Shala"
        case .vedaGurukul:        return "Gurukul"
        }
    }

    var resource: ResourceKind {
        switch self {
        case .goldMine:           return .gold
        case .metalFoundry:       return .metal
        case .techLab:            return .tech
        case .jotishaObservatory: return .jotisha
        case .vedaGurukul:        return .veda
        }
    }

    var cost: Resources {
        switch self {
        case .goldMine:           return Resources(gold: 60)
        case .metalFoundry:       return Resources(gold: 80)
        case .techLab:            return Resources(gold: 100, metal: 20)
        case .jotishaObservatory: return Resources(gold: 120, tech: 20)
        case .vedaGurukul:        return Resources(gold: 140, jotisha: 20)
        }
    }

    var baseGenPerSec: Double {
        // Per-resource rate calibrated to actual demand across all towers/stones.
        switch self {
        case .goldMine:           return 0.55
        case .metalFoundry:       return 0.55
        case .techLab:            return 0.30  // tech demand ≈ 1/4 of metal
        case .jotishaObservatory: return 0.65  // heavy T2/T3 demand
        case .vedaGurukul:        return 0.65  // heavy T2/T3 demand
        }
    }

    var symbol: String {
        switch self {
        case .goldMine:           return "hammer.fill"
        case .metalFoundry:       return "flame.circle.fill"
        case .techLab:            return "cpu.fill"
        case .jotishaObservatory: return "moon.stars.fill"
        case .vedaGurukul:        return "book.closed.fill"
        }
    }

    var color: Color { resource.color }
}

// MARK: - Entities

struct Tower: Identifiable {
    let id = UUID()
    let slotIndex: Int
    let position: CGPoint
    let path: TowerPath
    var tier: Int = 1
    var fireCooldown: TimeInterval = 0
    var stone: Stone? = nil
    var hp: Double = 200
    var maxHP: Double = 200
    /// 0 = no heal aura, 1-3 = upgrade tier of the heal aura.
    /// L1 unlocks at Treta Yug; each upgrade re-applies a resource cost.
    var healAuraLevel: Int = 0
    /// 0 = no shield aura, 1-3 = upgrade tier.
    /// L1 unlocks at Dvapara Yug; each upgrade re-applies a resource cost.
    var shieldAuraLevel: Int = 0

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

    var genPerSec: Double { kind.baseGenPerSec * Double(level) }

    var upgradeCost: Resources {
        kind.cost.scaled(by: 0.7 * Double(level + 1))
    }

    var sellValue: Resources {
        // 50% refund on total spent (base + every upgrade) — keeps the
        // refund ratio constant as the building levels up.
        var spent = kind.cost
        if level > 1 {
            for lvl in 1..<level {
                spent = spent + kind.cost.scaled(by: 0.7 * Double(lvl + 1))
            }
        }
        return spent.scaled(by: 0.5)
    }
}

// MARK: - Difficulty scaling

enum Difficulty {
    /// HP scaling — gentle 1-3, then +32% per 2 waves
    /// Softened from 1.45^t so player DPS curve can keep up past wave 15.
    static func hpMultiplier(wave: Int) -> Double {
        if wave <= 3 { return 1.0 }
        let tier = (wave - 3) / 2
        return pow(1.32, Double(tier))
    }
    /// Speed: +14% every 5 waves, capped at 1.6× to keep late waves playable.
    static func speedMultiplier(wave: Int) -> CGFloat {
        let tier = max(0, (wave - 1) / 5)
        return min(1.60, pow(1.14, CGFloat(tier)))
    }
    /// Boss tower damage: +40% every 4 waves
    static func bossDamageMultiplier(wave: Int) -> Double {
        let tier = max(0, (wave - 1) / 4)
        return pow(1.40, Double(tier))
    }
    /// Spawn interval shortens fast
    static func spawnInterval(baseWave n: Int) -> TimeInterval {
        max(0.12, 0.80 - Double(n) * 0.035)
    }
}

struct Enemy: Identifiable {
    let id = UUID()
    let kind: EnemyKind
    var hp: Double
    let maxHP: Double
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
}

/// Cinematic muzzle-flash burst at a tower position when it fires.
/// Ages out over ~0.25s to fade.
struct FireFlash: Identifiable {
    let id = UUID()
    let position: CGPoint
    let color: Color
    let damageType: DamageType
    var age: TimeInterval = 0
    static let lifetime: TimeInterval = 0.25
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
        case .raktabija:      return "Raktabija"
        case .tarakasura:     return "Tarakasura"
        case .bhasmasura:     return "Bhasmasura"
        case .vritra:         return "Vritra"
        case .putana:         return "Putana"
        case .kaliYuga:      return "Kali Yuga"
        }
    }

    var maxHP: Double {
        switch self {
        case .pishacha:    return 50
        case .rakshasa:    return 130
        case .daitya:      return 300
        case .asura:       return 500
        case .vetala:      return 320
        case .mahishasura: return 1800
        case .ravana:      return 5500
        case .mayavi:      return 200
        case .indrajit:    return 2800
        case .lobhaYaksha:    return 900
        case .lohaAsura:      return 1400
        case .yantraPishacha: return 800
        case .taraDevi:       return 1000
        case .rishiAtma:      return 1700
        case .raktabija:      return 1100
        case .tarakasura:     return 1800   // softened — boss trait already adds pressure
        case .bhasmasura:     return 800
        case .vritra:         return 3200
        case .putana:         return 1000
        case .kaliYuga:      return 50000  // final boss — chakra is the realistic killer
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

    /// Bazaar points granted for killing this enemy. Per-run currency; resets at game over.
    var bazaarPointReward: Int {
        switch self {
        case .pishacha:       return 1
        case .rakshasa:       return 1
        case .daitya:         return 2
        case .asura:          return 3
        case .vetala:         return 2
        case .mahishasura:    return 35
        case .ravana:         return 90
        case .mayavi:         return 3
        case .indrajit:       return 55
        case .lobhaYaksha:    return 4
        case .lohaAsura:      return 5
        case .yantraPishacha: return 4
        case .taraDevi:       return 5
        case .rishiAtma:      return 5
        case .raktabija:      return 22
        case .tarakasura:     return 50
        case .bhasmasura:     return 18
        case .vritra:         return 70
        case .putana:         return 28
        case .kaliYuga:       return 400  // victory reward (was 200)
        }
    }

    var reward: Int {
        switch self {
        case .pishacha:    return 5
        case .rakshasa:    return 11
        case .daitya:      return 25
        case .asura:       return 42
        case .vetala:      return 30
        case .mahishasura: return 320
        case .ravana:      return 900
        case .mayavi:      return 40
        case .indrajit:    return 620
        case .lobhaYaksha:    return 55
        case .lohaAsura:      return 70
        case .yantraPishacha: return 50
        case .taraDevi:       return 65
        case .rishiAtma:      return 75
        case .raktabija:      return 220
        case .tarakasura:     return 500
        case .bhasmasura:     return 170
        case .vritra:         return 720
        case .putana:         return 260
        case .kaliYuga:       return 3500   // huge gold drop on victory (was 2000)
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
        switch self {
        case .mahishasura: return 35
        case .ravana:      return 80
        case .indrajit:    return 55
        case .tarakasura:  return 45
        case .vritra:      return 65
        case .bhasmasura:  return 25
        case .putana:      return 28   // siphon — heals self for this amount per hit
        case .kaliYuga:   return 55   // strong but path-gated (won't move until tower dies)
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
}

// MARK: - View Model

@Observable
final class GameViewModel {
    var race: Race? = nil
    var stock: Resources = Resources()

    var lives: Int = 18    // reduced from 25 — less margin for mistakes
    /// Maximum lives at the start of a fresh run. Used by the relic HP bar.
    var maxLives: Int = 18
    /// Brief timer (seconds) that drives the Sudarshan relic hit-flash animation.
    var relicHitFlash: TimeInterval = 0
    var score: Int = 0
    var wave: Int = 0
    var isWaveActive: Bool = false
    var isGameOver: Bool = false
    var newAgeBanner: Age? = nil
    /// Briefly visible at the start of every 7th wave so the player knows
    /// dynamic resource bearers are inbound.
    var resourceWaveBanner: Bool = false
    private var lastSeenAge: Age = .ancient

    var towers: [Tower] = []
    var buildings: [Building] = []
    var enemies: [Enemy] = []
    var projectiles: [Projectile] = []
    var fireFlashes: [FireFlash] = []
    var damageNumbers: [DamageNumber] = []
    var slots: [BuildSlot] = []

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

    /// Trimurti tap cost: same per-tap weight as Sudarshan; rebalanced for
    /// achievable charge during the empowered phase.
    static let trimurtiTapCost = Resources(gold: 300, metal: 30, tech: 30, jotisha: 30, veda: 30)
    static let trimurtiTapProgress: Double = 0.167   // 6 taps fills the meter
    /// Bonus chip damage applied to the empowered boss on every charge tap
    /// so the player feels each contribution land.
    static let trimurtiTapChipDamage: Double = 3500

    /// HP pool for the Sudarshan center tower itself — only attackable once
    /// every other defence has fallen during the empowered phase.
    var sudarshanHP: Double = 600
    var sudarshanMaxHP: Double = 600

    /// Resources required per "charge tap" — 10 taps fills the meter.
    static let sudarshanTapCost = Resources(gold: 300, metal: 30, tech: 30, jotisha: 30, veda: 30)
    static let sudarshanTapProgress: Double = 0.10

    private(set) var pathPoints: [CGPoint] = []
    private(set) var pathLength: CGFloat = 0
    private var segmentLengths: [CGFloat] = []

    var selectedSlotIndex: Int? = nil
    var selectedTowerID: UUID? = nil
    var selectedBuildingID: UUID? = nil

    /// Run-buff Bazaar items that are active for the current run only.
    /// Instant items aren't tracked here — they apply immediately on purchase.
    var activeBazaarPerks: Set<BazaarItem> = []

    /// Bazaar points earned during the current run only. Resets every game.
    var points: Int = 0

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
        lives = 18 + BazaarStore.shared.bonusStartingLives + race.bonusStartingLives
        maxLives = lives
        relicHitFlash = 0
        activeBazaarPerks.removeAll()
        points = 0
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
    }

    var unlockedAge: Age = .ancient

    var currentAge: Age { unlockedAge }

    func isUnlocked(_ age: Age) -> Bool { age.rawValue <= unlockedAge.rawValue }

    func ageUpgradeCost(to age: Age) -> Resources {
        switch age {
        case .ancient: return Resources()
        case .middle:  return Resources(gold: 200, metal: 80, jotisha: 40)
        case .modern:  return Resources(gold: 500, metal: 200, tech: 120, jotisha: 80, veda: 80)
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
        // Trigger Sudarshan endgame the first time Dvapara is unlocked.
        if next == .modern, sudarshanPhase == .inactive {
            beginSudarshanPhase()
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
    @discardableResult
    func tapSudarshan() -> Bool {
        guard sudarshanPhase == .charging else { return false }
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
        // Combined power flows into the chakra — assimilate all towers.
        // (Stones refund half to the player as a small consolation.)
        for t in towers {
            if let s = t.stone {
                var stoneSpent = Resources()
                for lvl in 1...s.level { stoneSpent = stoneSpent + s.kind.cost(forLevel: lvl) }
                stock = stock + stoneSpent.scaled(by: 0.5)
            }
        }
        towers.removeAll()
        selectedTowerID = nil
        SoundEngine.shared.playAgeUnlocked()
    }

    /// Per-tick chakra logic. While .matured the chakra blasts every enemy on
    /// screen, with bonus damage to the final boss. Victory is detected in
    /// cleanupEnemies when Kali Yuga's HP drops to zero.
    private func runSudarshanPhase(dt: TimeInterval) {
        guard sudarshanPhase == .matured else { return }
        chakraAngle = (chakraAngle + dt * 320).truncatingRemainder(dividingBy: 360)
        let baseDPS = 650.0
        for i in enemies.indices where enemies[i].hp > 0 {
            let mult = enemies[i].kind == .kaliYuga ? 1.4 : 1.0
            enemies[i].hp -= baseDPS * mult * dt
        }
    }

    /// Ages the Rahu eclipse and, when it ends, respawns Kali Yuga in an
    /// empowered form for the final showdown.
    private func runRahuPhase(dt: TimeInterval) {
        guard sudarshanPhase == .rahuEclipse else { return }
        rahuTimer -= dt
        if rahuTimer <= 0 {
            sudarshanPhase = .empoweredBoss
            trimurtiCharge = 0
            // Empowered respawn — +20% HP, +25% tower damage.
            let empoweredHP = 60000.0
            var e = Enemy(kind: .kaliYuga,
                          hp: empoweredHP,
                          maxHP: empoweredHP,
                          distance: 0,
                          position: pathPoints.first ?? .zero,
                          heading: CGPoint(x: 1, y: 0))
            e.towerDamageOverride = 70
            enemies.append(e)
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
        // Each tap also chips the boss so the player feels immediate impact.
        for i in enemies.indices where enemies[i].kind == .kaliYuga {
            enemies[i].hp -= Self.trimurtiTapChipDamage
        }
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
        // Massive but bounded hit — 40 000 damage. Tap chip (3 500 × up to
        // ~6 taps) plus this hit usually finishes the empowered boss (60 k
        // HP) on first fire; a player who fires too early may have to
        // charge a second time.
        for i in enemies.indices where enemies[i].kind == .kaliYuga {
            enemies[i].hp -= 40000
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
            return updated
        }
        buildings = buildings.compactMap { b in
            guard let slot = slots.first(where: { $0.index == b.slotIndex }) else { return nil }
            var updated = Building(slotIndex: b.slotIndex, position: slot.position, kind: b.kind)
            updated.level = b.level
            updated.partial = b.partial
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
        slots = computeSlots(size: size, isLarge: isLarge)
        // Position the Sudarshan relic at path end from W1.
        sudarshanPosition = computeSudarshanPosition()
    }

    // Both paths now spiral inward from a screen edge and terminate at the
    // Sudarshan at screen-centre. The Sudarshan is the visible goal — the
    // enemies are visibly marching toward the relic at the heart of the map.

    private static func compactPath(w: CGFloat, h: CGFloat) -> [CGPoint] {
        [
            CGPoint(x: -10,       y: h * 0.12),        // enter top-left edge
            CGPoint(x: w * 0.88,  y: h * 0.12),        // hug top
            CGPoint(x: w * 0.88,  y: h * 0.88),        // down right side
            CGPoint(x: w * 0.12,  y: h * 0.88),        // along bottom
            CGPoint(x: w * 0.12,  y: h * 0.32),        // up left side (inset)
            CGPoint(x: w * 0.72,  y: h * 0.32),        // inward turn
            CGPoint(x: w * 0.72,  y: h * 0.68),        // down
            CGPoint(x: w * 0.50,  y: h * 0.68),        // approach centre
            CGPoint(x: w * 0.50,  y: h * 0.50)         // arrive at Sudarshan
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
        // Wider spacing so towers don't visually overlap
        // Towers are ~50px wide → need ≥55-60px between adjacent slots
        let step: CGFloat = isLarge ? 95 : 85
        // Inner row at 55, outer row at 120 (gap of 65 between rows)
        let offsets: [CGFloat] = isLarge ? [60, -60, 125, -125] : [55, -55, 115, -115]
        let topMargin: CGFloat = 110
        let bottomMargin: CGFloat = 130
        let minSlotDistance: CGFloat = 60   // reject slots that would crowd
        var d: CGFloat = step / 2
        while d < pathLength - 20 {
            let (pt, dir) = pointAndDirection(at: d)
            let normal = CGPoint(x: -dir.y, y: dir.x)
            for off in offsets {
                let pos = CGPoint(x: pt.x + normal.x * off, y: pt.y + normal.y * off)
                guard pos.x > 30, pos.x < size.width - 30,
                      pos.y > topMargin, pos.y < size.height - bottomMargin else { continue }
                // Reject if too close to path
                if overlapsPath(pos, threshold: 32) { continue }
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
        // perimeter, not only adjacent to the path itself.
        let edgeStepX: CGFloat = isLarge ? 90 : 78
        let edgeStepY: CGFloat = isLarge ? 78 : 70
        let leftEdgeMax: CGFloat = isLarge ? 110 : 80
        let rightEdgeMin: CGFloat = size.width - (isLarge ? 110 : 80)

        // 1) Bottom strip — two-row grid below the path's lowest extent.
        let bottomBandTop = size.height - (isLarge ? 180 : 150)
        var y = bottomBandTop
        while y < size.height - 70 {
            var x = edgeStepX * 0.5
            while x < size.width - edgeStepX * 0.5 {
                let pos = CGPoint(x: x, y: y)
                if !overlapsPath(pos, threshold: 36),
                   !result.contains(where: { hypot($0.position.x - pos.x, $0.position.y - pos.y) < minSlotDistance }) {
                    result.append(BuildSlot(index: idx, position: pos))
                    idx += 1
                }
                x += edgeStepX
            }
            y += edgeStepY
        }

        // 2) Left and right edge columns — vertical strips not already filled.
        var sideY = topMargin
        while sideY < size.height - bottomMargin {
            for x in [edgeStepX * 0.5, size.width - edgeStepX * 0.5] {
                let pos = CGPoint(x: x, y: sideY)
                let inSideBand = pos.x < leftEdgeMax || pos.x > rightEdgeMin
                guard inSideBand,
                      pos.y > topMargin, pos.y < size.height - bottomMargin else { continue }
                if overlapsPath(pos, threshold: 36) { continue }
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

    func effectiveCost(of kind: TowerKind) -> Resources {
        var c = kind.cost
        if let mult = race?.goldCostMultiplier, mult != 1.0 {
            c.gold = Int((Double(c.gold) * mult).rounded())
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
        wave += 1
        isWaveActive = true
        spawnQueue = buildWave(wave)
        spawnTimer = 0
        // Resource Wave banner (every 7th wave from W7 onward)
        if wave % 7 == 0 && wave >= 7 {
            resourceWaveBanner = true
            resourceBannerTimer = 2.8
        }
        SoundEngine.shared.playWaveStart()
    }

    private func buildWave(_ n: Int) -> [(EnemyKind, TimeInterval)] {
        var list: [(EnemyKind, TimeInterval)] = []
        let interval = Difficulty.spawnInterval(baseWave: n)

        // Every 7 waves is a BOON WAVE
        if n % 7 == 0 && n >= 7 {
            return scaleWaveByPath(buildBoonWave(n))
        }

        if n <= 4 {
            // Intro: Pishacha + a few Rakshasa, very gentle ramp
            let p = 4 + n * 2
            let r = max(0, n - 2)
            for _ in 0..<p { list.append((.pishacha, interval)) }
            for _ in 0..<r { list.append((.rakshasa, interval)) }

        } else if n <= 8 {
            // Mayavi now appears from W6 — sensory required earlier.
            // Bhasmasura (fire-immune fast tower-burner) enters from W6 — forces ice/water/divine play.
            let p = 8 + n
            let r = 5 + (n - 4)
            let d = max(0, n - 5) * 2
            let m = max(0, n - 5)
            let bh = max(0, n - 5)
            for _ in 0..<p { list.append((.pishacha, interval)) }
            for _ in 0..<r { list.append((.rakshasa, interval)) }
            for _ in 0..<d { list.append((.daitya, interval + 0.20)) }
            for _ in 0..<m { list.append((.mayavi, interval + 0.10)) }
            for _ in 0..<bh { list.append((.bhasmasura, interval + 0.18)) }
            if n == 5 { list.append((.mahishasura, 1.4)) }
            if n == 6 { list.append((.mahishasura, 1.3)) }
            if n == 7 { list.append((.mahishasura, 1.2)); list.append((.daitya, 1.5)) }
            if n == 8 { list.append((.mahishasura, 1.1)); list.append((.mahishasura, 1.4)) }  // DOUBLE Mahisha at W8

        } else if n <= 12 {
            // Vetala (ice+water imm) + Mayavi (invisible) appear from W9+
            // Sensory + multi-damage becomes mandatory.
            // Raktabija (phys-immune + regen) and Putana (divine-only) enter here.
            let p = 8 + n
            let r = 6 + (n - 8)
            let d = 3 + (n - 8)
            let v = max(0, n - 9)
            let m = max(0, n - 8) * 2   // invisible pressure
            let bh = 1 + (n - 9)
            let rb = max(0, n - 9)
            for _ in 0..<p { list.append((.pishacha, interval)) }
            for _ in 0..<r { list.append((.rakshasa, interval)) }
            for _ in 0..<d { list.append((.daitya, interval + 0.15)) }
            for _ in 0..<v { list.append((.vetala, interval + 0.15)) }
            for _ in 0..<m { list.append((.mayavi, interval + 0.10)) }
            for _ in 0..<bh { list.append((.bhasmasura, interval + 0.18)) }
            for _ in 0..<rb { list.append((.raktabija, interval + 0.25)) }
            if n == 9  { list.append((.mahishasura, 1.3)) }
            if n == 10 {
                // First multi-boss wave: 2 Mahishasuras
                list.append((.mahishasura, 1.1))
                list.append((.mahishasura, 1.3))
            }
            if n == 11 { list.append((.mahishasura, 1.2)); list.append((.putana, 1.7)) }
            if n == 12 {
                // Mahisha + invisible Indrajit (forces sensory by now)
                list.append((.mahishasura, 1.0))
                list.append((.indrajit, 1.5))
                list.append((.putana, 1.8))
            }

        } else if n <= 14 {
            // Asura (physical-immune) joins. Counts trimmed so waves feel
            // finite instead of dragging on for minutes.
            let p = 12 + n
            let r = 8 + (n - 12)
            let d = 5 + (n - 12)
            let v = 3 + (n - 12)
            let a = 2 + (n - 12)
            let m = 4 + (n - 12)
            for _ in 0..<p { list.append((.pishacha, interval)) }
            for _ in 0..<r { list.append((.rakshasa, interval)) }
            for _ in 0..<d { list.append((.daitya, interval)) }
            for _ in 0..<a { list.append((.asura, interval + 0.18)) }
            for _ in 0..<v { list.append((.vetala, interval + 0.12)) }
            for _ in 0..<m { list.append((.mayavi, interval + 0.10)) }
            // ONE big boss per wave instead of three — keeps the spotlight
            // on a single fight rather than a multi-boss pile.
            if n == 13 { list.append((.tarakasura, 1.5)) }
            if n == 14 { list.append((.raktabija, 1.5)) }

        } else if n <= 19 {
            // Bosses mixed in — but counts capped so each wave fits a
            // reasonable timeframe.
            let p = 14 + (n - 14)
            let r = 10 + (n - 14)
            let d = 7 + (n - 14)
            let v = 4 + (n - 14)
            let a = 4 + (n - 14)
            let m = 5 + (n - 14)
            for _ in 0..<p { list.append((.pishacha, interval)) }
            for _ in 0..<r { list.append((.rakshasa, interval)) }
            for _ in 0..<d { list.append((.daitya, interval)) }
            for _ in 0..<a { list.append((.asura, interval + 0.16)) }
            for _ in 0..<v { list.append((.vetala, interval + 0.12)) }
            for _ in 0..<m { list.append((.mayavi, interval + 0.10)) }
            // 1-2 bosses per wave only.
            switch n {
            case 15: list.append((.mahishasura, 1.2))
            case 16: list.append((.ravana, 1.4))
            case 17: list.append((.indrajit, 1.4)); list.append((.raktabija, 1.7))
            case 18: list.append((.tarakasura, 1.4)); list.append((.indrajit, 1.7))
            case 19: list.append((.ravana, 1.2)); list.append((.putana, 1.6))
            default: break
            }

        } else {
            // Late game (W20+). Still climactic but bounded.
            // FINAL: at wave 48, Kali Yuga debuts — only one ever spawned.
            if n == 48, !enemies.contains(where: { $0.kind == .kaliYuga }) {
                list.append((.kaliYuga, 0.6))
            }
            let p = 18 + min(15, n - 19)
            let r = 12 + min(10, n - 19)
            let d = 8  + min(8,  n - 19)
            let v = 5  + min(5,  n - 19)
            let a = 5  + min(5,  n - 19)
            let m = 6  + min(6,  n - 19)
            for _ in 0..<p { list.append((.pishacha, interval)) }
            for _ in 0..<r { list.append((.rakshasa, interval)) }
            for _ in 0..<d { list.append((.daitya, interval)) }
            for _ in 0..<a { list.append((.asura, interval + 0.16)) }
            for _ in 0..<v { list.append((.vetala, interval + 0.12)) }
            for _ in 0..<m { list.append((.mayavi, interval + 0.10)) }
            // 2 bosses per wave baseline, scaling toward 3 in apex range.
            list.append((.mahishasura, 1.2))
            list.append((.ravana, 1.5))
            if n % 2 == 0 { list.append((.tarakasura, 1.6)) }
            if n % 3 == 0 { list.append((.indrajit, 1.7)) }
            if n >= 25 { list.append((.vritra, 1.4)) }
            if n >= 35 { list.append((.raktabija, 1.5)) }
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
            if kind.attacksTowers || kind.isResourceBearer {
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

        // Fodder mob to keep pressure
        let p = 6 + n
        let r = 4 + (n / 4)
        for _ in 0..<p { list.append((.pishacha, interval + 0.05)) }
        for _ in 0..<r { list.append((.rakshasa, interval + 0.10)) }

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
        guard total > 0 else {
            for _ in 0..<count { picks.append(table.randomElement()!.kind) }
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
            if !picked { picks.append(table.last!.kind) }
        }
        return picks
    }

    // MARK: - Slot occupancy

    func isSlotOccupied(_ slotIndex: Int) -> Bool {
        towers.contains(where: { $0.slotIndex == slotIndex }) ||
        buildings.contains(where: { $0.slotIndex == slotIndex })
    }

    // MARK: - Tower management

    func canAffordPath(_ path: TowerPath) -> Bool {
        stock.canAfford(effectiveCost(of: path.astras[0]))
    }

    func buildTower(at slotIndex: Int, path: TowerPath) {
        guard let slot = slots.first(where: { $0.index == slotIndex }),
              !isSlotOccupied(slotIndex) else { return }
        let cost = effectiveCost(of: path.astras[0])
        guard stock.canAfford(cost) else { return }
        stock = stock - cost
        var tower = Tower(slotIndex: slotIndex, position: slot.position, path: path)
        // Pratihara signature: +30% tower HP.
        let hpMult = race?.towerHPMultiplier ?? 1.0
        tower.maxHP *= hpMult
        tower.hp = tower.maxHP
        towers.append(tower)
        selectedSlotIndex = nil
        SoundEngine.shared.playBuildPlaced()
    }

    func canUpgrade(tower: Tower) -> Bool {
        guard let nextAge = tower.requiredAgeForNextTier else { return false }
        return isUnlocked(nextAge) && stock.canAfford(effectiveUpgradeCost(of: tower))
    }

    func upgradeTower(id: UUID) {
        guard let i = towers.firstIndex(where: { $0.id == id }) else { return }
        guard canUpgrade(tower: towers[i]) else { return }
        stock = stock - effectiveUpgradeCost(of: towers[i])
        towers[i].tier += 1
    }

    func sellTower(id: UUID) {
        guard let i = towers.firstIndex(where: { $0.id == id }) else { return }
        stock = stock + effectiveSellValue(of: towers[i])
        // Refund 50% of stone investment too
        if let stone = towers[i].stone {
            var stoneSpent = Resources()
            for lvl in 1...stone.level { stoneSpent = stoneSpent + stone.kind.cost(forLevel: lvl) }
            stock = stock + stoneSpent.scaled(by: 0.5)
        }
        towers.remove(at: i)
        selectedTowerID = nil
    }

    // MARK: - Stone management

    // MARK: - Tower auras (heal + shield, 3 upgrade tiers each)

    static let maxAuraLevel: Int = 3

    /// Per-tier heal-rate and range (index by level, 0 = inactive).
    static let healAuraRate:  [Double]  = [0, 6,  12,  22]
    static let healAuraRange: [CGFloat] = [0, 85, 110, 140]
    /// Per-tier shield reduction and range. L3 now actually deflects half
    /// of incoming damage so a fully-upgraded shield can keep nearby
    /// towers alive through a Ravana / Vritra rampage.
    static let shieldAuraReduction: [Double]  = [0, 0.20, 0.35, 0.50]
    static let shieldAuraRangeTier: [CGFloat] = [0, 85,   110,  140]

    /// Costs to go from level N to level N+1.
    static let healAuraUpgradeCost: [Resources] = [
        Resources(),                              // L0 placeholder
        Resources(jotisha: 50,  veda: 5),         // 0 → 1
        Resources(jotisha: 90,  veda: 15),        // 1 → 2
        Resources(jotisha: 140, veda: 30)         // 2 → 3
    ]
    static let shieldAuraUpgradeCost: [Resources] = [
        Resources(),
        Resources(jotisha: 5,  veda: 50),
        Resources(jotisha: 15, veda: 90),
        Resources(jotisha: 30, veda: 140)
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

    func canUpgradeHealAura(on tower: Tower) -> Bool {
        guard isUnlocked(.middle) else { return false }
        guard tower.healAuraLevel < Self.maxAuraLevel else { return false }
        return stock.canAfford(nextHealAuraCost(for: tower))
    }

    func canUpgradeShieldAura(on tower: Tower) -> Bool {
        guard isUnlocked(.modern) else { return false }
        guard tower.shieldAuraLevel < Self.maxAuraLevel else { return false }
        return stock.canAfford(nextShieldAuraCost(for: tower))
    }

    func upgradeHealAura(towerID: UUID) {
        guard let i = towers.firstIndex(where: { $0.id == towerID }) else { return }
        guard canUpgradeHealAura(on: towers[i]) else { return }
        stock = stock - nextHealAuraCost(for: towers[i])
        towers[i].healAuraLevel += 1
    }

    func upgradeShieldAura(towerID: UUID) {
        guard let i = towers.firstIndex(where: { $0.id == towerID }) else { return }
        guard canUpgradeShieldAura(on: towers[i]) else { return }
        stock = stock - nextShieldAuraCost(for: towers[i])
        towers[i].shieldAuraLevel += 1
    }

    /// Pal signature: −25% stone cost (both attach and upgrade).
    func effectiveStoneCost(_ cost: Resources) -> Resources {
        let m = race?.stoneCostMultiplier ?? 1.0
        return m == 1.0 ? cost : cost.scaled(by: m)
    }

    func attachStone(towerID: UUID, kind: StoneKind) {
        guard let i = towers.firstIndex(where: { $0.id == towerID }) else { return }
        guard towers[i].stone == nil else { return }
        let cost = effectiveStoneCost(kind.cost(forLevel: 1))
        guard stock.canAfford(cost) else { return }
        stock = stock - cost
        towers[i].stone = Stone(kind: kind, level: 1)
        SoundEngine.shared.playBuildPlaced()
    }

    func canUpgradeStone(_ tower: Tower) -> Bool {
        guard let s = tower.stone, s.level < 3 else { return false }
        return stock.canAfford(effectiveStoneCost(s.kind.cost(forLevel: s.level + 1)))
    }

    func upgradeStone(towerID: UUID) {
        guard let i = towers.firstIndex(where: { $0.id == towerID }),
              var s = towers[i].stone, s.level < 3 else { return }
        let cost = effectiveStoneCost(s.kind.cost(forLevel: s.level + 1))
        guard stock.canAfford(cost) else { return }
        stock = stock - cost
        s.level += 1
        towers[i].stone = s
    }

    func removeStone(towerID: UUID) {
        guard let i = towers.firstIndex(where: { $0.id == towerID }),
              let s = towers[i].stone else { return }
        var spent = Resources()
        for lvl in 1...s.level { spent = spent + s.kind.cost(forLevel: lvl) }
        stock = stock + spent.scaled(by: 0.5)
        towers[i].stone = nil
    }

    // MARK: - Building management

    /// Rashtrakuta signature: −25% building cost.
    func effectiveBuildingCost(_ cost: Resources) -> Resources {
        let m = race?.buildingCostMultiplier ?? 1.0
        return m == 1.0 ? cost : cost.scaled(by: m)
    }

    func canAffordBuilding(_ kind: BuildingKind) -> Bool {
        stock.canAfford(effectiveBuildingCost(kind.cost))
    }

    func placeBuilding(at slotIndex: Int, kind: BuildingKind) {
        guard let slot = slots.first(where: { $0.index == slotIndex }),
              !isSlotOccupied(slotIndex) else { return }
        let cost = effectiveBuildingCost(kind.cost)
        guard stock.canAfford(cost) else { return }
        stock = stock - cost
        buildings.append(Building(slotIndex: slotIndex, position: slot.position, kind: kind))
        selectedSlotIndex = nil
        SoundEngine.shared.playBuildPlaced()
    }

    func canUpgradeBuilding(_ b: Building) -> Bool {
        b.level < 3 && stock.canAfford(effectiveBuildingCost(b.upgradeCost))
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
    /// 1.0 = normal, 2.0 = fast-forward. Multiplied into dt each tick.
    var gameSpeed: Double = 1.0

    func toggleGameSpeed() {
        gameSpeed = gameSpeed >= 1.99 ? 1.0 : 2.0
    }

    func update(now: TimeInterval) {
        guard !isGameOver, race != nil else { return }
        // While paused (e.g. Bazaar open), drop the clock so resume starts from dt=0.
        if isPaused {
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
        // Apply 1×/2× fast-forward to the gameplay clock (UI animations keep
        // their wall-clock cadence). Capped at 0.10s/tick to stay stable.
        let dt = min(0.10, rawDt * gameSpeed)

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
        bossAttackTowers(dt: dt)
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
        // during the empowered-boss endgame, when the player NEEDS resources
        // to charge the Trimurti, so the special endgame factories run 24/7
        // at 2.5× rate.
        let endgameOpen = sudarshanPhase == .empoweredBoss
        guard isWaveActive || endgameOpen else { return }
        let endgameBoost = endgameOpen ? 3.0 : 1.0
        for i in buildings.indices {
            // Vritra drought aura halts production entirely.
            if droughtBuildingIDs.contains(buildings[i].id) { continue }
            let mult = (race?.genMultiplier(for: buildings[i].kind.resource) ?? 1.0) * endgameBoost
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
    /// Baseline: iPhone-14 sized path (~1500px).
    var pathDifficultyScale: Double {
        max(1.0, Double(pathLength) / 1500.0)
    }

    private func spawnEnemy(kind: EnemyKind) {
        let (pt, dir) = pointAndDirection(at: 0)
        // Kali Yuga uses his hand-balanced HP / damage values verbatim — the
        // wave-multiplier (≈ 600× at W48) would otherwise put him in the
        // tens-of-millions of HP and the chakra could never kill him.
        let useScaling = (kind != .kaliYuga)
        let hpMult = useScaling ? Difficulty.hpMultiplier(wave: wave) * pathDifficultyScale : 1.0
        let scaledHP = kind.maxHP * hpMult
        let scaledTowerDmg = useScaling
            ? kind.towerDamage * Difficulty.bossDamageMultiplier(wave: wave)
            : kind.towerDamage
        var e = Enemy(
            kind: kind, hp: scaledHP, maxHP: scaledHP,
            distance: 0, position: pt, heading: dir
        )
        e.speedMultiplier = useScaling ? Difficulty.speedMultiplier(wave: wave) : 1.0
        e.towerDamageOverride = scaledTowerDmg
        enemies.append(e)
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
            let regen = enemies[i].kind.regenPerSec
            if regen > 0, enemies[i].hp > 0 {
                enemies[i].hp = min(enemies[i].maxHP, enemies[i].hp + regen * dt)
            }
            // Kali Yuga is path-gated: he stays put as long as any tower is
            // within his attack reach. Only advances after killing the tower.
            var effectiveSpeed = enemies[i].kind.speed * enemies[i].slowFactor * enemies[i].speedMultiplier
                                 * CGFloat(rageMultiplier(of: enemies[i]))
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
                let reach: CGFloat = 75
                let hasTowerToKill = towers.contains { t in
                    hypot(t.position.x - enemies[i].position.x,
                          t.position.y - enemies[i].position.y) < reach
                }
                if hasTowerToKill { effectiveSpeed = 0 }
            }
            enemies[i].distance += effectiveSpeed * CGFloat(dt)
            if enemies[i].distance >= pathLength {
                enemies[i].distance = pathLength
                // Empowered Kali Yuga doesn't despawn at path end — the
                // divert branch above will carry him on to the Sudarshan.
                if !(enemies[i].kind == .kaliYuga
                     && sudarshanPhase == .empoweredBoss) {
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
            // Raktabija blood-grip: towers under control don't fire.
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
                let p = Projectile(
                    position: towers[i].position,
                    heading: heading,
                    targetID: target.id,
                    damage: damage(of: towers[i]),
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
                    sourceKind: k
                )
                projectiles.append(p)
                towers[i].fireCooldown = 0
                // Cinematic muzzle flash at tower position
                fireFlashes.append(FireFlash(position: towers[i].position,
                                              color: k.color,
                                              damageType: k.damageType))
                SoundEngine.shared.playFire(for: k, now: now)
                HapticsEngine.shared.towerFire()
            }
        }
    }

    /// Age muzzle flashes; remove expired
    private func updateFireFlashes(dt: TimeInterval) {
        for i in fireFlashes.indices { fireFlashes[i].age += dt }
        fireFlashes.removeAll { $0.age >= FireFlash.lifetime }
    }

    private func updateBossAttackFlashes(dt: TimeInterval) {
        for i in bossAttackFlashes.indices { bossAttackFlashes[i].age += dt }
        bossAttackFlashes.removeAll { $0.age >= BossAttackFlash.lifetime }
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
    private func bossAttackTowers(dt: TimeInterval) {
        for i in enemies.indices where enemies[i].kind.attacksTowers {
            enemies[i].attackCooldown -= dt
            if enemies[i].attackCooldown > 0 { continue }
            let attackRadius: CGFloat = 70
            var nearestIdx: Int? = nil
            var nearestDist: CGFloat = attackRadius
            for (ti, t) in towers.enumerated() {
                let d = hypot(t.position.x - enemies[i].position.x,
                              t.position.y - enemies[i].position.y)
                if d < nearestDist {
                    nearestDist = d
                    nearestIdx = ti
                }
            }
            if let ti = nearestIdx {
                let dr = barrierReduction(at: towers[ti].position)
                let baseDmg = enemies[i].towerDamageOverride > 0
                    ? enemies[i].towerDamageOverride
                    : enemies[i].kind.towerDamage
                let dmg = baseDmg * (1.0 - dr) * rageMultiplier(of: enemies[i])
                towers[ti].hp -= dmg
                enemies[i].attackCooldown = enemies[i].kind.attackInterval
                bossAttackFlashes.append(BossAttackFlash(
                    from: enemies[i].position,
                    to: towers[ti].position,
                    color: enemies[i].kind.color
                ))
                // Putana siphons life from the tower she strikes.
                if enemies[i].kind == .putana {
                    let cap = enemies[i].maxHP
                    enemies[i].hp = min(cap, enemies[i].hp + dmg)
                    drainedTowerIDs.insert(towers[ti].id)
                }
            } else if enemies[i].kind == .kaliYuga,
                      sudarshanPhase == .empoweredBoss {
                // Last line — empowered Kali Yuga reaches the Sudarshan and
                // gnaws on the central relic itself.
                let d = hypot(sudarshanPosition.x - enemies[i].position.x,
                              sudarshanPosition.y - enemies[i].position.y)
                if d < 80 {
                    let baseDmg = enemies[i].towerDamageOverride > 0
                        ? enemies[i].towerDamageOverride
                        : enemies[i].kind.towerDamage
                    let dmg = baseDmg * rageMultiplier(of: enemies[i])
                    sudarshanHP = max(0, sudarshanHP - dmg)
                    enemies[i].attackCooldown = enemies[i].kind.attackInterval
                    bossAttackFlashes.append(BossAttackFlash(
                        from: enemies[i].position,
                        to: sudarshanPosition,
                        color: enemies[i].kind.color
                    ))
                    if sudarshanHP <= 0 && !isGameOver {
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
        for t in towers where t.shieldAuraLevel > 0 {
            let tierRange = Self.shieldAuraRangeTier[t.shieldAuraLevel]
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
            // Per-tower heal aura — tier 1/2/3 stats.
            for h in auraSources where h.id != towers[i].id {
                let tierRange = Self.healAuraRange[h.healAuraLevel]
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
        // --- Raktabija blood-grip: nearby unprotected towers get controlled.
        // Once taken, they stay taken for the rest of the wave (cleared in
        // checkWaveCompletion). Spreads to adjacent unprotected towers each tick.
        var newControlled = controlledTowerIDs
        let raktas = enemies.filter { $0.kind == .raktabija && $0.hp > 0 }
        let raktaReach: CGFloat = 70    // softened from 80 — gives time to set Rekha cover
        let bloodSpread: CGFloat = 55   // softened from 60
        for r in raktas {
            for t in towers where !newControlled.contains(t.id) && !protectedTowerIDs.contains(t.id) {
                let d = hypot(r.position.x - t.position.x, r.position.y - t.position.y)
                if d < raktaReach { newControlled.insert(t.id) }
            }
        }
        // Spread from already-controlled towers (their blood seeps further).
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
        guard enemy.kind == .mahishasura else { return 1.0 }
        return enemy.hp < enemy.maxHP * 0.5 ? 1.4 : 1.0
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
            if dist <= step {
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
        enemies[index].hp -= actualDamage

        // Floating damage number — caps the array so it never grows unbounded.
        if actualDamage >= 1 {
            damageNumbers.append(DamageNumber(
                value: Int(actualDamage.rounded()),
                position: enemies[index].position,
                color: projectile.color,
                isCrit: wasBossHit && bossMult > 1.0
            ))
            if damageNumbers.count > 50 {
                damageNumbers.removeFirst(damageNumbers.count - 50)
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

    private func cleanupEnemies() {
        var lifeLoss = 0
        var scoreGain = 0
        var pointGain = 0
        var drops = Resources()
        // Chola signature: +50% gold and Bazaar points per kill.
        let rewardMult = race?.killRewardMultiplier ?? 1.0
        for e in enemies where e.hp <= 0 {
            if e.distance >= pathLength {
                lifeLoss += 1
            } else {
                let goldReward = Int((Double(e.kind.reward) * rewardMult).rounded())
                drops.gold += goldReward
                scoreGain += goldReward
                let ptReward = Int((Double(e.kind.bazaarPointReward) * rewardMult).rounded())
                pointGain += ptReward
                // Bonus resource drop (resource bearers reward big)
                drops = drops + e.kind.resourceDrop
                // Kind-specific death sound; bosses also trigger a victory sloka.
                SoundEngine.shared.playEnemyDeath(kind: e.kind)
                if e.kind.isBoss {
                    HapticsEngine.shared.bossKilled()
                } else {
                    HapticsEngine.shared.enemyKilled()
                }
                // Kali Yuga falls — but Rahu may intervene.
                if e.kind == .kaliYuga {
                    if sudarshanPhase == .matured {
                        // First death → Rahu eclipse + revival.
                        sudarshanPhase = .rahuEclipse
                        rahuTimer = Self.rahuLifetime
                    } else if sudarshanPhase == .empoweredBoss {
                        // Second death → true victory.
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
        if scoreGain > 0 { score += scoreGain }
        if pointGain > 0 { points += pointGain }
        stock = stock + drops
        enemies.removeAll { $0.hp <= 0 }
    }

    private func checkWaveCompletion() {
        guard isWaveActive, spawnQueue.isEmpty, enemies.isEmpty else { return }
        isWaveActive = false
        // Stingy wave bonus
        let bonus = 12 + wave * 3
        stock.gold += bonus
        score += bonus
        // Active run buffs purchased mid-game
        if activeBazaarPerks.contains(.waveTribute)   { stock.gold += 120 }
        if activeBazaarPerks.contains(.waveVedaTithe) { stock.veda += 30 }
        // Per-run Bazaar points: 3 per wave, +3 every 5 waves, +10 every 10 waves.
        // Resets on game over with the rest of the run state.
        var wavePts = 3
        if wave % 5 == 0  { wavePts += 3 }
        if wave % 10 == 0 { wavePts += 10 }
        points += wavePts
        // Towers fully restored between waves
        for i in towers.indices {
            towers[i].hp = towers[i].maxHP
        }
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
    /// Lives restored when the Kalash is consumed.
    static let amritaKalashLifeGain = 40

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
        case .warVeda:          stock.veda += 75
        case .ironCache:        stock.metal += 100
        case .sageTech:         stock.tech += 60
        case .jyotishaBlessing: stock.jotisha += 80
        case .healersBoon:
            lives += 8
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
        lives = 18 + BazaarStore.shared.bonusStartingLives + (race?.bonusStartingLives ?? 0)
        maxLives = lives
        relicHitFlash = 0
        activeBazaarPerks.removeAll()
        points = 0
        score = 0
        wave = 0
        isWaveActive = false
        isGameOver = false
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

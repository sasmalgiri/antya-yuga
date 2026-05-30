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
    case sen
    case pal
    case maurya

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .raghuvansh: return "Raghuvansh"
        case .sen:        return "Sen"
        case .pal:        return "Pal"
        case .maurya:     return "Maurya"
        }
    }

    var dynasty: String {
        switch self {
        case .raghuvansh: return "Solar Dynasty"
        case .sen:        return "Sena of Bengal"
        case .pal:        return "Pala Empire"
        case .maurya:     return "Mauryan Empire"
        }
    }

    var description: String {
        switch self {
        case .raghuvansh: return "Solar warriors of Ayodhya, lineage of Lord Rama"
        case .sen:        return "Strategists of Bengal, masters of war science"
        case .pal:        return "Patrons of dharma, knowledge, and craft"
        case .maurya:     return "Imperial conquerors of Bharatvarsha"
        }
    }

    var trait: String {
        switch self {
        case .raghuvansh: return "+25% tower damage"
        case .sen:        return "+20% tower range"
        case .pal:        return "−10% gold cost on towers"
        case .maurya:     return "+25% tower fire rate"
        }
    }

    var bonusGen: String {
        switch self {
        case .raghuvansh: return "+30% Veda generation"
        case .sen:        return "+20% all resource generation"
        case .pal:        return "+40% Jotisha generation"
        case .maurya:     return "+40% Metal generation"
        }
    }

    var startingResources: Resources {
        switch self {
        case .raghuvansh: return Resources(gold: 200, metal: 20, tech: 0,  jotisha: 10, veda: 10)
        case .sen:        return Resources(gold: 190, metal: 15, tech: 25, jotisha: 10, veda: 0)
        case .pal:        return Resources(gold: 220, metal: 15, tech: 15, jotisha: 35, veda: 8)
        case .maurya:     return Resources(gold: 200, metal: 45, tech: 0,  jotisha: 10, veda: 0)
        }
    }

    var damageMultiplier: Double { self == .raghuvansh ? 1.25 : 1.0 }
    var rangeMultiplier: CGFloat { self == .sen ? 1.20 : 1.0 }
    var goldCostMultiplier: Double { self == .pal ? 0.90 : 1.0 }
    var fireRateMultiplier: Double { self == .maurya ? 1.25 : 1.0 }

    func genMultiplier(for kind: ResourceKind) -> Double {
        switch (self, kind) {
        case (.raghuvansh, .veda):    return 1.30
        case (.sen,        _):        return 1.20  // generalist scholar — every resource
        case (.pal,        .jotisha): return 1.40
        case (.maurya,     .metal):   return 1.40
        default: return 1.0
        }
    }

    var color: Color {
        switch self {
        case .raghuvansh: return .orange
        case .sen:        return .blue
        case .pal:        return Color(red: 0.78, green: 0.55, blue: 0.20)
        case .maurya:     return .green
        }
    }

    var symbol: String {
        switch self {
        case .raghuvansh: return "sun.max.fill"
        case .sen:        return "shield.fill"
        case .pal:        return "book.fill"
        case .maurya:     return "crown.fill"
        }
    }
}

// MARK: - Age

enum Age: Int, CaseIterable, Identifiable {
    case ancient = 0
    case middle  = 1
    case modern  = 2

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .ancient: return "Ancient Yug"
        case .middle:  return "Middle Yug"
        case .modern:  return "Modern Yug"
        }
    }

    var shortName: String {
        switch self {
        case .ancient: return "Ancient"
        case .middle:  return "Middle"
        case .modern:  return "Modern"
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
        case .mahishasura:    return 15
        case .ravana:         return 40
        case .mayavi:         return 3
        case .indrajit:       return 25
        case .lobhaYaksha:    return 4
        case .lohaAsura:      return 5
        case .yantraPishacha: return 4
        case .taraDevi:       return 5
        case .rishiAtma:      return 5
        }
    }

    var reward: Int {
        switch self {
        case .pishacha:    return 5
        case .rakshasa:    return 11
        case .daitya:      return 25
        case .asura:       return 42
        case .vetala:      return 30
        case .mahishasura: return 180
        case .ravana:      return 500
        case .mayavi:      return 40
        case .indrajit:    return 350
        case .lobhaYaksha:    return 55
        case .lohaAsura:      return 70
        case .yantraPishacha: return 50
        case .taraDevi:       return 65
        case .rishiAtma:      return 75
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
        }
    }

    var regenPerSec: Double { self == .vetala ? 10 : 0 }

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
        case .mahishasura, .ravana, .indrajit: return true
        default: return false
        }
    }

    var towerDamage: Double {
        switch self {
        case .mahishasura: return 35
        case .ravana:      return 80
        case .indrajit:    return 55
        default: return 0
        }
    }

    var attackInterval: TimeInterval {
        switch self {
        case .mahishasura: return 1.0
        case .ravana:      return 0.8
        case .indrajit:    return 0.7
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
    var score: Int = 0
    var wave: Int = 0
    var isWaveActive: Bool = false
    var isGameOver: Bool = false
    var newAgeBanner: Age? = nil
    private var lastSeenAge: Age = .ancient

    var towers: [Tower] = []
    var buildings: [Building] = []
    var enemies: [Enemy] = []
    var projectiles: [Projectile] = []
    var fireFlashes: [FireFlash] = []
    var slots: [BuildSlot] = []

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

    // MARK: - Race / setup

    func selectRace(_ race: Race) {
        self.race = race
        stock = race.startingResources
        lives = 18 + BazaarStore.shared.bonusStartingLives
        activeBazaarPerks.removeAll()
        points = 0
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
        SoundEngine.shared.playAgeUnlocked()
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
    }

    private static func compactPath(w: CGFloat, h: CGFloat) -> [CGPoint] {
        [
            CGPoint(x: -10,       y: h * 0.18),
            CGPoint(x: w * 0.42,  y: h * 0.18),
            CGPoint(x: w * 0.42,  y: h * 0.40),
            CGPoint(x: w * 0.86,  y: h * 0.40),
            CGPoint(x: w * 0.86,  y: h * 0.62),
            CGPoint(x: w * 0.16,  y: h * 0.62),
            CGPoint(x: w * 0.16,  y: h * 0.82),
            CGPoint(x: w + 10,    y: h * 0.82)
        ]
    }

    private static func largePath(w: CGFloat, h: CGFloat) -> [CGPoint] {
        // iPad: more zig-zags to fill space + more slot opportunities
        [
            CGPoint(x: -10,       y: h * 0.14),
            CGPoint(x: w * 0.30,  y: h * 0.14),
            CGPoint(x: w * 0.30,  y: h * 0.30),
            CGPoint(x: w * 0.70,  y: h * 0.30),
            CGPoint(x: w * 0.70,  y: h * 0.45),
            CGPoint(x: w * 0.20,  y: h * 0.45),
            CGPoint(x: w * 0.20,  y: h * 0.60),
            CGPoint(x: w * 0.85,  y: h * 0.60),
            CGPoint(x: w * 0.85,  y: h * 0.75),
            CGPoint(x: w * 0.15,  y: h * 0.75),
            CGPoint(x: w * 0.15,  y: h * 0.88),
            CGPoint(x: w + 10,    y: h * 0.88)
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

    func damage(of tower: Tower) -> Double {
        var d = tower.kind.baseDamage * (race?.damageMultiplier ?? 1.0)
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
        return tower.kind.baseFireInterval / raceMult
    }

    func range(of tower: Tower) -> CGFloat {
        var r = tower.kind.baseRange * (race?.rangeMultiplier ?? 1.0)
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
            // Mayavi now appears from W6 — sensory required earlier
            let p = 8 + n
            let r = 5 + (n - 4)
            let d = max(0, n - 5) * 2
            let m = max(0, n - 5)
            for _ in 0..<p { list.append((.pishacha, interval)) }
            for _ in 0..<r { list.append((.rakshasa, interval)) }
            for _ in 0..<d { list.append((.daitya, interval + 0.20)) }
            for _ in 0..<m { list.append((.mayavi, interval + 0.10)) }
            if n == 5 { list.append((.mahishasura, 1.4)) }
            if n == 6 { list.append((.mahishasura, 1.3)) }
            if n == 7 { list.append((.mahishasura, 1.2)); list.append((.daitya, 1.5)) }
            if n == 8 { list.append((.mahishasura, 1.1)); list.append((.mahishasura, 1.4)) }  // DOUBLE Mahisha at W8

        } else if n <= 12 {
            // Vetala (ice+water imm) + Mayavi (invisible) appear from W9+
            // Sensory + multi-damage becomes mandatory
            let p = 8 + n
            let r = 6 + (n - 8)
            let d = 3 + (n - 8)
            let v = max(0, n - 9)
            let m = max(0, n - 8) * 2   // invisible pressure
            for _ in 0..<p { list.append((.pishacha, interval)) }
            for _ in 0..<r { list.append((.rakshasa, interval)) }
            for _ in 0..<d { list.append((.daitya, interval + 0.15)) }
            for _ in 0..<v { list.append((.vetala, interval + 0.15)) }
            for _ in 0..<m { list.append((.mayavi, interval + 0.10)) }
            if n == 9  { list.append((.mahishasura, 1.3)) }
            if n == 10 {
                // First multi-boss wave: 2 Mahishasuras
                list.append((.mahishasura, 1.1))
                list.append((.mahishasura, 1.3))
            }
            if n == 11 { list.append((.mahishasura, 1.2)) }
            if n == 12 {
                // Mahisha + invisible Indrajit (forces sensory by now)
                list.append((.mahishasura, 1.0))
                list.append((.indrajit, 1.5))
            }

        } else if n <= 14 {
            // Asura (physical-immune) joins. Boss waves every wave.
            let p = 17 + n * 2
            let r = 13 + (n - 12)
            let d = 9 + (n - 12) * 2
            let v = 4 + (n - 12)
            let a = 2 + (n - 12) * 2
            let m = 6 + (n - 12) * 2
            for _ in 0..<p { list.append((.pishacha, interval)) }
            for _ in 0..<r { list.append((.rakshasa, interval)) }
            for _ in 0..<d { list.append((.daitya, interval)) }
            for _ in 0..<a { list.append((.asura, interval + 0.18)) }
            for _ in 0..<v { list.append((.vetala, interval + 0.12)) }
            for _ in 0..<m { list.append((.mayavi, interval + 0.10)) }
            // Mixed boss spawns
            if n == 13 { list.append((.mahishasura, 1.2)); list.append((.indrajit, 1.4)) }
            if n == 14 { list.append((.indrajit, 1.3)); list.append((.mahishasura, 1.2)) }

        } else if n <= 19 {
            // Bosses mixed into EVERY wave; Indrajit invisible boss recurring
            let p = 22 + n * 2
            let r = 16 + (n - 14)
            let d = 12 + (n - 14)
            let v = 6 + (n - 14)
            let a = 6 + (n - 14)
            let m = 7 + (n - 14) * 2
            for _ in 0..<p { list.append((.pishacha, interval)) }
            for _ in 0..<r { list.append((.rakshasa, interval)) }
            for _ in 0..<d { list.append((.daitya, interval)) }
            for _ in 0..<a { list.append((.asura, interval + 0.16)) }
            for _ in 0..<v { list.append((.vetala, interval + 0.12)) }
            for _ in 0..<m { list.append((.mayavi, interval + 0.10)) }
            // Mixed multi-boss waves (every wave from W15)
            switch n {
            case 15: list.append((.mahishasura, 1.0)); list.append((.indrajit, 1.5))
            case 16: list.append((.mahishasura, 1.0)); list.append((.mahishasura, 1.2)); list.append((.ravana, 1.6))
            case 17: list.append((.indrajit, 1.4)); list.append((.indrajit, 1.5))
            case 18: list.append((.mahishasura, 1.0)); list.append((.ravana, 1.4)); list.append((.indrajit, 1.6))
            case 19: list.append((.ravana, 1.2)); list.append((.mahishasura, 1.0)); list.append((.mahishasura, 1.2))
            default: break
            }

        } else {
            // EXTREME: every wave has 3+ bosses
            let p = 28 + n * 2
            let r = 20 + (n - 19)
            let d = 16 + (n - 19)
            let v = 9 + (n - 19)
            let a = 9 + (n - 19)
            let m = 10 + (n - 19) * 2
            for _ in 0..<p { list.append((.pishacha, interval)) }
            for _ in 0..<r { list.append((.rakshasa, interval)) }
            for _ in 0..<d { list.append((.daitya, interval)) }
            for _ in 0..<a { list.append((.asura, interval + 0.16)) }
            for _ in 0..<v { list.append((.vetala, interval + 0.12)) }
            for _ in 0..<m { list.append((.mayavi, interval + 0.10)) }
            // 3+ bosses per wave
            list.append((.mahishasura, 1.0))
            list.append((.mahishasura, 1.2))
            list.append((.ravana, 1.4))
            if n % 2 == 0 { list.append((.indrajit, 1.4)) }
            if n % 3 == 0 { list.append((.ravana, 1.2)) }
            if n >= 25 { list.append((.indrajit, 1.2)) }
            if n >= 30 {
                // Apocalyptic: 5+ bosses
                list.append((.mahishasura, 1.0))
                list.append((.ravana, 1.2))
            }
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

        // Resource bearers by tier
        let bearers: [EnemyKind] = {
            switch n {
            case 7:   return [.lobhaYaksha, .yantraPishacha]                // gold + tech
            case 14:  return [.lobhaYaksha, .lohaAsura, .taraDevi]          // gold + metal + jotisha
            case 21:  return [.lohaAsura, .taraDevi, .rishiAtma]            // metal + jotisha + veda
            case 28:  return [.lobhaYaksha, .lohaAsura, .yantraPishacha,
                              .taraDevi, .rishiAtma]                        // all five
            default:
                // Higher boon waves (35, 42, 49...) — all bearers, more of each
                return [.lobhaYaksha, .lobhaYaksha,
                        .lohaAsura, .lohaAsura,
                        .yantraPishacha, .yantraPishacha,
                        .taraDevi, .taraDevi,
                        .rishiAtma, .rishiAtma]
            }
        }()

        for b in bearers {
            list.append((b, 1.8))
        }

        return list
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
        towers.append(Tower(slotIndex: slotIndex, position: slot.position, path: path))
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

    func attachStone(towerID: UUID, kind: StoneKind) {
        guard let i = towers.firstIndex(where: { $0.id == towerID }) else { return }
        guard towers[i].stone == nil else { return }
        let cost = kind.cost(forLevel: 1)
        guard stock.canAfford(cost) else { return }
        stock = stock - cost
        towers[i].stone = Stone(kind: kind, level: 1)
        SoundEngine.shared.playBuildPlaced()
    }

    func canUpgradeStone(_ tower: Tower) -> Bool {
        guard let s = tower.stone, s.level < 3 else { return false }
        return stock.canAfford(s.kind.cost(forLevel: s.level + 1))
    }

    func upgradeStone(towerID: UUID) {
        guard let i = towers.firstIndex(where: { $0.id == towerID }),
              var s = towers[i].stone, s.level < 3 else { return }
        let cost = s.kind.cost(forLevel: s.level + 1)
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

    func canAffordBuilding(_ kind: BuildingKind) -> Bool {
        stock.canAfford(kind.cost)
    }

    func placeBuilding(at slotIndex: Int, kind: BuildingKind) {
        guard let slot = slots.first(where: { $0.index == slotIndex }),
              !isSlotOccupied(slotIndex) else { return }
        guard stock.canAfford(kind.cost) else { return }
        stock = stock - kind.cost
        buildings.append(Building(slotIndex: slotIndex, position: slot.position, kind: kind))
        selectedSlotIndex = nil
        SoundEngine.shared.playBuildPlaced()
    }

    func canUpgradeBuilding(_ b: Building) -> Bool {
        b.level < 3 && stock.canAfford(b.upgradeCost)
    }

    func upgradeBuilding(id: UUID) {
        guard let i = buildings.firstIndex(where: { $0.id == id }) else { return }
        guard canUpgradeBuilding(buildings[i]) else { return }
        stock = stock - buildings[i].upgradeCost
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

    func update(now: TimeInterval) {
        guard !isGameOver, race != nil else { return }
        // While paused (e.g. Bazaar open), drop the clock so resume starts from dt=0.
        if isPaused {
            lastUpdate = nil
            return
        }

        let dt: TimeInterval
        if let last = lastUpdate {
            dt = min(0.05, now - last)
        } else {
            dt = 0
        }
        lastUpdate = now
        guard dt > 0 else { return }

        if bannerTimer > 0 {
            bannerTimer -= dt
            if bannerTimer <= 0 { newAgeBanner = nil }
        }

        generateResources(dt: dt)
        spawnTick(dt: dt)
        updateEnemies(dt: dt)
        updateFireFlashes(dt: dt)
        runDetection()
        runHealers(dt: dt)
        bossAttackTowers(dt: dt)
        fireTowers(dt: dt, now: now)
        moveProjectiles(dt: dt)
        cleanupEnemies()
        cleanupTowers()
        checkWaveCompletion()
        checkGameOver()
    }

    private func generateResources(dt: TimeInterval) {
        // Buildings only produce during active waves (work-time only)
        guard isWaveActive else { return }
        for i in buildings.indices {
            let mult = race?.genMultiplier(for: buildings[i].kind.resource) ?? 1.0
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
        let hpMult = Difficulty.hpMultiplier(wave: wave) * pathDifficultyScale
        let scaledHP = kind.maxHP * hpMult
        let scaledTowerDmg = kind.towerDamage * Difficulty.bossDamageMultiplier(wave: wave)
        var e = Enemy(
            kind: kind, hp: scaledHP, maxHP: scaledHP,
            distance: 0, position: pt, heading: dir
        )
        e.speedMultiplier = Difficulty.speedMultiplier(wave: wave)
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
                continue
            }
            let regen = enemies[i].kind.regenPerSec
            if regen > 0, enemies[i].hp > 0 {
                enemies[i].hp = min(enemies[i].maxHP, enemies[i].hp + regen * dt)
            }
            let speed = enemies[i].kind.speed * enemies[i].slowFactor * enemies[i].speedMultiplier
            enemies[i].distance += speed * CGFloat(dt)
            if enemies[i].distance >= pathLength {
                enemies[i].distance = pathLength
                enemies[i].hp = 0
            }
            let (pt, dir) = pointAndDirection(at: enemies[i].distance)
            enemies[i].position = pt
            enemies[i].heading = dir
        }
    }

    private func fireTowers(dt: TimeInterval, now: TimeInterval) {
        for i in towers.indices {
            guard towers[i].path.isOffensive else { continue }
            towers[i].fireCooldown += dt
            let interval = fireInterval(of: towers[i])
            guard towers[i].fireCooldown >= interval else { continue }
            if let target = pickTarget(for: towers[i]) {
                let k = towers[i].kind
                let dx = target.position.x - towers[i].position.x
                let dy = target.position.y - towers[i].position.y
                let len = max(0.0001, hypot(dx, dy))
                let heading = CGPoint(x: dx / len, y: dy / len)
                let p = Projectile(
                    position: towers[i].position,
                    heading: heading,
                    targetID: target.id,
                    damage: damage(of: towers[i]),
                    speed: k.projectileSpeed,
                    splashRadius: k.splashRadius,
                    color: k.color,
                    burnDPS: k.burnDPS,
                    burnDuration: k.burnDuration,
                    slowFactor: k.slowFactor,
                    slowDuration: k.slowDuration,
                    freezeDuration: k.freezeDuration,
                    chainTargets: k.chainTargets,
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
            }
        }
    }

    /// Age muzzle flashes; remove expired
    private func updateFireFlashes(dt: TimeInterval) {
        for i in fireFlashes.indices { fireFlashes[i].age += dt }
        fireFlashes.removeAll { $0.age >= FireFlash.lifetime }
    }

    private func pickTarget(for tower: Tower) -> Enemy? {
        var best: Enemy? = nil
        var bestDistance: CGFloat = -1
        let r = range(of: tower)
        for e in enemies where e.hp > 0 {
            // Invisible enemies must be detected to be targetable
            if e.kind.isInvisible && !e.detected { continue }
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
                let dmg = baseDmg * (1.0 - dr)
                towers[ti].hp -= dmg
                enemies[i].attackCooldown = enemies[i].kind.attackInterval
            }
        }
    }

    // Highest damage reduction available from any Rekha tower covering this position
    private func barrierReduction(at point: CGPoint) -> Double {
        var best = 0.0
        for t in towers where t.path == .rekha {
            let r = range(of: t)
            let d = hypot(t.position.x - point.x, t.position.y - point.y)
            if d <= r {
                best = max(best, t.kind.damageReduction)
            }
        }
        return best
    }

    // Healers regenerate HP of any tower in range (during wave)
    private func runHealers(dt: TimeInterval) {
        guard isWaveActive else { return }
        let healers = towers.filter { $0.path == .sanjivani }
        guard !healers.isEmpty else { return }
        for i in towers.indices {
            guard towers[i].hp < towers[i].maxHP else { continue }
            var bestRate = 0.0
            for h in healers {
                let r = range(of: h)
                let d = hypot(h.position.x - towers[i].position.x,
                              h.position.y - towers[i].position.y)
                if d <= r {
                    bestRate = max(bestRate, h.kind.healPerSec)
                }
            }
            if bestRate > 0 {
                towers[i].hp = min(towers[i].maxHP, towers[i].hp + bestRate * dt)
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
        let actualDamage = immune ? 0 : damage
        enemies[index].hp -= actualDamage

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
                enemies[index].freezeRemaining = max(enemies[index].freezeRemaining, projectile.freezeDuration)
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
        for e in enemies where e.hp <= 0 {
            if e.distance >= pathLength {
                lifeLoss += 1
            } else {
                drops.gold += e.kind.reward
                scoreGain += e.kind.reward
                pointGain += e.kind.bazaarPointReward
                // Bonus resource drop (resource bearers reward big)
                drops = drops + e.kind.resourceDrop
            }
        }
        if lifeLoss > 0 { lives -= lifeLoss }
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
        if activeBazaarPerks.contains(.waveTribute)   { stock.gold += 30 }
        if activeBazaarPerks.contains(.waveVedaTithe) { stock.veda += 8 }
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
    }

    private func checkGameOver() {
        if lives <= 0 {
            lives = 0
            if !isGameOver {
                isGameOver = true
                SoundEngine.shared.playGameOver()
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
        case .healersBoon:      lives += 8
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
        lives = 18 + BazaarStore.shared.bonusStartingLives
        activeBazaarPerks.removeAll()
        points = 0
        score = 0
        wave = 0
        isWaveActive = false
        isGameOver = false
        newAgeBanner = nil
        lastSeenAge = .ancient
        unlockedAge = .ancient
        towers.removeAll()
        buildings.removeAll()
        enemies.removeAll()
        projectiles.removeAll()
        fireFlashes.removeAll()
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

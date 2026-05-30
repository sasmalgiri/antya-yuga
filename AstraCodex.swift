//
//  AstraCodex.swift
//  towerlogicstrategicgame
//
//  Sanskrit lore data + the cinematic codex overlay view that shows
//  AAA artwork for each astra. When a Player long-presses or taps the
//  info button on a build menu card, this overlay slides in showing
//  the full painted card (if asset exists) or a vector fallback.
//

import SwiftUI

// MARK: - Lore per astra

extension TowerKind {
    /// Sanskrit name (Devanagari) for the cinematic header
    var sanskritTitle: String {
        switch self {
        case .dart:              return "बाण"
        case .aindrastra:        return "ऐन्द्रास्त्र"
        case .sudarshanaChakra:  return "सुदर्शन चक्र"
        case .agneyastra:        return "आग्नेयास्त्र"
        case .suryastra:         return "सूर्यास्त्र"
        case .brahmashirsha:     return "ब्रह्मशीर्ष"
        case .varunastra:        return "वरुणास्त्र"
        case .nagaPasha:         return "नाग पाश"
        case .garudastra:        return "गरुड़ास्त्र"
        case .sheetastra:        return "शीतास्त्र"
        case .twashtar:          return "त्वष्टास्त्र"
        case .mohiniAstra:       return "मोहिनी अस्त्र"
        case .trishul:           return "त्रिशूल"
        case .vajrastra:         return "वज्रास्त्र"
        case .pashupatastra:     return "पाशुपतास्त्र"
        case .bala:              return "बल"
        case .atibala:           return "अतिबल"
        case .divyaDrishti:      return "दिव्य दृष्टि"
        case .aushadhi:          return "औषधि"
        case .sanjivaniBooti:    return "संजीवनी बूटी"
        case .amritKalash:       return "अमृत कलश"
        case .surakshaRekha:     return "सुरक्षा रेखा"
        case .lakshmanRekha:     return "लक्ष्मण रेखा"
        case .vajraKavach:       return "वज्र कवच"
        }
    }

    var subtitle: String {
        switch self {
        case .dart:              return "The Simple Arrow"
        case .aindrastra:        return "Indra's Lightning Bow"
        case .sudarshanaChakra:  return "Vishnu's Eternal Disc"
        case .agneyastra:        return "The Fire Weapon"
        case .suryastra:         return "The Weapon of the Sun"
        case .brahmashirsha:     return "The Whirlwind Weapon"
        case .varunastra:        return "Controller of Cosmic Waters"
        case .nagaPasha:         return "The Serpent Noose"
        case .garudastra:        return "The Divine Weapon of Lord Vishnu"
        case .sheetastra:        return "The Ice Weapon"
        case .twashtar:          return "Divine Craftsman's Weapon"
        case .mohiniAstra:       return "The Enchanting Astra"
        case .trishul:           return "Shiva's Trident"
        case .vajrastra:         return "The Thunder Weapon"
        case .pashupatastra:     return "The Ultimate Divine Weapon"
        case .bala:              return "Power of Sight"
        case .atibala:           return "Greater Vision"
        case .divyaDrishti:      return "Cosmic Sight"
        case .aushadhi:          return "The Healing Herb"
        case .sanjivaniBooti:    return "Herb of Resurrection"
        case .amritKalash:       return "Pot of Immortality Nectar"
        case .surakshaRekha:     return "Protective Boundary"
        case .lakshmanRekha:     return "Lakshman's Sacred Line"
        case .vajraKavach:       return "Diamond Armor"
        }
    }

    var elementName: String {
        switch damageType {
        case .physical: return "Physical (Bhautik)"
        case .fire:     return "Fire (Agni)"
        case .water:    return "Water (Jala)"
        case .ice:      return "Ice (Sheet)"
        case .divine:   return "Divine (Daivik)"
        }
    }

    var bestowedBy: String {
        switch self {
        case .dart, .aindrastra, .sudarshanaChakra: return "Indra / Vishnu"
        case .agneyastra, .suryastra, .brahmashirsha: return "Agni / Surya / Brahma"
        case .varunastra, .nagaPasha, .garudastra: return "Varuna / Nagas / Vishnu"
        case .sheetastra, .twashtar, .mohiniAstra: return "Sheet / Tvashtr / Vishnu"
        case .trishul, .vajrastra, .pashupatastra: return "Shiva / Indra / Shiva"
        case .bala, .atibala, .divyaDrishti: return "Vishvamitra / Vyasa"
        case .aushadhi, .sanjivaniBooti, .amritKalash: return "Dhanvantari / Hanuman"
        case .surakshaRekha, .lakshmanRekha, .vajraKavach: return "Lakshman / Indra"
        }
    }

    var loreDescription: String {
        switch self {
        case .dart:              return "A simple but swift arrow. The fundamental weapon of every warrior."
        case .aindrastra:        return "Indra's lightning-bow that chains arcs of thunder between foes."
        case .sudarshanaChakra:  return "The eternal spinning disc of Vishnu that returns to its master."
        case .agneyastra:        return "Summons Agni, the god of fire. Engulfs enemies in scorching flames."
        case .suryastra:         return "The radiant sun-arrow. Burns with the brilliance of a thousand suns."
        case .brahmashirsha:     return "A divine weapon of Lord Shiva. Creates a destructive whirlwind that obliterates all in its path."
        case .varunastra:        return "Bestowed by Lord Varuna. Capable of drenching, binding, or drowning the enemy. Extinguishes fire, nullifies heat weapons."
        case .nagaPasha:         return "A noose of cobras that binds and slows. Their venom drains the foe."
        case .garudastra:        return "Lord Vishnu's mount-weapon. The divine eagle Garuda strikes with talons of gold."
        case .sheetastra:        return "Conjures eternal frost. Freezes enemies solid for moments."
        case .twashtar:          return "Forged by Tvashtr the divine craftsman. Creates illusions and confusion in foes."
        case .mohiniAstra:       return "The enchanting form of Vishnu. Mesmerizes all in its aura into stillness."
        case .trishul:           return "Shiva's three-pronged trident. Represents creation, preservation, destruction."
        case .vajrastra:         return "The weapon of Indra's power. Forged from the essence of the Vajra, it strikes with unbreakable force and destroys evil without fail."
        case .pashupatastra:     return "Shiva's ultimate weapon — wielded by Krishna in the Mahabharata. The most powerful astra known."
        case .bala:              return "The power of sight. Reveals what is hidden to the naked eye."
        case .atibala:           return "Greater sight. Pierces deeper illusions and detects further enemies."
        case .divyaDrishti:      return "Cosmic vision gifted to Sanjaya by Vyasa. Sees all things in all places."
        case .aushadhi:          return "Sacred herbs of healing. Restores vitality to allies."
        case .sanjivaniBooti:    return "The herb of resurrection that Hanuman brought from the Himalayas."
        case .amritKalash:       return "The pot of immortal nectar churned from the cosmic ocean. Brings life eternal."
        case .surakshaRekha:     return "A protective boundary. Wards off harm from those within."
        case .lakshmanRekha:     return "The sacred line drawn by Lakshman that no enemy may cross unharmed."
        case .vajraKavach:       return "Diamond armor forged from Indra's vajra. Impenetrable to all weapons."
        }
    }

    var chant: String {
        switch self {
        case .dart:              return "ॐ बाणाय नमः"
        case .aindrastra:        return "ॐ ऐन्द्राय नमः"
        case .sudarshanaChakra:  return "ॐ सुदर्शनाय नमः"
        case .agneyastra:        return "ॐ अग्नये नमः"
        case .suryastra:         return "ॐ सूर्याय नमः"
        case .brahmashirsha:     return "ॐ ब्रह्मणे नमः"
        case .varunastra:        return "ॐ वरुणाय नमः"
        case .nagaPasha:         return "ॐ नागाय नमः"
        case .garudastra:        return "ॐ गरुडाय नमः"
        case .sheetastra:        return "ॐ शीताय नमः"
        case .twashtar:          return "ॐ त्वष्ट्रे नमः"
        case .mohiniAstra:       return "ॐ मोहिन्यै नमः"
        case .trishul:           return "ॐ त्रिशूलाय नमः"
        case .vajrastra:         return "ॐ वज्राय नमः"
        case .pashupatastra:     return "ॐ पशुपतये नमः"
        case .bala:              return "ॐ बलाय नमः"
        case .atibala:           return "ॐ अतिबलाय नमः"
        case .divyaDrishti:      return "ॐ दिव्यदृष्ट्यै नमः"
        case .aushadhi:          return "ॐ औषधये नमः"
        case .sanjivaniBooti:    return "ॐ संजीवन्यै नमः"
        case .amritKalash:       return "ॐ अमृताय नमः"
        case .surakshaRekha:     return "ॐ रक्षायै नमः"
        case .lakshmanRekha:     return "ॐ लक्ष्मणाय नमः"
        case .vajraKavach:       return "ॐ वज्रकवचाय नमः"
        }
    }
}

// MARK: - Cinematic Codex Card (AAA artwork showcase)

struct AstraCodexCard: View {
    let kind: TowerKind
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 12) {
                // Header
                VStack(spacing: 2) {
                    Text(kind.sanskritTitle)
                        .font(.system(size: 26, weight: .heavy, design: .serif))
                        .foregroundColor(.yellow)
                        .shadow(color: .orange, radius: 4)
                    Text(kind.displayName.uppercased())
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(2)
                    Text(kind.subtitle)
                        .font(.system(size: 11, design: .serif))
                        .foregroundColor(.white.opacity(0.75))
                        .italic()
                }
                .padding(.top, 10)

                // Hero artwork
                ZStack {
                    if AssetCatalog.has(AssetName.astraCard(kind)) {
                        Image(AssetName.astraCard(kind))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        // Vector fallback — show the in-game arrow at 5×
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(LinearGradient(colors: [
                                    kind.color.opacity(0.3),
                                    Color.black
                                ], startPoint: .topLeading, endPoint: .bottomTrailing))
                            // Decorative glow rings
                            ForEach(0..<3, id: \.self) { i in
                                Circle()
                                    .stroke(kind.color.opacity(0.3 - Double(i) * 0.08),
                                            lineWidth: 1.5)
                                    .frame(width: 140 + CGFloat(i) * 30,
                                           height: 140 + CGFloat(i) * 30)
                            }
                            AstraTowerArt(tower: Tower(slotIndex: 0,
                                                       position: .zero,
                                                       path: kind.path))
                                .scaleEffect(3.5)
                                .shadow(color: kind.color, radius: 12)
                        }
                        .overlay(
                            Text("Drop  astra_card_\(kind.rawValue)  into Assets.xcassets\nto see your cinematic image here")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.45))
                                .multilineTextAlignment(.center)
                                .padding(8),
                            alignment: .bottom
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(kind.color.opacity(0.8), lineWidth: 1.5)
                )
                .shadow(color: kind.color.opacity(0.5), radius: 8)

                // Lore stats (5-column grid like reference image)
                HStack(alignment: .top, spacing: 8) {
                    statCol(icon: "atom",
                            title: "ELEMENT",
                            value: kind.elementName)
                    statCol(icon: "burst.fill",
                            title: "POWER",
                            value: kind.tagline)
                    statCol(icon: "person.fill",
                            title: "BESTOWED",
                            value: kind.bestowedBy)
                    statCol(icon: "shield.fill",
                            title: "TIER",
                            value: "T\(kind.tier)")
                }
                .padding(.horizontal, 12)

                // Description
                Text(kind.loreDescription)
                    .font(.system(size: 11, design: .serif))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 16)

                // Chant
                VStack(spacing: 2) {
                    Text("CHANT (BIJA MANTRA)")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundColor(.yellow.opacity(0.8))
                        .tracking(2)
                    Text(kind.chant)
                        .font(.system(size: 14, design: .serif))
                        .foregroundColor(.white)
                }
                .padding(.top, 4)

                Button(action: onDismiss) {
                    Text("Close")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 26)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(kind.color.opacity(0.7)))
                        .overlay(Capsule().stroke(kind.color, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: 520)
        }
    }

    private func statCol(icon: String, title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(kind.color)
            Text(title)
                .font(.system(size: 8, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .tracking(1)
            Text(value)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }
}

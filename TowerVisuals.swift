//
//  TowerVisuals.swift
//  towerlogicstrategicgame
//
//  Unified staff-and-head design: every tower is a vertical wooden
//  staff with a red grip wrap and a SMALL astra-specific element at
//  the top. Like a trishul: staff + 3-prong head. Each kind has its
//  own head silhouette but the structural pattern is consistent.
//

import SwiftUI

// MARK: - Dispatcher

struct AstraTowerArt: View {
    let tower: Tower

    // Disc diameter; weapon fits entirely inside
    private let diameter: CGFloat = 72

    // Continuous animation for T3 cinematics (slow ring rotation + halo pulse).
    @State private var t3Angle: Double = 0
    @State private var t3Pulse: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let isT3 = tower.tier >= 3
        ZStack {
            if isT3 { t3OuterHalo }
            discContent
            if isT3 { t3OrbitingParticles }
        }
        .onAppear {
            // Reduce Motion users get a static T3 disc — no rotation or pulse.
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                t3Angle = 360
            }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                t3Pulse = 1
            }
        }
    }

    // MARK: - T3 cinematic flourishes (drawn OUTSIDE the disc clip)

    private var t3OuterHalo: some View {
        ZStack {
            // Soft halo bloom extending beyond the disc.
            Circle()
                .fill(RadialGradient(colors: [
                    tower.kind.color.opacity(0.55 + 0.25 * t3Pulse),
                    tower.kind.color.opacity(0.18),
                    .clear
                ], center: .center, startRadius: diameter * 0.45, endRadius: diameter * 0.78))
                .frame(width: diameter * 1.6, height: diameter * 1.6)
                .blendMode(.plusLighter)

            // Rotating dashed gold ring just outside the disc.
            Circle()
                .stroke(LinearGradient(colors: [Color.yellow, tower.kind.color, Color.yellow],
                                       startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 1.1, dash: [4, 5]))
                .frame(width: diameter * 1.10, height: diameter * 1.10)
                .rotationEffect(.degrees(t3Angle))
                .shadow(color: tower.kind.color.opacity(0.85), radius: 4)
        }
    }

    private var t3OrbitingParticles: some View {
        ForEach(0..<8, id: \.self) { i in
            let baseAngle = Double(i) * 45.0
            Circle()
                .fill(Color.white)
                .frame(width: 2.6, height: 2.6)
                .shadow(color: tower.kind.color, radius: 4)
                .offset(x: cos((baseAngle + t3Angle) * .pi / 180) * diameter * 0.58,
                        y: sin((baseAngle + t3Angle) * .pi / 180) * diameter * 0.58)
        }
    }

    private var discContent: some View {
        ZStack {
            // === YANTRA BACKGROUND ===
            // Dark filled disc with astra tint
            Circle()
                .fill(RadialGradient(colors: [
                    tower.kind.color.opacity(0.35),
                    Color(red: 0.08, green: 0.05, blue: 0.18).opacity(0.95),
                    Color.black.opacity(0.95)
                ], center: .center, startRadius: 4, endRadius: diameter * 0.5))
                .frame(width: diameter, height: diameter)

            // 8-pointed star backdrop
            ForEach(0..<8, id: \.self) { i in
                Path { p in
                    p.move(to: CGPoint(x: 0, y: -diameter * 0.46))
                    p.addLine(to: CGPoint(x: 2, y: -diameter * 0.18))
                    p.addLine(to: CGPoint(x: -2, y: -diameter * 0.18))
                    p.closeSubpath()
                }
                .fill(tower.kind.color.opacity(0.18))
                .rotationEffect(.degrees(Double(i) * 45))
            }

            // Concentric magic rings
            Circle()
                .stroke(tower.kind.color.opacity(0.45),
                        style: StrokeStyle(lineWidth: 0.8, dash: [3, 2]))
                .frame(width: diameter * 0.78, height: diameter * 0.78)
            Circle()
                .stroke(Color.yellow.opacity(0.35), lineWidth: 0.6)
                .frame(width: diameter * 0.58, height: diameter * 0.58)

            // Cardinal rune marks
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(tower.kind.color)
                    .frame(width: 3, height: 3)
                    .shadow(color: tower.kind.color, radius: 2)
                    .offset(x: cos(Double(i) * .pi / 2) * diameter * 0.39,
                            y: sin(Double(i) * .pi / 2) * diameter * 0.39)
            }
            // Diagonal accent dots
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(Color.yellow.opacity(0.6))
                    .frame(width: 1.8, height: 1.8)
                    .offset(x: cos(Double(i) * .pi / 2 + .pi / 4) * diameter * 0.39,
                            y: sin(Double(i) * .pi / 2 + .pi / 4) * diameter * 0.39)
            }

            // Outer gold border ring (thick, glowing)
            Circle()
                .stroke(LinearGradient(colors: [
                    Color.yellow,
                    Color(red: 0.95, green: 0.55, blue: 0.10),
                    tower.kind.color,
                    Color.yellow
                ], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 2)
                .frame(width: diameter, height: diameter)
                .shadow(color: tower.kind.color.opacity(0.7), radius: 4)
            // Inner thin gold border
            Circle()
                .stroke(Color.yellow.opacity(0.7), lineWidth: 0.6)
                .frame(width: diameter - 6, height: diameter - 6)

            // Halo glow behind weapon
            Circle()
                .fill(RadialGradient(colors: [
                    tower.kind.color.opacity(0.65),
                    tower.kind.color.opacity(0.15),
                    .clear
                ], center: .center, startRadius: 2, endRadius: diameter * 0.32))
                .frame(width: diameter * 0.7, height: diameter * 0.7)
                .blendMode(.plusLighter)

            // === WEAPON — head pulled into the middle so nothing exits the disc ===
            CenteredWeapon(tower: tower, diameter: diameter)

            // Tier indicators kept INSIDE the disc (no outer ornaments)
            if tower.tier >= 2 {
                // Tier 2: small gold dots ON the gold border (touching, not outside)
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 3, height: 3)
                        .shadow(color: .yellow, radius: 2)
                        .offset(x: cos(Double(i) * .pi / 2 + .pi / 4) * (diameter * 0.50),
                                y: sin(Double(i) * .pi / 2 + .pi / 4) * (diameter * 0.50))
                }
            }
            if tower.tier >= 3 {
                // Tier 3: inner ring of white sparkles INSIDE the disc
                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .fill(Color.white)
                        .frame(width: 2, height: 2)
                        .shadow(color: tower.kind.color, radius: 2)
                        .offset(x: cos(Double(i) * .pi / 3) * (diameter * 0.44),
                                y: sin(Double(i) * .pi / 3) * (diameter * 0.44))
                }
            }
        }
        // Frame matches disc exactly — nothing rendered outside this layer
        .frame(width: diameter, height: diameter)
        .clipShape(Circle())
    }
}

// MARK: - Weapon centered inside the yantra disc

/// The full weapon (staff + head + ornaments) drawn vertically centered
/// inside the disc so it fills the diameter top-to-bottom.
struct CenteredWeapon: View {
    let tower: Tower
    let diameter: CGFloat

    // === LAYOUT — HEAD CENTERED + STAFF BELOW ===
    private var headCenterY: CGFloat { diameter * 0.10 }
    private var headScale: CGFloat   { 2.2 }
    private var capY: CGFloat { diameter * 0.27 }
    private var staffCenterY: CGFloat { diameter * 0.34 }
    private var staffBottomY: CGFloat { diameter * 0.43 }

    var body: some View {
        ZStack {
            // Short wooden staff (lower portion)
            Rectangle()
                .fill(LinearGradient(colors: [Color(red: 0.65, green: 0.45, blue: 0.22),
                                              Color(red: 0.32, green: 0.18, blue: 0.08)],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(width: 4, height: diameter * 0.22)
                .offset(y: staffCenterY)
                .shadow(color: .black.opacity(0.4), radius: 1)
            // Wood-grain highlight
            Rectangle()
                .fill(Color(red: 0.85, green: 0.65, blue: 0.35).opacity(0.5))
                .frame(width: 0.8, height: diameter * 0.20)
                .offset(x: -1, y: staffCenterY)

            // Red grip wrap
            Rectangle()
                .fill(LinearGradient(colors: [Color.red, Color(red: 0.55, green: 0.0, blue: 0.0)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 7, height: 7)
                .offset(y: staffCenterY)
            // Grip diagonal stripes
            ForEach(0..<3, id: \.self) { i in
                Rectangle()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: 7, height: 0.5)
                    .offset(y: staffCenterY - 2 + CGFloat(i) * 2)
            }
            // Gold rings bracketing the grip
            Capsule().fill(Color.yellow)
                .frame(width: 8, height: 1.5)
                .offset(y: staffCenterY - 4.5)
            Capsule().fill(Color.yellow)
                .frame(width: 8, height: 1.5)
                .offset(y: staffCenterY + 4.5)

            // Bottom pommel
            Circle()
                .fill(LinearGradient(colors: [.yellow, .orange,
                                              Color(red: 0.5, green: 0.3, blue: 0.0)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 5, height: 5)
                .shadow(color: .yellow, radius: 2)
                .offset(y: staffBottomY)

            // Gold cap between head and staff
            Capsule()
                .fill(LinearGradient(colors: [.white, .yellow, .orange,
                                              Color(red: 0.6, green: 0.35, blue: 0.0)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 13, height: 3.5)
                .shadow(color: .yellow, radius: 2)
                .offset(y: capY)
            // Flanking gold beads
            HStack(spacing: 16) {
                Circle().fill(Color.yellow).frame(width: 2.5, height: 2.5)
                    .shadow(color: .yellow, radius: 1.5)
                Circle().fill(Color.yellow).frame(width: 2.5, height: 2.5)
                    .shadow(color: .yellow, radius: 1.5)
            }
            .offset(y: capY)

            // Head halo behind the centered head
            Circle()
                .fill(RadialGradient(colors: [tower.kind.color.opacity(0.8),
                                              tower.kind.color.opacity(0.3),
                                              .clear],
                                     center: .center, startRadius: 2, endRadius: 22))
                .frame(width: 44, height: 44)
                .offset(y: headCenterY - 4)
                .blendMode(.plusLighter)

            // === ASTRA HEAD — VISUALLY CENTERED IN THE DISC ===
            AstraHeadView(tower: tower)
                .scaleEffect(headScale)
                .offset(y: headCenterY)
                .shadow(color: tower.kind.color, radius: 5)
        }
    }
}

// MARK: - Head dispatcher

struct AstraHeadView: View {
    let tower: Tower

    @ViewBuilder
    var body: some View {
        switch tower.kind {
        case .dart:              DartHead()
        case .aindrastra:        AindraHead()
        case .sudarshanaChakra:  SudarshanaHead()
        case .agneyastra:        FlameHead(small: false)
        case .suryastra:         SunDiscHead()
        case .brahmashirsha:     SkullHead()
        case .varunastra:        DropletHead()
        case .nagaPasha:         CobraHead()
        case .garudastra:        EagleHead()
        case .sheetastra:        CrystalHead()
        case .twashtar:          TripleCrystalHead()
        case .mohiniAstra:       VortexHead()
        case .trishul:           TridentHead()
        case .vajrastra:         VajraHeadShape()
        case .pashupatastra:     DivineEyeHead()
        case .bala:              EyeHead()
        case .atibala:           DualEyeHead()
        case .divyaDrishti:      CosmicEyeHead()
        case .aushadhi:          LeafHead(color: .green)
        case .sanjivaniBooti:    LeafHead(color: Color(red: 0.3, green: 0.95, blue: 0.5), glow: true)
        case .amritKalash:       KalashHead()
        case .surakshaRekha:     ShieldHead(color: Color(red: 0.95, green: 0.55, blue: 0.85))
        case .lakshmanRekha:     HexEmblemHead()
        case .vajraKavach:       DiamondHead()
        }
    }
}

// MARK: - (Legacy) Shared staff with kind-specific head
// Kept for reference; AstraTowerArt now uses CenteredWeapon instead.

private struct StaffWithHead_Legacy: View {
    let tower: Tower

    var body: some View {
        ZStack {
            // Wooden staff (vertical, 3.5 wide, 26 tall — slightly thicker for balance)
            Rectangle()
                .fill(LinearGradient(colors: [Color(red: 0.62, green: 0.42, blue: 0.20),
                                              Color(red: 0.32, green: 0.18, blue: 0.08)],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(width: 3.5, height: 26)
                .shadow(color: .black.opacity(0.4), radius: 0.8)
                .offset(y: 10)
            // Staff wood-grain accent (subtle vertical highlight line)
            Rectangle()
                .fill(Color(red: 0.85, green: 0.65, blue: 0.35).opacity(0.4))
                .frame(width: 0.6, height: 24)
                .offset(x: -0.8, y: 10)
            // Decorative gold bands along staff (3 small ones)
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(LinearGradient(colors: [Color(red: 0.95, green: 0.78, blue: 0.20),
                                                  Color(red: 0.60, green: 0.40, blue: 0.0)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 5, height: 1.3)
                    .offset(y: 4 + CGFloat(i) * 6)
            }
            // Red grip wrap (middle of staff)
            Rectangle()
                .fill(LinearGradient(colors: [Color.red, Color(red: 0.55, green: 0.0, blue: 0.0)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 6, height: 7)
                .offset(y: 12)
            // Grip wrap detail (diagonal lines)
            ForEach(0..<3, id: \.self) { i in
                Rectangle()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: 6, height: 0.5)
                    .offset(y: 10 + CGFloat(i) * 2)
            }
            // Gold cap where head meets staff (bigger, decorated)
            Capsule()
                .fill(LinearGradient(colors: [.yellow, .orange,
                                              Color(red: 0.7, green: 0.4, blue: 0.0)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 9, height: 3)
                .shadow(color: .yellow, radius: 2)
                .offset(y: -2)
            // Gold pommel (small bead at top of cap)
            Circle()
                .fill(LinearGradient(colors: [.white, .yellow, .orange],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 3, height: 3)
                .shadow(color: .yellow, radius: 2)
                .offset(y: -4)
            // Head glow ring (behind head, astra-colored)
            Circle()
                .fill(RadialGradient(colors: [tower.kind.color.opacity(0.6), .clear],
                                     center: .center, startRadius: 2, endRadius: 14))
                .frame(width: 22, height: 22)
                .offset(y: -14)
                .blendMode(.plusLighter)
            // Astra-specific HEAD (full body will be scaled 1.5x at parent)
            astraHead
                .offset(y: -14)
                .shadow(color: tower.kind.color.opacity(0.7), radius: 3)
        }
    }

    @ViewBuilder
    private var astraHead: some View {
        switch tower.kind {
        // Arrow
        case .dart:              DartHead()
        case .aindrastra:        AindraHead()
        case .sudarshanaChakra:  SudarshanaHead()
        // Fire
        case .agneyastra:        FlameHead(small: false)
        case .suryastra:         SunDiscHead()
        case .brahmashirsha:     SkullHead()
        // Water
        case .varunastra:        DropletHead()
        case .nagaPasha:         CobraHead()
        case .garudastra:        EagleHead()
        // Ice
        case .sheetastra:        CrystalHead()
        case .twashtar:          TripleCrystalHead()
        case .mohiniAstra:       VortexHead()
        // Divine
        case .trishul:           TridentHead()
        case .vajrastra:         VajraHeadShape()
        case .pashupatastra:     DivineEyeHead()
        // Sensory
        case .bala:              EyeHead()
        case .atibala:           DualEyeHead()
        case .divyaDrishti:      CosmicEyeHead()
        // Healer
        case .aushadhi:          LeafHead(color: .green)
        case .sanjivaniBooti:    LeafHead(color: Color(red: 0.3, green: 0.95, blue: 0.5), glow: true)
        case .amritKalash:       KalashHead()
        // Barrier
        case .surakshaRekha:     ShieldHead(color: Color(red: 0.95, green: 0.55, blue: 0.85))
        case .lakshmanRekha:     HexEmblemHead()
        case .vajraKavach:       DiamondHead()
        }
    }
}

// =====================================================================
// MARK: - Arrow path heads
// =====================================================================

struct DartHead: View {
    var body: some View {
        Path { p in
            p.move(to: CGPoint(x: 0, y: -7))
            p.addLine(to: CGPoint(x: 4, y: 3))
            p.addLine(to: CGPoint(x: -4, y: 3))
            p.closeSubpath()
        }
        .fill(LinearGradient(colors: [.white, Color(red: 0.7, green: 0.7, blue: 0.8)],
                             startPoint: .top, endPoint: .bottom))
        .shadow(color: .black.opacity(0.4), radius: 1)
    }
}

struct AindraHead: View {
    var body: some View {
        ZStack {
            // Barbed yellow arrowhead
            Path { p in
                p.move(to: CGPoint(x: 0, y: -8))
                p.addLine(to: CGPoint(x: 5, y: 4))
                p.addLine(to: CGPoint(x: 2, y: 2))
                p.addLine(to: CGPoint(x: 2, y: 5))
                p.addLine(to: CGPoint(x: -2, y: 5))
                p.addLine(to: CGPoint(x: -2, y: 2))
                p.addLine(to: CGPoint(x: -5, y: 4))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [.white, .yellow],
                                 startPoint: .top, endPoint: .bottom))
            .shadow(color: .yellow, radius: 3)
            // Mini lightning over head
            Path { p in
                p.move(to: CGPoint(x: -2, y: -10))
                p.addLine(to: CGPoint(x: 0, y: -6))
                p.addLine(to: CGPoint(x: -1, y: -5))
                p.addLine(to: CGPoint(x: 2, y: -1))
            }
            .stroke(Color.yellow, lineWidth: 1)
            .shadow(color: .yellow, radius: 2)
        }
    }
}

struct SudarshanaHead: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(LinearGradient(colors: [.yellow, .orange],
                                       startPoint: .top, endPoint: .bottom),
                        lineWidth: 1.5)
                .frame(width: 13, height: 13)
                .shadow(color: .orange, radius: 2)
            ForEach(0..<6, id: \.self) { i in
                Rectangle().fill(Color.orange)
                    .frame(width: 0.8, height: 5)
                    .rotationEffect(.degrees(Double(i) * 60))
            }
            Circle().fill(Color.yellow).frame(width: 3, height: 3)
                .shadow(color: .yellow, radius: 1.5)
        }
    }
}

// =====================================================================
// MARK: - Fire path heads
// =====================================================================

struct FlameHead: View {
    var small: Bool = true
    var body: some View {
        ZStack {
            // Outer flame
            Path { p in
                p.move(to: CGPoint(x: -5, y: 4))
                p.addQuadCurve(to: CGPoint(x: 0, y: -10),
                               control: CGPoint(x: -7, y: -3))
                p.addQuadCurve(to: CGPoint(x: 5, y: 4),
                               control: CGPoint(x: 7, y: -3))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [.red, .orange],
                                 startPoint: .bottom, endPoint: .top))
            .shadow(color: .orange, radius: 3)
            // Inner flame
            Path { p in
                p.move(to: CGPoint(x: -2.5, y: 3))
                p.addQuadCurve(to: CGPoint(x: 0, y: -7),
                               control: CGPoint(x: -3, y: -2))
                p.addQuadCurve(to: CGPoint(x: 2.5, y: 3),
                               control: CGPoint(x: 3, y: -2))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [.orange, .yellow],
                                 startPoint: .bottom, endPoint: .top))
            // White core
            Circle().fill(Color.white)
                .frame(width: 2, height: 3)
                .offset(y: -1)
        }
    }
}

struct SunDiscHead: View {
    var body: some View {
        ZStack {
            // Rays
            ForEach(0..<10, id: \.self) { i in
                Rectangle().fill(Color.yellow)
                    .frame(width: 1, height: 4)
                    .offset(y: -10)
                    .rotationEffect(.degrees(Double(i) * 36))
                    .offset(y: 2)
            }
            // Sun disc
            Circle()
                .fill(RadialGradient(colors: [.white, .yellow, .orange],
                                     center: .center, startRadius: 1, endRadius: 7))
                .frame(width: 13, height: 13)
                .shadow(color: .orange, radius: 4)
            // Core
            Circle().fill(Color.white).frame(width: 3, height: 3)
        }
    }
}

struct SkullHead: View {
    var body: some View {
        ZStack {
            // Flame backdrop
            ForEach(0..<5, id: \.self) { i in
                Path { p in
                    p.move(to: CGPoint(x: -1.5, y: 2))
                    p.addQuadCurve(to: CGPoint(x: 0, y: -10),
                                   control: CGPoint(x: -3, y: -4))
                    p.addQuadCurve(to: CGPoint(x: 1.5, y: 2),
                                   control: CGPoint(x: 3, y: -4))
                    p.closeSubpath()
                }
                .fill(LinearGradient(colors: [.red, .yellow],
                                     startPoint: .bottom, endPoint: .top))
                .rotationEffect(.degrees(Double(i - 2) * 20))
            }
            // Skull
            Ellipse()
                .fill(LinearGradient(colors: [.white, Color(red: 0.85, green: 0.85, blue: 0.8)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 11, height: 11)
                .shadow(color: .black.opacity(0.5), radius: 1.5)
            // Eyes
            HStack(spacing: 2.5) {
                Circle().fill(Color.black).frame(width: 2.5, height: 3)
                Circle().fill(Color.black).frame(width: 2.5, height: 3)
            }
            .offset(y: -1)
            // Teeth
            HStack(spacing: 0.6) {
                ForEach(0..<4, id: \.self) { _ in
                    Rectangle().fill(Color.black).frame(width: 0.8, height: 2.5)
                }
            }
            .offset(y: 4)
        }
    }
}

// =====================================================================
// MARK: - Water path heads
// =====================================================================

struct DropletHead: View {
    var body: some View {
        ZStack {
            // Droplet
            Path { p in
                p.move(to: CGPoint(x: 0, y: -8))
                p.addQuadCurve(to: CGPoint(x: 5, y: 3),
                               control: CGPoint(x: 5, y: -2))
                p.addArc(center: CGPoint(x: 0, y: 3), radius: 5,
                         startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [.cyan, .blue],
                                 startPoint: .top, endPoint: .bottom))
            .shadow(color: .cyan, radius: 3)
            // Highlight
            Circle().fill(Color.white.opacity(0.85))
                .frame(width: 1.5, height: 2)
                .offset(x: -1.5, y: 0)
        }
    }
}

struct CobraHead: View {
    var body: some View {
        ZStack {
            // Cobra hood (flared)
            Path { p in
                p.move(to: CGPoint(x: -7, y: 0))
                p.addQuadCurve(to: CGPoint(x: -5, y: -8),
                               control: CGPoint(x: -10, y: -5))
                p.addQuadCurve(to: CGPoint(x: 5, y: -8),
                               control: CGPoint(x: 0, y: -12))
                p.addQuadCurve(to: CGPoint(x: 7, y: 0),
                               control: CGPoint(x: 10, y: -5))
                p.addLine(to: CGPoint(x: 4, y: 4))
                p.addLine(to: CGPoint(x: -4, y: 4))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [Color(red: 0.4, green: 0.85, blue: 0.4), .green],
                                 startPoint: .top, endPoint: .bottom))
            .shadow(color: .green, radius: 2)
            // Yellow eyes
            HStack(spacing: 3) {
                Circle().fill(Color.yellow).frame(width: 1.8, height: 1.8)
                    .shadow(color: .yellow, radius: 1)
                Circle().fill(Color.yellow).frame(width: 1.8, height: 1.8)
                    .shadow(color: .yellow, radius: 1)
            }
            .offset(y: -3)
            // Fork tongue
            Path { p in
                p.move(to: CGPoint(x: 0, y: 4))
                p.addLine(to: CGPoint(x: -1, y: 7))
                p.move(to: CGPoint(x: 0, y: 4))
                p.addLine(to: CGPoint(x: 1, y: 7))
            }
            .stroke(Color.red, lineWidth: 0.7)
        }
    }
}

struct EagleHead: View {
    var body: some View {
        ZStack {
            // Wings spread
            Path { p in
                p.move(to: CGPoint(x: 0, y: 0))
                p.addQuadCurve(to: CGPoint(x: -8, y: -3),
                               control: CGPoint(x: -6, y: -6))
                p.addQuadCurve(to: CGPoint(x: 0, y: 3),
                               control: CGPoint(x: -4, y: 3))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [.mint, .green],
                                 startPoint: .leading, endPoint: .trailing))
            .offset(y: -1)
            Path { p in
                p.move(to: CGPoint(x: 0, y: 0))
                p.addQuadCurve(to: CGPoint(x: 8, y: -3),
                               control: CGPoint(x: 6, y: -6))
                p.addQuadCurve(to: CGPoint(x: 0, y: 3),
                               control: CGPoint(x: 4, y: 3))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [.mint, .green],
                                 startPoint: .trailing, endPoint: .leading))
            .offset(y: -1)
            // Head
            Circle().fill(Color.white).frame(width: 6, height: 6)
                .offset(y: -4)
            // Beak
            Path { p in
                p.move(to: CGPoint(x: 0, y: 0))
                p.addLine(to: CGPoint(x: 5, y: 2))
                p.addLine(to: CGPoint(x: 0, y: -3))
                p.closeSubpath()
            }
            .fill(Color.orange)
            .offset(x: 2, y: -3)
            // Eye
            Circle().fill(Color.black).frame(width: 1.5, height: 1.5).offset(x: -1, y: -4)
        }
    }
}

// =====================================================================
// MARK: - Ice path heads
// =====================================================================

struct CrystalHead: View {
    var body: some View {
        ZStack {
            // Big crystal
            Path { p in
                p.move(to: CGPoint(x: 0, y: -10))
                p.addLine(to: CGPoint(x: 5, y: 0))
                p.addLine(to: CGPoint(x: 0, y: 5))
                p.addLine(to: CGPoint(x: -5, y: 0))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [.white, .cyan],
                                 startPoint: .top, endPoint: .bottom))
            .shadow(color: .cyan, radius: 3)
            // Facet
            Path { p in
                p.move(to: CGPoint(x: 0, y: -10))
                p.addLine(to: CGPoint(x: 0, y: 5))
            }
            .stroke(Color.white.opacity(0.7), lineWidth: 0.5)
        }
    }
}

struct TripleCrystalHead: View {
    var body: some View {
        ZStack {
            // Center tall crystal
            Path { p in
                p.move(to: CGPoint(x: 0, y: -10))
                p.addLine(to: CGPoint(x: 4, y: 0))
                p.addLine(to: CGPoint(x: 0, y: 4))
                p.addLine(to: CGPoint(x: -4, y: 0))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [.white, .cyan],
                                 startPoint: .top, endPoint: .bottom))
            .shadow(color: .cyan, radius: 2)
            // Left small
            Path { p in
                p.move(to: CGPoint(x: 0, y: -6))
                p.addLine(to: CGPoint(x: 2.5, y: 1))
                p.addLine(to: CGPoint(x: 0, y: 3))
                p.addLine(to: CGPoint(x: -2.5, y: 1))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [.white, .cyan],
                                 startPoint: .top, endPoint: .bottom))
            .offset(x: -6, y: 2)
            // Right small
            Path { p in
                p.move(to: CGPoint(x: 0, y: -6))
                p.addLine(to: CGPoint(x: 2.5, y: 1))
                p.addLine(to: CGPoint(x: 0, y: 3))
                p.addLine(to: CGPoint(x: -2.5, y: 1))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [.white, .cyan],
                                 startPoint: .top, endPoint: .bottom))
            .offset(x: 6, y: 2)
        }
    }
}

struct VortexHead: View {
    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color(red: 0.85, green: 0.75, blue: 1.0).opacity(0.9 - Double(i) * 0.25),
                            style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    .frame(width: 13 - CGFloat(i) * 4, height: 13 - CGFloat(i) * 4)
                    .rotationEffect(.degrees(Double(i) * 120))
            }
            Circle()
                .fill(RadialGradient(colors: [.white, .purple.opacity(0.5)],
                                     center: .center, startRadius: 1, endRadius: 4))
                .frame(width: 5, height: 5)
                .shadow(color: .purple, radius: 3)
        }
    }
}

// =====================================================================
// MARK: - Divine path heads
// =====================================================================

/// Smaller trident — 3 short prongs at top
struct TridentHead: View {
    var body: some View {
        ZStack {
            // Crossguard
            Capsule()
                .fill(LinearGradient(colors: [.indigo, Color(red: 0.2, green: 0.15, blue: 0.5)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 12, height: 2)
                .offset(y: 1)
            // Center prong (tallest)
            Path { p in
                p.move(to: CGPoint(x: 0, y: -10))
                p.addLine(to: CGPoint(x: 1.6, y: 0))
                p.addLine(to: CGPoint(x: -1.6, y: 0))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [.white, .indigo],
                                 startPoint: .top, endPoint: .bottom))
            .shadow(color: .indigo, radius: 1.5)
            // Left prong (curves outward, shorter)
            Path { p in
                p.move(to: CGPoint(x: 0, y: -7))
                p.addQuadCurve(to: CGPoint(x: -2, y: 0),
                               control: CGPoint(x: -4, y: -4))
                p.addLine(to: CGPoint(x: 0.5, y: 0))
                p.addLine(to: CGPoint(x: 1.5, y: -5))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [.white, .indigo],
                                 startPoint: .top, endPoint: .bottom))
            .offset(x: -4, y: 0)
            // Right prong
            Path { p in
                p.move(to: CGPoint(x: 0, y: -7))
                p.addQuadCurve(to: CGPoint(x: 2, y: 0),
                               control: CGPoint(x: 4, y: -4))
                p.addLine(to: CGPoint(x: -0.5, y: 0))
                p.addLine(to: CGPoint(x: -1.5, y: -5))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [.white, .indigo],
                                 startPoint: .top, endPoint: .bottom))
            .offset(x: 4, y: 0)
        }
    }
}

struct VajraHeadShape: View {
    var body: some View {
        ZStack {
            // Diamond
            Path { p in
                p.move(to: CGPoint(x: 0, y: -8))
                p.addLine(to: CGPoint(x: 5, y: 0))
                p.addLine(to: CGPoint(x: 0, y: 5))
                p.addLine(to: CGPoint(x: -5, y: 0))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [.white, .yellow, .orange],
                                 startPoint: .top, endPoint: .bottom))
            .shadow(color: .yellow, radius: 3)
            // Cross facet
            Path { p in
                p.move(to: CGPoint(x: 0, y: -8))
                p.addLine(to: CGPoint(x: 0, y: 5))
                p.move(to: CGPoint(x: -5, y: 0))
                p.addLine(to: CGPoint(x: 5, y: 0))
            }
            .stroke(Color.white.opacity(0.7), lineWidth: 0.6)
        }
    }
}

struct DivineEyeHead: View {
    var body: some View {
        ZStack {
            // Almond eye (horizontal)
            Path { p in
                p.move(to: CGPoint(x: -7, y: 0))
                p.addQuadCurve(to: CGPoint(x: 7, y: 0),
                               control: CGPoint(x: 0, y: -6))
                p.addQuadCurve(to: CGPoint(x: -7, y: 0),
                               control: CGPoint(x: 0, y: 6))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [.white, Color(red: 0.95, green: 0.85, blue: 1.0)],
                                 startPoint: .top, endPoint: .bottom))
            .shadow(color: .purple, radius: 3)
            // Iris
            Circle().fill(Color(red: 0.85, green: 0.15, blue: 0.95))
                .frame(width: 5, height: 5)
            // Pupil
            Circle().fill(Color.black).frame(width: 2, height: 2)
            // Crescent above
            Path { p in
                p.addArc(center: .zero, radius: 2.5,
                         startAngle: .degrees(80), endAngle: .degrees(-80), clockwise: true)
                p.addArc(center: CGPoint(x: -1, y: 0), radius: 2.5,
                         startAngle: .degrees(-80), endAngle: .degrees(80), clockwise: false)
                p.closeSubpath()
            }
            .fill(Color.white)
            .offset(y: -10)
        }
    }
}

// =====================================================================
// MARK: - Sensory heads
// =====================================================================

struct EyeHead: View {
    var body: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: -7, y: 0))
                p.addQuadCurve(to: CGPoint(x: 7, y: 0),
                               control: CGPoint(x: 0, y: -5))
                p.addQuadCurve(to: CGPoint(x: -7, y: 0),
                               control: CGPoint(x: 0, y: 5))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [.white, Color(red: 1.0, green: 0.95, blue: 0.85)],
                                 startPoint: .top, endPoint: .bottom))
            .shadow(color: .yellow.opacity(0.6), radius: 2)
            Circle().fill(Color(red: 1.0, green: 0.85, blue: 0.2))
                .frame(width: 5, height: 5)
            Circle().fill(Color.black).frame(width: 2, height: 2)
            Circle().fill(Color.white).frame(width: 0.8, height: 0.8)
                .offset(x: 0.5, y: -0.5)
        }
    }
}

struct DualEyeHead: View {
    var body: some View {
        ZStack {
            // Upper eye (small)
            ZStack {
                Ellipse().fill(Color.white).frame(width: 8, height: 5)
                Circle().fill(Color(red: 1.0, green: 0.55, blue: 0.0))
                    .frame(width: 3, height: 3)
                Circle().fill(Color.black).frame(width: 1.5, height: 1.5)
            }
            .offset(y: -6)
            // Lower eye (larger)
            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: -6, y: 0))
                    p.addQuadCurve(to: CGPoint(x: 6, y: 0),
                                   control: CGPoint(x: 0, y: -4))
                    p.addQuadCurve(to: CGPoint(x: -6, y: 0),
                                   control: CGPoint(x: 0, y: 4))
                    p.closeSubpath()
                }
                .fill(Color.white)
                .shadow(color: .yellow.opacity(0.6), radius: 2)
                Circle().fill(Color(red: 1.0, green: 0.75, blue: 0.0))
                    .frame(width: 5, height: 5)
                Circle().fill(Color.black).frame(width: 2, height: 2)
            }
            .offset(y: 2)
        }
    }
}

struct CosmicEyeHead: View {
    var body: some View {
        ZStack {
            // Radiating cosmic rays
            ForEach(0..<12, id: \.self) { i in
                Rectangle()
                    .fill(LinearGradient(colors: [Color(red: 1.0, green: 0.95, blue: 0.55), .clear],
                                         startPoint: .center, endPoint: .top))
                    .frame(width: 0.8, height: 10)
                    .offset(y: -10)
                    .rotationEffect(.degrees(Double(i) * 30))
                    .offset(y: 4)
            }
            // Eye
            Path { p in
                p.move(to: CGPoint(x: -7, y: 0))
                p.addQuadCurve(to: CGPoint(x: 7, y: 0),
                               control: CGPoint(x: 0, y: -5))
                p.addQuadCurve(to: CGPoint(x: -7, y: 0),
                               control: CGPoint(x: 0, y: 5))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [.white, Color(red: 1.0, green: 0.95, blue: 0.55)],
                                 startPoint: .top, endPoint: .bottom))
            .shadow(color: .yellow, radius: 3)
            Circle().fill(Color(red: 1.0, green: 0.75, blue: 0.0)).frame(width: 5, height: 5)
            Circle().fill(Color.black).frame(width: 2, height: 2)
        }
    }
}

// =====================================================================
// MARK: - Healer heads
// =====================================================================

struct LeafHead: View {
    var color: Color = .green
    var glow: Bool = false
    var body: some View {
        ZStack {
            // Leaf
            Path { p in
                p.move(to: CGPoint(x: 0, y: -8))
                p.addQuadCurve(to: CGPoint(x: 5, y: 0),
                               control: CGPoint(x: 4, y: -4))
                p.addQuadCurve(to: CGPoint(x: 0, y: 4),
                               control: CGPoint(x: 2.5, y: 3))
                p.addQuadCurve(to: CGPoint(x: -5, y: 0),
                               control: CGPoint(x: -2.5, y: 3))
                p.addQuadCurve(to: CGPoint(x: 0, y: -8),
                               control: CGPoint(x: -4, y: -4))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [.white, color],
                                 startPoint: .top, endPoint: .bottom))
            .shadow(color: glow ? color : .black.opacity(0.4), radius: glow ? 4 : 1)
            // Leaf vein
            Path { p in
                p.move(to: CGPoint(x: 0, y: -8))
                p.addLine(to: CGPoint(x: 0, y: 4))
            }
            .stroke(Color.black.opacity(0.4), lineWidth: 0.4)
        }
    }
}

struct KalashHead: View {
    var body: some View {
        ZStack {
            // Pot
            Path { p in
                p.move(to: CGPoint(x: -5, y: 4))
                p.addCurve(to: CGPoint(x: -4, y: -2),
                           control1: CGPoint(x: -7, y: 2), control2: CGPoint(x: -6, y: 0))
                p.addLine(to: CGPoint(x: -3, y: -4))
                p.addLine(to: CGPoint(x: 3, y: -4))
                p.addLine(to: CGPoint(x: 4, y: -2))
                p.addCurve(to: CGPoint(x: 5, y: 4),
                           control1: CGPoint(x: 6, y: 0), control2: CGPoint(x: 7, y: 2))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [.yellow, Color(red: 0.85, green: 0.55, blue: 0.1)],
                                 startPoint: .top, endPoint: .bottom))
            .shadow(color: .yellow, radius: 3)
            // Band
            Rectangle().fill(Color(red: 0.55, green: 0.35, blue: 0.0))
                .frame(width: 10, height: 1.2).offset(y: 1)
            // Coconut on top
            Circle()
                .fill(Color(red: 0.55, green: 0.35, blue: 0.15))
                .frame(width: 4, height: 4)
                .offset(y: -7)
            // Glow drop
            Circle().fill(Color.white).frame(width: 2, height: 2)
                .shadow(color: .yellow, radius: 3)
                .offset(y: -10)
        }
    }
}

// =====================================================================
// MARK: - Barrier heads
// =====================================================================

struct ShieldHead: View {
    var color: Color = Color(red: 0.95, green: 0.55, blue: 0.85)
    var body: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 0, y: -8))
                p.addCurve(to: CGPoint(x: 6, y: -2),
                           control1: CGPoint(x: 3, y: -8), control2: CGPoint(x: 6, y: -5))
                p.addCurve(to: CGPoint(x: 0, y: 6),
                           control1: CGPoint(x: 6, y: 2), control2: CGPoint(x: 4, y: 6))
                p.addCurve(to: CGPoint(x: -6, y: -2),
                           control1: CGPoint(x: -4, y: 6), control2: CGPoint(x: -6, y: 2))
                p.addCurve(to: CGPoint(x: 0, y: -8),
                           control1: CGPoint(x: -6, y: -5), control2: CGPoint(x: -3, y: -8))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [color, color.opacity(0.6)],
                                 startPoint: .top, endPoint: .bottom))
            .shadow(color: color, radius: 3)
            // Rune cross
            ForEach(0..<4, id: \.self) { i in
                Rectangle().fill(Color.white.opacity(0.85))
                    .frame(width: 0.8, height: 5)
                    .rotationEffect(.degrees(Double(i) * 45))
            }
            Circle().fill(Color.white).frame(width: 2, height: 2)
        }
    }
}

struct HexEmblemHead: View {
    var body: some View {
        ZStack {
            Path { p in
                let r: CGFloat = 8
                for i in 0..<6 {
                    let angle = Double(i) * .pi / 3 - .pi / 2
                    let pt = CGPoint(x: cos(angle) * r, y: sin(angle) * r)
                    if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                }
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [Color(red: 1.0, green: 0.5, blue: 0.85),
                                          Color(red: 0.55, green: 0.15, blue: 0.5)],
                                 startPoint: .top, endPoint: .bottom))
            .shadow(color: .pink, radius: 3)
            Path { p in
                let r: CGFloat = 8
                for i in 0..<6 {
                    let angle = Double(i) * .pi / 3 - .pi / 2
                    let pt = CGPoint(x: cos(angle) * r, y: sin(angle) * r)
                    if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                }
                p.closeSubpath()
            }
            .stroke(Color.white, lineWidth: 1)
            Circle().fill(Color.white).frame(width: 2.5, height: 2.5)
        }
    }
}

struct DiamondHead: View {
    var body: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 0, y: -9))
                p.addLine(to: CGPoint(x: 6, y: 0))
                p.addLine(to: CGPoint(x: 0, y: 7))
                p.addLine(to: CGPoint(x: -6, y: 0))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [.white, Color(red: 0.85, green: 0.3, blue: 0.95)],
                                 startPoint: .top, endPoint: .bottom))
            .shadow(color: .purple, radius: 4)
            // Facets
            Path { p in
                p.move(to: CGPoint(x: 0, y: -9))
                p.addLine(to: CGPoint(x: 0, y: 7))
                p.move(to: CGPoint(x: -6, y: 0))
                p.addLine(to: CGPoint(x: 6, y: 0))
            }
            .stroke(Color.white.opacity(0.7), lineWidth: 0.6)
        }
    }
}

//
//  GameArt.swift
//  towerlogicstrategicgame
//
//  Custom Shape silhouettes for towers, buildings, and enemies.
//  Each entity gets a visually-distinct outline matching its name.
//

import SwiftUI

extension View {
    /// Wraps a view in `.drawingGroup()` only when Optimized graphics is
    /// selected. Full mode skips rasterization so blends / shadows render
    /// at native fidelity.
    @ViewBuilder
    func compositingGroupIfNeeded(isFull: Bool) -> some View {
        if isFull {
            self
        } else {
            self.drawingGroup()
        }
    }
}

// MARK: - Projectile Art (per damage type, scaled by tier)

struct ProjectileArtView: View {
    let projectile: Projectile
    @State private var pulse: Double = 0

    private var rotationDegrees: Double {
        atan2(Double(projectile.heading.y), Double(projectile.heading.x)) * 180 / .pi
    }

    /// The three divine T3 ultimates render with extra halo + ring layers
    /// — they're the dramatic "I am the wrath" projectiles, so a bigger,
    /// more detailed shell makes them read instantly across the board.
    private var isDivineUltimate: Bool {
        let k = projectile.sourceKind
        return k == .sudarshanaChakra || k == .brahmashirsha || k == .pashupatastra
    }

    var body: some View {
        let isFull = GraphicsSettings.shared.isFull
        ZStack {
            // Divine ultimates get a layered halo + outer ring before the head
            if isDivineUltimate {
                divineHalo
                divineRing
            }
            // Per-astra signature trail — each named astra renders its
            // characteristic visual (Trishul = trident, Vajrastra =
            // lightning fork, Sudarshana = spinning disc, etc.).
            // Falls back to the generic elemental trail for fodder paths.
            astraSignatureTrail
            // The astra head itself — same shape as the tower's head.
            // Spinning kinds (Sudarshana, Aindra chain, Vajrastra arc)
            // get a permanent rotation overlay so the head reads as
            // "live" rather than static while flying. Shadow strength
            // tracks the graphics setting: Full = original glow on every
            // projectile (5 base / 10 divine), Optimized = no shadow on
            // fodder / 6 on divine ultimates.
            let shadowRadius: CGFloat = isFull
                ? (isDivineUltimate ? 10 : 5)
                : (isDivineUltimate ? 6 : 0)
            AstraHeadView(tower: dummyTower)
                .scaleEffect(scaleForProjectile)
                .rotationEffect(.degrees(headSpinAngle))
                .shadow(color: shadowRadius > 0 ? projectile.color : .clear,
                        radius: shadowRadius)
        }
        // Optimized mode rasterizes the whole projectile each frame so
        // sub-view shading doesn't compound across many in-flight darts.
        // Full mode skips drawingGroup so every blendMode + shadow renders
        // at native fidelity.
        .compositingGroupIfNeeded(isFull: isFull)
        // Rotate so the head's "tip" points toward the target.
        // Heads are drawn with their tip pointing UP (y negative), and the
        // projectile flies along +X to the target, so we rotate by
        // (heading angle) + 90° to turn the top toward the heading vector.
        .rotationEffect(.degrees(rotationDegrees + 90))
        .onAppear {
            // Divine ultimates always get the pulse loop; spinning astras
            // run a faster loop too so the disc/chain twirls.
            if isDivineUltimate {
                withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) {
                    pulse = 1
                }
            } else if isSpinningAstra {
                withAnimation(.linear(duration: 0.35).repeatForever(autoreverses: false)) {
                    pulse = 1
                }
            }
        }
    }

    /// Astras whose head should visibly spin while flying.
    private var isSpinningAstra: Bool {
        let k = projectile.sourceKind
        return k == .sudarshanaChakra
            || k == .aindrastra
            || k == .shaktiAstra
            || k == .vajrastra
            || k == .nagaPasha
            || k == .narayanaAstra
            || k == .mohiniAstra
    }

    /// Continuous spin angle for the astra head — 0 by default. Pulse loops
    /// 0..1 (via withAnimation), so multiplying by 360 gives a full turn.
    private var headSpinAngle: Double {
        guard isSpinningAstra else { return 0 }
        return pulse * 360
    }

    /// A dummy tower used only to feed the source kind into AstraHeadView.
    private var dummyTower: Tower {
        Tower(slotIndex: 0,
              position: projectile.position,
              path: projectile.sourceKind.path,
              tier: projectile.sourceTier)
    }

    /// Projectile scale: T1≈1.5, T2≈1.9, T3≈2.3. Divine ultimates jump to
    /// ~3.5 so the player sees the kill blow flying across the screen.
    private var scaleForProjectile: CGFloat {
        if isDivineUltimate { return 3.5 + 0.3 * CGFloat(pulse) }
        return 1.5 + CGFloat(projectile.sourceTier - 1) * 0.4
    }

    /// Pulsing radial bloom on the divine ultimates — sells the "incoming
    /// apocalyptic hit" feeling as it flies toward the target.
    @ViewBuilder
    private var divineHalo: some View {
        let base = Circle()
            .fill(RadialGradient(
                colors: [
                    projectile.color.opacity(0.55 + 0.20 * pulse),
                    projectile.color.opacity(0.25),
                    .clear
                ],
                center: .center,
                startRadius: 4,
                endRadius: 30 + CGFloat(pulse) * 8))
            .frame(width: 60, height: 60)
        // Restore the bright `.plusLighter` compositing in Full graphics
        // mode — drops back to the cheaper alpha blend in Optimized.
        if GraphicsSettings.shared.isFull {
            base.blendMode(.plusLighter)
        } else {
            base
        }
    }

    /// Outer dashed counter-rotating ring — ties the projectile visually back
    /// to the divine-ultimate tower head and gives it more on-screen weight.
    private var divineRing: some View {
        Circle()
            .stroke(
                projectile.color.opacity(0.75),
                style: StrokeStyle(lineWidth: 1.6, dash: [5, 4]))
            .frame(width: 42 + CGFloat(pulse) * 5,
                   height: 42 + CGFloat(pulse) * 5)
            .rotationEffect(.degrees(pulse * 360))
    }

    /// Per-astra signature trail. Each named astra renders its
    /// characteristic visual; falls back to the elemental trail otherwise.
    @ViewBuilder
    private var astraSignatureTrail: some View {
        let c = projectile.color
        switch projectile.sourceKind {
        // ─── Arrow path ─────────────────────────────────────────────
        case .aindrastra:
            // Indra's chain bow — zig-zag thunder arc trail
            Path { p in
                p.move(to: CGPoint(x: -22, y: 0))
                p.addLine(to: CGPoint(x: -16, y: -3))
                p.addLine(to: CGPoint(x: -11, y: 2))
                p.addLine(to: CGPoint(x: -6, y: -2))
                p.addLine(to: CGPoint(x: 0, y: 0))
            }
            .stroke(LinearGradient(colors: [c.opacity(0), .white, c],
                                   startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            .shadow(color: c, radius: 5)
        case .shaktiAstra:
            // Karna's spear — straight spear tip with sparks
            Path { p in
                p.move(to: CGPoint(x: -24, y: 0))
                p.addLine(to: CGPoint(x: 0, y: 0))
            }
            .stroke(LinearGradient(colors: [c.opacity(0), c, .white],
                                   startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
            .shadow(color: c, radius: 6)
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(c)
                    .frame(width: CGFloat(3 - i), height: CGFloat(3 - i))
                    .offset(x: CGFloat(-8 - i * 6), y: CGFloat([2, -2, 1][i]))
                    .shadow(color: c, radius: 2)
            }
        case .sudarshanaChakra:
            // Vishnu's discus — spinning motion-blur arc
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(c.opacity(0.7 - Double(i) * 0.2),
                            style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                    .frame(width: CGFloat(14 + i * 6), height: CGFloat(14 + i * 6))
                    .rotationEffect(.degrees(pulse * 360 + Double(i) * 30))
            }
        case .dart:
            // Simple shaft
            Path { p in
                p.move(to: CGPoint(x: -16, y: 0))
                p.addLine(to: CGPoint(x: 0, y: 0))
            }
            .stroke(LinearGradient(colors: [c.opacity(0), c],
                                   startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 1.6, lineCap: .round))

        // ─── Fire path ──────────────────────────────────────────────
        case .agneyastra, .suryastra, .rudraAstra:
            // Flame comet tail — bigger / brighter at higher tier
            let tailLen: CGFloat = projectile.sourceKind == .rudraAstra ? 24 : 18
            Path { p in
                p.move(to: CGPoint(x: -2, y: -3))
                p.addQuadCurve(to: CGPoint(x: -tailLen, y: 0), control: CGPoint(x: -tailLen * 0.6, y: -7))
                p.addQuadCurve(to: CGPoint(x: -2, y: 3), control: CGPoint(x: -tailLen * 0.6, y: 7))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [.red.opacity(0), .red.opacity(0.8), .orange, .yellow],
                                 startPoint: .leading, endPoint: .trailing))
            .shadow(color: .orange, radius: 5)
        case .brahmashirsha:
            // Apocalyptic inferno — multi-flame head + ember sparks
            ForEach(0..<3, id: \.self) { i in
                Path { p in
                    p.move(to: CGPoint(x: -3, y: -4 + CGFloat(i) * 4))
                    p.addQuadCurve(to: CGPoint(x: -20, y: -4 + CGFloat(i) * 4),
                                   control: CGPoint(x: -12, y: -8 + CGFloat(i) * 4))
                }
                .stroke(LinearGradient(colors: [c.opacity(0), c, .white],
                                       startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .shadow(color: c, radius: 4)
            }

        // ─── Water path ─────────────────────────────────────────────
        case .varunastra:
            // Single water droplet trail with ripples
            ForEach(0..<3, id: \.self) { i in
                Ellipse()
                    .stroke(Color.cyan.opacity(0.6 - Double(i) * 0.18), lineWidth: 1.2)
                    .frame(width: CGFloat(6 + i * 4), height: CGFloat(3 + i * 2))
                    .offset(x: CGFloat(-4 - i * 4))
            }
        case .nagaPasha:
            // Serpent noose — wavy snake trail
            Path { p in
                p.move(to: CGPoint(x: -22, y: 0))
                p.addCurve(to: CGPoint(x: 0, y: 0),
                           control1: CGPoint(x: -15, y: -6),
                           control2: CGPoint(x: -7, y: 6))
            }
            .stroke(LinearGradient(colors: [c.opacity(0), c, c.opacity(0.7)],
                                   startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
            .shadow(color: c, radius: 3)
        case .garudastra:
            // Garuda's wings — pair of swept-back arcs
            ForEach([-1, 1], id: \.self) { sign in
                Path { p in
                    p.move(to: CGPoint(x: -3, y: 0))
                    p.addQuadCurve(to: CGPoint(x: -16, y: CGFloat(sign) * 8),
                                   control: CGPoint(x: -10, y: CGFloat(sign) * 2))
                }
                .stroke(c.opacity(0.85),
                        style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                .shadow(color: c, radius: 4)
            }

        // ─── Ice path ───────────────────────────────────────────────
        case .sheetastra:
            // Snowflake particles trail
            ForEach(0..<4, id: \.self) { i in
                Image(systemName: "snowflake")
                    .font(.system(size: CGFloat(6 - i)))
                    .foregroundColor(Color.cyan.opacity(0.7 - Double(i) * 0.15))
                    .offset(x: CGFloat(-5 - i * 4), y: CGFloat([2, -2, 1, -1][i]))
            }
        case .twashtar:
            // Triple-crystal frost trail
            ForEach(0..<3, id: \.self) { i in
                Path { p in
                    p.move(to: CGPoint(x: CGFloat(-6 - i * 5), y: -3))
                    p.addLine(to: CGPoint(x: CGFloat(-6 - i * 5) - 2, y: 0))
                    p.addLine(to: CGPoint(x: CGFloat(-6 - i * 5), y: 3))
                    p.closeSubpath()
                }
                .fill(Color.cyan.opacity(0.75 - Double(i) * 0.18))
                .shadow(color: Color(red: 0.6, green: 0.85, blue: 1.0), radius: 2)
            }
        case .mohiniAstra:
            // Enchanting vortex — swirling spiral arcs
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .trim(from: 0.2, to: 0.8)
                    .stroke(c.opacity(0.7 - Double(i) * 0.15),
                            style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
                    .frame(width: CGFloat(10 + i * 4), height: CGFloat(10 + i * 4))
                    .rotationEffect(.degrees(pulse * 360 + Double(i) * 60))
            }

        // ─── Divine path ────────────────────────────────────────────
        case .trishul:
            // Shiva's trident — 3 prongs at the tail
            ForEach(-1...1, id: \.self) { sign in
                Path { p in
                    p.move(to: CGPoint(x: -22, y: CGFloat(sign) * 5))
                    p.addLine(to: CGPoint(x: 0, y: 0))
                }
                .stroke(LinearGradient(colors: [c.opacity(0), .white, c],
                                       startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                .shadow(color: c, radius: 4)
            }
        case .vajrastra:
            // Indra's thunderbolt — Y-shaped lightning fork
            Path { p in
                // Center jagged line
                p.move(to: CGPoint(x: -22, y: 0))
                p.addLine(to: CGPoint(x: -16, y: -3))
                p.addLine(to: CGPoint(x: -12, y: 2))
                p.addLine(to: CGPoint(x: -6, y: -2))
                p.addLine(to: CGPoint(x: 0, y: 0))
                // Upper fork
                p.move(to: CGPoint(x: -12, y: 2))
                p.addLine(to: CGPoint(x: -8, y: -6))
                // Lower fork
                p.move(to: CGPoint(x: -6, y: -2))
                p.addLine(to: CGPoint(x: -2, y: 6))
            }
            .stroke(LinearGradient(colors: [c.opacity(0), .white, c],
                                   startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .shadow(color: c, radius: 5)
        case .narayanaAstra:
            // Vishnu's arrow storm — 5 parallel arrow trails
            ForEach(-2...2, id: \.self) { row in
                Path { p in
                    p.move(to: CGPoint(x: -20, y: CGFloat(row) * 3))
                    p.addLine(to: CGPoint(x: 0, y: 0))
                }
                .stroke(LinearGradient(colors: [c.opacity(0), c],
                                       startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
            }
        case .pashupatastra:
            // Shiva's wrath — divine third-eye beam with cosmic rays
            ForEach(0..<6, id: \.self) { i in
                Rectangle()
                    .fill(LinearGradient(colors: [c.opacity(0), .white, c],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: 20, height: 1.5)
                    .rotationEffect(.degrees(Double(i) * 30 - 75))
                    .shadow(color: c, radius: 4)
            }

        // ─── Sensory path (Bala / Atibala / Divya Drishti) ──────────
        case .bala, .atibala, .divyaDrishti:
            EmptyView()       // sensory towers don't fire projectiles

        // ─── Fallback for any other astra ───────────────────────────
        default:
            elementalTrail
        }
    }

    /// Elemental trail behind the astra head, matching the damage type
    @ViewBuilder
    private var elementalTrail: some View {
        switch projectile.damageType {
        case .physical:
            // Lightning/spark trail
            Path { p in
                p.move(to: CGPoint(x: -16, y: 0))
                p.addLine(to: CGPoint(x: -10, y: -2))
                p.addLine(to: CGPoint(x: -5, y: 1))
                p.addLine(to: CGPoint(x: 0, y: 0))
            }
            .stroke(LinearGradient(colors: [projectile.color.opacity(0), projectile.color],
                                   startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .shadow(color: projectile.color, radius: 4)
        case .fire:
            // Flame comet tail
            Path { p in
                p.move(to: CGPoint(x: -2, y: -3))
                p.addQuadCurve(to: CGPoint(x: -18, y: 0), control: CGPoint(x: -10, y: -6))
                p.addQuadCurve(to: CGPoint(x: -2, y: 3), control: CGPoint(x: -10, y: 6))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [.red.opacity(0), .red.opacity(0.7), .orange],
                                 startPoint: .leading, endPoint: .trailing))
            .shadow(color: .orange, radius: 5)
        case .water:
            // Ripple trail
            ForEach(0..<3, id: \.self) { i in
                Ellipse()
                    .stroke(Color.cyan.opacity(0.6 - Double(i) * 0.18), lineWidth: 1.2)
                    .frame(width: CGFloat(6 + i * 4), height: CGFloat(3 + i * 2))
                    .offset(x: CGFloat(-4 - i * 4))
            }
        case .ice:
            // Frost particles
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(Color.cyan.opacity(0.5 - Double(i) * 0.10))
                    .frame(width: CGFloat(4 - i), height: CGFloat(4 - i))
                    .offset(x: CGFloat(-5 - i * 3))
            }
        case .divine:
            // Light beam
            Path { p in
                p.move(to: CGPoint(x: -22, y: 0))
                p.addLine(to: CGPoint(x: 0, y: 0))
            }
            .stroke(LinearGradient(colors: [projectile.color.opacity(0), .white],
                                   startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .shadow(color: projectile.color, radius: 6)
        }
    }

}

// MARK: - Tower Fire Flash (cinematic burst when shooting)

/// A short flash effect drawn at the tower's position when it fires.
/// Stored briefly in the model and rendered as decay.
struct TowerFireFlash: View {
    let color: Color
    let damageType: DamageType
    /// Tower tier — drives flash size, spike count, and ring intensity.
    var tier: Int = 1
    /// Which astra fired — drives the Sanskrit power-glyph overlay
    /// (श्री on Sudarshana Chakra, भम्भ्र on Bhambhrastra, ॐ on
    /// Pashupatastra). nil = no glyph overlay.
    var sourceKind: TowerKind? = nil
    var progress: Double = 0  // 0..1 fade out

    var body: some View {
        let alpha = 1.0 - progress
        let isFull = GraphicsSettings.shared.isFull
        // Per-tier scale-up: T1 = 1.00×, T2 = 1.20×, T3 = 1.50×, T4 = 1.95×.
        let tierScale: Double = [1.0, 1.0, 1.20, 1.50, 1.95][max(0, min(4, tier))]
        // Full mode keeps the original heavier spike count (T1 = 8 …
        // T4 = 20). Optimized halves it to save fill rate.
        let spikes: Int = isFull
            ? max(8, 4 + tier * 4)
            : max(4, 2 + tier * 2)
        ZStack {
            // Shockwave ring — only on T3/T4. Expands outward and fades.
            if tier >= 3 {
                let shock = Circle()
                    .stroke(color.opacity(alpha * 0.8), lineWidth: 1.5)
                    .frame(width: (40 + CGFloat(progress) * 60) * CGFloat(tierScale),
                           height: (40 + CGFloat(progress) * 60) * CGFloat(tierScale))
                if isFull {
                    shock.blendMode(.plusLighter)
                } else {
                    shock
                }
            }
            // Bright flash burst.
            let burst = Circle()
                .fill(RadialGradient(colors: [.white.opacity(alpha),
                                              color.opacity(alpha * 0.7),
                                              .clear],
                                     center: .center, startRadius: 2,
                                     endRadius: (24 + CGFloat(progress) * 16) * CGFloat(tierScale)))
                .frame(width: (48 + CGFloat(progress) * 32) * CGFloat(tierScale),
                       height: (48 + CGFloat(progress) * 32) * CGFloat(tierScale))
            if isFull {
                burst.blendMode(.plusLighter)
            } else {
                burst
            }
            // Radial spike rays — more spikes at higher tier.
            let rays = ForEach(0..<spikes, id: \.self) { i in
                Rectangle()
                    .fill(LinearGradient(colors: [color.opacity(alpha), .clear],
                                         startPoint: .center, endPoint: .top))
                    .frame(width: 1.5,
                           height: (18 + CGFloat(progress) * 8) * CGFloat(tierScale))
                    .rotationEffect(.degrees(Double(i) * 360.0 / Double(spikes)))
            }
            if isFull {
                ZStack { rays }.blendMode(.plusLighter)
            } else {
                rays
            }
            // T4 — extra inner gold core flash.
            if tier >= 4 {
                let core = Circle()
                    .fill(RadialGradient(colors: [Color.white.opacity(alpha),
                                                  Color(red: 1.0, green: 0.85, blue: 0.25).opacity(alpha),
                                                  .clear],
                                         center: .center, startRadius: 1, endRadius: 14))
                    .frame(width: 28, height: 28)
                if isFull {
                    core.blendMode(.plusLighter)
                } else {
                    core
                }
            }
            // Sanskrit power-glyph overlay for select astras. Full mode
            // restores the second shadow pass for a brighter halo.
            if let glyph = sanskritGlyph(for: sourceKind) {
                let text = Text(glyph)
                    .font(.system(size: 22 * CGFloat(tierScale),
                                  weight: .heavy, design: .serif))
                    .foregroundColor(.white.opacity(alpha))
                    .shadow(color: color.opacity(alpha),
                            radius: isFull ? 6 : 4)
                    .scaleEffect(1.0 + 0.35 * CGFloat(progress))
                if isFull {
                    text.shadow(color: .white.opacity(alpha * 0.6), radius: 2)
                } else {
                    text
                }
            }
        }
        // Optimized mode flattens the flash into one bitmap; Full mode
        // keeps native compositing so every blend renders at full strength.
        .compositingGroupIfNeeded(isFull: isFull)
    }

    /// Returns the Devanagari power-syllable rendered on this astra's fire
    /// flash. Three astras have signature glyphs the player should learn
    /// to recognise on-screen.
    private func sanskritGlyph(for kind: TowerKind?) -> String? {
        switch kind {
        case .sudarshanaChakra: return "श्री"     // Shree — Vishnu's auspicious mark
        case .brahmashirsha:    return "भम्भ्र"   // Bhambhra — Bhambhrastra's seed mantra
        case .pashupatastra:    return "ॐ"        // Om — Shiva's primal sound
        default:                return nil
        }
    }
}

// MARK: - Helper: small primitive shapes

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Tower Shapes (5 path styles)

struct WatchtowerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        // Body trapezoid
        p.move(to: CGPoint(x: w * 0.10, y: h * 0.95))
        p.addLine(to: CGPoint(x: w * 0.25, y: h * 0.40))
        p.addLine(to: CGPoint(x: w * 0.75, y: h * 0.40))
        p.addLine(to: CGPoint(x: w * 0.90, y: h * 0.95))
        p.closeSubpath()
        // Pointed roof
        p.move(to: CGPoint(x: w * 0.20, y: h * 0.42))
        p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.08))
        p.addLine(to: CGPoint(x: w * 0.80, y: h * 0.42))
        p.closeSubpath()
        return p
    }
}

struct BrazierShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        // Pillar
        p.addRect(CGRect(x: w * 0.32, y: h * 0.45, width: w * 0.36, height: h * 0.50))
        // Bowl on top
        p.addEllipse(in: CGRect(x: w * 0.15, y: h * 0.28, width: w * 0.70, height: h * 0.25))
        // Base
        p.addRect(CGRect(x: w * 0.18, y: h * 0.92, width: w * 0.64, height: h * 0.08))
        return p
    }
}

struct WaterPillarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        // Wavy curved pillar
        p.move(to: CGPoint(x: w * 0.12, y: h * 0.95))
        p.addCurve(to: CGPoint(x: w * 0.28, y: h * 0.30),
                   control1: CGPoint(x: w * 0.05, y: h * 0.70),
                   control2: CGPoint(x: w * 0.18, y: h * 0.50))
        p.addQuadCurve(to: CGPoint(x: w * 0.72, y: h * 0.30),
                       control: CGPoint(x: w * 0.5, y: h * 0.05))
        p.addCurve(to: CGPoint(x: w * 0.88, y: h * 0.95),
                   control1: CGPoint(x: w * 0.82, y: h * 0.50),
                   control2: CGPoint(x: w * 0.95, y: h * 0.70))
        p.closeSubpath()
        return p
    }
}

struct IceSpireShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        // Jagged crystalline silhouette
        p.move(to: CGPoint(x: w * 0.05, y: h * 0.95))
        p.addLine(to: CGPoint(x: w * 0.18, y: h * 0.60))
        p.addLine(to: CGPoint(x: w * 0.30, y: h * 0.78))
        p.addLine(to: CGPoint(x: w * 0.42, y: h * 0.22))
        p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.03))
        p.addLine(to: CGPoint(x: w * 0.58, y: h * 0.22))
        p.addLine(to: CGPoint(x: w * 0.70, y: h * 0.78))
        p.addLine(to: CGPoint(x: w * 0.82, y: h * 0.60))
        p.addLine(to: CGPoint(x: w * 0.95, y: h * 0.95))
        p.closeSubpath()
        return p
    }
}

struct TempleGopuramShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        // 3 stacked tiers (stepped pyramid)
        let tiers: [(yTop: CGFloat, yBot: CGFloat, widthRatio: CGFloat)] = [
            (h * 0.05, h * 0.20, 0.30),
            (h * 0.22, h * 0.42, 0.50),
            (h * 0.44, h * 0.66, 0.70)
        ]
        for tier in tiers {
            let x = (w - w * tier.widthRatio) / 2
            p.addRect(CGRect(x: x, y: tier.yTop, width: w * tier.widthRatio, height: tier.yBot - tier.yTop))
        }
        // Base
        p.addRect(CGRect(x: w * 0.08, y: h * 0.68, width: w * 0.84, height: h * 0.27))
        // Pinnacle on top
        p.move(to: CGPoint(x: w * 0.45, y: h * 0.05))
        p.addLine(to: CGPoint(x: w * 0.50, y: 0))
        p.addLine(to: CGPoint(x: w * 0.55, y: h * 0.05))
        p.closeSubpath()
        return p
    }
}

// MARK: - Tower Art View

struct TowerArtView: View {
    let tower: Tower
    let selected: Bool
    /// iPhone (compact) shrinks the entire tower visual to match the
    /// tighter slot grid on small screens. iPad / Mac (regular) keep the
    /// original 60×60 layout untouched.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        let ac = tower.kind.color
        let isCompact = horizontalSizeClass == .compact
        let frameSize: CGFloat = isCompact ? 36 : 60
        let visualScale: CGFloat = isCompact ? 0.60 : 1.0

        // Drive continuous animations off a single timeline so every
        // tower on screen shares cadence and the GPU doesn't thrash with
        // separate withAnimation loops. Frame rate scales with the
        // player's chosen graphics quality (30 fps full / 15 fps optimized).
        let isFull = GraphicsSettings.shared.isFull
        let timelineInterval: Double = isFull ? (1.0 / 30.0) : (1.0 / 15.0)
        TimelineView(.animation(minimumInterval: timelineInterval, paused: false)) { ctx in
            let now = ctx.date.timeIntervalSinceReferenceDate
            let pulse = (sin(now * 1.4) + 1) * 0.5            // 0..1, slow breathe
            let rotation = (now.truncatingRemainder(dividingBy: 6)) * 60.0 // continuous spin
            // "Charged super shot" cadence — every ~4 seconds a brief
            // flash builds and discharges, signalling a powered attack.
            let chargePhase = (now.truncatingRemainder(dividingBy: 4)) / 4.0  // 0..1
            let chargeFlash = max(0, chargePhase - 0.85) / 0.15               // 0..1 last 15%

            ZStack {
                // Selection outline.
                if selected {
                    Circle()
                        .stroke(ac.opacity(0.6), lineWidth: 2)
                        .frame(width: 60, height: 60)
                }

                // Tier 2+ — slow rotating outer glow ring. Subtle for T2,
                // brighter dashed ring for T3, double-ring for T4. Heavy
                // effects (.plusLighter blend, glow shadows) only render
                // in FULL graphics mode.
                if tower.tier >= 2 {
                    let ring = Circle()
                        .stroke(ac.opacity(0.4 + 0.15 * pulse),
                                style: StrokeStyle(lineWidth: 1.0,
                                                   dash: [4, 3]))
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(rotation))
                    if isFull {
                        ring.blendMode(.plusLighter)
                    } else {
                        ring
                    }
                }
                if tower.tier >= 3 {
                    let ring = Circle()
                        .stroke(ac.opacity(0.55 + 0.20 * pulse),
                                style: StrokeStyle(lineWidth: 1.4,
                                                   dash: [6, 4]))
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-rotation * 0.65))
                    if isFull {
                        ring
                            .shadow(color: ac.opacity(0.5), radius: 3)
                            .blendMode(.plusLighter)
                    } else {
                        ring
                    }
                }
                if tower.tier >= 4 {
                    // T4 — divine halo + 4 orbiting sparks.
                    let halo = Circle()
                        .stroke(ac.opacity(0.85),
                                style: StrokeStyle(lineWidth: 1.6))
                        .frame(width: 72, height: 72)
                        .scaleEffect(1.0 + 0.04 * pulse)
                    if isFull {
                        halo
                            .shadow(color: ac, radius: 6)
                            .blendMode(.plusLighter)
                    } else {
                        halo
                    }
                    ForEach(0..<4, id: \.self) { i in
                        let spark = Circle()
                            .fill(ac)
                            .frame(width: 4, height: 4)
                            .offset(x: cos(rotation * .pi / 180 + Double(i) * .pi / 2) * 38,
                                    y: sin(rotation * .pi / 180 + Double(i) * .pi / 2) * 38)
                        if isFull {
                            spark
                                .shadow(color: ac, radius: 3)
                                .blendMode(.plusLighter)
                        } else {
                            spark
                        }
                    }
                }

                // Charged super-shot indicator — kept (cheap radial
                // gradient, no shadow).
                if tower.tier >= 2 {
                    Circle()
                        .fill(RadialGradient(colors: [
                            ac.opacity(0.7 * chargeFlash * Double(tower.tier - 1)),
                            ac.opacity(0)
                        ], center: .center, startRadius: 0, endRadius: 36))
                        .frame(width: 72, height: 72)
                        .allowsHitTesting(false)
                }

                // Unique per-astra art (changes completely per tier).
                AstraTowerArt(tower: tower)
                    .scaleEffect(1.0 + 0.06 * chargeFlash * Double(tower.tier - 1))

                // Per-astra idle animation — each named astra layers a
                // signature visual on top of the base art so every tower
                // reads as alive in its own way (Sudarshana spins, Agneya
                // flickers, Naga coils, etc.).
                astraIdleAnimation(now: now, pulse: pulse, rotation: rotation)
                    .allowsHitTesting(false)

                // Stone glow (if equipped) — orbit the level dots so it
                // reads as "a stone is socketed in this tower". Shadow
                // only in FULL graphics mode.
                if let stone = tower.stone {
                    let ring = Circle()
                        .stroke(stone.kind.color.opacity(0.6 + 0.3 * pulse),
                                style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(rotation * 0.5))
                    if isFull {
                        ring.shadow(color: stone.kind.color, radius: 3)
                    } else {
                        ring
                    }
                    HStack(spacing: 1.5) {
                        ForEach(0..<stone.level, id: \.self) { _ in
                            let dot = Circle()
                                .fill(stone.kind.color)
                                .frame(width: 4, height: 4)
                            if isFull {
                                dot.shadow(color: stone.kind.color, radius: 2)
                            } else {
                                dot
                            }
                        }
                    }
                    .offset(x: 22, y: -22)
                }

                // (Tier badge removed — the player can already read tier
                // from the surrounding rings: T2 single dashed ring, T3
                // double-ring, T4 halo + orbit sparks. No need for the
                // Roman-numeral chip cluttering each tower.)

                // HP bar — ALWAYS visible above the tower so the player
                // can read each defender's health at a glance, not just
                // the wounded ones.
                hpBar
                    .frame(width: 36, height: 3)
                    .offset(y: -32)
            }
            // Render the tower content at its native size, then scale the
            // whole thing down on iPhone so the tower frame matches the
            // tighter slot grid (42 px vs 60 px). iPad / Mac unchanged.
            .scaleEffect(visualScale)
            .frame(width: frameSize, height: frameSize)
            // (No drawingGroup here — it was clipping the HP bar, tier
            // badge, and stone dots that offset outside the 60×60 frame.
            // The 15 fps cadence + lighter materials below give us most
            // of the performance win without losing detail.)
        }
    }

    /// Per-astra idle animation layered on top of the base AstraTowerArt.
    /// Each named astra renders its own signature motion (spin, flicker,
    /// ripple, coil, gleam) so every tower on the field reads as unique.
    @ViewBuilder
    private func astraIdleAnimation(now: TimeInterval, pulse: Double, rotation: Double) -> some View {
        let c = tower.kind.color
        switch tower.kind {

        // ─── Arrow path ─────────────────────────────────────────────
        case .dart:
            // Simple aiming reticle — tiny gold crosshair spinning slowly
            ForEach(0..<4, id: \.self) { i in
                Rectangle()
                    .fill(c.opacity(0.45))
                    .frame(width: 1, height: 5)
                    .offset(y: -12)
                    .rotationEffect(.degrees(Double(i) * 90 + rotation * 0.3))
            }
        case .aindrastra:
            // Indra's lightning crackle — random thunder arc
            Path { p in
                let phase = sin(now * 8)
                p.move(to: CGPoint(x: -10, y: -12))
                p.addLine(to: CGPoint(x: CGFloat(-4 + phase * 3), y: -6))
                p.addLine(to: CGPoint(x: CGFloat(6 - phase * 2), y: -2))
                p.addLine(to: CGPoint(x: 10, y: 8))
            }
            .stroke(c.opacity(0.6 + 0.3 * abs(sin(now * 8))),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            .shadow(color: c, radius: 3)
            .blendMode(.plusLighter)
        case .shaktiAstra:
            // Karna's spear gleam — diagonal light streak
            Capsule()
                .fill(LinearGradient(colors: [c.opacity(0), .white, c.opacity(0)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 24, height: 2)
                .rotationEffect(.degrees(-45 + sin(now * 1.2) * 5))
                .offset(y: -2)
                .opacity(0.5 + 0.4 * pulse)
                .blendMode(.plusLighter)
        case .sudarshanaChakra:
            // Vishnu's discus — fast continuous spin overlay
            ForEach(0..<6, id: \.self) { i in
                Rectangle()
                    .fill(c.opacity(0.45))
                    .frame(width: 14, height: 1.5)
                    .rotationEffect(.degrees(Double(i) * 30 + now * 480))
            }
            .blendMode(.plusLighter)
            Circle()
                .stroke(c.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                .frame(width: 22, height: 22)
                .rotationEffect(.degrees(now * -160))
                .blendMode(.plusLighter)

        // ─── Fire path ──────────────────────────────────────────────
        case .agneyastra:
            // Agni's flame flicker — wobble + vertical shimmer
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: "flame.fill")
                    .font(.system(size: CGFloat(6 - i)))
                    .foregroundColor(Color.orange.opacity(0.75 - Double(i) * 0.2))
                    .offset(x: sin(now * 6 + Double(i)) * 2,
                            y: CGFloat(-9 - i * 3) + sin(now * 4 + Double(i)) * 1.5)
                    .blendMode(.plusLighter)
            }
        case .suryastra:
            // Surya's radiant rays — sun rays pulsing outward
            ForEach(0..<8, id: \.self) { i in
                Rectangle()
                    .fill(LinearGradient(colors: [c.opacity(0), c.opacity(0.6 + 0.3 * pulse)],
                                         startPoint: .center, endPoint: .top))
                    .frame(width: 1.2, height: CGFloat(8 + 3 * pulse))
                    .offset(y: -14)
                    .rotationEffect(.degrees(Double(i) * 45 + rotation * 0.2))
                    .blendMode(.plusLighter)
            }
        case .rudraAstra:
            // Rudra's wrath flame — pulsing ember halo
            Circle()
                .fill(RadialGradient(colors: [.red.opacity(0.6 + 0.3 * pulse), .clear],
                                     center: .center, startRadius: 0, endRadius: 18))
                .frame(width: 36, height: 36)
                .blendMode(.plusLighter)
            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .fill(Color.orange.opacity(0.7))
                    .frame(width: 2, height: 2)
                    .offset(x: cos(now * 2 + Double(i) * 1.25) * 14,
                            y: sin(now * 2 + Double(i) * 1.25) * 14)
                    .blendMode(.plusLighter)
            }
        case .brahmashirsha:
            // Brahmastra inferno — multi-headed dark fire crown
            ForEach(0..<5, id: \.self) { i in
                Image(systemName: "flame.fill")
                    .font(.system(size: 6 + CGFloat(pulse) * 2))
                    .foregroundColor(c.opacity(0.85))
                    .shadow(color: c, radius: 3)
                    .offset(x: cos(Double(i) * .pi / 2.5 - .pi / 2) * 16,
                            y: sin(Double(i) * .pi / 2.5 - .pi / 2) * 16)
                    .blendMode(.plusLighter)
            }

        // ─── Water path ─────────────────────────────────────────────
        case .varunastra:
            // Varuna's ripple — expanding rings
            ForEach(0..<2, id: \.self) { i in
                let phase = (now + Double(i) * 0.6).truncatingRemainder(dividingBy: 1.2) / 1.2
                Circle()
                    .stroke(Color.cyan.opacity(0.7 * (1 - phase)), lineWidth: 1.2)
                    .frame(width: 12 + 18 * CGFloat(phase), height: 12 + 18 * CGFloat(phase))
                    .blendMode(.plusLighter)
            }
        case .nagaPasha:
            // Naga Pasha — coiling serpent line
            Path { p in
                let amp = 6.0 * (0.6 + 0.4 * sin(now * 2))
                p.move(to: CGPoint(x: -14, y: 0))
                for i in 0..<28 {
                    let t = Double(i) / 27.0
                    let x = -14 + 28 * t
                    let y = sin(t * .pi * 3 + now * 4) * amp
                    p.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(c.opacity(0.75), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
            .shadow(color: c, radius: 3)
            .blendMode(.plusLighter)
        case .garudastra:
            // Garuda's wings — wing flap motion
            ForEach([-1, 1], id: \.self) { sign in
                Path { p in
                    let flap = 4 + sin(now * 4) * 3
                    p.move(to: CGPoint(x: 0, y: -2))
                    p.addQuadCurve(to: CGPoint(x: CGFloat(sign) * 16, y: -CGFloat(flap)),
                                   control: CGPoint(x: CGFloat(sign) * 10, y: -CGFloat(flap) * 0.5))
                }
                .stroke(c.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .shadow(color: c, radius: 2)
                .blendMode(.plusLighter)
            }

        // ─── Ice path ───────────────────────────────────────────────
        case .sheetastra:
            // Sheetastra — crystal sparkle
            ForEach(0..<4, id: \.self) { i in
                Image(systemName: "snowflake")
                    .font(.system(size: CGFloat(4 + (i % 2) * 2)))
                    .foregroundColor(Color.cyan.opacity(0.6 + 0.3 * abs(sin(now * 2 + Double(i)))))
                    .offset(x: cos(Double(i) * .pi / 2 + now * 0.7) * 12,
                            y: sin(Double(i) * .pi / 2 + now * 0.7) * 12)
                    .blendMode(.plusLighter)
            }
        case .twashtar:
            // Twashtar — triple crystal floating
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: "diamond.fill")
                    .font(.system(size: 5))
                    .foregroundColor(Color(red: 0.6, green: 0.85, blue: 1.0).opacity(0.85))
                    .offset(x: cos(Double(i) * .pi * 2 / 3 + now * 1.2) * 13,
                            y: sin(Double(i) * .pi * 2 / 3 + now * 1.2) * 13 - 2)
                    .shadow(color: .cyan, radius: 2)
                    .blendMode(.plusLighter)
            }
        case .mohiniAstra:
            // Mohini enchantment — vortex swirls
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .trim(from: 0.2, to: 0.8)
                    .stroke(c.opacity(0.55), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                    .frame(width: CGFloat(14 + i * 5), height: CGFloat(14 + i * 5))
                    .rotationEffect(.degrees(now * 80 + Double(i) * 60))
                    .blendMode(.plusLighter)
            }

        // ─── Divine path ────────────────────────────────────────────
        case .trishul:
            // Shiva's trident — golden gleam pulse at the prong tips
            ForEach([-1.0, 0.0, 1.0], id: \.self) { off in
                Circle()
                    .fill(c.opacity(0.6 + 0.4 * pulse))
                    .frame(width: 3, height: 3)
                    .offset(x: CGFloat(off) * 5, y: -14)
                    .shadow(color: c, radius: 3)
                    .blendMode(.plusLighter)
            }
        case .vajrastra:
            // Vajra — sporadic thunderbolt arc + flickering glow
            Path { p in
                p.move(to: CGPoint(x: -8, y: -10))
                p.addLine(to: CGPoint(x: -3, y: -4))
                p.addLine(to: CGPoint(x: 4, y: -6))
                p.addLine(to: CGPoint(x: 8, y: 4))
            }
            .stroke(.white.opacity(0.4 + 0.5 * abs(sin(now * 12))),
                    style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
            .shadow(color: c, radius: 3)
            .blendMode(.plusLighter)
        case .narayanaAstra:
            // Narayanastra — orbiting arrow ghosts
            ForEach(0..<5, id: \.self) { i in
                Capsule()
                    .fill(c.opacity(0.55))
                    .frame(width: 6, height: 1.4)
                    .offset(x: cos(Double(i) * .pi * 2 / 5 + now * 1.5) * 14,
                            y: sin(Double(i) * .pi * 2 / 5 + now * 1.5) * 14)
                    .rotationEffect(.degrees(Double(i) * 72 + now * 80))
                    .blendMode(.plusLighter)
            }
        case .pashupatastra:
            // Pashupatastra — divine third-eye watching
            Circle()
                .fill(c.opacity(0.6 + 0.4 * pulse))
                .frame(width: 6, height: 6)
                .overlay(Circle().stroke(.white.opacity(0.85), lineWidth: 1))
                .shadow(color: c, radius: 6)
                .offset(y: -2)
                .scaleEffect(1.0 + 0.3 * pulse)
                .blendMode(.plusLighter)

        // ─── Sensory path ───────────────────────────────────────────
        case .bala, .atibala, .divyaDrishti:
            // Sensory eyes — slow blink + scanning glint
            Circle()
                .fill(c.opacity(0.5 + 0.4 * (sin(now * 1.5) * 0.5 + 0.5)))
                .frame(width: 4, height: 4)
                .offset(y: -2)
                .blendMode(.plusLighter)

        // ─── Healer path ────────────────────────────────────────────
        case .aushadhi, .sanjivaniBooti, .amritKalash:
            // Healer halo — soft green pulse + drifting plus signs
            Circle()
                .fill(c.opacity(0.25 + 0.15 * pulse))
                .frame(width: 32, height: 32)
                .blendMode(.plusLighter)
            ForEach(0..<3, id: \.self) { i in
                let phase = (now + Double(i) * 0.4).truncatingRemainder(dividingBy: 1.6) / 1.6
                Image(systemName: "plus")
                    .font(.system(size: 6, weight: .heavy))
                    .foregroundColor(c.opacity(1 - phase))
                    .offset(y: -CGFloat(phase) * 16)
            }

        // ─── Barrier path ───────────────────────────────────────────
        case .surakshaRekha, .lakshmanRekha, .vajraKavach:
            // Barrier shimmer — rotating hexagonal aura
            ForEach(0..<6, id: \.self) { i in
                Rectangle()
                    .fill(c.opacity(0.5))
                    .frame(width: 2, height: 8)
                    .offset(y: -10)
                    .rotationEffect(.degrees(Double(i) * 60 + rotation * 0.4))
                    .blendMode(.plusLighter)
            }

        // ─── Maya path (illusion / divine arrows) ───────────────────
        case .mayaAstra:
            // Maya — shimmering afterimage ghosts that fade in/out
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .stroke(c.opacity(0.4 * abs(sin(now * 1.5 + Double(i) * 0.6))),
                            lineWidth: 1)
                    .frame(width: CGFloat(10 + i * 5), height: CGFloat(10 + i * 5))
                    .blendMode(.plusLighter)
            }
        case .gangaAstra:
            // Ganga — flowing river ripple streams
            ForEach(0..<2, id: \.self) { i in
                Path { p in
                    let yc = CGFloat(-6 + i * 12)
                    let amp = 4.0 + sin(now * 2) * 1.5
                    p.move(to: CGPoint(x: -14, y: yc))
                    for j in 0..<24 {
                        let t = Double(j) / 23.0
                        let x = -14 + 28 * t
                        let y = yc + sin(t * .pi * 4 + now * 3) * amp
                        p.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(Color.cyan.opacity(0.55), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                .blendMode(.plusLighter)
            }
        case .anjalikaAstra:
            // Anjalika — radiating spear tips around the tower
            ForEach(0..<6, id: \.self) { i in
                Capsule()
                    .fill(c.opacity(0.6 + 0.3 * pulse))
                    .frame(width: 8, height: 1.6)
                    .offset(x: 14)
                    .rotationEffect(.degrees(Double(i) * 60 + rotation * 0.5))
                    .blendMode(.plusLighter)
            }
        case .brahmasiraAstra:
            // Brahmasira (Maya T4) — divine apocalyptic crown
            ForEach(0..<6, id: \.self) { i in
                Image(systemName: "star.fill")
                    .font(.system(size: 5 + CGFloat(pulse) * 2))
                    .foregroundColor(c.opacity(0.85))
                    .shadow(color: c, radius: 3)
                    .offset(x: cos(Double(i) * .pi / 3 + now * 0.6) * 16,
                            y: sin(Double(i) * .pi / 3 + now * 0.6) * 16)
                    .blendMode(.plusLighter)
            }
        }
    }

    private var romanTier: String {
        switch tower.tier {
        case 1: return "I"
        case 2: return "II"
        case 3: return "III"
        case 4: return "IV"
        default: return ""
        }
    }

    private var hpBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.7))
                Capsule()
                    .fill(tower.hp / tower.maxHP > 0.5 ? Color.green :
                            tower.hp / tower.maxHP > 0.25 ? Color.yellow : Color.red)
                    .frame(width: max(0, geo.size.width * CGFloat(tower.hp / tower.maxHP)))
            }
        }
    }
}

// MARK: - Eye/Sensory Tower Shape

struct EyeTowerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        // Slender pillar
        p.addRect(CGRect(x: w * 0.40, y: h * 0.35, width: w * 0.20, height: h * 0.60))
        // Large eye at top
        p.addEllipse(in: CGRect(x: w * 0.18, y: h * 0.10, width: w * 0.64, height: h * 0.35))
        // Iris (smaller dark circle inside)
        p.addEllipse(in: CGRect(x: w * 0.35, y: h * 0.20, width: w * 0.30, height: h * 0.16))
        // Base
        p.addRect(CGRect(x: w * 0.20, y: h * 0.90, width: w * 0.60, height: h * 0.10))
        return p
    }
}

// MARK: - Building Shapes (5 kinds)

struct GoldMineShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        // Mountain triangle
        p.move(to: CGPoint(x: 0, y: h * 0.95))
        p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.08))
        p.addLine(to: CGPoint(x: w, y: h * 0.95))
        p.closeSubpath()
        // Inner snow cap
        p.move(to: CGPoint(x: w * 0.40, y: h * 0.25))
        p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.10))
        p.addLine(to: CGPoint(x: w * 0.60, y: h * 0.25))
        p.addLine(to: CGPoint(x: w * 0.55, y: h * 0.32))
        p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.22))
        p.addLine(to: CGPoint(x: w * 0.45, y: h * 0.32))
        p.closeSubpath()
        return p
    }
}

struct FoundryShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        // House base
        p.addRect(CGRect(x: w * 0.12, y: h * 0.50, width: w * 0.76, height: h * 0.45))
        // Roof
        p.move(to: CGPoint(x: w * 0.10, y: h * 0.52))
        p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.22))
        p.addLine(to: CGPoint(x: w * 0.90, y: h * 0.52))
        p.closeSubpath()
        // Chimney
        p.addRect(CGRect(x: w * 0.65, y: h * 0.10, width: w * 0.14, height: h * 0.28))
        return p
    }
}

struct TechLabShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        // Tall building
        p.addRect(CGRect(x: w * 0.18, y: h * 0.25, width: w * 0.64, height: h * 0.70))
        // Antenna mast
        p.addRect(CGRect(x: w * 0.48, y: h * 0.02, width: w * 0.04, height: h * 0.25))
        // Antenna disc
        p.addEllipse(in: CGRect(x: w * 0.40, y: 0, width: w * 0.20, height: h * 0.10))
        return p
    }
}

struct ObservatoryShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        // Base building
        p.addRect(CGRect(x: w * 0.08, y: h * 0.55, width: w * 0.84, height: h * 0.40))
        // Dome (half circle)
        p.move(to: CGPoint(x: w * 0.20, y: h * 0.55))
        p.addArc(center: CGPoint(x: w * 0.50, y: h * 0.55),
                 radius: w * 0.30,
                 startAngle: .degrees(180),
                 endAngle: .degrees(0),
                 clockwise: false)
        p.closeSubpath()
        // Telescope slit
        p.addRect(CGRect(x: w * 0.46, y: h * 0.30, width: w * 0.08, height: h * 0.25))
        return p
    }
}

struct GurukulShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        // Stepped temple roof (3 levels)
        for i in 0..<3 {
            let y = h * (0.10 + CGFloat(i) * 0.10)
            let widthScale = 0.25 + CGFloat(i) * 0.18
            let x = (w - w * widthScale) / 2
            p.addRect(CGRect(x: x, y: y, width: w * widthScale, height: h * 0.08))
        }
        // Base with pillars
        p.addRect(CGRect(x: w * 0.10, y: h * 0.45, width: w * 0.80, height: h * 0.50))
        // Pillar dividers (vertical lines inside as cutouts via thin rects in fill)
        return p
    }
}

/// Parijata Briksha — the divine wish-tree. A leafy three-lobed crown sits
/// atop a slender trunk, distinguishing it from the boxy production buildings.
struct ParijataShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        // Trunk
        p.addRect(CGRect(x: w * 0.44, y: h * 0.55, width: w * 0.12, height: h * 0.40))
        // Three-lobed canopy
        p.addEllipse(in: CGRect(x: w * 0.10, y: h * 0.18, width: w * 0.50, height: h * 0.50))
        p.addEllipse(in: CGRect(x: w * 0.40, y: h * 0.18, width: w * 0.50, height: h * 0.50))
        p.addEllipse(in: CGRect(x: w * 0.25, y: h * 0.05, width: w * 0.50, height: h * 0.50))
        return p
    }
}

// MARK: - Building Art View

struct BuildingArtView: View {
    let building: Building
    let selected: Bool

    var body: some View {
        let c = building.kind.color

        ZStack {
            if selected {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(c.opacity(0.6), lineWidth: 2)
                    .frame(width: 54, height: 54)
            }

            ZStack {
                AssetImageOr(assetName: AssetName.building(building.kind)) {
                    vectorBody
                }

                // Resource icon
                ZStack {
                    Circle().fill(building.kind.resource.color)
                        .frame(width: 16, height: 16)
                    Circle().stroke(Color.white.opacity(0.85), lineWidth: 1)
                        .frame(width: 16, height: 16)
                    Image(systemName: building.kind.resource.symbol)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: 14, y: -16)
            }
            .frame(width: 46, height: 50)

            // Level pips
            HStack(spacing: 2) {
                ForEach(0..<building.level, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(c)
                        .frame(width: 5, height: 3)
                }
            }
            .offset(y: 26)
        }
        .frame(width: 56, height: 60)
    }

    private var kindShape: AnyShape {
        switch building.kind {
        case .goldMine:           return AnyShape(GoldMineShape())
        case .metalFoundry:       return AnyShape(FoundryShape())
        case .techLab:            return AnyShape(TechLabShape())
        case .jotishaObservatory: return AnyShape(ObservatoryShape())
        case .vedaGurukul:        return AnyShape(GurukulShape())
        case .parijata:           return AnyShape(ParijataShape())
        }
    }

    private var vectorBody: some View {
        let c = building.kind.color
        let scale: CGFloat = 1.0 + CGFloat(building.level - 1) * 0.10  // L1=1.0, L2=1.1, L3=1.2
        return ZStack {
            // Glowing aura at L2+ (sign of upgraded building)
            if building.level >= 2 {
                Circle()
                    .fill(RadialGradient(colors: [c.opacity(0.3), .clear],
                                         center: .center, startRadius: 4, endRadius: 28))
                    .frame(width: 52, height: 52)
            }

            kindShape
                .fill(LinearGradient(
                    colors: [c.opacity(0.95), c.opacity(0.45)],
                    startPoint: .top, endPoint: .bottom
                ))
                .scaleEffect(scale)
            kindShape
                .stroke(c, lineWidth: 1.2 + CGFloat(building.level - 1) * 0.4)
                .scaleEffect(scale)
            kindDetails

            // L2 decorations: side flags / banners
            if building.level >= 2 {
                Triangle()
                    .fill(c)
                    .frame(width: 4, height: 6)
                    .offset(x: -16, y: -16)
                Triangle()
                    .fill(c)
                    .frame(width: 4, height: 6)
                    .offset(x: 16, y: -16)
            }

            // L3 decorations: gold crown / royal trim
            if building.level >= 3 {
                // Golden crown on top
                Path { p in
                    p.move(to: CGPoint(x: -10, y: 0))
                    p.addLine(to: CGPoint(x: -10, y: -3))
                    p.addLine(to: CGPoint(x: -6, y: -6))
                    p.addLine(to: CGPoint(x: -2, y: -3))
                    p.addLine(to: CGPoint(x: 0, y: -6))
                    p.addLine(to: CGPoint(x: 2, y: -3))
                    p.addLine(to: CGPoint(x: 6, y: -6))
                    p.addLine(to: CGPoint(x: 10, y: -3))
                    p.addLine(to: CGPoint(x: 10, y: 0))
                    p.closeSubpath()
                }
                .fill(LinearGradient(colors: [.yellow, .orange],
                                     startPoint: .top, endPoint: .bottom))
                .shadow(color: .yellow, radius: 3)
                .offset(y: -26)
                // Sparkles
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: "sparkle")
                        .font(.system(size: 6))
                        .foregroundColor(.yellow)
                        .offset(x: CGFloat(i - 1) * 18, y: CGFloat(i % 2 == 0 ? -22 : 22))
                }
            }
        }
    }

    @ViewBuilder
    private var kindDetails: some View {
        switch building.kind {
        case .goldMine:
            // Dark cave entrance
            Capsule()
                .fill(Color.black.opacity(0.6))
                .frame(width: 10, height: 12)
                .offset(y: 14)
        case .metalFoundry:
            // Smoke puff
            Circle()
                .fill(Color.gray.opacity(0.6))
                .frame(width: 8, height: 8)
                .offset(x: 8, y: -22)
        case .techLab:
            // Lit windows
            VStack(spacing: 2) {
                Rectangle().fill(Color.cyan.opacity(0.9)).frame(width: 4, height: 3)
                Rectangle().fill(Color.cyan.opacity(0.9)).frame(width: 4, height: 3)
            }
            .offset(y: 0)
        case .jotishaObservatory:
            // Star inside dome
            Image(systemName: "sparkles")
                .font(.system(size: 8))
                .foregroundColor(.yellow)
                .offset(y: -8)
        case .vedaGurukul:
            // Sacred Om-like symbol
            Image(systemName: "book.closed.fill")
                .font(.system(size: 9))
                .foregroundColor(Color.white.opacity(0.85))
                .offset(y: 6)
        case .parijata:
            // Glowing golden bloom — the wish-tree's signature
            Image(systemName: "sparkles")
                .font(.system(size: 11))
                .foregroundColor(.yellow)
                .shadow(color: .yellow.opacity(0.8), radius: 3)
                .offset(y: -6)
        }
    }
}

// MARK: - Enemy Art (compound shapes for distinct silhouettes)

struct EnemyArtView: View {
    let enemy: Enemy

    var body: some View {
        let s = enemy.kind.radius * 2
        let c = enemy.kind.color

        ZStack {
            AssetImageOr(assetName: AssetName.enemy(enemy.kind)) {
                silhouette(size: s, color: c)
            }
            .frame(width: s + 8, height: s + 8)
        }
    }

    @ViewBuilder
    private func silhouette(size: CGFloat, color: Color) -> some View {
        switch enemy.kind {
        case .pishacha:       PishachaArt(size: size, color: color)
        case .rakshasa:       RakshasaArt(size: size, color: color)
        case .daitya:         DaityaArt(size: size, color: color)
        case .asura:          AsuraArt(size: size, color: color)
        case .vetala:         VetalaArt(size: size, color: color)
        case .mahishasura:    MahishasuraArt(size: size, color: color)
        case .ravana:         RavanaArt(size: size, color: color)
        case .mayavi:         MayaviArt(size: size, color: color)
        case .indrajit:       IndrajitArt(size: size, color: color)
        case .lobhaYaksha:    ResourceBearerArt(size: size, color: color, badge: "dollarsign.circle.fill", badgeColor: .yellow)
        case .lohaAsura:      ResourceBearerArt(size: size, color: color, badge: "gearshape.fill", badgeColor: Color(red: 0.85, green: 0.85, blue: 0.9))
        case .yantraPishacha: ResourceBearerArt(size: size, color: color, badge: "cpu.fill", badgeColor: .cyan)
        case .taraDevi:       ResourceBearerArt(size: size, color: color, badge: "moon.stars.fill", badgeColor: .purple)
        case .rishiAtma:      ResourceBearerArt(size: size, color: color, badge: "book.closed.fill", badgeColor: .orange)
        case .maniMurta:      ResourceBearerArt(size: size, color: color, badge: "diamond.fill",    badgeColor: Color(red: 0.95, green: 0.55, blue: 0.85))
        case .raktabija:      SpecialistEnemyArt(size: size, color: color, badge: "drop.fill",                badgeColor: .red,    halo: true)
        case .tarakasura:     SpecialistEnemyArt(size: size, color: color, badge: "shield.lefthalf.filled",  badgeColor: Color(red: 0.95, green: 0.50, blue: 0.10), halo: false)
        case .bhasmasura:     SpecialistEnemyArt(size: size, color: color, badge: "flame.fill",              badgeColor: .orange, halo: true)
        case .vritra:         SpecialistEnemyArt(size: size, color: color, badge: "cloud.bolt.rain.fill",    badgeColor: .cyan,   halo: false)
        case .putana:         SpecialistEnemyArt(size: size, color: color, badge: "leaf.fill",               badgeColor: .green,  halo: true)
        case .kaliYuga:      SpecialistEnemyArt(size: size, color: color, badge: "crown.fill",              badgeColor: .red,    halo: true)
        }
    }
}

/// Compact silhouette for the new specialist demons (Raktabija, Tarakasura,
/// Bhasmasura, Vritra, Putana). A jagged hexagonal body + glowing SF Symbol
/// badge identifies the immunity profile at a glance.
struct SpecialistEnemyArt: View {
    let size: CGFloat
    let color: Color
    let badge: String
    let badgeColor: Color
    /// If true, draw a pulsing aura ring to signal heavy regen or special trait.
    let halo: Bool

    var body: some View {
        ZStack {
            if halo {
                Circle()
                    .stroke(badgeColor.opacity(0.6), style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                    .frame(width: size + 8, height: size + 8)
            }
            // Hex body
            Path { p in
                let r = size * 0.48
                for i in 0..<6 {
                    let a = .pi / 3.0 * Double(i) - .pi / 2
                    let x = r * CGFloat(cos(a)) + size / 2
                    let y = r * CGFloat(sin(a)) + size / 2
                    if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                    else      { p.addLine(to: CGPoint(x: x, y: y)) }
                }
                p.closeSubpath()
            }
            .fill(
                RadialGradient(colors: [color.opacity(0.95), color.opacity(0.55)],
                               center: .center, startRadius: 1, endRadius: size * 0.5)
            )
            .overlay(
                Path { p in
                    let r = size * 0.48
                    for i in 0..<6 {
                        let a = .pi / 3.0 * Double(i) - .pi / 2
                        let x = r * CGFloat(cos(a)) + size / 2
                        let y = r * CGFloat(sin(a)) + size / 2
                        if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                        else      { p.addLine(to: CGPoint(x: x, y: y)) }
                    }
                    p.closeSubpath()
                }
                .stroke(badgeColor.opacity(0.85), lineWidth: 1.5)
            )
            // Badge
            Image(systemName: badge)
                .font(.system(size: size * 0.45, weight: .heavy))
                .foregroundColor(badgeColor)
                .shadow(color: badgeColor.opacity(0.7), radius: 3)
        }
        .frame(width: size, height: size)
    }
}

// Resource bearer — robed figure with legs + hands holding a glowing chest with the resource icon
struct ResourceBearerArt: View {
    let size: CGFloat
    let color: Color
    let badge: String
    let badgeColor: Color

    var body: some View {
        ZStack {
            // Dashed halo signaling "kill me for big reward"
            Circle()
                .stroke(badgeColor.opacity(0.7), style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                .frame(width: size + 8, height: size + 8)
                .shadow(color: badgeColor.opacity(0.5), radius: 3)
            // Two legs poking out of robe
            Capsule().fill(color.opacity(0.7))
                .frame(width: size * 0.10, height: size * 0.20)
                .offset(x: -size * 0.12, y: size * 0.48)
            Capsule().fill(color.opacity(0.7))
                .frame(width: size * 0.10, height: size * 0.20)
                .offset(x: size * 0.12, y: size * 0.48)
            // Robed body (flowing cloak)
            Path { p in
                p.move(to: CGPoint(x: -size * 0.42, y: size * 0.45))
                p.addLine(to: CGPoint(x: -size * 0.32, y: -size * 0.05))
                p.addQuadCurve(to: CGPoint(x: size * 0.32, y: -size * 0.05),
                               control: CGPoint(x: 0, y: -size * 0.28))
                p.addLine(to: CGPoint(x: size * 0.42, y: size * 0.45))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [color.opacity(0.85), color.opacity(0.4)],
                                 startPoint: .top, endPoint: .bottom))
            .shadow(color: color.opacity(0.5), radius: 3)
            // Robe trim (gold band)
            Path { p in
                p.move(to: CGPoint(x: -size * 0.42, y: size * 0.43))
                p.addLine(to: CGPoint(x: size * 0.42, y: size * 0.43))
            }
            .stroke(badgeColor, lineWidth: 1.5)
            // Two arms (clutching chest in front)
            Capsule().fill(color.opacity(0.85))
                .frame(width: size * 0.08, height: size * 0.22)
                .rotationEffect(.degrees(-35), anchor: .top)
                .offset(x: -size * 0.20, y: size * 0.05)
            Capsule().fill(color.opacity(0.85))
                .frame(width: size * 0.08, height: size * 0.22)
                .rotationEffect(.degrees(35), anchor: .top)
                .offset(x: size * 0.20, y: size * 0.05)
            // Glowing treasure chest in front (held by both hands)
            ZStack {
                // Glow behind chest
                RoundedRectangle(cornerRadius: 4)
                    .fill(badgeColor.opacity(0.4))
                    .frame(width: size * 0.62, height: size * 0.45)
                    .shadow(color: badgeColor, radius: 5)
                // Chest body
                RoundedRectangle(cornerRadius: 3)
                    .fill(LinearGradient(colors: [Color(red: 0.65, green: 0.45, blue: 0.20),
                                                  Color(red: 0.30, green: 0.20, blue: 0.10)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: size * 0.55, height: size * 0.40)
                // Gold trim
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color(red: 0.95, green: 0.75, blue: 0.20), lineWidth: 1.5)
                    .frame(width: size * 0.55, height: size * 0.40)
                // Lid divider
                Rectangle().fill(Color(red: 0.95, green: 0.75, blue: 0.20))
                    .frame(width: size * 0.55, height: 1)
                    .offset(y: -size * 0.06)
                // Big badge icon (resource)
                Image(systemName: badge)
                    .font(.system(size: size * 0.28, weight: .bold))
                    .foregroundColor(badgeColor)
                    .shadow(color: badgeColor, radius: 3)
                    .offset(y: size * 0.03)
                // Lock keyhole
                Circle().fill(Color.black).frame(width: 3, height: 3)
                    .offset(y: -size * 0.08)
            }
            .offset(y: size * 0.15)
            // Hood
            Path { p in
                p.move(to: CGPoint(x: -size * 0.22, y: -size * 0.10))
                p.addQuadCurve(to: CGPoint(x: size * 0.22, y: -size * 0.10),
                               control: CGPoint(x: 0, y: -size * 0.42))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [color, color.opacity(0.7)],
                                 startPoint: .top, endPoint: .bottom))
            // Shadowed face inside hood
            Path { p in
                p.move(to: CGPoint(x: -size * 0.16, y: -size * 0.10))
                p.addQuadCurve(to: CGPoint(x: size * 0.16, y: -size * 0.10),
                               control: CGPoint(x: 0, y: -size * 0.32))
                p.closeSubpath()
            }
            .fill(Color.black.opacity(0.75))
            // Glowing eyes
            HStack(spacing: size * 0.10) {
                Circle().fill(badgeColor).frame(width: 3, height: 3)
                    .shadow(color: badgeColor, radius: 2)
                Circle().fill(badgeColor).frame(width: 3, height: 3)
                    .shadow(color: badgeColor, radius: 2)
            }
            .offset(y: -size * 0.18)
        }
    }
}

// Invisible scout — cloaked sneak with peeking legs + shimmering aura
struct MayaviArt: View {
    let size: CGFloat
    let color: Color
    var body: some View {
        ZStack {
            // Shimmering distortion aura behind
            Circle()
                .fill(RadialGradient(colors: [color.opacity(0.35), .clear],
                                     center: .center, startRadius: 4, endRadius: size * 0.55))
                .frame(width: size * 1.1, height: size * 1.1)
            // Two thin legs (just peeking from cloak)
            Capsule().fill(color.opacity(0.75))
                .frame(width: size * 0.06, height: size * 0.18)
                .offset(x: -size * 0.10, y: size * 0.45)
            Capsule().fill(color.opacity(0.75))
                .frame(width: size * 0.06, height: size * 0.18)
                .offset(x: size * 0.10, y: size * 0.45)
            // Cloak — wide triangular hood + body
            Path { p in
                p.move(to: CGPoint(x: 0, y: -size * 0.42))
                p.addLine(to: CGPoint(x: -size * 0.36, y: size * 0.40))
                p.addQuadCurve(to: CGPoint(x: size * 0.36, y: size * 0.40),
                               control: CGPoint(x: 0, y: size * 0.30))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [color.opacity(0.8), color.opacity(0.4)],
                                 startPoint: .top, endPoint: .bottom))
            Path { p in
                p.move(to: CGPoint(x: 0, y: -size * 0.42))
                p.addLine(to: CGPoint(x: -size * 0.36, y: size * 0.40))
                p.addQuadCurve(to: CGPoint(x: size * 0.36, y: size * 0.40),
                               control: CGPoint(x: 0, y: size * 0.30))
                p.closeSubpath()
            }
            .stroke(color, lineWidth: 1.2)
            // Shadowed hood interior (face hidden)
            Path { p in
                p.move(to: CGPoint(x: -size * 0.15, y: -size * 0.25))
                p.addLine(to: CGPoint(x: 0, y: -size * 0.40))
                p.addLine(to: CGPoint(x: size * 0.15, y: -size * 0.25))
                p.addQuadCurve(to: CGPoint(x: 0, y: -size * 0.10),
                               control: CGPoint(x: 0, y: -size * 0.18))
                p.addQuadCurve(to: CGPoint(x: -size * 0.15, y: -size * 0.25),
                               control: CGPoint(x: -size * 0.10, y: -size * 0.18))
                p.closeSubpath()
            }
            .fill(Color.black.opacity(0.75))
            // Glowing yellow eye-slits inside hood
            HStack(spacing: size * 0.07) {
                Rectangle().fill(Color.yellow).frame(width: size * 0.05, height: 1.5)
                    .shadow(color: .yellow, radius: 2)
                Rectangle().fill(Color.yellow).frame(width: size * 0.05, height: 1.5)
                    .shadow(color: .yellow, radius: 2)
            }
            .offset(y: -size * 0.25)
            // Mystery question mark badge
            Image(systemName: "questionmark")
                .font(.system(size: size * 0.22, weight: .heavy))
                .foregroundColor(.yellow.opacity(0.85))
                .offset(y: size * 0.10)
        }
    }
}

// Indrajit invisible boss — cloaked archer with bow, legs, smoke trail
struct IndrajitArt: View {
    let size: CGFloat
    let color: Color
    var body: some View {
        ZStack {
            // Smoke trail / illusion mist (behind)
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(color.opacity(0.25 - Double(i) * 0.08))
                    .frame(width: size * (0.55 + CGFloat(i) * 0.12),
                           height: size * (0.55 + CGFloat(i) * 0.12))
            }
            // Two legs (booted)
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(colors: [color, color.opacity(0.5)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.10, height: size * 0.28)
                .offset(x: -size * 0.12, y: size * 0.42)
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(colors: [color, color.opacity(0.5)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.10, height: size * 0.28)
                .offset(x: size * 0.12, y: size * 0.42)
            // Body cloak
            Path { p in
                p.move(to: CGPoint(x: -size * 0.40, y: size * 0.40))
                p.addLine(to: CGPoint(x: -size * 0.34, y: -size * 0.10))
                p.addQuadCurve(to: CGPoint(x: size * 0.34, y: -size * 0.10),
                               control: CGPoint(x: 0, y: -size * 0.40))
                p.addLine(to: CGPoint(x: size * 0.40, y: size * 0.40))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [color, color.opacity(0.4)],
                                 startPoint: .top, endPoint: .bottom))
            // Cloak border
            Path { p in
                p.move(to: CGPoint(x: -size * 0.40, y: size * 0.40))
                p.addLine(to: CGPoint(x: -size * 0.34, y: -size * 0.10))
                p.addQuadCurve(to: CGPoint(x: size * 0.34, y: -size * 0.10),
                               control: CGPoint(x: 0, y: -size * 0.40))
                p.addLine(to: CGPoint(x: size * 0.40, y: size * 0.40))
                p.closeSubpath()
            }
            .stroke(color, lineWidth: 1.5)
            // Arm holding bow (left side)
            Capsule().fill(color.opacity(0.8))
                .frame(width: size * 0.08, height: size * 0.30)
                .rotationEffect(.degrees(-25), anchor: .top)
                .offset(x: -size * 0.30, y: size * 0.05)
            // Bow (curved)
            Path { p in
                p.addArc(center: .zero, radius: size * 0.18,
                         startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
            }
            .stroke(LinearGradient(colors: [.white, color],
                                   startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .offset(x: -size * 0.40, y: size * 0.05)
            // Right arm
            Capsule().fill(color.opacity(0.8))
                .frame(width: size * 0.08, height: size * 0.28)
                .rotationEffect(.degrees(20), anchor: .top)
                .offset(x: size * 0.30, y: size * 0.05)
            // Hood (deep dark shadow)
            Path { p in
                p.move(to: CGPoint(x: -size * 0.18, y: -size * 0.10))
                p.addQuadCurve(to: CGPoint(x: size * 0.18, y: -size * 0.10),
                               control: CGPoint(x: 0, y: -size * 0.38))
                p.closeSubpath()
            }
            .fill(Color.black.opacity(0.8))
            // Two glowing red eye-slits
            HStack(spacing: size * 0.06) {
                Rectangle().fill(Color.red).frame(width: size * 0.06, height: 2)
                    .shadow(color: .red, radius: 2)
                Rectangle().fill(Color.red).frame(width: size * 0.06, height: 2)
                    .shadow(color: .red, radius: 2)
            }
            .offset(y: -size * 0.20)
            // Crescent moon emblem on forehead
            Image(systemName: "moon.fill")
                .font(.system(size: size * 0.14))
                .foregroundColor(.white.opacity(0.9))
                .offset(y: -size * 0.35)
        }
    }
}

// Small skinny figure with pointed ears, arms, legs
struct PishachaArt: View {
    let size: CGFloat
    let color: Color
    var body: some View {
        ZStack {
            // Legs (two)
            Capsule().fill(color.opacity(0.7))
                .frame(width: size * 0.10, height: size * 0.30)
                .offset(x: -size * 0.12, y: size * 0.35)
            Capsule().fill(color.opacity(0.7))
                .frame(width: size * 0.10, height: size * 0.30)
                .offset(x: size * 0.12, y: size * 0.35)
            // Body (torso)
            Capsule().fill(color.opacity(0.55))
                .frame(width: size * 0.45, height: size * 0.45)
                .offset(y: size * 0.08)
            // Arms (two, slightly outstretched/clawed)
            Capsule().fill(color.opacity(0.7))
                .frame(width: size * 0.08, height: size * 0.30)
                .offset(x: -size * 0.28, y: size * 0.10)
                .rotationEffect(.degrees(-15), anchor: .top)
            Capsule().fill(color.opacity(0.7))
                .frame(width: size * 0.08, height: size * 0.30)
                .offset(x: size * 0.28, y: size * 0.10)
                .rotationEffect(.degrees(15), anchor: .top)
            // Head
            Circle().fill(color)
                .frame(width: size * 0.40, height: size * 0.40)
                .offset(y: -size * 0.25)
            // Pointed ears
            Triangle().fill(color)
                .frame(width: size * 0.12, height: size * 0.18)
                .offset(x: -size * 0.16, y: -size * 0.40)
            Triangle().fill(color)
                .frame(width: size * 0.12, height: size * 0.18)
                .offset(x: size * 0.16, y: -size * 0.40)
            // Glowing eyes
            HStack(spacing: size * 0.08) {
                Circle().fill(Color.red).frame(width: 2.5, height: 2.5)
                Circle().fill(Color.red).frame(width: 2.5, height: 2.5)
            }
            .offset(y: -size * 0.27)
            // Fanged mouth
            Path { p in
                p.move(to: CGPoint(x: -1.5, y: 0))
                p.addLine(to: CGPoint(x: 0, y: 2))
                p.addLine(to: CGPoint(x: 1.5, y: 0))
            }
            .stroke(Color.white, lineWidth: 0.8)
            .offset(y: -size * 0.20)
        }
    }
}

// Bigger demon with horns, muscled arms, legs
struct RakshasaArt: View {
    let size: CGFloat
    let color: Color
    var body: some View {
        ZStack {
            // Legs
            Capsule().fill(color.opacity(0.7))
                .frame(width: size * 0.18, height: size * 0.30)
                .offset(x: -size * 0.15, y: size * 0.38)
            Capsule().fill(color.opacity(0.7))
                .frame(width: size * 0.18, height: size * 0.30)
                .offset(x: size * 0.15, y: size * 0.38)
            // Body
            RoundedRectangle(cornerRadius: size * 0.15)
                .fill(LinearGradient(colors: [color, color.opacity(0.55)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.65, height: size * 0.55)
                .offset(y: size * 0.05)
            // Muscled arms — bent at sides, fists
            Capsule().fill(color.opacity(0.75))
                .frame(width: size * 0.16, height: size * 0.35)
                .offset(x: -size * 0.30, y: size * 0.08)
            Capsule().fill(color.opacity(0.75))
                .frame(width: size * 0.16, height: size * 0.35)
                .offset(x: size * 0.30, y: size * 0.08)
            // Fists at end of arms
            Circle().fill(color)
                .frame(width: size * 0.14, height: size * 0.14)
                .offset(x: -size * 0.30, y: size * 0.26)
            Circle().fill(color)
                .frame(width: size * 0.14, height: size * 0.14)
                .offset(x: size * 0.30, y: size * 0.26)
            // Head
            Circle().fill(color)
                .frame(width: size * 0.48, height: size * 0.48)
                .offset(y: -size * 0.25)
            // Curved horns
            Path { p in
                p.move(to: CGPoint(x: -size * 0.20, y: -size * 0.42))
                p.addQuadCurve(to: CGPoint(x: -size * 0.32, y: -size * 0.60),
                               control: CGPoint(x: -size * 0.36, y: -size * 0.47))
            }
            .stroke(color, lineWidth: 2.5)
            Path { p in
                p.move(to: CGPoint(x: size * 0.20, y: -size * 0.42))
                p.addQuadCurve(to: CGPoint(x: size * 0.32, y: -size * 0.60),
                               control: CGPoint(x: size * 0.36, y: -size * 0.47))
            }
            .stroke(color, lineWidth: 2.5)
            // Eyes (red glowing)
            HStack(spacing: size * 0.10) {
                Circle().fill(Color.red).frame(width: 3, height: 3)
                Circle().fill(Color.red).frame(width: 3, height: 3)
            }
            .offset(y: -size * 0.28)
            // Fangs (downward triangles)
            HStack(spacing: 2) {
                Triangle().fill(Color.white).frame(width: 3, height: 5).rotationEffect(.degrees(180))
                Triangle().fill(Color.white).frame(width: 3, height: 5).rotationEffect(.degrees(180))
            }
            .offset(y: -size * 0.17)
        }
    }
}

// Massive giant — thick body, huge fists, stomping legs
struct DaityaArt: View {
    let size: CGFloat
    let color: Color
    var body: some View {
        ZStack {
            // Thick stomping legs
            RoundedRectangle(cornerRadius: 4)
                .fill(color.opacity(0.7))
                .frame(width: size * 0.20, height: size * 0.32)
                .offset(x: -size * 0.18, y: size * 0.40)
            RoundedRectangle(cornerRadius: 4)
                .fill(color.opacity(0.7))
                .frame(width: size * 0.20, height: size * 0.32)
                .offset(x: size * 0.18, y: size * 0.40)
            // Massive torso
            RoundedRectangle(cornerRadius: size * 0.10)
                .fill(LinearGradient(colors: [color, color.opacity(0.5)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.75, height: size * 0.55)
                .offset(y: size * 0.04)
            // Belt
            Rectangle().fill(Color(red: 0.4, green: 0.25, blue: 0.10))
                .frame(width: size * 0.75, height: 3)
                .offset(y: size * 0.25)
            // Huge arms
            RoundedRectangle(cornerRadius: 4)
                .fill(color.opacity(0.75))
                .frame(width: size * 0.22, height: size * 0.45)
                .offset(x: -size * 0.45, y: size * 0.05)
            RoundedRectangle(cornerRadius: 4)
                .fill(color.opacity(0.75))
                .frame(width: size * 0.22, height: size * 0.45)
                .offset(x: size * 0.45, y: size * 0.05)
            // Big fists
            Circle().fill(color)
                .frame(width: size * 0.22, height: size * 0.22)
                .offset(x: -size * 0.45, y: size * 0.30)
            Circle().fill(color)
                .frame(width: size * 0.22, height: size * 0.22)
                .offset(x: size * 0.45, y: size * 0.30)
            // Small head (tiny by comparison)
            Circle().fill(color)
                .frame(width: size * 0.32, height: size * 0.32)
                .offset(y: -size * 0.32)
            // Underbite tusks
            HStack(spacing: 2) {
                Triangle().fill(Color.white).frame(width: 2.5, height: 4)
                Triangle().fill(Color.white).frame(width: 2.5, height: 4)
            }
            .offset(y: -size * 0.24)
            // Angry yellow eyes
            HStack(spacing: size * 0.08) {
                Circle().fill(Color.yellow).frame(width: 3.5, height: 3.5)
                Circle().fill(Color.yellow).frame(width: 3.5, height: 3.5)
            }
            .offset(y: -size * 0.34)
        }
    }
}

// Armored warrior — plate armor, sword, legs, full body
struct AsuraArt: View {
    let size: CGFloat
    let color: Color
    var body: some View {
        ZStack {
            // Armored legs (plate greaves)
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(colors: [color.opacity(0.85), color.opacity(0.5)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.14, height: size * 0.32)
                .offset(x: -size * 0.13, y: size * 0.38)
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(colors: [color.opacity(0.85), color.opacity(0.5)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.14, height: size * 0.32)
                .offset(x: size * 0.13, y: size * 0.38)
            // Plate armor torso
            RoundedRectangle(cornerRadius: 4)
                .fill(LinearGradient(colors: [color, color.opacity(0.4)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.55, height: size * 0.50)
                .offset(y: size * 0.10)
            // Chest plate detail (X cross)
            Path { p in
                p.move(to: CGPoint(x: -size * 0.10, y: -size * 0.05))
                p.addLine(to: CGPoint(x: size * 0.10, y: size * 0.12))
                p.move(to: CGPoint(x: size * 0.10, y: -size * 0.05))
                p.addLine(to: CGPoint(x: -size * 0.10, y: size * 0.12))
            }
            .stroke(Color.white.opacity(0.4), lineWidth: 1)
            .offset(y: size * 0.10)
            // Arm (left holds sword)
            Capsule()
                .fill(color.opacity(0.75))
                .frame(width: size * 0.13, height: size * 0.35)
                .offset(x: -size * 0.30, y: size * 0.10)
            // Right arm
            Capsule()
                .fill(color.opacity(0.75))
                .frame(width: size * 0.13, height: size * 0.35)
                .offset(x: size * 0.30, y: size * 0.10)
            // Sword (long blade in right hand)
            Path { p in
                p.move(to: CGPoint(x: 0, y: -size * 0.20))
                p.addLine(to: CGPoint(x: -3, y: size * 0.25))
                p.addLine(to: CGPoint(x: 3, y: size * 0.25))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [.white, Color.gray.opacity(0.8)],
                                 startPoint: .top, endPoint: .bottom))
            .offset(x: size * 0.32, y: 0)
            // Cross-guard
            Rectangle().fill(Color(red: 0.7, green: 0.5, blue: 0.2))
                .frame(width: size * 0.14, height: 3)
                .offset(x: size * 0.32, y: size * 0.25)
            // Helmet (rounded plate)
            Path { p in
                let r = size * 0.22
                p.addArc(center: .zero, radius: r, startAngle: .degrees(170), endAngle: .degrees(10), clockwise: false)
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [color, color.opacity(0.6)],
                                 startPoint: .top, endPoint: .bottom))
            .frame(width: size * 0.55, height: size * 0.30)
            .offset(y: -size * 0.28)
            // Crimson plume
            Triangle().fill(LinearGradient(colors: [.red, .red.opacity(0.6)],
                                           startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.10, height: size * 0.20)
                .offset(y: -size * 0.48)
            // Visor slit (glowing red)
            Rectangle().fill(Color.red)
                .frame(width: size * 0.20, height: 1.5)
                .shadow(color: .red, radius: 2)
                .offset(y: -size * 0.27)
        }
    }
}

// Ghost — floating body with visible arms + wispy lower mist
struct VetalaArt: View {
    let size: CGFloat
    let color: Color

    private func ghostBody() -> Path {
        var p = Path()
        let w = size * 0.75
        let h = size * 0.70
        p.move(to: CGPoint(x: -w/2, y: h/2))
        p.addLine(to: CGPoint(x: -w/2, y: 0))
        p.addArc(center: .zero, radius: w/2,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: w/2, y: h/2))
        // Wavy bottom (mist tails)
        let humpW = w / 4
        for i in 0..<4 {
            let x = w/2 - CGFloat(i) * humpW
            let nx = x - humpW
            p.addQuadCurve(to: CGPoint(x: nx, y: h/2),
                           control: CGPoint(x: x - humpW/2, y: h/2 + 7))
        }
        p.closeSubpath()
        return p
    }

    var body: some View {
        ZStack {
            // Floating arms (translucent, extending outward)
            Capsule()
                .fill(color.opacity(0.4))
                .frame(width: size * 0.08, height: size * 0.28)
                .rotationEffect(.degrees(-20), anchor: .top)
                .offset(x: -size * 0.30, y: size * 0.05)
            Capsule()
                .fill(color.opacity(0.4))
                .frame(width: size * 0.08, height: size * 0.28)
                .rotationEffect(.degrees(20), anchor: .top)
                .offset(x: size * 0.30, y: size * 0.05)
            // Bony hands at end of arms
            Circle().fill(color.opacity(0.6)).frame(width: size * 0.10, height: size * 0.10)
                .offset(x: -size * 0.36, y: size * 0.22)
            Circle().fill(color.opacity(0.6)).frame(width: size * 0.10, height: size * 0.10)
                .offset(x: size * 0.36, y: size * 0.22)
            // Main body
            ghostBody().fill(color.opacity(0.55))
            ghostBody().stroke(color, lineWidth: 1.5)
            // Sunken eye sockets (oval black hollows)
            HStack(spacing: size * 0.20) {
                Ellipse().fill(Color.black).frame(width: size * 0.11, height: size * 0.15)
                Ellipse().fill(Color.black).frame(width: size * 0.11, height: size * 0.15)
            }
            .offset(y: -size * 0.18)
            // Glowing pupil pinpoints
            HStack(spacing: size * 0.20) {
                Circle().fill(Color(red: 0.7, green: 0.9, blue: 1.0)).frame(width: 2, height: 2)
                    .shadow(color: .cyan, radius: 1.5)
                Circle().fill(Color(red: 0.7, green: 0.9, blue: 1.0)).frame(width: 2, height: 2)
                    .shadow(color: .cyan, radius: 1.5)
            }
            .offset(y: -size * 0.17)
            // Gaping ghostly mouth (vertical oval, dark)
            Ellipse().fill(Color.black.opacity(0.6))
                .frame(width: size * 0.10, height: size * 0.15)
                .offset(y: -size * 0.02)
        }
    }
}

// Buffalo demon king — buffalo head + muscular humanoid body + mace + cloven legs
struct MahishasuraArt: View {
    let size: CGFloat
    let color: Color
    var body: some View {
        ZStack {
            // Cloven legs (thick, hoofed)
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(colors: [color, color.opacity(0.55)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.18, height: size * 0.30)
                .offset(x: -size * 0.16, y: size * 0.45)
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(colors: [color, color.opacity(0.55)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.18, height: size * 0.30)
                .offset(x: size * 0.16, y: size * 0.45)
            // Cloven hooves (dark)
            HStack(spacing: size * 0.13) {
                Triangle().fill(Color.black.opacity(0.7)).frame(width: size * 0.20, height: size * 0.07).rotationEffect(.degrees(180))
                Triangle().fill(Color.black.opacity(0.7)).frame(width: size * 0.20, height: size * 0.07).rotationEffect(.degrees(180))
            }.offset(y: size * 0.59)
            // Muscular torso
            RoundedRectangle(cornerRadius: size * 0.10)
                .fill(LinearGradient(colors: [color, color.opacity(0.5)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.75, height: size * 0.55)
                .offset(y: size * 0.10)
            // Armor band across chest (red sash)
            Rectangle().fill(Color.red.opacity(0.85))
                .frame(width: size * 0.75, height: 5)
                .offset(y: size * 0.06)
            // Two arms holding heavy mace
            Capsule()
                .fill(color.opacity(0.85))
                .frame(width: size * 0.16, height: size * 0.40)
                .offset(x: -size * 0.38, y: size * 0.05)
                .rotationEffect(.degrees(-10), anchor: .top)
            Capsule()
                .fill(color.opacity(0.85))
                .frame(width: size * 0.16, height: size * 0.40)
                .offset(x: size * 0.38, y: size * 0.05)
                .rotationEffect(.degrees(10), anchor: .top)
            // Mace (right hand): handle + spiked head
            Rectangle().fill(Color(red: 0.5, green: 0.3, blue: 0.15))
                .frame(width: 3, height: size * 0.40)
                .offset(x: size * 0.45, y: size * 0.20)
            // Spiked mace head
            ZStack {
                Circle().fill(LinearGradient(colors: [.gray, .black],
                                             startPoint: .top, endPoint: .bottom))
                    .frame(width: size * 0.20, height: size * 0.20)
                ForEach(0..<8, id: \.self) { i in
                    Triangle().fill(Color.gray)
                        .frame(width: 3, height: size * 0.10)
                        .rotationEffect(.degrees(Double(i) * 45))
                }
            }
            .offset(x: size * 0.45, y: size * 0.40)
            // Buffalo head (wide, flat)
            Ellipse().fill(LinearGradient(colors: [color, color.opacity(0.7)],
                                          startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.65, height: size * 0.50)
                .offset(y: -size * 0.20)
            Ellipse().stroke(color, lineWidth: 1.5)
                .frame(width: size * 0.65, height: size * 0.50)
                .offset(y: -size * 0.20)
            // Massive curved horns
            Path { p in
                p.move(to: CGPoint(x: -size * 0.30, y: -size * 0.28))
                p.addQuadCurve(to: CGPoint(x: -size * 0.55, y: -size * 0.55),
                               control: CGPoint(x: -size * 0.62, y: -size * 0.35))
            }
            .stroke(LinearGradient(colors: [.white, color],
                                   startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round))
            Path { p in
                p.move(to: CGPoint(x: size * 0.30, y: -size * 0.28))
                p.addQuadCurve(to: CGPoint(x: size * 0.55, y: -size * 0.55),
                               control: CGPoint(x: size * 0.62, y: -size * 0.35))
            }
            .stroke(LinearGradient(colors: [.white, color],
                                   startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round))
            // Snout
            Ellipse().fill(color.opacity(0.7))
                .frame(width: size * 0.25, height: size * 0.18)
                .offset(y: -size * 0.08)
            // Nose ring (gold)
            Circle().stroke(Color.gold, lineWidth: 1.5)
                .frame(width: size * 0.10, height: size * 0.10)
                .offset(y: -size * 0.06)
            // Furious red eyes
            HStack(spacing: size * 0.18) {
                Circle().fill(Color.red).frame(width: size * 0.08, height: size * 0.08)
                    .shadow(color: .red, radius: 2)
                Circle().fill(Color.red).frame(width: size * 0.08, height: size * 0.08)
                    .shadow(color: .red, radius: 2)
            }
            .offset(y: -size * 0.24)
        }
    }
}

// Ten-headed Ravana — fanned heads + body + 6+ arms with weapons + regal legs
struct RavanaArt: View {
    let size: CGFloat
    let color: Color
    var body: some View {
        ZStack {
            // Royal legs (dhoti-clad)
            RoundedRectangle(cornerRadius: 4)
                .fill(LinearGradient(colors: [Color(red: 0.85, green: 0.65, blue: 0.10),
                                              Color(red: 0.55, green: 0.30, blue: 0.05)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.20, height: size * 0.32)
                .offset(x: -size * 0.16, y: size * 0.50)
            RoundedRectangle(cornerRadius: 4)
                .fill(LinearGradient(colors: [Color(red: 0.85, green: 0.65, blue: 0.10),
                                              Color(red: 0.55, green: 0.30, blue: 0.05)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.20, height: size * 0.32)
                .offset(x: size * 0.16, y: size * 0.50)
            // Royal torso (dark muscular)
            RoundedRectangle(cornerRadius: size * 0.10)
                .fill(LinearGradient(colors: [color, color.opacity(0.5)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.80, height: size * 0.60)
                .offset(y: size * 0.12)
            // Golden royal sash diagonal
            Path { p in
                p.move(to: CGPoint(x: -size * 0.40, y: -size * 0.08))
                p.addLine(to: CGPoint(x: size * 0.40, y: size * 0.18))
            }
            .stroke(Color.yellow, lineWidth: 3)
            // SIX arms (3 per side), each holding a weapon
            let armOffsetsLeft: [(angle: Double, ox: CGFloat, oy: CGFloat)] = [
                (-30, -0.40, 0.05), (-10, -0.45, 0.20), (15, -0.42, 0.35)
            ]
            ForEach(0..<3, id: \.self) { i in
                let o = armOffsetsLeft[i]
                Capsule()
                    .fill(color.opacity(0.85))
                    .frame(width: size * 0.10, height: size * 0.32)
                    .offset(x: o.ox * size, y: o.oy * size)
                    .rotationEffect(.degrees(o.angle), anchor: .top)
            }
            ForEach(0..<3, id: \.self) { i in
                let o = armOffsetsLeft[i]
                Capsule()
                    .fill(color.opacity(0.85))
                    .frame(width: size * 0.10, height: size * 0.32)
                    .offset(x: -o.ox * size, y: o.oy * size)
                    .rotationEffect(.degrees(-o.angle), anchor: .top)
            }
            // Weapons in arms — sword left, mace right, shield third
            // Left side: curved blade
            Path { p in
                p.move(to: CGPoint(x: 0, y: -size * 0.25))
                p.addQuadCurve(to: CGPoint(x: 0, y: size * 0.25),
                               control: CGPoint(x: -size * 0.06, y: 0))
            }
            .stroke(Color.white, lineWidth: 2.5)
            .offset(x: -size * 0.50, y: size * 0.20)
            // Right side: spiked club
            Rectangle().fill(Color(red: 0.5, green: 0.3, blue: 0.10))
                .frame(width: 3, height: size * 0.40)
                .offset(x: size * 0.52, y: size * 0.18)
            Circle().fill(Color.gray)
                .frame(width: size * 0.16, height: size * 0.16)
                .offset(x: size * 0.52, y: size * 0.38)
            // Central main head (largest)
            Circle().fill(LinearGradient(colors: [color, color.opacity(0.7)],
                                         startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.40, height: size * 0.40)
                .offset(y: -size * 0.22)
            // Nine secondary heads fanning out (4 left + 5 right above, or 4-4-1)
            // Place heads in arc above main head
            ForEach(0..<9, id: \.self) { i in
                let angle = Double(i - 4) * 18.0 - 90.0  // -90° to +90° spread
                let rad = angle * .pi / 180
                let r = size * 0.42
                let dx = CGFloat(sin(rad)) * r
                let dy = -size * 0.42 - CGFloat(cos(rad) - 1) * r * 0.5
                Circle().fill(color.opacity(0.85))
                    .frame(width: size * 0.16, height: size * 0.16)
                    .offset(x: dx, y: dy)
                // Tiny eyes on each
                Circle().fill(Color.red).frame(width: 1.5, height: 1.5)
                    .offset(x: dx, y: dy - 1)
            }
            // Golden crown (multi-pointed) on main head
            Path { p in
                let w = size * 0.50
                let baseY = -size * 0.36
                p.move(to: CGPoint(x: -w/2, y: baseY))
                let pts: [CGFloat] = [0, 0.15, 0.30, 0.45, 0.55, 0.70, 0.85, 1.0]
                for (i, t) in pts.enumerated() {
                    let x = -w/2 + w * t
                    let y = baseY + (i % 2 == 0 ? -size * 0.10 : 0)
                    p.addLine(to: CGPoint(x: x, y: y))
                }
                p.addLine(to: CGPoint(x: w/2, y: baseY))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [Color.yellow, Color.orange],
                                 startPoint: .top, endPoint: .bottom))
            .shadow(color: .yellow.opacity(0.6), radius: 3)
            // Main head: third eye (vertical) + red eyes
            Ellipse().fill(Color.red)
                .frame(width: size * 0.05, height: size * 0.10)
                .offset(y: -size * 0.30)
                .shadow(color: .red, radius: 2)
            HStack(spacing: size * 0.10) {
                Circle().fill(Color.red).frame(width: 3.5, height: 3.5)
                Circle().fill(Color.red).frame(width: 3.5, height: 3.5)
            }
            .offset(y: -size * 0.22)
            // Mustached fanged mouth
            HStack(spacing: 1.5) {
                Triangle().fill(Color.white).frame(width: 2.5, height: 4).rotationEffect(.degrees(180))
                Triangle().fill(Color.white).frame(width: 2.5, height: 4).rotationEffect(.degrees(180))
            }
            .offset(y: -size * 0.14)
        }
    }
}

// Color.gold polyfill
extension Color {
    static var gold: Color { Color(red: 1.0, green: 0.84, blue: 0.0) }
}

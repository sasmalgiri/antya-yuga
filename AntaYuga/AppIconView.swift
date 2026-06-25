//
//  AppIconView.swift
//  AntaYuga
//
//  Pure SwiftUI app icon at 1024×1024. NOT shipped at runtime — this file
//  exists so you can render the icon in Xcode Canvas, screenshot at full
//  resolution, and drop the PNG into Assets.xcassets → AppIcon (1024×1024
//  marketing slot).
//
//  HOW TO EXPORT THE PNG:
//    1) Open this file in Xcode.
//    2) Open the right-hand Canvas (Editor → Canvas, or ⌥⌘↩).
//    3) Click the "Live" / "Selectable" preview to render the icon.
//    4) Right-click the rendered preview → "Export Preview…" → save as PNG.
//    5) Drop the PNG into Assets.xcassets → AppIcon → 1024×1024 marketing slot.
//
//  ⚠️  Apple requires the icon PNG to have NO transparency and NO rounded
//  corners (the system rounds it for you). The view below renders a solid
//  background so the export is App-Store-compliant.
//

import SwiftUI

struct AppIconView: View {
    /// Icon canvas size. Apple's marketing slot is 1024×1024; previews
    /// scale this down for display.
    var size: CGFloat = 1024

    var body: some View {
        ZStack {
            // ─── Background ─────────────────────────────────────────────
            // Deep cosmic gradient — purple → indigo → near-black.
            RadialGradient(
                colors: [
                    Color(red: 0.18, green: 0.06, blue: 0.30),
                    Color(red: 0.06, green: 0.02, blue: 0.14),
                    Color(red: 0.02, green: 0.01, blue: 0.06)
                ],
                center: .center,
                startRadius: size * 0.10,
                endRadius: size * 0.65
            )

            // Sprinkle of stars
            starfield

            // ─── Sudarshan Chakra (the spinning disc) ───────────────────
            chakra
                .scaleEffect(0.90)

            // ─── Central glyph: ॐ (Om) ─────────────────────────────────
            // The most universally recognised Sanskrit symbol — readable
            // even at the 60×60 home-screen size.
            Text("ॐ")
                .font(.system(size: size * 0.34, weight: .heavy, design: .serif))
                .foregroundColor(.white)
                .shadow(color: .yellow.opacity(0.9), radius: size * 0.025)
                .shadow(color: .orange.opacity(0.6), radius: size * 0.012)
        }
        .frame(width: size, height: size)
        .background(Color(red: 0.02, green: 0.01, blue: 0.06))
        .clipped()                          // hard-clip to the square
    }

    // MARK: - Chakra (spinning disc silhouette)

    private var chakra: some View {
        ZStack {
            // Outer halo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 1.00, green: 0.78, blue: 0.20).opacity(0.55),
                            Color(red: 1.00, green: 0.45, blue: 0.08).opacity(0.25),
                            .clear
                        ],
                        center: .center,
                        startRadius: size * 0.10,
                        endRadius: size * 0.45
                    )
                )
                .frame(width: size * 0.85, height: size * 0.85)

            // Outer ring with 24 sharp spokes
            ForEach(0..<24, id: \.self) { i in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.00, green: 0.92, blue: 0.55),
                                Color(red: 1.00, green: 0.55, blue: 0.10)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(width: size * 0.012, height: size * 0.34)
                    .offset(y: -size * 0.22)
                    .rotationEffect(.degrees(Double(i) * 15))
            }

            // Inner ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 1.00, green: 0.92, blue: 0.55),
                            Color(red: 1.00, green: 0.55, blue: 0.10)
                        ],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: size * 0.022
                )
                .frame(width: size * 0.46, height: size * 0.46)

            // Solid disc behind the glyph so it pops
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 1.00, green: 0.78, blue: 0.20),
                            Color(red: 0.85, green: 0.30, blue: 0.05),
                            Color(red: 0.18, green: 0.06, blue: 0.30)
                        ],
                        center: .center,
                        startRadius: 2,
                        endRadius: size * 0.22
                    )
                )
                .frame(width: size * 0.42, height: size * 0.42)
        }
    }

    // MARK: - Starfield

    private var starfield: some View {
        Canvas { ctx, sz in
            var seed: UInt64 = 0xC0DE_F00D_AC_75
            func next() -> Double {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                return Double(seed >> 11) / Double(UInt64.max >> 11)
            }
            for _ in 0..<160 {
                let x = next() * Double(sz.width)
                let y = next() * Double(sz.height)
                let s = next() * sz.width * 0.005 + sz.width * 0.0015
                let alpha = 0.30 + next() * 0.55
                let rect = CGRect(x: x, y: y, width: s, height: s)
                ctx.fill(Path(ellipseIn: rect), with: .color(.white.opacity(alpha)))
            }
        }
    }
}

// MARK: - Alternate designs (uncomment in the preview to switch)

/// Alternate icon: large Sanskrit "अन्त" syllable (= "Anta", End) sitting
/// over the chakra. Bolder, more wordmark-y.
struct AppIconView_Anta: View {
    var size: CGFloat = 1024
    var body: some View {
        ZStack {
            AppIconView(size: size)
                // Hide the Om in the base view by overlaying a solid colour
                // disc the same shade as the chakra centre.
            Text("अन्त")
                .font(.system(size: size * 0.26, weight: .heavy, design: .serif))
                .foregroundColor(.white)
                .shadow(color: .yellow.opacity(0.9), radius: size * 0.025)
                .shadow(color: .orange.opacity(0.6), radius: size * 0.012)
        }
        .frame(width: size, height: size)
    }
}

/// Alternate icon: दुर्गा syllable (the flagship attack's signature).
struct AppIconView_Durga: View {
    var size: CGFloat = 1024
    var body: some View {
        ZStack {
            AppIconView(size: size)
            Text("दुर्गा")
                .font(.system(size: size * 0.20, weight: .heavy, design: .serif))
                .foregroundColor(.white)
                .shadow(color: .yellow.opacity(0.95), radius: size * 0.03)
                .shadow(color: Color(red: 0.95, green: 0.20, blue: 0.55).opacity(0.7),
                        radius: size * 0.018)
        }
        .frame(width: size, height: size)
    }
}

#Preview("ॐ Om (default)", traits: .fixedLayout(width: 512, height: 512)) {
    AppIconView(size: 512)
}

#Preview("अन्त Anta", traits: .fixedLayout(width: 512, height: 512)) {
    AppIconView_Anta(size: 512)
}

#Preview("दुर्गा Durga", traits: .fixedLayout(width: 512, height: 512)) {
    AppIconView_Durga(size: 512)
}

//
//  AssetAdapter.swift
//  towerlogicstrategicgame
//
//  Drop-in image-asset support. When you add a PNG/PDF image to
//  Assets.xcassets with one of the naming conventions below, the game
//  will automatically use it instead of the built-in vector art.
//
//  -------------------------------------------------------------------
//  ASSET NAMING CONVENTION
//  -------------------------------------------------------------------
//  Towers     → "astra_<rawValue>"     e.g.  astra_dart, astra_brahmashirsha,
//                                              astra_pashupatastra, astra_vajraKavach
//  Enemies    → "enemy_<rawValue>"     e.g.  enemy_pishacha, enemy_ravana,
//                                              enemy_indrajit, enemy_lobhaYaksha
//  Buildings  → "building_<rawValue>"  e.g.  building_goldMine, building_techLab
//  Stones     → "stone_<rawValue>"     e.g.  stone_chuni, stone_raktamukhi
//
//  Backgrounds & theme
//      bg_field            — main play area background (large)
//      bg_race_select      — race selection screen background
//      bg_gameover         — game-over overlay background
//      theme_path_texture  — repeating texture stroked along the path
//
//  Image specs (suggested):
//      Towers/Buildings:   transparent PNG, 1× = 60×60, supply @2x and @3x
//      Enemies:            transparent PNG, 1× = 80×80, supply @2x and @3x
//      Stones:             transparent PNG, 1× = 32×32
//      Backgrounds:        full-screen JPG/PNG, supply 2048×2732 (iPad max)
//
//  How to add (Xcode):
//      1. Open Assets.xcassets
//      2. Right-click → New Image Set → rename to one of the names above
//      3. Drag your @1x / @2x / @3x PNGs into the slots
//      Build and run — the game will pick up the new image automatically.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Asset presence check (cached)

enum AssetCatalog {
    private static var lookupCache: [String: Bool] = [:]

    static func has(_ name: String) -> Bool {
        if let cached = lookupCache[name] { return cached }
        let exists = lookupRaw(name)
        lookupCache[name] = exists
        return exists
    }

    private static func lookupRaw(_ name: String) -> Bool {
        #if canImport(UIKit)
        return UIImage(named: name) != nil
        #elseif canImport(AppKit)
        return NSImage(named: name) != nil
        #else
        return false
        #endif
    }
}

// MARK: - Drop-in image view with vector fallback

/// Renders `Image(name)` when asset exists, otherwise renders the fallback.
/// The asset is fitted (preserving aspect ratio) into the parent's frame.
struct AssetImageOr<Fallback: View>: View {
    let assetName: String
    @ViewBuilder let fallback: () -> Fallback

    var body: some View {
        if AssetCatalog.has(assetName) {
            Image(assetName)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
        } else {
            fallback()
        }
    }
}

// MARK: - Asset name builders

enum AssetName {
    static func tower(_ kind: TowerKind) -> String   { "astra_\(kind.rawValue)" }
    /// CINEMATIC card image (full AAA artwork) for the codex overlay
    /// e.g. "astra_card_varunastra", "astra_card_garudastra"
    static func astraCard(_ kind: TowerKind) -> String { "astra_card_\(kind.rawValue)" }
    static func enemy(_ kind: EnemyKind) -> String   { "enemy_\(kind.rawValue)" }
    static func building(_ k: BuildingKind) -> String { "building_\(k.rawValue)" }
    static func stone(_ kind: StoneKind) -> String   { "stone_\(kind.rawValue)" }

    static let fieldBackground   = "bg_field"
    static let raceSelectBG      = "bg_race_select"
    static let gameOverBG        = "bg_gameover"
    static let pathTexture       = "theme_path_texture"
}

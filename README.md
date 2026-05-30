# Astra Yug

A SwiftUI tower-defence game for iOS / iPadOS, inspired by Indian itihāsa
(Ramayana, Mahabharata, Puranas).

> Defend the cosmos across three Yugas with 24 divine astras, 14 mythological
> enemies, and 4 dynasties.

**Site:** <https://sasmalgiri.github.io/astra-yug/>

---

## Stack

- SwiftUI + `@Observable` for state
- AVAudioEngine for procedurally synthesized sound
- StoreKit 2 for in-app purchases
- `UserDefaults` for local-only persistence (no servers, no analytics)

## Features

- **4 dynasties** — Raghuvansh, Sen, Pal, Maurya — each with a unique combat
  trait and economy bonus
- **24 astras** across 8 paths × 3 tiers, from the basic Dart to apex
  Pashupatastra
- **14 enemies** including resource bearers and bosses (Ravana, Mahishasura,
  Indrajit) with damage-type immunities
- **5-resource economy** (Gold, Metal, Tech, Jotisha, Veda) plus 4 power-stone
  variants
- **In-run Bazaar** with instant items, run-long buffs, and permanent
  unlocks; persistent point wallet via StoreKit IAP

## Building

Open `towerlogicstrategicgame.xcodeproj` in Xcode 16+ and run on an iOS 17+
device or simulator.

## Project layout

| Path | What |
|---|---|
| `towerlogicstrategicgame/towerlogicstrategicgame/` | App bundle (entry point, ContentView, Assets, PrivacyInfo) |
| `towerlogicstrategicgame/GameViewModel.swift` | Single `@Observable` model |
| `towerlogicstrategicgame/GameArt.swift`, `TowerVisuals.swift` | Vector SwiftUI art |
| `towerlogicstrategicgame/BazaarStore.swift`, `StoreManager.swift` | Bazaar economy + StoreKit 2 |
| `towerlogicstrategicgame/SoundEngine.swift` | AVAudioEngine synth |
| `towerlogicstrategicgame/AstraCodex.swift` | Cinematic codex overlay |
| `docs/` | Landing page, privacy policy, terms, support (GitHub Pages source) |

## Privacy

The app collects nothing and transmits no data. Gameplay state lives in
`UserDefaults` on-device only. Full policy: [docs/privacy.html](docs/privacy.html).

## Licence

© Shirshendu Sasmal. All rights reserved.

# Antya Yuga

A SwiftUI tower-defence game for iOS / iPadOS, inspired by Indian itihāsa
(Ramayana, Mahabharata, Puranas).

> Defend the cosmos across three Yugas with 24 divine astras, 14 mythological
> enemies, and 4 dynasties.

**Site:** <https://sasmalgiri.github.io/antya-yuga/>
**App Store:** <https://apps.apple.com/app/antya-yuga/id6783359423>

---

## Stack

- SwiftUI + `@Observable` for state
- AVAudioEngine for procedurally synthesized sound
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
  unlocks — all bought with points earned in-game (no IAP)

## Building

Open `AntaYuga.xcodeproj` in Xcode 16+ and run on an iOS 17+
device or simulator.

## Project layout

| Path | What |
|---|---|
| `towerlogicstrategicgame/AntaYuga/` | App bundle (entry point, ContentView, Assets, PrivacyInfo) |
| `AntaYuga/GameViewModel.swift` | Single `@Observable` model |
| `AntaYuga/GameArt.swift`, `TowerVisuals.swift` | Vector SwiftUI art |
| `AntaYuga/BazaarStore.swift` | Bazaar economy (points earned in-game) |
| `AntaYuga/SoundEngine.swift` | AVAudioEngine synth |
| `AntaYuga/AstraCodex.swift` | Cinematic codex overlay |
| `docs/` | Landing page, privacy policy, terms, support (GitHub Pages source) |

## Privacy

The app collects nothing and transmits no data. Gameplay state lives in
`UserDefaults` on-device only. Full policy: [docs/privacy.html](docs/privacy.html).

## Licence

© EcoSanskriti Innovation. All rights reserved.

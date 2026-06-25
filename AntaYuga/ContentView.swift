//
//  ContentView.swift
//  AntaYuga
//

import SwiftUI

// MARK: - Root view

struct ContentView: View {
    @State private var vm = GameViewModel()
    // First-launch acknowledgement of the cultural / mythological framing.
    // Stored in UserDefaults so the disclaimer appears exactly once per
    // device. Resetting requires reinstalling the app — same as Apple does
    // for the privacy / tracking prompts.
    @AppStorage("hasSeenCulturalDisclaimer") private var hasSeenCulturalDisclaimer = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                SpaceBackground().ignoresSafeArea()

                if vm.race != nil {
                    gameView(geo: geo)
                }

                if vm.race == nil {
                    RaceSelectionView(vm: vm)
                        .transition(.opacity)
                }

                if !hasSeenCulturalDisclaimer {
                    CulturalDisclaimerOverlay {
                        hasSeenCulturalDisclaimer = true
                    }
                    .transition(.opacity)
                    .zIndex(2000)
                }
            }
            .task { await runGameLoop() }
        }
        .preferredColorScheme(.dark)
    }

    @State private var showBazaarInGame = false
    @State private var showStoneShop = false
    @State private var showHelp = false

    @ViewBuilder
    private func gameView(geo: GeometryProxy) -> some View {
        ZStack {
            GameField(vm: vm)
                .contentShape(Rectangle())
                .onTapGesture { vm.deselectAll() }

            VStack(spacing: 0) {
                TopHUD(vm: vm,
                       showBazaar: $showBazaarInGame,
                       showStoneShop: $showStoneShop,
                       showHelp: $showHelp)
                Spacer()
                BottomBar(vm: vm)
            }

            // Amrita Kalash — appears in top-middle once the player can afford it.
            // Hidden while a center-top banner (tooltip / age / resource-wave /
            // relocate / boss-info / hint) is up so they don't visually stack.
            if vm.canUseAmritaKalash && !vm.isGameOver && !centerTopBannerActive {
                AmritaKalashButton(vm: vm)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 80)
                    .transition(.scale.combined(with: .opacity))
            }

            if let slotIndex = vm.selectedSlotIndex {
                BuildMenu(vm: vm, slotIndex: slotIndex)
                    .padding(.bottom, 80)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .transition(.opacity)
                    .zIndex(800)
            }

            if let id = vm.selectedTowerID,
               let tower = vm.towers.first(where: { $0.id == id }) {
                TowerMenu(vm: vm, tower: tower)
                    .padding(.bottom, 80)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .transition(.opacity)
                    .zIndex(800)
            }

            if let id = vm.selectedBuildingID,
               let building = vm.buildings.first(where: { $0.id == id }) {
                BuildingMenu(vm: vm, building: building)
                    .padding(.bottom, 80)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .transition(.opacity)
                    .zIndex(800)
            }

            if let banner = vm.newAgeBanner {
                AgeBanner(age: banner)
                    .padding(.top, 110)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Pending-relocate hint banner — visible while the player has
            // started a tower relocation. Tap to cancel.
            if vm.relocatingTowerID != nil {
                Button {
                    vm.cancelRelocate()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                            .font(.system(size: 12, weight: .heavy))
                        Text("Tap an empty slot to relocate · tap here to cancel")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.8))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.cyan.opacity(0.7), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.top, 100)
                .frame(maxHeight: .infinity, alignment: .top)
                .transition(.scale.combined(with: .opacity))
                .zIndex(950)
            }

            if vm.resourceWaveBanner {
                ResourceWaveBanner()
                    .padding(.top, 110)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // The Sudarshan relic is the player's goal — enemies are marching
            // toward it from W1. Shown in its dormant state until the Dvapara
            // unlock activates the charging UI. Long-press reveals its full
            // story — single tap does nothing (matches the universal
            // "press to learn" gesture). 110px hit target via .frame +
            // .contentShape so the long-press registers across the halo.
            if vm.race != nil
               && vm.sudarshanPhase == .inactive
               && (vm.sudarshanPosition.x > 0 || vm.sudarshanPosition.y > 0) {
                SudarshanRelicView(vm: vm)
                    .frame(width: 110, height: 110)
                    .contentShape(Rectangle())
                    .infoTap("Sudarshan Relic — \(vm.lives)/\(vm.maxLives) HP",
                             "This is the CENTRAL TOWER — Vishnu's discus relic at the path's end. Every wave, enemies march here trying to destroy it. " +
                             "Each enemy that breaches the path damages it (more per wave). At 0 → Game Over. " +
                             "Heal aura towers (Treta+) and Wall stones restore it. " +
                             "Once you reach Dvapara Yug, a charging meter unlocks here — feed it gold to ready the Sudarshan Chakra for W\(GameViewModel.kaliYugaArrivalWave) (the ONLY weapon that can kill Kali Yuga, the final boss).",
                             icon: "circle.hexagongrid.fill",
                             tint: .yellow)
                    .position(vm.sudarshanPosition)
            }
            // Sudarshan endgame UI — center relic, charging meter, and
            // tap-to-feed button. Replaces the dormant relic from Dvapara on.
            if vm.sudarshanPhase == .charging {
                SudarshanCenterTowerView(vm: vm)
                    .position(vm.sudarshanPosition)
                    .allowsHitTesting(true)
            }
            // Chakra animation — spins on the path centre while it burns
            // Kali Yuga down. The Sudarshan Chakra IS the finisher; victory
            // triggers directly from this phase ending.
            if vm.sudarshanPhase == .matured {
                SudarshanChakraView(vm: vm)
                    .allowsHitTesting(false)
                // Recharge bar floats near the top of the screen so the
                // player can keep topping up the chakra while it burns
                // Kali Yuga — the burn drains it ~1.4%/sec.
                ChakraRechargeBar(vm: vm)
                    .frame(maxWidth: .infinity, maxHeight: .infinity,
                           alignment: .top)
                    .padding(.top, 84)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(820)
            }
            // दुर्गा-Strike status pill — visible on ANY wave once the
            // player can plausibly have a divine line (W3+). Shows the
            // three role slots while building, then flips to "FIRING /
            // cooldown" once all three are alive and any enemy is on
            // the field (strike auto-fires every 8 s).
            if vm.race != nil && vm.wave >= 3 {
                if vm.hasTrimurtiCombination
                    && vm.enemies.contains(where: { $0.hp > 0 }) {
                    TrimurtiStrikeIndicator(vm: vm)
                        .frame(maxWidth: .infinity, maxHeight: .infinity,
                               alignment: .top)
                        .padding(.top, vm.sudarshanPhase == .matured ? 132 : 84)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(821)
                } else {
                    TrimurtiProgressPill(vm: vm)
                        .frame(maxWidth: .infinity, maxHeight: .infinity,
                               alignment: .top)
                        .padding(.top, vm.sudarshanPhase == .matured ? 132 : 84)
                        .zIndex(819)
                }
            }
            // Durga strike animation — three beams + Durga symbol overlay
            // while the strike envelope is alive.
            if vm.trimurtiStrikeTimer > 0 {
                TrimurtiStrikeOverlay(vm: vm)
                    .zIndex(830)
            }

            // Active boss info card — pinned top-right while the info
            // timer is ticking. Auto-dismisses after a few seconds so it
            // doesn't act as a sticky note for the entire wave. Player can
            // tap the boss enemy to bring it back.
            if vm.bossInfoCardTimer > 0,
               let id = vm.bossInfoCardEnemyID,
               let boss = vm.enemies.first(where: { $0.id == id && $0.hp > 0 }) {
                BossInfoCard(enemy: boss)
                    .frame(maxWidth: .infinity, maxHeight: .infinity,
                           alignment: .topTrailing)
                    .padding(.top, 110)
                    .padding(.trailing, 10)
                    .allowsHitTesting(false)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .zIndex(890)
                    .onAppear { HintsStore.shared.trigger(.bossInfoCard) }
            }
            // Boss-entry dialog — Sanskrit roar + translation when a boss
            // spawns for the first time.
            if let dlg = vm.bossDialog {
                BossDialogOverlay(kind: dlg.kind, timer: dlg.timer)
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
                    .zIndex(900)
            }

            if vm.sudarshanPhase == .victory {
                VictoryOverlay(vm: vm)
                    .zIndex(980)
            }

            // God Mode is now docked inside the BottomBar (next to the
            // Next Wave button) so it can't overlap build slots or path
            // tiles in the bottom-right corner.

            if vm.isGameOver {
                GameOverOverlay(vm: vm)
                    .zIndex(980)
            }

            if showBazaarInGame {
                BazaarOverlay(vm: vm, presented: $showBazaarInGame)
                    .zIndex(945)
            }

            if showStoneShop {
                StoneShopOverlay(vm: vm, presented: $showStoneShop)
                    .transition(.opacity)
                    .zIndex(950)
            }

            if showHelp {
                HelpOverlay(presented: $showHelp)
                    .transition(.opacity)
                    .zIndex(960)
            }

            // Universal tooltip banner — surfaces info when the player
            // long-presses any tooltip-equipped element. Auto-dismisses
            // after 3.5 s, or on tap.
            if let tip = TooltipManager.shared.active {
                TooltipBanner(payload: tip)
                    .padding(.top, 100)
                    .frame(maxWidth: .infinity, maxHeight: .infinity,
                           alignment: .top)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(970)
                    .onTapGesture { TooltipManager.shared.dismiss() }
            }

            // First-time hints (HintsStore) — pinned to the centre so they're
            // unmissable but tappable to dismiss. One at a time; the store
            // queues additional triggers until the active one is dismissed.
            if let hint = HintsStore.shared.active {
                HintBanner(hint: hint)
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
                    .zIndex(1000)
            }
        }
        .onAppear { vm.configure(size: geo.size) }
        .onChange(of: geo.size) { _, newSize in
            vm.reconfigure(size: newSize)
        }
        // Modal overlays all pause the game while open so wave time
        // doesn't tick on through. Resumes the moment the player closes
        // any one (we combine the booleans so closing one doesn't break
        // pause for the others if multiple opened — UI prevents that
        // in practice, but defensive belt-and-braces).
        .onChange(of: showBazaarInGame) { _, _ in updatePauseFromOverlays() }
        .onChange(of: showStoneShop)   { _, _ in updatePauseFromOverlays() }
        .onChange(of: showHelp)        { _, _ in updatePauseFromOverlays() }
    }

    private func updatePauseFromOverlays() {
        vm.isPaused = showBazaarInGame || showStoneShop || showHelp
    }

    /// True when any element that occupies the center-top column is on
    /// screen. Used to suppress the AmritaKalashButton (which also lives
    /// in the center-top column) so the two don't stack visually.
    private var centerTopBannerActive: Bool {
        if TooltipManager.shared.active != nil { return true }
        if vm.newAgeBanner != nil { return true }
        if vm.resourceWaveBanner { return true }
        if vm.relocatingTowerID != nil { return true }
        if vm.bossDialog != nil { return true }
        if HintsStore.shared.active != nil { return true }
        return false
    }

    private func runGameLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 16_000_000)
            vm.update(now: Date().timeIntervalSinceReferenceDate)
        }
    }
}

// MARK: - Race Selection

/// Title-screen toggle between full and optimized graphics quality. The
/// choice persists via UserDefaults (handled by `GraphicsSettings.shared`)
/// so the player only sets it once.
struct GraphicsQualityPicker: View {
    @State private var quality: GraphicsQuality = GraphicsSettings.shared.quality

    var body: some View {
        VStack(spacing: 4) {
            Text("Animations")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
            HStack(spacing: 8) {
                ForEach(GraphicsQuality.allCases) { q in
                    Button {
                        quality = q
                        GraphicsSettings.shared.quality = q
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: q.symbol)
                                .font(.system(size: 14, weight: .heavy))
                            Text(q.displayName)
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(quality == q ? .black : q.tint)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(quality == q
                                                   ? q.tint
                                                   : q.tint.opacity(0.18)))
                        .overlay(Capsule().stroke(q.tint.opacity(0.7), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            Text(quality.summary)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
        }
    }
}

struct RaceSelectionView: View {
    let vm: GameViewModel
    @State private var showBazaar = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 14) {
                    HStack {
                        Spacer()
                        BazaarButton(vm: vm, presented: $showBazaar)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 14)

                    Text("Choose Your Dynasty")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 6)

                    Text("Each lineage brings unique war traits")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))

                    // Difficulty picker — pure resource-production scaler.
                    // Combat is the same on every mode.
                    VStack(spacing: 4) {
                        Text("Choose Difficulty")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                        HStack(spacing: 8) {
                            ForEach(GameDifficulty.allCases) { mode in
                                Button {
                                    vm.difficulty = mode
                                } label: {
                                    VStack(spacing: 2) {
                                        Image(systemName: mode.symbol)
                                            .font(.system(size: 14, weight: .heavy))
                                        Text(mode.displayName)
                                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                                        Text(String(format: "%.1fx prod", mode.productionMultiplier))
                                            .font(.system(size: 8, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    .foregroundColor(vm.difficulty == mode ? .black : mode.tint)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(vm.difficulty == mode
                                                               ? mode.tint
                                                               : mode.tint.opacity(0.18)))
                                    .overlay(Capsule().stroke(mode.tint.opacity(0.7), lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        Text(vm.difficulty.summary)
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 14)
                    }
                    .padding(.top, 4)

                    // Graphics quality picker — persistent across runs.
                    GraphicsQualityPicker()
                        .padding(.top, 4)

                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(Race.allCases) { race in
                            Button {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    vm.selectRace(race)
                                }
                            } label: {
                                raceCard(race)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 6)

                    Text("Resources generate via buildings.\nUpgrade towers across 3 ages.")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 30)
                }
            }

            if showBazaar {
                BazaarOverlay(vm: vm, presented: $showBazaar)
            }
        }
    }

    private func raceCard(_ race: Race) -> some View {
        VStack(spacing: 6) {
            // Beginner-friendly badge — only on Sen and Pal.
            if race.isBeginnerFriendly {
                Text("RECOMMENDED FOR BEGINNERS")
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.green.opacity(0.18)))
                    .overlay(Capsule().stroke(Color.green.opacity(0.6), lineWidth: 0.7))
                    .padding(.top, 6)
            }

            Image(systemName: race.symbol)
                .font(.system(size: 30))
                .foregroundColor(race.color)
                .padding(.top, race.isBeginnerFriendly ? 0 : 8)

            Text(race.displayName)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.white)

            Text(race.dynasty)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.65))

            Text(race.description)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 6)
                .frame(height: 28)

            Divider()
                .background(Color.white.opacity(0.2))
                .padding(.horizontal, 8)

            VStack(spacing: 3) {
                Label(race.trait, systemImage: "burst.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(race.color)
                Label(race.bonusGen, systemImage: "arrow.up.right.circle.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.cyan)
            }
            .labelStyle(.titleAndIcon)
            .padding(.vertical, 2)

            ResourceCostRow(cost: race.startingResources, size: 9)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(race.isBeginnerFriendly
                                ? Color.green.opacity(0.85)
                                : race.color.opacity(0.7),
                                lineWidth: race.isBeginnerFriendly ? 2.0 : 1.5)
                )
                .shadow(color: race.isBeginnerFriendly ? .green.opacity(0.35) : .clear,
                        radius: race.isBeginnerFriendly ? 6 : 0)
        )
    }
}

// MARK: - Game field

struct GameField: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let vm: GameViewModel

    var body: some View {
        // iPhone shrinks the path corridor to one tower-row wide so the
        // slot grid gets more breathing room.
        let isCompact = horizontalSizeClass == .compact
        let pathCorridor: CGFloat = isCompact ? 24 : 44
        ZStack {
            PathShape(points: vm.pathPoints)
                .stroke(
                    Color.white.opacity(0.08),
                    style: StrokeStyle(lineWidth: pathCorridor, lineCap: .round, lineJoin: .round)
                )
            PathShape(points: vm.pathPoints)
                .stroke(
                    Color.cyan.opacity(0.55),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [6, 8])
                )

            ForEach(vm.slots) { slot in
                if !vm.isSlotOccupied(slot.index) {
                    BuildSlotView(selected: vm.selectedSlotIndex == slot.index)
                        .position(slot.position)
                        .onTapGesture {
                            // Relocate has the highest priority: if a tower
                            // is in-flight for relocation, this slot becomes
                            // its new home (preserving HP, kills, auras…).
                            if vm.relocatingTowerID != nil {
                                vm.confirmRelocate(toSlotIndex: slot.index)
                                return
                            }
                            // Quick-build path: armed AND affordable → drop
                            // in one tap. Armed but no longer affordable →
                            // disarm and fall through to the BuildMenu so
                            // the player gets feedback instead of a silent
                            // no-op.
                            if let armed = vm.armedQuickBuildPath {
                                if vm.canAffordPath(armed) {
                                    vm.buildTower(at: slot.index, path: armed)
                                    HintsStore.shared.trigger(.firstBuildSlot)
                                    return
                                } else {
                                    vm.armQuickBuildTower(nil)
                                }
                            }
                            if let armedB = vm.armedQuickBuildBuilding {
                                if vm.canAffordBuilding(armedB) {
                                    vm.placeBuilding(at: slot.index, kind: armedB)
                                    HintsStore.shared.trigger(.firstBuildSlot)
                                    return
                                } else {
                                    vm.armQuickBuildBuilding(nil)
                                }
                            }
                            withAnimation(.easeOut(duration: 0.15)) {
                                vm.selectedSlotIndex = slot.index
                                vm.selectedTowerID = nil
                                vm.selectedBuildingID = nil
                            }
                            HintsStore.shared.trigger(.firstBuildSlot)
                        }
                }
            }

            // Range circle for selected tower
            if let id = vm.selectedTowerID,
               let tower = vm.towers.first(where: { $0.id == id }) {
                let r = vm.range(of: tower)
                Circle()
                    .stroke(tower.kind.color.opacity(0.55), lineWidth: 1.5)
                    .background(Circle().fill(tower.kind.color.opacity(0.08)))
                    .frame(width: r * 2, height: r * 2)
                    .position(tower.position)
                    .allowsHitTesting(false)
            }

            // Buildings
            ForEach(vm.buildings) { building in
                BuildingView(building: building, selected: vm.selectedBuildingID == building.id)
                    .position(building.position)
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.15)) {
                            vm.selectedBuildingID = building.id
                            vm.selectedTowerID = nil
                            vm.selectedSlotIndex = nil
                        }
                    }
            }

            // Towers
            ForEach(vm.towers) { tower in
                TowerView(
                    tower: tower,
                    selected: vm.selectedTowerID == tower.id,
                    isProtected: vm.protectedTowerIDs.contains(tower.id),
                    isBeingHealed: vm.healedTowerIDs.contains(tower.id),
                    isControlled: vm.controlledTowerIDs.contains(tower.id),
                    isDebuffed: vm.debuffedTowerIDs.contains(tower.id),
                    isDrained: vm.drainedTowerIDs.contains(tower.id)
                )
                .overlay(
                    // Relocating tower — pulsing cyan ring so the player
                    // can see *which* tower they're about to move.
                    Group {
                        if vm.relocatingTowerID == tower.id {
                            RelocateHaloView()
                                .allowsHitTesting(false)
                        }
                    }
                )
                .overlay(
                    // Wall shield — rotating hex ring around every tower
                    // that currently has wallShield > 0. Spins out when
                    // the shield depletes / wave ends.
                    Group {
                        if tower.wallShield > 0 {
                            WallShieldView()
                                .allowsHitTesting(false)
                        }
                    }
                )
                .position(tower.position)
                .onTapGesture {
                    // Tap just opens the menu — no info banner. Long-press
                    // on the tower body fires the tooltip if the player
                    // wants the at-a-glance summary instead.
                    withAnimation(.easeOut(duration: 0.15)) {
                        vm.selectedTowerID = tower.id
                        vm.selectedBuildingID = nil
                        vm.selectedSlotIndex = nil
                    }
                }
            }

            ForEach(vm.fireFlashes) { flash in
                TowerFireFlash(color: flash.color,
                               damageType: flash.damageType,
                               tier: flash.tier,
                               sourceKind: flash.sourceKind,
                               progress: flash.age / FireFlash.lifetime)
                    .position(flash.position)
                    .allowsHitTesting(false)
            }
            ForEach(vm.projectiles) { p in
                ProjectileArtView(projectile: p)
                    .position(p.position)
                    .allowsHitTesting(false)
            }

            // Boss-attack bolts — drawn after projectiles so they read
            // clearly on top of the field.
            ForEach(vm.bossAttackFlashes) { flash in
                BossAttackBoltView(
                    flash: flash,
                    progress: flash.age / BossAttackFlash.lifetime
                )
                .allowsHitTesting(false)
            }

            ForEach(vm.enemies) { enemy in
                EnemyView(enemy: enemy)
                    .position(enemy.position)
                    // Card-worthy bosses are tappable so the player can
                    // re-summon the info card (which auto-dismisses after
                    // a few seconds). Fodder enemies stay non-interactive.
                    .allowsHitTesting(enemy.kind.isCardWorthy)
                    .onTapGesture {
                        guard enemy.kind.isCardWorthy else { return }
                        vm.showBossInfoCard(enemyID: enemy.id)
                    }
            }
            // Floating damage numbers
            ForEach(vm.damageNumbers) { dn in
                DamageNumberView(number: dn)
                    .allowsHitTesting(false)
            }
        }
    }
}

// MARK: - Path shape

struct PathShape: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var p = Path()
        guard let first = points.first else { return p }
        p.move(to: first)
        for pt in points.dropFirst() { p.addLine(to: pt) }
        return p
    }
}

// MARK: - Build slot

struct BuildSlotView: View {
    let selected: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.cyan.opacity(selected ? 0.95 : 0.45), lineWidth: 1.5)
            Image(systemName: "plus")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.cyan.opacity(0.85))
        }
        .frame(width: 30, height: 30)
        .background(Circle().fill(Color.black.opacity(0.35)))
        .scaleEffect(selected ? 1.15 : 1.0)
    }
}

/// Pulsing cyan ring rendered around a tower that's mid-relocation, so the
/// player can tell at a glance which tower will move when they tap a slot.
struct RelocateHaloView: View {
    @State private var pulse: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Circle()
            .stroke(Color.cyan.opacity(0.7 + 0.3 * pulse), lineWidth: 2)
            .frame(width: 56, height: 56)
            .scaleEffect(1.0 + 0.10 * pulse)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                    pulse = 1
                }
            }
    }
}

/// Wall-shield animation rendered around every tower that has an active
/// wallShield. Two concentric rings counter-rotate while the shield is up,
/// with a slow green pulse so the player sees the protection at a glance.
struct WallShieldView: View {
    @State private var rotate: Double = 0
    @State private var pulse: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Outer ring — clockwise spin
            Circle()
                .stroke(Color.green.opacity(0.85), style: StrokeStyle(lineWidth: 2.5, dash: [4, 3]))
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(rotate))
            // Inner ring — counter-clockwise, brighter
            Circle()
                .stroke(Color(red: 0.55, green: 1.0, blue: 0.55).opacity(0.95),
                        style: StrokeStyle(lineWidth: 1.5, dash: [2, 4]))
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(-rotate * 1.4))
            // Soft inner glow that breathes
            Circle()
                .fill(Color.green.opacity(0.10 + 0.18 * pulse))
                .frame(width: 44, height: 44)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 3.5).repeatForever(autoreverses: false)) {
                rotate = 360
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = 1
            }
        }
    }
}

// MARK: - Tower view

struct TowerView: View {
    let tower: Tower
    let selected: Bool
    var isProtected: Bool = false
    var isBeingHealed: Bool = false
    var isControlled: Bool = false
    var isDebuffed: Bool = false
    var isDrained: Bool = false

    @State private var pulse: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Stone aura (always-on faint colored ring while a stone is socketed)
            if let stone = tower.stone {
                Circle()
                    .stroke(stone.kind.color.opacity(0.35), lineWidth: 1.5)
                    .frame(width: 84, height: 84)
                    .shadow(color: stone.kind.color.opacity(0.55), radius: 5)
            }

            // Bhasmasura ash debuff — orange charred haze + ↓ arrow
            if isDebuffed {
                Circle()
                    .stroke(Color.orange.opacity(0.65), style: StrokeStyle(lineWidth: 1.6, dash: [3, 3]))
                    .frame(width: 88, height: 88)
                    .shadow(color: .orange.opacity(0.4), radius: 4)
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.orange)
                    .shadow(color: .black.opacity(0.8), radius: 2)
                    .offset(x: 28, y: -28)
            }

            // Putana drain — pink line flash that pulses once
            if isDrained {
                Circle()
                    .stroke(Color(red: 0.95, green: 0.35, blue: 0.65).opacity(0.85),
                            style: StrokeStyle(lineWidth: 2.5))
                    .frame(width: 86 + 12 * pulse, height: 86 + 12 * pulse)
                    .opacity(1.0 - pulse)
            }

            // Raktabija blood-grip — red dripping outline + skull
            if isControlled {
                Circle()
                    .stroke(Color(red: 0.85, green: 0.05, blue: 0.15).opacity(0.85),
                            style: StrokeStyle(lineWidth: 2.2, dash: [6, 3]))
                    .frame(width: 92, height: 92)
                    .shadow(color: .red.opacity(0.7), radius: 6)
                ForEach(0..<5, id: \.self) { i in
                    Image(systemName: "drop.fill")
                        .font(.system(size: 8))
                        .foregroundColor(Color(red: 0.85, green: 0.05, blue: 0.15))
                        .offset(x: cos(Double(i) * .pi * 0.4) * 38,
                                y: sin(Double(i) * .pi * 0.4) * 38 + pulse * 8)
                        .opacity(0.9 - pulse * 0.5)
                }
                Image(systemName: "xmark.octagon.fill")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.red)
                    .shadow(color: .black, radius: 2)
                    .offset(x: -28, y: -28)
            }

            // Shield shimmer (Lakshman/Suraksha/Vajra Kavach barrier coverage)
            if isProtected {
                Circle()
                    .stroke(
                        AngularGradient(colors: [
                            Color.cyan.opacity(0.0),
                            Color.cyan.opacity(0.85),
                            Color.white.opacity(0.9),
                            Color.cyan.opacity(0.85),
                            Color.cyan.opacity(0.0)
                        ], center: .center, angle: .degrees(pulse * 360)),
                        style: StrokeStyle(lineWidth: 2.0, dash: [5, 4])
                    )
                    .frame(width: 92, height: 92)
                    .shadow(color: .cyan.opacity(0.6), radius: 4)
            }

            // Heal pulse (Aushadhi/Sanjivani/Amrit aura)
            if isBeingHealed {
                Circle()
                    .stroke(Color.green.opacity(0.85 - 0.55 * pulse), lineWidth: 2)
                    .frame(width: 76 + 24 * pulse, height: 76 + 24 * pulse)
                ForEach(0..<4, id: \.self) { i in
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(.green.opacity(0.85))
                        .offset(x: cos(Double(i) * .pi / 2 + pulse * .pi * 2) * 32,
                                y: sin(Double(i) * .pi / 2 + pulse * .pi * 2) * 32 - pulse * 18)
                        .opacity(1.0 - pulse)
                }
            }

            TowerArtView(tower: tower, selected: selected)

            // Stone power-up timer bar — shows how much time the attached
            // stone has left. Same visual language as the wall-button bar
            // so the player groups them mentally as "timed buffs".
            if let stone = tower.stone, tower.stoneTimerTotal > 0 {
                let frac = max(0, min(1, tower.stoneTimer / tower.stoneTimerTotal))
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.55))
                        .frame(width: 40, height: 3)
                    Capsule()
                        .fill(stone.kind.color)
                        .frame(width: 40 * CGFloat(frac), height: 3)
                }
                .overlay(Capsule().stroke(Color.white.opacity(0.35), lineWidth: 0.5))
                .offset(y: 26)
            }

            // Kill-count badge — shows how many enemies this tower has
            // killed (drives the +0.1 veteran-power bonus & a tiny visible
            // record of the tower's performance). Hidden when zero so a
            // freshly-built tower stays clean.
            if tower.kills > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "scope")
                        .font(.system(size: 7, weight: .heavy))
                    Text("\(tower.kills)")
                        .font(.system(size: 8, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                }
                .foregroundColor(.black)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Capsule().fill(Color.yellow))
                .overlay(Capsule().stroke(Color.black.opacity(0.4), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.5), radius: 1)
                .offset(x: 22, y: -22)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: false)) {
                pulse = 1
            }
        }
    }
}

// MARK: - Boss attack bolt (jagged red line from boss to a hit tower)

struct BossAttackBoltView: View {
    let flash: BossAttackFlash
    let progress: Double  // 0..1

    var body: some View {
        let alpha = 1.0 - progress
        Path { p in
            // Build a jagged segmented line between from→to with offsets
            let from = flash.from
            let to = flash.to
            let dx = to.x - from.x
            let dy = to.y - from.y
            let dist = max(1, hypot(dx, dy))
            let nx = -dy / dist
            let ny = dx / dist
            let segments = 6
            var pts: [CGPoint] = [from]
            for i in 1..<segments {
                let t = CGFloat(i) / CGFloat(segments)
                let cx = from.x + dx * t
                let cy = from.y + dy * t
                // Pseudo-random jitter for jagged look (deterministic per flash)
                let seed = (flash.id.hashValue &+ i) & 0xFF
                let jitter = (CGFloat(seed) / 255.0 - 0.5) * 18
                pts.append(CGPoint(x: cx + nx * jitter, y: cy + ny * jitter))
            }
            pts.append(to)
            p.move(to: pts[0])
            for q in pts.dropFirst() { p.addLine(to: q) }
        }
        .stroke(flash.color.opacity(0.85 * alpha), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
        .shadow(color: flash.color.opacity(0.9 * alpha), radius: 5)
        .overlay(
            Path { p in
                p.move(to: flash.from)
                p.addLine(to: flash.to)
            }
            .stroke(Color.white.opacity(0.85 * alpha), lineWidth: 1.2)
        )
        // Tower-end impact star
        .overlay(
            Image(systemName: "burst.fill")
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(.white.opacity(alpha))
                .shadow(color: flash.color, radius: 6)
                .position(flash.to)
                .scaleEffect(0.8 + 0.4 * progress)
                .opacity(alpha)
        )
    }
}

// MARK: - Building view

struct BuildingView: View {
    let building: Building
    let selected: Bool

    var body: some View {
        BuildingArtView(building: building, selected: selected)
    }
}

// MARK: - Enemy view

struct EnemyView: View {
    let enemy: Enemy

    private var enemyAlpha: Double {
        if enemy.kind.isInvisible && !enemy.detected { return 0.25 }
        return 1.0
    }

    var body: some View {
        let size = enemy.kind.radius * 2
        ZStack {
            EnemyArtView(enemy: enemy)
                .opacity(enemyAlpha)

            // Micro HP bar — shown when wounded so the player can read remaining HP.
            if enemy.hp > 0 && enemy.hp < enemy.maxHP {
                let frac = max(0, min(1, enemy.hp / enemy.maxHP))
                VStack(spacing: 0) {
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.black.opacity(0.55))
                            .frame(width: size + 6, height: 4)
                        Capsule()
                            .fill(frac > 0.5 ? Color.green
                                  : frac > 0.25 ? Color.yellow : Color.red)
                            .frame(width: (size + 6) * CGFloat(frac), height: 4)
                    }
                    .overlay(Capsule().stroke(Color.white.opacity(0.5), lineWidth: 0.5))
                }
                .offset(y: -size * 0.6 - 4)
            }

            if enemy.kind.isInvisible && enemy.detected {
                // Detection ring (yellow)
                Circle()
                    .stroke(Color.yellow.opacity(0.8), style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                    .frame(width: size + 10, height: size + 10)
            }

            if enemy.freezeRemaining > 0 {
                Circle()
                    .stroke(Color.cyan, lineWidth: 2)
                    .frame(width: size + 6, height: size + 6)
                    .opacity(0.85)
            } else if enemy.slowRemaining > 0 {
                Circle()
                    .stroke(Color.blue, lineWidth: 1.5)
                    .frame(width: size + 6, height: size + 6)
                    .opacity(0.75)
            }

            if enemy.burnRemaining > 0 {
                Image(systemName: "flame.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.orange)
                    .offset(x: size * 0.45, y: -size * 0.50)
            }

            // Empowered Kali Yuga: the Amrit Kalash inside his body flashes
            // visible whenever an attack lands. This is the visual cue that
            // hits ARE landing, even when his regen is restoring HP between blows.
            if enemy.kind == .kaliYuga && enemy.kalashReveal > 0 {
                let revealAlpha = min(1.0, enemy.kalashReveal / 1.4)
                let pulse = 0.85 + 0.15 * sin(enemy.kalashReveal * 12)
                ZStack {
                    // Soft golden halo behind the Kalash
                    Circle()
                        .fill(RadialGradient(
                            colors: [
                                Color.yellow.opacity(0.55 * revealAlpha),
                                Color.orange.opacity(0.20 * revealAlpha),
                                .clear
                            ],
                            center: .center,
                            startRadius: 2, endRadius: 22))
                        .frame(width: 40, height: 40)
                        .blendMode(.plusLighter)
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(.yellow)
                        .shadow(color: .white.opacity(revealAlpha), radius: 4)
                        .scaleEffect(pulse)
                        .opacity(revealAlpha)
                }
            }
        }
        .overlay(alignment: .top) {
            if !(enemy.kind.isInvisible && !enemy.detected) {
                HPBar(fraction: enemy.hp / enemy.maxHP)
                    .frame(width: size, height: 4)
                    .offset(y: -10)
            }
        }
    }
}

struct HPBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.6))
                Capsule()
                    .fill(barColor)
                    .frame(width: max(0, geo.size.width * CGFloat(fraction)))
            }
        }
    }

    private var barColor: Color {
        if fraction > 0.6 { return .green }
        if fraction > 0.3 { return .yellow }
        return .red
    }
}

// MARK: - Resource cost row

struct ResourceCostRow: View {
    let cost: Resources
    var size: CGFloat = 10
    /// If non-nil, each entry is colored by whether the player can cover that
    /// specific resource. Entries already covered render full-colour ("active");
    /// entries still short render dimmed and red-numbered ("deactive"), so a
    /// glance at the row tells the player exactly which resource is blocking.
    var available: Resources? = nil

    var body: some View {
        HStack(spacing: 5) {
            if cost.gold > 0    { entry(.gold,    cost.gold) }
            if cost.metal > 0   { entry(.metal,   cost.metal) }
            if cost.tech > 0    { entry(.tech,    cost.tech) }
            if cost.jotisha > 0 { entry(.jotisha, cost.jotisha) }
            if cost.veda > 0    { entry(.veda,    cost.veda) }
        }
    }

    private func entry(_ kind: ResourceKind, _ value: Int) -> some View {
        let satisfied: Bool = {
            guard let have = available else { return true }
            return have.amount(kind) >= value
        }()
        return HStack(spacing: 1) {
            Image(systemName: kind.symbol)
                .font(.system(size: size))
                .foregroundColor(satisfied ? kind.color : kind.color.opacity(0.35))
            Text("\(value)")
                .font(.system(size: size + 1, weight: .semibold, design: .rounded))
                .foregroundColor(satisfied ? .white : Color(red: 1.0, green: 0.45, blue: 0.45))
        }
        .opacity(satisfied ? 1.0 : 0.75)
    }
}

// MARK: - Top HUD

/// Tower paths and resource buildings shown in the quick-build HUD bar.
/// Healers and barriers are aura toggles on each tower, not their own paths,
/// so they're omitted here. Parijata is gated behind the empowered endgame
/// and surfaces conditionally.
enum QuickBuildBar {
    static let paths: [TowerPath] = [.arrow, .fire, .water, .ice, .divine, .maya, .drishti]
    static let buildings: [BuildingKind] = [.goldMine, .metalFoundry, .techLab,
                                            .jotishaObservatory, .vedaGurukul]
}

struct TopHUD: View {
    let vm: GameViewModel
    @Binding var showBazaar: Bool
    @Binding var showStoneShop: Bool
    @Binding var showHelp: Bool
    @State private var muted: Bool = false
    @State private var confirmRestart: Bool = false
    /// `.compact` on iPhone portrait, `.regular` on iPad / Mac. Drives the
    /// HUD's compact-vs-roomy layout decisions WITHOUT affecting iPad.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// Tint for the adaptive-difficulty badge — green at low bumps, orange
    /// mid, red as the cap approaches. Gives the player a heads-up that
    /// the run is heating up well before they feel it.
    private var adaptiveBadgeColor: Color {
        let m = vm.adaptivePowerMultiplier
        if m > 1.90 { return .red }
        if m > 1.50 { return .orange }
        if m > 1.20 { return .yellow }
        return .green
    }

    /// Stat pills on the left of Row 1: lives / score / race / DP /
    /// adaptive. Pulled out as a ViewBuilder so iPhone can wrap them onto
    /// their own row while iPad keeps the single-row layout.
    @ViewBuilder private var row1StatsContent: some View {
        pill(icon: "heart.fill", color: .red, text: "\(vm.lives)")
            .infoTap("Lives — \(vm.lives) / \(vm.maxLives)",
                     "These are the HP of your central tower (the Sudarshan relic at the path's end). " +
                     "HOW BOSSES ATTACK IT: melee bosses (Mahishasura, Ravana, Indrajit, Vritra, Bhasmasura, Putana, Kali Yuga) march toward the relic and SLAM it every time they reach it — damage scales 5-50 per hit by wave. " +
                     "Trash mobs that breach the path also peck a small amount. " +
                     "At 0 lives = Game Over. " +
                     "HOW TO RESTORE LIVES: (1) Amrita Kalash button — spend 2,000 run score → +25 lives. (2) Healer's Boon — 80 Bazaar pts → +25 lives. (3) Heal-aura towers nearby (Treta+) regen the relic during waves. (4) Wall stones fully heal every tower including the centre.",
                     icon: "heart.fill", tint: .red)
        pill(icon: "star.fill", color: .cyan, text: "\(vm.score)")
            .infoTap("Run Score — \(vm.score)",
                     "Lifetime points earned THIS RUN (resets on Game Over). Every gold-yielding kill adds to it, plus a small +12+3×wave bonus on wave clear. " +
                     "Why it matters: at 2,000 score the Amrita Kalash button appears at the top of the screen — tap to spend 2,000 score for +25 lives. Big emergency life-refill before the boss.",
                     icon: "star.fill", tint: .cyan)
        if let race = vm.race {
            pill(icon: race.symbol, color: race.color, text: race.displayName)
                .infoTap(race.displayName,
                         raceTooltipBody(race),
                         icon: race.symbol, tint: race.color)
        }
        if vm.divinePoints > 0 {
            pill(icon: "sparkle",
                 color: Color(red: 0.85, green: 0.15, blue: 0.95),
                 text: "\(vm.divinePoints) DP")
                .infoTap("Divine Points — \(vm.divinePoints)",
                         "Earned every time one of your DIVINE-PATH towers (Trishul / Vajrastra / Narayana / Pashupatastra) lands the killing blow on a boss. " +
                         "Each point empowers the Parijata Briksha building by +12% production. " +
                         "Build the Parijata (gold 2,500 + 200 of each other resource) on any empty slot during the Sudarshan endgame — it's INACTIVE until you have at least one divine tower placed, then every divine point compounds its universal output.",
                         icon: "sparkle",
                         tint: Color(red: 0.85, green: 0.15, blue: 0.95))
        }
        if vm.race != nil && vm.adaptivePowerMultiplier > 1.05 {
            let pct = Int(((vm.adaptivePowerMultiplier - 1.0) * 100).rounded())
            pill(icon: "chart.line.uptrend.xyaxis",
                 color: adaptiveBadgeColor,
                 text: "+\(pct)%")
                .infoTap("Adaptive Difficulty",
                         "Enemy HP & damage bonus when your defence is dominating. Capped at +140%. Eases back if your defence is leaking. Kills pay more gold/Bazaar points at higher multipliers.",
                         icon: "chart.line.uptrend.xyaxis", tint: .orange)
        }
        // Age pill stays grouped with stats so it doesn't get truncated.
        let agePct = Int(((vm.ageEnemyPowerMultiplier - 1.0) * 100).rounded())
        pill(icon: vm.currentAge.symbol, color: vm.currentAge.color,
             text: agePct > 0
                  ? "\(vm.currentAge.shortName) • W\(vm.wave) • +\(agePct)%"
                  : "\(vm.currentAge.shortName) • W\(vm.wave)")
            .infoTap("Current Yug + Wave",
                     "Your current Yug (Satya → Treta → Dvapara) and wave number. The +N% shows the enemy power bonus your current Yug grants. Advancing yug unlocks better towers but bumps enemy HP/damage.",
                     icon: vm.currentAge.symbol, tint: vm.currentAge.color)
    }

    /// System controls on the right of Row 1: Guide / Mute / Pause /
    /// Speed / Restart. On iPhone these wrap to their own row.
    @ViewBuilder private var row1ControlsContent: some View {
        let compact = horizontalSizeClass == .compact
        Button { showHelp = true } label: {
            Image(systemName: "book.fill")
                .font(.system(size: compact ? 11 : 12, weight: .heavy))
                .foregroundColor(.cyan)
                .padding(.horizontal, compact ? 6 : 8)
                .padding(.vertical, compact ? 4 : 5)
                .background(Color.black.opacity(0.6))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.cyan.opacity(0.55), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .tooltip("Guide Book",
                 "Opens the comprehensive in-game guide book — every tower, building, enemy, stone, aura, race, Yug, control gesture, and strategy tip explained in detail. " +
                 "Tap any HUD pill or game element for a quick tooltip. Long-press for the same tooltip on a button without firing its action.",
                 icon: "book.fill", tint: .cyan)
        Button {
            muted.toggle()
            SoundEngine.shared.setMuted(muted)
        } label: {
            Image(systemName: muted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                .font(.system(size: compact ? 11 : 12, weight: .heavy))
                .foregroundColor(muted ? .gray : .cyan)
                .padding(.horizontal, compact ? 6 : 8)
                .padding(.vertical, compact ? 4 : 5)
                .background(Color.black.opacity(0.55))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .tooltip("Audio Mute",
                 "Toggles all game sound — astra fire, enemy deaths, ambient chants. Stays muted until tapped again.",
                 icon: "speaker.slash.fill", tint: .cyan)
        Button {
            HintsStore.shared.trigger(.pauseButton)
            vm.togglePause()
        } label: {
            Image(systemName: vm.isPaused ? "play.fill" : "pause.fill")
                .font(.system(size: 12, weight: .heavy))
                .foregroundColor(vm.isPaused ? .green : .white.opacity(0.85))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.55))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(vm.isPaused ? Color.green.opacity(0.8) : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .tooltip("Pause / Resume",
                 "Freezes the wave clock, enemy motion, projectiles, and production. You can still tap towers and slots to plan or rebuild. Useful for emergencies and strategic planning.",
                 icon: "pause.fill", tint: .green)
        Button {
            HintsStore.shared.trigger(.speedToggle)
            vm.toggleGameSpeed()
        } label: {
            let speed = Int(vm.gameSpeed.rounded())
            Text("\(speed)×")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundColor(speed >= 8 ? .pink
                                 : speed >= 4 ? .red
                                 : speed >= 2 ? .orange
                                 : .cyan)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.55))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .tooltip("Game Speed",
                 "Cycles 1× → 2× → 4× → 8× → 1×. Speeds up the simulation for grinding mid-waves. Physics remain accurate at high speed.",
                 icon: "forward.fill", tint: .orange)
        Button { confirmRestart = true } label: {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: 12, weight: .heavy))
                .foregroundColor(.red.opacity(0.95))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.55))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.red.opacity(0.5), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .tooltip("Restart Run",
                 "Abandons the current run and starts fresh. Towers, buildings, resources, and progress are all lost. Confirmation required.",
                 icon: "arrow.counterclockwise", tint: .red)
        .confirmationDialog(
            "Restart this run?",
            isPresented: $confirmRestart,
            titleVisibility: .visible
        ) {
            Button("Restart Run", role: .destructive) { vm.reset() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your towers, buildings, and progress will be lost.")
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            // Row 1: stats + system controls.
            //  • iPhone (compact): stats pills hidden to save vertical
            //    space — lives are visible on the Sudarshan HP bar, wave
            //    on the bottom Start/Advance buttons. Only the system
            //    controls row remains.
            //  • iPad / Mac (regular): single row with Spacer push.
            if horizontalSizeClass == .compact {
                HStack(spacing: 4) {
                    row1ControlsContent
                    Spacer(minLength: 0)
                }
            } else {
                HStack(spacing: 6) {
                    row1StatsContent
                    Spacer()
                    row1ControlsContent
                }
            }

            // Bazaar + quick-build + resources.
            //  • iPhone (compact): split into TWO non-scrolling rows so
            //    every shortcut is visible without swiping.
            //      Row A: Bazaar + 4 Tower Paths + Stones
            //      Row B: 4 Buildings + Auto + Aura + Wall
            //  • iPad / Mac: single scroll row (already fits).
            if horizontalSizeClass == .compact {
                HStack(spacing: 5) {
                    bazaarButton
                    if vm.race != nil {
                        row3aTowersContent
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 2)
                if vm.race != nil {
                    HStack(spacing: 5) {
                        row3bBuildingsContent
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 2)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 5) {
                        bazaarButton
                        if vm.race != nil {
                            row2QuickBuildContent
                            rowDivider
                        }
                        row2ResourcesContent
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
    }

    /// 5 resource pills + Stone Shop button + stones inventory.
    /// `bazaarButton` is rendered separately so it can sit at the far left
    /// of Row 2 regardless of what else follows.
    ///
    /// iPhone (compact) hides the 5 resource pills to drop a HUD line —
    /// resource counts are still visible in the BuildMenu when tapping a
    /// slot or tower. Stones inventory + the Stone Shop button stay.
    @ViewBuilder private var row2ResourcesContent: some View {
        if horizontalSizeClass != .compact {
            ForEach(ResourceKind.allCases) { kind in
                resourcePill(kind: kind)
            }
        }
        if vm.race != nil {
            rowDivider
            Button {
                showStoneShop = true
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "diamond.fill")
                        .foregroundColor(Color(red: 0.95, green: 0.55, blue: 0.85))
                    Text("Stones")
                        .foregroundColor(.white)
                }
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.55))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color(red: 0.95, green: 0.55, blue: 0.85).opacity(0.7), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .tooltip("Stone Shop",
                     "Buy power stones with gold. Stones power up towers (timed buff), activate Wall, and are the ONLY way to attach/upgrade stones on towers. Also drop free from killing Mani Murta.",
                     icon: "diamond.fill", tint: Color(red: 0.95, green: 0.55, blue: 0.85))
            let stash = StoneKind.allCases.filter { vm.stoneCount($0) > 0 }
            ForEach(stash, id: \.self) { kind in
                stonePill(kind: kind)
            }
        }
    }

    /// Quick-build tower paths + building shortcuts + Auto / Aura / Wall.
    /// Only meaningful once a race is picked. Leading divider is the
    /// caller's responsibility so this view can sit at any position.
    @ViewBuilder private var row2QuickBuildContent: some View {
        if vm.race != nil {
            EmptyView()
                .onAppear { HintsStore.shared.trigger(.quickBuildBar) }
            ForEach(QuickBuildBar.paths, id: \.self) { path in
                quickBuildButton(path)
                    .tooltip("\(path.pathName) Path",
                             pathTooltipBody(path),
                             icon: path.astras[0].symbol,
                             tint: path.pathColor)
            }
            rowDivider
            ForEach(QuickBuildBar.buildings, id: \.self) { kind in
                quickBuildBuildingButton(kind)
                    .tooltip(kind.displayName,
                             buildingTooltipBody(kind),
                             icon: kind.symbol,
                             tint: kind.color)
            }
            rowDivider
            autoToggleButton(
                icon: "play.square.fill",
                active: vm.autoStartWave,
                label: "Auto"
            ) { vm.autoStartWave.toggle() }
            .onAppear { HintsStore.shared.trigger(.autoStartToggle) }
            .tooltip("Auto-Start Waves",
                     "When ON, the next wave auto-starts ~3s after the previous one ends. A countdown badge appears so you can cancel that one timer.",
                     icon: "play.square.fill", tint: .cyan)
            let auraUnlocked = vm.isUnlocked(.middle)
            autoToggleButton(
                icon: auraUnlocked ? "cross.case.fill" : "lock.fill",
                active: vm.autoBuyAura && auraUnlocked,
                label: auraUnlocked ? "Aura" : "Treta"
            ) {
                guard auraUnlocked else { return }
                vm.autoBuyAura.toggle()
            }
            .disabled(!auraUnlocked)
            .opacity(auraUnlocked ? 1.0 : 0.45)
            .onAppear { HintsStore.shared.trigger(.autoAuraToggle) }
            .tooltip("Auto-Buy Auras",
                     "When ON, every tower auto-upgrades its Heal aura (Treta+) and Shield aura (Dvapara+) at wave end if you can afford the next tier. Saves taps late-game.",
                     icon: "cross.case.fill", tint: Color(red: 0.30, green: 0.95, blue: 0.55))
            wallButton
                .onAppear { HintsStore.shared.trigger(.wallButton) }
                .tooltip("Wall (Emergency Shield)",
                         "Spend ONE stone from inventory → all towers heal to full + gain a 5,000 HP shield. Duration scales with stone used: Chuni 10s · Panna 14s · Nila 18s · Raktamukhi 28s.",
                         icon: "shield.lefthalf.filled", tint: .green)
        }
    }

    /// iPhone Row A: 4 Tower Path quick-build buttons + Stones shop + the
    /// stones inventory (everything that goes onto a path/lives outside of
    /// the slot grid).
    @ViewBuilder private var row3aTowersContent: some View {
        ForEach(QuickBuildBar.paths, id: \.self) { path in
            quickBuildButton(path)
                .tooltip("\(path.pathName) Path",
                         pathTooltipBody(path),
                         icon: path.astras[0].symbol,
                         tint: path.pathColor)
        }
        rowDivider
        Button {
            showStoneShop = true
        } label: {
            Image(systemName: "diamond.fill")
                .font(.system(size: 11, weight: .heavy))
                .foregroundColor(Color(red: 0.95, green: 0.55, blue: 0.85))
                .padding(.horizontal, 7)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.55))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color(red: 0.95, green: 0.55, blue: 0.85).opacity(0.7), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .fixedSize()
        .tooltip("Stone Shop",
                 "Buy power stones with gold. Stones power up towers (timed buff), activate Wall, and are the ONLY way to attach/upgrade stones on towers. Also drop free from killing Mani Murta.",
                 icon: "diamond.fill", tint: Color(red: 0.95, green: 0.55, blue: 0.85))
        let stash = StoneKind.allCases.filter { vm.stoneCount($0) > 0 }
        ForEach(stash, id: \.self) { kind in
            stonePill(kind: kind)
        }
    }

    /// iPhone Row B: 4 resource-building quick-build buttons + Auto-start /
    /// Auto-aura toggles + Wall button.
    @ViewBuilder private var row3bBuildingsContent: some View {
        ForEach(QuickBuildBar.buildings, id: \.self) { kind in
            quickBuildBuildingButton(kind)
                .tooltip(kind.displayName,
                         buildingTooltipBody(kind),
                         icon: kind.symbol,
                         tint: kind.color)
        }
        rowDivider
        autoToggleButton(
            icon: "play.square.fill",
            active: vm.autoStartWave,
            label: "Auto"
        ) { vm.autoStartWave.toggle() }
        .tooltip("Auto-Start Waves",
                 "When ON, the next wave auto-starts ~3s after the previous one ends. A countdown badge appears so you can cancel that one timer.",
                 icon: "play.square.fill", tint: .cyan)
        let auraUnlocked = vm.isUnlocked(.middle)
        autoToggleButton(
            icon: auraUnlocked ? "cross.case.fill" : "lock.fill",
            active: vm.autoBuyAura && auraUnlocked,
            label: auraUnlocked ? "Aura" : "Treta"
        ) {
            guard auraUnlocked else { return }
            vm.autoBuyAura.toggle()
        }
        .disabled(!auraUnlocked)
        .opacity(auraUnlocked ? 1.0 : 0.45)
        .tooltip("Auto-Buy Auras",
                 "When ON, every tower auto-upgrades its Heal aura (Treta+) and Shield aura (Dvapara+) at wave end if you can afford the next tier. Saves taps late-game.",
                 icon: "cross.case.fill", tint: Color(red: 0.30, green: 0.95, blue: 0.55))
        wallButton
            .tooltip("Wall (Emergency Shield)",
                     "Spend ONE stone from inventory → all towers heal to full + gain a 5,000 HP shield. Duration scales with stone used: Chuni 10s · Panna 14s · Nila 18s · Raktamukhi 28s.",
                     icon: "shield.lefthalf.filled", tint: .green)
    }

    /// Bazaar / storefront pill — moved into row 2 so it sits in the same
    /// row as resources and the quick-build icons.
    private var bazaarButton: some View {
        Button {
            withAnimation(.easeOut(duration: 0.18)) { showBazaar = true }
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "storefront.fill")
                    .foregroundColor(.yellow)
                Text("\(vm.availablePoints)")
                    .foregroundColor(.white)
                    .monospacedDigit()
            }
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(LinearGradient(colors: [Color(red: 0.55, green: 0.30, blue: 0.78),
                                                  Color(red: 0.32, green: 0.18, blue: 0.55)],
                                         startPoint: .top, endPoint: .bottom))
            )
            .overlay(Capsule().stroke(Color.white.opacity(0.30), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .tooltip("Bazaar Points Shop",
                 "Spend Bazaar Points (number shown) on Instant Items (resources/lives), Run Buffs (Wave Tribute, Wave Veda Tithe), and Permanent Perks (carry over runs). Points earned from kills + wave clears.",
                 icon: "storefront.fill", tint: Color(red: 0.78, green: 0.52, blue: 0.95))
    }

    /// Thin vertical divider used between the resource / tower / building /
    /// toggle clusters inside the consolidated row 2.
    private var rowDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.15))
            .frame(width: 1, height: 18)
            .padding(.horizontal, 2)
    }

    /// Quick-build button for a resource building — mirrors the tower
    /// quick-build button. Tap to arm, tap again to disarm; tapping any
    /// empty build slot while armed places this building in one tap.
    private func quickBuildBuildingButton(_ kind: BuildingKind) -> some View {
        let armed = vm.armedQuickBuildBuilding == kind
        let affordable = vm.canAffordBuilding(kind)
        // Show the actual cost of the NEXT building — same-kind tax climbs
        // every time the player places another.
        let cost = vm.nextBuildingPlacementCost(for: kind)
        let owned = vm.ownedBuildingCount(of: kind)
        return Button {
            vm.armQuickBuildBuilding(armed ? nil : kind)
        } label: {
            VStack(spacing: 1) {
                Image(systemName: kind.symbol)
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundColor(armed ? .black : kind.color)
                Text("\(cost.gold)")
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                    .foregroundColor(armed ? .black : .white.opacity(0.8))
                    .monospacedDigit()
            }
            .frame(width: 32, height: 32)
            .background(armed ? kind.color : Color.black.opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(armed ? Color.white : kind.color.opacity(0.55), lineWidth: armed ? 1.5 : 1)
            )
            .overlay(alignment: .topTrailing) {
                if owned > 0 {
                    Text("\(owned)")
                        .font(.system(size: 7, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 3)
                        .background(Capsule().fill(Color.orange))
                        .offset(x: 3, y: -3)
                }
            }
            .opacity(affordable ? 1 : 0.45)
        }
        .buttonStyle(.plain)
        .disabled(!affordable)
    }

    private func quickBuildButton(_ path: TowerPath) -> some View {
        let armed = vm.armedQuickBuildPath == path
        let kind = path.astras[0]
        let affordable = vm.canAffordPath(path)
        let cost = vm.nextTowerPlacementCost(for: path)
        let owned = vm.ownedTowerCount(of: path)
        return Button {
            // Toggle arming on/off — second tap on the same path disarms.
            // Going through `armQuickBuildTower` also disarms any building.
            vm.armQuickBuildTower(armed ? nil : path)
        } label: {
            VStack(spacing: 1) {
                Image(systemName: kind.symbol)
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundColor(armed ? .black : kind.color)
                Text("\(cost.gold)")
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                    .foregroundColor(armed ? .black : .white.opacity(0.8))
                    .monospacedDigit()
            }
            .frame(width: 32, height: 32)
            .background(armed ? kind.color : Color.black.opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(armed ? Color.white : kind.color.opacity(0.55), lineWidth: armed ? 1.5 : 1)
            )
            .overlay(alignment: .topTrailing) {
                if owned > 0 {
                    Text("\(owned)")
                        .font(.system(size: 7, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 3)
                        .background(Capsule().fill(Color.orange))
                        .offset(x: 3, y: -3)
                }
            }
            .opacity(affordable ? 1 : 0.45)
        }
        .buttonStyle(.plain)
        .disabled(!affordable)
    }

    private func autoToggleButton(
        icon: String,
        active: Bool,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .heavy))
                Text(label)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
            }
            .foregroundColor(active ? .black : .white.opacity(0.85))
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .background(active ? Color.cyan : Color.black.opacity(0.55))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(active ? Color.white : Color.cyan.opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func pill(icon: String, color: Color, text: String) -> some View {
        let isCompact = horizontalSizeClass == .compact
        return HStack(spacing: isCompact ? 3 : 4) {
            Image(systemName: icon).foregroundColor(color)
            Text(text).foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .font(.system(size: isCompact ? 10 : 12,
                      weight: .semibold, design: .rounded))
        .padding(.horizontal, isCompact ? 6 : 8)
        .padding(.vertical, isCompact ? 3 : 5)
        .background(Color.black.opacity(0.55))
        .clipShape(Capsule())
        .fixedSize(horizontal: false, vertical: true)
    }

    /// Wall button — pay a one-time fee (gold + jotisha + veda) to heal
    /// every tower to full AND grant a shield that absorbs the next
    /// Wall is now stone-driven and TIMED. Tapping spends the highest-tier
    /// stone available (Raktamukhi > Nila > Panna > Chuni) — a Raktamukhi
    /// buys 28 s of wall, a Chuni only 10 s. When active the button
    /// shows the seconds remaining and is locked until the timer expires.
    @ViewBuilder
    private var wallButton: some View {
        let active = vm.wallTimer > 0
        let affordable = vm.canActivateWall()
        let nextStone = vm.bestWallStone()
        Button {
            // Silent — tap activates the wall if all preconditions hold,
            // no-op otherwise. Long-press the button to see what's
            // missing (no stones, no towers, already active).
            if !active && affordable && nextStone != nil && !vm.towers.isEmpty {
                vm.activateWall()
            }
        } label: {
            VStack(spacing: 1) {
                HStack(spacing: 2) {
                    Image(systemName: active ? "shield.fill" : "shield.lefthalf.filled")
                        .font(.system(size: 10, weight: .heavy))
                    Text(active
                         ? String(format: "%.0fs", vm.wallTimer)
                         : "Wall")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                }
                if !active {
                    if let kind = nextStone {
                        let secs = Int(GameViewModel.wallDuration(for: kind).rounded())
                        HStack(spacing: 2) {
                            Image(systemName: kind.symbol)
                                .foregroundColor(kind.color)
                            Text("\(secs)s")
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .font(.system(size: 8, weight: .heavy, design: .rounded))
                        .lineLimit(1)
                        .fixedSize()
                    } else {
                        Text("no stone")
                            .font(.system(size: 7, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(red: 1.0, green: 0.45, blue: 0.45))
                            .lineLimit(1)
                            .fixedSize()
                    }
                }
            }
            .foregroundColor(active ? .black : .white.opacity(0.85))
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .background(active ? Color.green : Color.black.opacity(0.55))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(active ? Color.white
                                        : (affordable ? Color.green.opacity(0.6) : Color.gray.opacity(0.4)),
                                 lineWidth: 1)
            )
            // Wall-time-remaining progress bar — overlaid under the
            // active wall button so the player sees at a glance how much
            // time the stone is still buying.
            .overlay(alignment: .bottom) {
                if active, let total = vm.wallActivationDuration, total > 0 {
                    GeometryReader { geo in
                        let frac = max(0, min(1, vm.wallTimer / total))
                        Capsule()
                            .fill(Color.black.opacity(0.7))
                            .frame(width: geo.size.width * CGFloat(frac), height: 3)
                            .offset(y: -1)
                    }
                    .frame(height: 3)
                }
            }
            .opacity(active || affordable ? 1.0 : 0.55)
        }
        .buttonStyle(.plain)
    }

    /// God Mode button — distinct from the Wall button. Tapping it makes
    /// every resource building fire divine beams at enemies for 12 s.
    /// Locked until W8 + steep cost, so it's a real panic button rather
    /// than a free clear. Visually distinct (gold / sunburst) so it
    /// reads as a different ability from Wall / Aura.
    @ViewBuilder
    private var godModeButton: some View {
        let active = vm.isGodModeActive
        let affordable = vm.canActivateGodMode()
        let unlocked = vm.wave >= GameViewModel.godModeUnlockWave
        let cost = GameViewModel.godModeActivationCost
        Button {
            vm.activateGodMode()
        } label: {
            VStack(spacing: 1) {
                HStack(spacing: 2) {
                    Image(systemName: active ? "sun.max.fill" : "sparkles")
                        .font(.system(size: 10, weight: .heavy))
                    Text(active
                         ? String(format: "%.0fs", vm.godModeTimer)
                         : (unlocked ? "Pralay" : "W\(GameViewModel.godModeUnlockWave)"))
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                }
                if !active && unlocked {
                    HStack(spacing: 2) {
                        Text("\(cost.gold)")
                        Image(systemName: "dollarsign.circle.fill").foregroundColor(.yellow)
                    }
                    .font(.system(size: 7, weight: .heavy, design: .rounded))
                }
            }
            .foregroundColor(active ? .black : .white.opacity(0.85))
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .background(active
                        ? Color(red: 1.0, green: 0.85, blue: 0.25)
                        : Color.black.opacity(0.55))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(active ? Color.white
                                        : (affordable ? Color(red: 1.0, green: 0.85, blue: 0.25).opacity(0.7)
                                                      : Color.gray.opacity(0.4)),
                                 lineWidth: 1)
            )
            .opacity(active || affordable ? 1.0 : 0.55)
        }
        .buttonStyle(.plain)
        .disabled(!affordable && !active)
    }

    private func resourcePill(kind: ResourceKind) -> some View {
        HStack(spacing: 3) {
            Image(systemName: kind.symbol).foregroundColor(kind.color)
            Text("\(vm.stock.amount(kind))").foregroundColor(.white)
        }
        .font(.system(size: 11, weight: .semibold, design: .rounded))
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.5))
        .clipShape(Capsule())
        .infoTap(kind.displayName, resourceTooltipBody(kind), icon: kind.symbol, tint: kind.color)
    }

    private func raceTooltipBody(_ race: Race) -> String {
        switch race {
        case .raghuvansh:
            return "RAGHUVANSH (Ikshvaku line — Rama's dynasty). The legendary warrior lineage. " +
                "SIGNATURE POWER: +25% damage to every BOSS enemy (Mahishasura, Ravana, Indrajit, Tarakasura, Vritra, Bhasmasura, Putana, Kali Yuga). " +
                "Best for: aggressive single-target builds that focus boss melts."
        case .maurya:
            return "MAURYA (Chandragupta's empire). Apex of ancient engineering. " +
                "SIGNATURE POWER: +30% projectile speed across every astra — your arrows hit before enemies can dodge or charge. " +
                "Best for: high-rate astras (Dart, Aindrastra, Maya) that benefit from rapid hit chains."
        case .gupta:
            return "GUPTA (Golden Age of India). Sages who saw beyond illusion. " +
                "SIGNATURE POWER: every tower can target INVISIBLE enemies (Mayavi, Putana etc.) — no Drishti tower required. " +
                "Best for: skipping the entire Drishti detection path and saving slots for damage."
        case .pratihara:
            return "PRATIHARA (gatekeepers of the western front). The defender's lineage. " +
                "SIGNATURE POWER: +30% starting tower HP — every tower spawns tankier and survives more boss hits. " +
                "Best for: front-line setups where towers absorb melee."
        case .rashtrakuta:
            return "RASHTRAKUTA (Deccan empire). Economy-first dynasty. " +
                "SIGNATURE POWER: −25% on every BUILDING cost (gold mine, foundry, lab, observatory, gurukul, parijata). " +
                "Best for: heavy economy openers — you out-scale the curve by W5."
        case .pal:
            return "PAL (Bengal, patrons of Buddhist sciences). Stone-craft empire. " +
                "SIGNATURE POWER: −25% on every STONE cost (attach + upgrade + buy-with-gold). " +
                "RECOMMENDED FOR BEGINNERS — cheaper stones make Wall + tower boosts trivially affordable. " +
                "Best for: stone-driven builds where you stack Chuni/Panna/Nila for sustained DPS bursts."
        case .chola:
            return "CHOLA (maritime traders, Tamil south). " +
                "SIGNATURE POWER: +1% gold AND Bazaar points per kill, plus a small bump to all building production. " +
                "Best for: long runs that snowball — every kill compounds into more gold + faster bazaar buys."
        case .sen:
            return "SEN (scholars, late Bengal). " +
                "SIGNATURE POWER: +1 chain target on Aindrastra (T2 arrow) and Naga Pasha (T2 water). Sen Aindra hits 3 enemies per shot, Sen Naga chains to 3. " +
                "RECOMMENDED FOR BEGINNERS — clears packed waves with minimal micromanagement. " +
                "Best for: trash-clear builds where you face waves of fodder."
        case .ahom:
            return "AHOM (Assam highlands). Forest defenders. " +
                "SIGNATURE POWER: +4.5 HP/sec passive tower regeneration during waves AND +25% aura range. " +
                "Best for: defensive grinds where Heal + Shield auras keep towers indestructible through long sieges."
        }
    }

    private func resourceTooltipBody(_ kind: ResourceKind) -> String {
        switch kind {
        case .gold:
            return "Universal currency. Buy towers, buildings, age upgrades, stones, and Pralay. Earned from every kill + wave clear. Gold Mine produces it during waves."
        case .metal:
            return "Mid-game resource. Required for T2-T4 astras (Aindra, Trishul, Pashupatastra). Foundry building produces it."
        case .tech:
            return "Used by Aindrastra (T2 arrow), Sudarshana Chakra (T4), and the Modern Yug upgrade. Tech Lab produces it."
        case .jotisha:
            return "Mystic resource. Powers Heal aura tiers, Bala drishti, Suryastra, divine astras. Observatory produces it."
        case .veda:
            return "Sacred knowledge. Powers Shield aura tiers, T4 divine ultimates, Amrit Kalash. Gurukul produces it."
        }
    }

    /// Inventory pill for power stones harvested from Mani Murta kills.
    private func stonePill(kind: StoneKind) -> some View {
        HStack(spacing: 3) {
            Image(systemName: kind.symbol).foregroundColor(kind.color)
            Text("\(vm.stoneCount(kind))").foregroundColor(.white)
        }
        .font(.system(size: 11, weight: .semibold, design: .rounded))
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.5))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(kind.color.opacity(0.5), lineWidth: 1))
        .infoTap(kind.displayName, stoneTooltipBody(kind), icon: kind.symbol, tint: kind.color)
    }

    private func stoneTooltipBody(_ kind: StoneKind) -> String {
        switch kind {
        case .chuni:
            return "+Damage stone (Manikya). Boosts attached tower's damage by 20% per level. Wall duration: 10s (Chuni)."
        case .panna:
            return "+Fire Rate stone (Marakata). Boosts attack speed by 15% per level. Wall duration: 14s (Panna)."
        case .nila:
            return "+Range stone (Nilamani). Boosts tower range by 15% per level. Wall duration: 18s (Nila)."
        case .raktamukhi:
            return "+ALL Stats stone (Rakta-Nila). +10% damage, +10% fire rate, +10% range per level. Premium. Wall duration: 28s (Raktamukhi)."
        }
    }

    private func pathTooltipBody(_ path: TowerPath) -> String {
        let astras = path.astras.map(\.displayName).joined(separator: " → ")
        switch path {
        case .arrow:
            return "Archer / Arrow path. T1-T4: \(astras). Steady single-target DPS that culminates in Sudarshana Chakra (splash disc, full-area)."
        case .fire:
            return "Fire path — burn DoT family. T1-T4: \(astras). Trades raw burst for ticking burn damage. Ultimate: Bhambhrastra (divine inferno)."
        case .water:
            return "Water path — slow + crowd control. T1-T3: \(astras). Naga Pasha chains, Garudastra splashes wind."
        case .ice:
            return "Ice path — freeze / stun. T1-T3: \(astras). Mohini Astra AoE-freezes whole packs at endgame."
        case .divine:
            return "Divine path. T1-T4: \(astras). Heavy hitters culminating in Pashupatastra (Dvapara-only T4 ultimate, full-area)."
        case .maya:
            return "Maya / Illusion path. T1-T4: \(astras). Phantom-arrow line. T4 Brahmasira is Dvapara-locked."
        case .drishti:
            return "Sensory path — detects invisible. T1-T3: \(astras). Required to target Putana / Bhasmasura early on (or play as Gupta race)."
        case .sanjivani:
            return "Healer path. T1-T3: \(astras). Heals nearby towers. Amrit Kalash is a divine restorative."
        case .rekha:
            return "Barrier path. T1-T3: \(astras). Shield aura. Vajra Kavach is the diamond endgame shield."
        }
    }

    private func buildingTooltipBody(_ kind: BuildingKind) -> String {
        let cost = kind.cost
        let costStr = "\(Int(cost.gold))g"
            + (cost.metal > 0 ? " + \(Int(cost.metal))m" : "")
            + (cost.tech > 0 ? " + \(Int(cost.tech))t" : "")
            + (cost.jotisha > 0 ? " + \(Int(cost.jotisha))j" : "")
            + (cost.veda > 0 ? " + \(Int(cost.veda))v" : "")
        let gen = String(format: "%.2f", kind.baseGenPerSec)
        switch kind {
        case .goldMine:
            return "\(kind.sanskritName). Generates \(gen) gold/sec during waves. Cost: \(costStr). Upgrades to L4 for ~12× output. Build first — gold gates everything."
        case .metalFoundry:
            return "\(kind.sanskritName). Generates \(gen) metal/sec during waves. Cost: \(costStr). Required for T2-T4 astras (Aindra/Trishul/Pashupat)."
        case .techLab:
            return "\(kind.sanskritName). Generates \(gen) tech/sec during waves. Cost: \(costStr). Powers Aindrastra, Sudarshana Chakra, and the Modern Yug upgrade."
        case .jotishaObservatory:
            return "\(kind.sanskritName). Generates \(gen) jotisha/sec during waves. Cost: \(costStr). Powers Heal auras, Bala drishti, Suryastra, divine astras."
        case .vedaGurukul:
            return "\(kind.sanskritName). Generates \(gen) veda/sec during waves. Cost: \(costStr). Powers Shield auras, T4 ultimates, Amrit Kalash."
        case .parijata:
            return "\(kind.sanskritName) — the divine wish-fulfilling tree. Generates \(gen) of EVERY resource per tick. Endgame-only. Cost: \(costStr)."
        }
    }
}

// MARK: - Bottom bar

struct BottomBar: View {
    let vm: GameViewModel
    @State private var showAgeCostDetail: Bool = false

    var body: some View {
        VStack(spacing: 6) {
            if let next = vm.nextAgeToPurchase {
                ageUpgradeButton(next: next)
            }
            HStack(spacing: 8) {
                Button {
                    vm.startNextWave()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: vm.isWaveActive ? "hourglass" : "play.fill")
                        Text(buttonText)
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(vm.isWaveActive ? Color.gray.opacity(0.7) : Color.cyan)
                    .clipShape(Capsule())
                }
                .disabled(vm.isWaveActive || vm.isGameOver)
                .tooltip(nextWaveTooltipTitle,
                         nextWaveTooltipBody,
                         icon: vm.isWaveActive ? "hourglass" : "play.fill",
                         tint: .cyan)

                // Auto-start countdown badge — appears between waves when
                // the player has the Auto toggle on.
                if vm.autoStartCountdown > 0 && !vm.isWaveActive {
                    Button {
                        vm.cancelAutoStartCountdown()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .font(.system(size: 11, weight: .heavy))
                            Text(String(format: "%.1fs", vm.autoStartCountdown))
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .monospacedDigit()
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.7))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.cyan.opacity(0.6), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .tooltip("Auto-Start Countdown",
                             "Next wave starts in \(String(format: "%.1fs", vm.autoStartCountdown)). Tap to cancel just this one and start manually.",
                             icon: "timer", tint: .cyan)
                }

                Spacer()

                // God Mode docked here so it can't overlap path slots.
                if vm.race != nil && !vm.isGameOver {
                    GodModeFloatingButton(vm: vm)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        // No background gradient — let the game field show through so the
        // bottom row of build slots stays visible AND tappable. Each
        // button inside (Next Wave, age upgrade, God Mode) carries its
        // own capsule background so they still read against the field.
    }

    private func ageUpgradeButton(next: Age) -> some View {
        let affordable = vm.canPurchaseNextAge()
        let cost = vm.ageUpgradeCost(to: next)
        return HStack(spacing: 6) {
            Button {
                // First tap reveals the cost row (visible UI, not a banner).
                // Second tap purchases if affordable. No info banners on tap.
                if showAgeCostDetail {
                    if affordable {
                        vm.purchaseNextAge()
                    }
                    showAgeCostDetail = false
                } else {
                    showAgeCostDetail = true
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: next.symbol).foregroundColor(next.color)
                    Text(showAgeCostDetail
                         ? (affordable ? "Confirm \(next.shortName)" : "Need:")
                         : "Advance to \(next.shortName) Yug")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    if showAgeCostDetail {
                        ResourceCostRow(cost: cost, size: 9, available: vm.stock)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(affordable ? next.color.opacity(showAgeCostDetail ? 0.5 : 0.32)
                                       : Color.black.opacity(0.5))
                .overlay(Capsule().stroke(next.color.opacity(affordable ? 0.9 : 0.45),
                                          lineWidth: showAgeCostDetail ? 1.5 : 1))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .opacity(affordable || showAgeCostDetail ? 1 : 0.7)
            .tooltip("Advance to \(next.shortName) Yug",
                     ageTooltipBody(next: next, affordable: affordable),
                     icon: next.symbol, tint: next.color)
            // Dismiss-on-tap-outside support: tapping the empty area
            // around the button cancels the detail view.
            if showAgeCostDetail {
                Button {
                    showAgeCostDetail = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    private var atKaliYugaWave: Bool {
        vm.wave >= GameViewModel.kaliYugaArrivalWave
            && vm.sudarshanPhase != .victory
    }

    private var buttonText: String {
        if vm.isWaveActive { return "Wave \(vm.wave) active" }
        if atKaliYugaWave { return "Summon Kali Yuga" }
        return vm.wave == 0 ? "Start Defence" : "Next Wave"
    }

    private var nextWaveTooltipTitle: String {
        if vm.isWaveActive { return "Wave Active" }
        if atKaliYugaWave  { return "Summon Kali Yuga" }
        return vm.wave == 0 ? "Start Defence" : "Start Next Wave"
    }

    private func ageTooltipBody(next: Age, affordable: Bool) -> String {
        let benefit: String
        switch next {
        case .ancient: benefit = "Starting Yug — already unlocked."
        case .middle:  benefit = "Treta Yug: unlocks T2 astras (Aindra/Suryastra/etc.), Heal aura L1, Raktabija enemy starts spawning."
        case .modern:  benefit = "Dvapara Yug: unlocks T3 (Shakti/Rudra/Narayana), T4 divine ultimates, Shield aura L1, Vritra enemy. Full-area astras become possible."
        }
        let prefix = affordable ? "READY — tap once to see cost, again to confirm." : "Not enough resources yet."
        return "\(prefix) \(benefit)"
    }

    private var nextWaveTooltipBody: String {
        if vm.isWaveActive {
            return "Wave \(vm.wave) is in progress. Wait for all enemies to die — then this becomes the Next Wave button again."
        }
        if atKaliYugaWave {
            return "Final boss is ready. Summoning Kali Yuga begins the Sudarshan endgame phase. Make sure your central tower charge is ready."
        }
        return vm.wave == 0
            ? "Tap to spawn the first wave. Place at least one offensive tower first or you'll lose lives fast."
            : "Tap to spawn wave \(vm.wave + 1). Each new wave gives ~10s of free production before enemies arrive."
    }

}

// MARK: - Build menu (tabs: Towers / Buildings)

enum BuildTab { case towers, buildings }

struct BuildMenu: View {
    let vm: GameViewModel
    let slotIndex: Int

    @State private var tab: BuildTab = .towers
    @State private var codexAstra: TowerKind? = nil

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                tabButton(title: "Towers", icon: "burst.fill", active: tab == .towers) {
                    tab = .towers
                }
                tabButton(title: "Buildings", icon: "building.2.fill", active: tab == .buildings) {
                    tab = .buildings
                }
            }

            if tab == .towers {
                // Healer (sanjivani) and barrier (rekha) paths are no longer
                // built directly — heal and shield are unlocked as aura
                // toggles on every other tower once the matching Yug is open.
                let buildable = TowerPath.allCases.filter {
                    $0 != .sanjivani && $0 != .rekha
                }
                HStack(spacing: 5) {
                    ForEach(buildable) { path in
                        Button {
                            // Silent — tap places the tower if affordable
                            // + age-unlocked. Long-press the card to see
                            // the cost breakdown + lock reason tooltip.
                            if vm.isPathAgeUnlocked(path) && vm.canAffordPath(path) {
                                vm.buildTower(at: slotIndex, path: path)
                            }
                        } label: {
                            towerPathCard(path)
                        }
                        .buttonStyle(.plain)
                        .opacity(vm.canAffordPath(path) ? 1 : 0.45)
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.4)
                                .onEnded { _ in
                                    codexAstra = path.astras[0]
                                }
                        )
                        .tooltip("Build \(path.astras[0].displayName)",
                                 buildTowerTooltipBody(path),
                                 icon: path.astras[0].symbol,
                                 tint: path.pathColor)
                    }
                }
                Text("Long-press a tower to view its codex · Heal/Shield unlock as aura toggles")
                    .font(.system(size: 8))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            } else {
                // Parijata Briksha — the divine wish-tree. Unlocks from
                // W11 onward (the late-Dvapara push toward the Anta) and
                // can be planted ONCE per run. Already-built parijatas
                // remove it from the menu so the player can't stack them.
                let parijataUnlocked = vm.wave >= 11
                let parijataAlreadyPlanted = vm.buildings.contains(where: { $0.kind == .parijata })
                let placeable = BuildingKind.allCases.filter { kind in
                    if kind == .parijata {
                        return parijataUnlocked && !parijataAlreadyPlanted
                    }
                    return !kind.requiresEndgame
                }
                HStack(spacing: 5) {
                    ForEach(placeable) { kind in
                        Button {
                            // Silent — tap places the building if afford-
                            // able, no-op otherwise. Long-press the card
                            // for the cost-breakdown tooltip.
                            if vm.canAffordBuilding(kind) {
                                vm.placeBuilding(at: slotIndex, kind: kind)
                            }
                        } label: {
                            buildingCard(kind)
                        }
                        .buttonStyle(.plain)
                        .opacity(vm.canAffordBuilding(kind) ? 1 : 0.45)
                        .tooltip("Build \(kind.displayName)",
                                 buildBuildingTooltipBody(kind),
                                 icon: kind.symbol,
                                 tint: kind.color)
                    }
                }
            }

            Button("Cancel") { vm.deselectAll() }
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.cyan.opacity(0.35), lineWidth: 1)
                )
        )
        .padding(.horizontal, 8)
        .overlay(
            Group {
                if let astra = codexAstra {
                    AstraCodexCard(kind: astra) { codexAstra = nil }
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
        )
    }

    private func tabButton(title: String, icon: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 10))
                Text(title).font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(active ? .white : .white.opacity(0.55))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(active ? Color.cyan.opacity(0.35) : Color.black.opacity(0.4)))
            .overlay(Capsule().stroke(active ? Color.cyan : Color.clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func towerPathCard(_ path: TowerPath) -> some View {
        let base = path.astras[0]
        // Show the actual cost of the NEXT one — climbs as the player
        // stacks more of the same path.
        let cost = vm.nextTowerPlacementCost(for: path)
        let owned = vm.ownedTowerCount(of: path)
        let ageLocked = !vm.isPathAgeUnlocked(path)
        let reqAge = base.requiredAge
        return VStack(spacing: 2) {
            Image(systemName: base.symbol)
                .font(.system(size: 18))
                .foregroundColor(path.pathColor)
            Text(base.displayName)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(base.tagline)
                .font(.system(size: 7))
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if ageLocked {
                HStack(spacing: 2) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 7, weight: .heavy))
                    Text("\(reqAge.shortName) Yug")
                        .font(.system(size: 7, weight: .heavy, design: .rounded))
                }
                .foregroundColor(reqAge.color)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Capsule().fill(Color.black.opacity(0.6)))
                .overlay(Capsule().stroke(reqAge.color.opacity(0.7), lineWidth: 0.5))
            } else if owned > 0 {
                Text("×\(owned) owned")
                    .font(.system(size: 7, weight: .heavy, design: .rounded))
                    .foregroundColor(.orange)
            }
            ResourceCostRow(cost: cost, size: 8, available: vm.stock)
            // Mini upgrade preview
            HStack(spacing: 1) {
                Image(systemName: path.astras[1].symbol)
                    .font(.system(size: 7))
                    .foregroundColor(.white.opacity(0.45))
                Image(systemName: "chevron.right")
                    .font(.system(size: 5))
                    .foregroundColor(.white.opacity(0.3))
                Image(systemName: path.astras[2].symbol)
                    .font(.system(size: 7))
                    .foregroundColor(.white.opacity(0.55))
            }
            .padding(.top, 1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .padding(.horizontal, 3)
        .background(Color.black.opacity(0.4))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(path.pathColor.opacity(0.65), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func buildTowerTooltipBody(_ path: TowerPath) -> String {
        let cost = vm.nextTowerPlacementCost(for: path)
        let costStr = resourceShort(cost)
        let owned = vm.ownedTowerCount(of: path)
        let ageLocked = !vm.isPathAgeUnlocked(path)
        let reqAge = path.astras[0].requiredAge
        let astras = path.astras.map(\.displayName).joined(separator: " → ")
        var lines: [String] = []
        lines.append("Cost: \(costStr)\(owned > 0 ? " · already own ×\(owned) (next costs more)" : "")")
        if ageLocked { lines.append("LOCKED — needs \(reqAge.shortName) Yug.") }
        lines.append("Upgrade chain: \(astras)")
        return lines.joined(separator: " · ")
    }

    private func buildBuildingTooltipBody(_ kind: BuildingKind) -> String {
        let cost = vm.nextBuildingPlacementCost(for: kind)
        let costStr = resourceShort(cost)
        let owned = vm.ownedBuildingCount(of: kind)
        let gen = String(format: "%.2f", kind.baseGenPerSec)
        var body = "Cost: \(costStr). "
        body += kind == .parijata
            ? "Generates +\(Int(kind.baseGenPerSec))/s of EVERY resource during waves."
            : "Generates \(gen) \(kind.resource.displayName)/sec during waves."
        if owned > 0 { body += " You own ×\(owned) (price climbs with stacking)." }
        return body
    }

    private func resourceShort(_ r: Resources) -> String {
        var parts: [String] = []
        if r.gold > 0    { parts.append("\(Int(r.gold))g") }
        if r.metal > 0   { parts.append("\(Int(r.metal))m") }
        if r.tech > 0    { parts.append("\(Int(r.tech))t") }
        if r.jotisha > 0 { parts.append("\(Int(r.jotisha))j") }
        if r.veda > 0    { parts.append("\(Int(r.veda))v") }
        return parts.isEmpty ? "Free" : parts.joined(separator: " + ")
    }

    private func buildingCard(_ kind: BuildingKind) -> some View {
        let cost = vm.nextBuildingPlacementCost(for: kind)
        let owned = vm.ownedBuildingCount(of: kind)
        return VStack(spacing: 2) {
            Image(systemName: kind.symbol)
                .font(.system(size: 18))
                .foregroundColor(kind.color)
            Text(kind.displayName)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(kind.sanskritName)
                .font(.system(size: 7))
                .foregroundColor(.white.opacity(0.55))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            HStack(spacing: 2) {
                Image(systemName: "arrow.up.right.circle")
                    .font(.system(size: 7))
                    .foregroundColor(kind.color)
                Text(kind == .parijata
                     ? "+\(Int(kind.baseGenPerSec))/s ALL"
                     : "+1/s \(kind.resource.displayName.prefix(1))")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            if owned > 0 {
                Text("×\(owned) owned")
                    .font(.system(size: 7, weight: .heavy, design: .rounded))
                    .foregroundColor(.orange)
            }
            ResourceCostRow(cost: cost, size: 8, available: vm.stock)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .padding(.horizontal, 3)
        .background(Color.black.opacity(0.4))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(kind.color.opacity(0.65), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Tower menu

struct TowerMenu: View {
    let vm: GameViewModel
    let tower: Tower

    @State private var showStonePicker = false

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: tower.kind.symbol).foregroundColor(tower.kind.color)
                Text(tower.kind.displayName)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("• Tier \(tower.tier)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }

            HStack(spacing: 8) {
                statTile(icon: "burst.fill", value: String(format: "%.0f", vm.damage(of: tower)), label: "DMG")
                statTile(icon: "timer", value: String(format: "%.2fs", vm.fireInterval(of: tower)), label: "Rate")
                statTile(icon: "scope", value: "\(Int(vm.range(of: tower)))", label: "Range")
            }
            // Veteran power — kills give +1 flat damage each, so seasoned
            // defenders quietly out-hit fresh ones with the same astra.
            if tower.kills > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "rosette")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.yellow)
                    Text("\(tower.kills) kills · +\(Int(tower.veteranPower)) atk")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.yellow.opacity(0.12)))
                .overlay(Capsule().stroke(Color.yellow.opacity(0.45), lineWidth: 0.8))
            }
            // Boss-slayer badge — the tower has personally finished bosses.
            // Each kill = +12% damage permanently AND +1 special-attack charge.
            if tower.bossKills > 0 {
                let dmgPct = Int((tower.bossPowerMultiplier - 1.0) * 100)
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(Color(red: 1.0, green: 0.55, blue: 0.20))
                    Text("\(tower.bossKills) boss kill\(tower.bossKills == 1 ? "" : "s") · +\(dmgPct)% dmg")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(red: 1.0, green: 0.55, blue: 0.20))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if tower.specialCharges > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 9, weight: .heavy))
                            Text("×\(tower.specialCharges)")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(.yellow)
                    }
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color(red: 1.0, green: 0.55, blue: 0.20).opacity(0.14)))
                .overlay(Capsule().stroke(Color(red: 1.0, green: 0.55, blue: 0.20).opacity(0.55), lineWidth: 0.8))
            }

            // Stone slot section
            stoneSection

            // Heal / Shield aura toggles — unlocked by age, replace the
            // removed Sanjivani and Rekha tower paths.
            auraSection

            HStack(spacing: 10) {
                upgradeButton
                Button {
                    vm.startRelocate(towerID: tower.id)
                } label: {
                    relocateTile(cost: vm.relocateCost(for: tower),
                                 affordable: vm.canAffordRelocate(tower))
                }
                .buttonStyle(.plain)
                .disabled(!vm.canAffordRelocate(tower))
                .tooltip("Relocate Tower",
                         "Move this tower to a different empty slot. The first relocate is free; subsequent moves cost gold (scales with how often you've shuffled it).",
                         icon: "arrow.up.and.down.and.arrow.left.and.right",
                         tint: .cyan)
                Button {
                    vm.sellTower(id: tower.id)
                } label: {
                    sellTile(value: vm.effectiveSellValue(of: tower))
                }
                .buttonStyle(.plain)
                .tooltip("Sell Tower",
                         "Refund ~60% of the tower's invested resources (including upgrades & aura levels) back into your stock. Stone is also returned to inventory.",
                         icon: "dollarsign.circle.fill",
                         tint: .red)
            }

            Button("Close") { vm.deselectAll() }
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(12)
        // Cap the width so a socketed stone row (which uses a Spacer to
        // push action buttons right) doesn't expand the whole menu to
        // span the entire screen.
        .frame(maxWidth: 360)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(tower.kind.color.opacity(0.4), lineWidth: 1)
                )
        )
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private var auraSection: some View {
        let healUnlocked = vm.isUnlocked(.middle)
        let shieldUnlocked = vm.isUnlocked(.modern)
        if healUnlocked || shieldUnlocked {
            HStack(spacing: 8) {
                if healUnlocked {
                    auraTierToggle(
                        icon: "cross.case.fill",
                        title: "Heal",
                        level: tower.healAuraLevel,
                        color: Color(red: 0.30, green: 0.95, blue: 0.55),
                        // Mass cost — applies to every same-kind same-tier tower.
                        nextCost: vm.massHealAuraCost(for: tower),
                        canUpgrade: vm.canUpgradeHealAura(on: tower),
                        massCount: vm.healAuraMassCount(pivot: tower)
                    ) {
                        vm.upgradeHealAura(towerID: tower.id)
                    }
                }
                if shieldUnlocked {
                    auraTierToggle(
                        icon: "shield.checkered",
                        title: "Shield",
                        level: tower.shieldAuraLevel,
                        color: .cyan,
                        nextCost: vm.massShieldAuraCost(for: tower),
                        canUpgrade: vm.canUpgradeShieldAura(on: tower),
                        massCount: vm.shieldAuraMassCount(pivot: tower)
                    ) {
                        vm.upgradeShieldAura(towerID: tower.id)
                    }
                }
            }
        }
    }

    /// Tier-aware aura toggle: shows current level (0-3), upgrade cost for
    /// the next tier, and "MAX" once the third level is reached.
    private func auraTierToggle(
        icon: String,
        title: String,
        level: Int,
        color: Color,
        nextCost: Resources,
        canUpgrade: Bool,
        massCount: Int = 1,
        action: @escaping () -> Void
    ) -> some View {
        let isMax = level >= GameViewModel.maxAuraLevel
        let active = level > 0
        // L4 is the mythic-tier upgrade — heal becomes "Sanjivani" (the
        // life-restoring herb from the Ramayana), shield becomes "Lakshman
        // Rekha" (the protective line). Show the bespoke name instead of "L4"
        // so the player feels the power-band crossover.
        let isMythicTier = level >= GameViewModel.maxAuraLevel
        let isHealAura = (title == "Heal")
        let mythicName = isHealAura ? "Sanjivani" : "Lakshman Rekha"
        let mythicMaxLabel = isHealAura ? "MAX · 28 HP/s" : "MAX · 45% block"
        return Button {
            // Silent — tap upgrades the aura tier if affordable + not at
            // max, no-op otherwise. Long-press for the descriptive tooltip
            // and cost breakdown.
            if !isMax && canUpgrade {
                action()
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 3) {
                        Text(isMythicTier ? mythicName : title)
                            .font(.system(size: isMythicTier ? 9 : 11, weight: .heavy, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        if active && !isMythicTier {
                            Text("L\(level)")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Capsule().fill(Color.black.opacity(0.30)))
                        }
                        // Mass-apply badge — only shows when more than one
                        // tower will be lifted by the tap.
                        if !isMax && massCount > 1 {
                            Text("×\(massCount)")
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .padding(.horizontal, 3)
                                .padding(.vertical, 1)
                                .foregroundColor(.yellow)
                                .background(Capsule().fill(Color.black.opacity(0.45)))
                                .overlay(Capsule().stroke(Color.yellow.opacity(0.6), lineWidth: 0.7))
                        }
                    }
                    if isMax {
                        Text(mythicMaxLabel)
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundColor(active ? .black : .white.opacity(0.8))
                    } else if level == GameViewModel.maxAuraLevel - 1 {
                        // Pre-mythic tier: tease the upgrade name.
                        VStack(alignment: .leading, spacing: 0) {
                            Text("→ \(mythicName)")
                                .font(.system(size: 7, weight: .heavy))
                                .foregroundColor(active ? .black : .yellow)
                            ResourceCostRow(cost: nextCost, size: 7, available: vm.stock)
                        }
                    } else {
                        ResourceCostRow(cost: nextCost, size: 7, available: vm.stock)
                    }
                }
            }
            .foregroundColor(active ? .black : .white)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity)
            .background(active ? color : color.opacity(0.20))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color.opacity(active ? 0.0 : 0.55), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .opacity(isMax ? 1.0 : (canUpgrade ? 1.0 : 0.55))
        .tooltip("\(isMythicTier ? mythicName : title) Aura L\(level)/\(GameViewModel.maxAuraLevel)",
                 auraTooltipBody(title: title, level: level, isMax: isMax, canUpgrade: canUpgrade, nextCost: nextCost),
                 icon: icon, tint: color)
    }

    private func auraTooltipBody(title: String, level: Int, isMax: Bool, canUpgrade: Bool, nextCost: Resources) -> String {
        let costStr = resourceShortLocal(nextCost)
        if isMax {
            return title == "Heal"
                ? "MAX: Sanjivani — heals 28 HP/sec to every nearby tower in range. Permanent buff while this tower lives."
                : "MAX: Lakshman Rekha — every nearby tower blocks 45% of incoming damage. Permanent buff while this tower lives."
        }
        let descr = title == "Heal"
            ? "Heals nearby towers per second. Tier 1 unlocks at Treta. Tier 3 → Sanjivani (mythic)."
            : "Reduces damage taken by nearby towers. Tier 1 unlocks at Dvapara. Tier 3 → Lakshman Rekha (mythic)."
        let prefix = canUpgrade ? "READY to upgrade to L\(level + 1)." : "Cannot afford yet."
        return "\(prefix) Cost: \(costStr). \(descr)"
    }

    @ViewBuilder
    private var stoneSection: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "diamond.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.55))
                Text("Power Stone")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }

            if let stone = tower.stone {
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: stone.kind.symbol)
                            .font(.system(size: 14))
                            .foregroundColor(stone.kind.color)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(stone.displayName)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                            Text(stone.kind.tagline)
                                .font(.system(size: 8))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    Spacer()
                    if stone.level < 3 {
                        Button {
                            // Silent — upgrades if affordable, no-op
                            // otherwise. Long-press for the cost tooltip.
                            if vm.canUpgradeStone(tower) {
                                vm.upgradeStone(towerID: tower.id)
                            }
                        } label: {
                            VStack(spacing: 1) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.green)
                                ResourceCostRow(cost: stone.kind.cost(forLevel: stone.level + 1), size: 7, available: vm.stock)
                            }
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(Color.black.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .opacity(vm.canUpgradeStone(tower) ? 1 : 0.5)
                        .tooltip("Upgrade Stone → L\(stone.level + 1)",
                                 "Spend another stone of the same kind to upgrade this socket to L\(stone.level + 1). Each level scales the stone's bonus (damage / fire rate / range / all).",
                                 icon: "arrow.up.circle.fill", tint: .green)
                    }
                    Button {
                        vm.removeStone(towerID: tower.id)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.red.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                    .tooltip("Remove Stone",
                             "Detach this stone from the tower. Refunds floor(level / 2) stones back into inventory. Use to free a socket so you can attach a different kind.",
                             icon: "xmark.circle.fill", tint: .red)
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(stone.kind.color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(stone.kind.color.opacity(0.55), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if showStonePicker {
                // Top row: attach from inventory (tap to apply, disabled if
                // none owned of that kind).
                HStack(spacing: 5) {
                    ForEach(StoneKind.allCases) { kind in
                        Button {
                            vm.attachStone(towerID: tower.id, kind: kind)
                            showStonePicker = false
                        } label: {
                            stonePickerCard(kind, inventoryCount: vm.stoneCount(kind))
                        }
                        .buttonStyle(.plain)
                        .disabled(vm.stoneCount(kind) <= 0)
                        .opacity(vm.stoneCount(kind) > 0 ? 1 : 0.45)
                        .tooltip("Attach \(kind.displayName)",
                                 attachStoneTooltipBody(kind),
                                 icon: kind.symbol, tint: kind.color)
                    }
                }
                Text("Buy stones with gold")
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                    .foregroundColor(.yellow.opacity(0.85))
                    .padding(.top, 2)
                // Second row: gold-buy buttons that add to the stone inventory.
                HStack(spacing: 5) {
                    ForEach(StoneKind.allCases) { kind in
                        Button {
                            vm.buyStone(kind)
                        } label: {
                            stoneBuyCard(kind, price: GameViewModel.goldPriceForStone(kind))
                        }
                        .buttonStyle(.plain)
                        .disabled(!vm.canBuyStone(kind))
                        .opacity(vm.canBuyStone(kind) ? 1 : 0.45)
                        .tooltip("Buy \(kind.displayName)",
                                 "Spend \(GameViewModel.goldPriceForStone(kind))g to add ONE \(kind.displayName) to your stone inventory. Useful when Mani Murta isn't dropping the kind you need.",
                                 icon: "plus.circle.fill", tint: kind.color)
                    }
                }
                Button("Hide stones") { showStonePicker = false }
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.6))
            } else {
                Button {
                    showStonePicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 10))
                        Text("Add Power Stone")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.cyan.opacity(0.18))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .tooltip("Add Power Stone",
                         "Open the stone picker for this tower. Stones are timed power-ups that auto-remove when their timer expires. Wall ALSO uses stones (one per activation).",
                         icon: "diamond.fill", tint: .cyan)
            }
        }
    }

    private func attachStoneTooltipBody(_ kind: StoneKind) -> String {
        let owned = vm.stoneCount(kind)
        let benefit: String
        switch kind {
        case .chuni:      benefit = "+20% damage at L1 (timed buff)."
        case .panna:      benefit = "+15% fire rate at L1 (timed buff)."
        case .nila:       benefit = "+15% range at L1 (timed buff)."
        case .raktamukhi: benefit = "+10% damage / fire rate / range at L1 (timed buff)."
        }
        if owned <= 0 {
            return "You have 0 of these. Buy with gold below, or kill Mani Murta enemies (every wave from W3+) for free drops. \(benefit)"
        }
        return "You own ×\(owned). Attaches a \(kind.displayName) to this tower for a timed buff. \(benefit)"
    }

    private func stonePickerCard(_ kind: StoneKind, inventoryCount: Int) -> some View {
        VStack(spacing: 2) {
            Image(systemName: kind.symbol)
                .font(.system(size: 16))
                .foregroundColor(kind.color)
            Text(kind.displayName)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(kind.tagline)
                .font(.system(size: 7))
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(1)
            HStack(spacing: 2) {
                Image(systemName: "diamond.fill")
                    .font(.system(size: 7))
                    .foregroundColor(kind.color)
                Text("\(inventoryCount) owned")
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                    .foregroundColor(inventoryCount > 0 ? .white : Color(red: 1.0, green: 0.45, blue: 0.45))
            }
        }
        .frame(width: 64, height: 70)
        .padding(4)
        .background(Color.black.opacity(0.4))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(kind.color.opacity(0.65), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    /// Gold-buy card — pay gold to add one stone of this kind to the
    /// player's inventory. Disabled when gold is short.
    private func stoneBuyCard(_ kind: StoneKind, price: Int) -> some View {
        VStack(spacing: 2) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.yellow)
            Image(systemName: kind.symbol)
                .font(.system(size: 12))
                .foregroundColor(kind.color)
            HStack(spacing: 1) {
                Text("\(price)")
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 7))
                    .foregroundColor(.yellow)
            }
            .foregroundColor(.white)
        }
        .frame(width: 64, height: 56)
        .padding(2)
        .background(Color.black.opacity(0.4))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.yellow.opacity(0.6), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var upgradeButton: some View {
        if let next = tower.nextAstra, let reqAge = tower.requiredAgeForNextTier {
            let ageReady = vm.isUnlocked(reqAge)
            // Tower upgrade is single-tower: only the selected tower
            // advances tiers. Heal/Shield auras and stones still mass-apply.
            let cost = vm.effectiveUpgradeCost(of: tower)
            let affordable = vm.stock.canAfford(cost)
            let enabled = ageReady && affordable

            Button {
                // Silent — tap upgrades if affordable AND age-ready,
                // no-op otherwise. Long-press the button to see the cost
                // breakdown + locked-reason tooltip.
                if ageReady && affordable {
                    vm.upgradeTower(id: tower.id)
                }
            } label: {
                VStack(spacing: 2) {
                    HStack(spacing: 3) {
                        Image(systemName: tower.kind.symbol)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.5))
                        Image(systemName: next.symbol)
                            .font(.system(size: 15))
                            .foregroundColor(next.color)
                    }
                    Text(next.displayName)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if !ageReady {
                        Text("Reach \(reqAge.shortName) Yug")
                            .font(.system(size: 8))
                            .foregroundColor(reqAge.color)
                    } else {
                        ResourceCostRow(cost: cost, size: 8, available: vm.stock)
                    }
                }
                .frame(width: 130, height: 76)
                .background(Color.black.opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(enabled ? next.color.opacity(0.7) : Color.white.opacity(0.2), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .opacity(enabled ? 1 : 0.55)
            }
            .buttonStyle(.plain)
            .tooltip("Upgrade → \(next.displayName)",
                     upgradeTooltipBody(next: next, reqAge: reqAge, ageReady: ageReady, affordable: affordable, cost: cost),
                     icon: next.symbol, tint: next.color)
        } else {
            VStack(spacing: 3) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                Text("Max Tier")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(width: 130, height: 76)
            .background(Color.black.opacity(0.45))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .tooltip("Max Tier",
                     "This tower is already at its highest astra (T\(tower.tier) — \(tower.kind.displayName)). No further upgrades. Tip: boost it with a power stone or aura.",
                     icon: "checkmark.seal.fill", tint: .gray)
        }
    }

    private func upgradeTooltipBody(next: TowerKind, reqAge: Age, ageReady: Bool, affordable: Bool, cost: Resources) -> String {
        let costStr = resourceShortLocal(cost)
        let prefix: String
        if !ageReady {
            prefix = "LOCKED — needs \(reqAge.shortName) Yug."
        } else if !affordable {
            prefix = "Not enough resources."
        } else {
            prefix = "READY."
        }
        return "\(prefix) Cost: \(costStr). Upgrades to \(next.displayName) — \(next.tagline)."
    }

    private func resourceShortLocal(_ r: Resources) -> String {
        var parts: [String] = []
        if r.gold > 0    { parts.append("\(Int(r.gold))g") }
        if r.metal > 0   { parts.append("\(Int(r.metal))m") }
        if r.tech > 0    { parts.append("\(Int(r.tech))t") }
        if r.jotisha > 0 { parts.append("\(Int(r.jotisha))j") }
        if r.veda > 0    { parts.append("\(Int(r.veda))v") }
        return parts.isEmpty ? "Free" : parts.joined(separator: " + ")
    }

    private func statTile(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 1) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.7))
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(width: 62, height: 50)
        .background(Color.black.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func sellTile(value: Resources) -> some View {
        VStack(spacing: 2) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(.red)
            Text("Sell")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
            ResourceCostRow(cost: value, size: 8)
        }
        .frame(width: 90, height: 76)
        .background(Color.black.opacity(0.4))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.red.opacity(0.6), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func relocateTile(cost: Resources, affordable: Bool) -> some View {
        let isFree = (cost.gold + cost.metal + cost.tech + cost.jotisha + cost.veda) == 0
        return VStack(spacing: 2) {
            Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                .font(.system(size: 16))
                .foregroundColor(affordable ? .cyan : .gray)
            Text("Relocate")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
            if isFree {
                Text("FREE")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundColor(.green)
            } else {
                ResourceCostRow(cost: cost, size: 8)
            }
        }
        .frame(width: 90, height: 76)
        .background(Color.black.opacity(0.4))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke((affordable ? Color.cyan : Color.gray).opacity(0.6), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .opacity(affordable ? 1.0 : 0.55)
        .onAppear { HintsStore.shared.trigger(.relocateTower) }
    }
}

// MARK: - Building menu

struct BuildingMenu: View {
    let vm: GameViewModel
    let building: Building

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: building.kind.symbol).foregroundColor(building.kind.color)
                Text(building.kind.displayName)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("• Lv \(building.level)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }

            Text(building.kind.sanskritName)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.6))

            HStack(spacing: 8) {
                if building.kind == .parijata {
                    // Wish-tree pours every resource at the per-sec rate. No
                    // race multiplier — its bounty is universal.
                    statTile(
                        icon: "arrow.up.right.circle.fill",
                        value: String(format: "+%.1f/s", building.genPerSec),
                        label: "All Five"
                    )
                } else {
                    statTile(
                        icon: "arrow.up.right.circle.fill",
                        value: String(format: "+%.1f/s",
                                      building.genPerSec * (vm.race?.genMultiplier(for: building.kind.resource) ?? 1.0)),
                        label: building.kind.resource.displayName
                    )
                }
            }

            HStack(spacing: 10) {
                if building.level < building.kind.maxLevel {
                    Button {
                        // Silent — tap upgrades if affordable, no-op
                        // otherwise. Long-press the button to see the cost
                        // breakdown tooltip.
                        if vm.canUpgradeBuilding(building) {
                            vm.upgradeBuilding(id: building.id)
                        }
                    } label: {
                        upgradeTile(building: building)
                    }
                    .buttonStyle(.plain)
                    .tooltip("Upgrade → Lv \(building.level + 1)",
                             "Increases production rate. Cost: \(buildingUpgradeCostString(building.upgradeCost)). Buildings only generate resources during waves, so upgrade early to compound.",
                             icon: "arrow.up.circle.fill", tint: .green)
                } else {
                    VStack(spacing: 3) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                        Text("Max Level")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(width: 110, height: 76)
                    .background(Color.black.opacity(0.45))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .tooltip("Max Level",
                             "This building is fully upgraded (Lv \(building.level)). Its production is at the ceiling — stack more buildings for higher total throughput.",
                             icon: "checkmark.seal.fill", tint: .gray)
                }

                Button {
                    vm.sellBuilding(id: building.id)
                } label: {
                    sellTile(value: building.sellValue)
                }
                .buttonStyle(.plain)
                .tooltip("Sell Building",
                         "Refund a portion of the building's invested resources back into your stock. Useful to repurpose a slot mid-run.",
                         icon: "dollarsign.circle.fill", tint: .red)
            }

            Button("Close") { vm.deselectAll() }
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(building.kind.color.opacity(0.4), lineWidth: 1)
                )
        )
        .padding(.horizontal, 8)
    }

    private func buildingUpgradeCostString(_ r: Resources) -> String {
        var parts: [String] = []
        if r.gold > 0    { parts.append("\(Int(r.gold))g") }
        if r.metal > 0   { parts.append("\(Int(r.metal))m") }
        if r.tech > 0    { parts.append("\(Int(r.tech))t") }
        if r.jotisha > 0 { parts.append("\(Int(r.jotisha))j") }
        if r.veda > 0    { parts.append("\(Int(r.veda))v") }
        return parts.isEmpty ? "Free" : parts.joined(separator: " + ")
    }

    // (announceShortfall removed — superseded by the global CostAnnouncer
    // so every build / upgrade / place button uses the same breakdown UX.)

    private func upgradeTile(building: Building) -> some View {
        let enabled = vm.canUpgradeBuilding(building)
        return VStack(spacing: 2) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(.green)
            Text("Upgrade")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
            Text("Lv \(building.level + 1)")
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.7))
            ResourceCostRow(cost: building.upgradeCost, size: 8, available: vm.stock)
        }
        .frame(width: 110, height: 76)
        .background(Color.black.opacity(0.4))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.green.opacity(enabled ? 0.7 : 0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .opacity(enabled ? 1 : 0.55)
    }

    private func statTile(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 1) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.cyan)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(width: 100, height: 50)
        .background(Color.black.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func sellTile(value: Resources) -> some View {
        VStack(spacing: 2) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(.red)
            Text("Sell")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
            ResourceCostRow(cost: value, size: 8)
        }
        .frame(width: 90, height: 76)
        .background(Color.black.opacity(0.4))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.red.opacity(0.6), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Age banner

struct AgeBanner: View {
    let age: Age

    var body: some View {
        VStack(spacing: 4) {
            Text("New Yug Unlocked")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
            HStack(spacing: 6) {
                Image(systemName: age.symbol).foregroundColor(age.color)
                Text(age.name)
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }
            Text("Upgrade towers to next astra tier")
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.78))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(age.color, lineWidth: 1.5)
                )
        )
    }
}

// MARK: - First-time hint banner

/// Centred tutorial card shown the first time a player encounters a new
/// game element (Sudarshan, empowered boss, Parijata, etc.). One-shot per
/// hint key — persistence handled by HintsStore.
/// Centred dramatic boss-entry roar. Shows the Sanskrit dialog the boss
/// shouts on first appearance + English translation. Auto-dismisses via
/// the GameViewModel.bossDialog timer.
struct BossDialogOverlay: View {
    let kind: EnemyKind
    let timer: TimeInterval

    private var alpha: Double {
        // Fade in for 0.25s, hold, fade out for last 0.3s
        let total = GameViewModel.bossDialogLifetime
        let elapsed = total - timer
        if elapsed < 0.25 { return elapsed / 0.25 }
        if timer < 0.3 { return timer / 0.3 }
        return 1.0
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: kind.isBoss ? "crown.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(kind.color)
                    .shadow(color: kind.color, radius: 8)
                Text(kind.displayName)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: kind.color.opacity(0.6), radius: 4)
            }
            Text(kind.entryDialog)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(.yellow)
                .multilineTextAlignment(.center)
                .shadow(color: .red.opacity(0.7), radius: 6)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
            Text(kind.entryTranslation)
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .italic()
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .frame(maxWidth: 360)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.black.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(kind.color.opacity(0.85), lineWidth: 2)
                )
                .shadow(color: kind.color.opacity(0.7), radius: 18)
        )
        .padding(.horizontal, 30)
        .opacity(alpha)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.35 * alpha).ignoresSafeArea())
        .allowsHitTesting(false)
    }
}

/// Top-right card that shows the active boss's name, speciality, and the
/// weakness the player should exploit. Auto-shows for any card-worthy
/// enemy (full bosses + the specialist demons with unique mechanics).
struct BossInfoCard: View {
    let enemy: Enemy

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: enemy.kind.isBoss ? "crown.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(enemy.kind.color)
                    .shadow(color: enemy.kind.color.opacity(0.8), radius: 4)
                Text(enemy.kind.displayName)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            // HP bar — quick read of how close to dead the boss is
            HStack(spacing: 4) {
                Text("HP")
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundColor(.white.opacity(0.6))
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 110, height: 5)
                    Capsule()
                        .fill(hpColor)
                        .frame(width: 110 * CGFloat(max(0, min(1, enemy.hp / enemy.maxHP))),
                               height: 5)
                }
                .overlay(Capsule().stroke(Color.white.opacity(0.4), lineWidth: 0.5))
            }
            divider
            label("Speciality", icon: "sparkles", color: .yellow)
            Text(enemy.kind.speciality)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)
            label("Weakness", icon: "scope", color: .green)
            Text(enemy.kind.weakness)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Color(red: 0.55, green: 1.0, blue: 0.65))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .frame(width: 180)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(enemy.kind.color.opacity(0.7), lineWidth: 1)
                )
                .shadow(color: enemy.kind.color.opacity(0.45), radius: 5)
        )
    }

    private var hpColor: Color {
        let frac = enemy.hp / enemy.maxHP
        if frac > 0.6 { return .green }
        if frac > 0.3 { return .yellow }
        return .red
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.18))
            .frame(height: 0.6)
            .padding(.vertical, 1)
    }

    private func label(_ text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(color)
            Text(text.uppercased())
                .font(.system(size: 8, weight: .heavy))
                .foregroundColor(color.opacity(0.9))
        }
    }
}

struct HintBanner: View {
    let hint: GameHint

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: hint.icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(hint.tint)
                    .shadow(color: hint.tint.opacity(0.7), radius: 6)
                Text(hint.title)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }
            Text(hint.body)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.88))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                withAnimation(.easeOut(duration: 0.18)) {
                    HintsStore.shared.dismiss()
                }
            } label: {
                Text("Got it")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(hint.tint))
                    .overlay(Capsule().stroke(Color.white.opacity(0.75), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: 320)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(hint.tint.opacity(0.85), lineWidth: 1.5)
                )
                .shadow(color: hint.tint.opacity(0.55), radius: 10)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Resource wave banner

struct ResourceWaveBanner: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("Resource Wave")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(.yellow)
                .shadow(color: .black.opacity(0.7), radius: 2)
            HStack(spacing: 8) {
                ForEach(ResourceKind.allCases) { kind in
                    Image(systemName: kind.symbol)
                        .foregroundColor(kind.color)
                        .font(.system(size: 13, weight: .bold))
                }
            }
            Text("Bearers spawn weighted by your shortages")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.75))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.82))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.yellow.opacity(0.85), lineWidth: 1.5)
                )
                .shadow(color: .yellow.opacity(0.55), radius: 6)
        )
    }
}

// MARK: - Game over

struct GameOverOverlay: View {
    let vm: GameViewModel

    var body: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()

            VStack(spacing: 14) {
                Text("Defence Broken")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(.red)

                VStack(spacing: 4) {
                    Text("Score: \(vm.score)")
                    Text("Reached \(vm.currentAge.name) • Wave \(vm.wave)")
                    if let race = vm.race {
                        Text("As \(race.displayName)")
                    }
                }
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.white)

                HStack(spacing: 10) {
                    Button {
                        vm.reset()
                    } label: {
                        Text("Try Again")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Color.cyan)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        vm.fullReset()
                    } label: {
                        Text("Change Race")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Color.gray.opacity(0.7))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        exit(0)
                    } label: {
                        Text("Exit")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Color(red: 0.55, green: 0.10, blue: 0.10))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.red.opacity(0.4), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Bazaar (meta-progression store)

struct BazaarButton: View {
    let vm: GameViewModel
    @Binding var presented: Bool

    var body: some View {
        Button {
            withAnimation(.easeOut(duration: 0.18)) { presented = true }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "storefront.fill")
                    .font(.system(size: 14, weight: .bold))
                Text("Bazaar")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                Image(systemName: "sparkle")
                    .font(.system(size: 9))
                Text("\(vm.availablePoints)")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .monospacedDigit()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(LinearGradient(colors: [Color(red: 0.55, green: 0.30, blue: 0.78),
                                                  Color(red: 0.32, green: 0.18, blue: 0.55)],
                                         startPoint: .top, endPoint: .bottom))
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct BazaarOverlay: View {
    let vm: GameViewModel
    @Binding var presented: Bool
    private let store = BazaarStore.shared
    private var inGame: Bool { vm.race != nil && !vm.isGameOver }
    private var canAfford: (BazaarItem) -> Bool { { vm.availablePoints >= $0.cost } }

    var body: some View {
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 0) {
                header
                Divider().background(Color.white.opacity(0.15))
                ScrollView {
                    LazyVStack(spacing: 14) {
                        getPointsSection
                        section(title: "In-Run Items",
                                subtitle: "Apply to the current game",
                                items: BazaarItem.allCases.filter { $0.kind == .instant })
                        section(title: "Run Buffs",
                                subtitle: "Last until this run ends",
                                items: BazaarItem.allCases.filter { $0.kind == .runBuff })
                        section(title: "Permanent Perks",
                                subtitle: "Apply to every future run",
                                items: BazaarItem.allCases.filter { $0.kind == .permanent })
                    }
                    .padding(14)
                }
                footer
            }
            .frame(maxWidth: 440)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(red: 0.08, green: 0.05, blue: 0.16).opacity(0.96))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color(red: 0.55, green: 0.30, blue: 0.78).opacity(0.7), lineWidth: 1.5)
                    )
            )
            .padding(.horizontal, 18)
            .padding(.vertical, 28)
        }
        .transition(.opacity)
    }

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.15)) { presented = false }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "storefront.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.yellow)
            VStack(alignment: .leading, spacing: 1) {
                Text("Bazaar")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text("Hatta")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                HStack(spacing: 4) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 11))
                    Text("\(vm.availablePoints)")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                    Text("pts")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                }
                .foregroundColor(.yellow)
                Text("Run \(vm.points) · Saved \(store.persistentPoints)")
                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .monospacedDigit()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.black.opacity(0.4)))
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
    }

    private var footer: some View {
        Text("Run points come from kills + wave clears and reset every game. Bought points (Get Points) stay in your wallet across runs.")
            .font(.system(size: 10))
            .foregroundColor(.white.opacity(0.55))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
    }

    private var getPointsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("Get Points")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text("· Buy any time — points stay in your wallet")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.55))
                Spacer()
                Button {
                    Task { await StoreManager.shared.restorePurchases() }
                } label: {
                    Text("Restore")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.white.opacity(0.10)))
                }
                .buttonStyle(.plain)
            }
            VStack(spacing: 8) {
                ForEach(PointBundle.all) { bundle in
                    bundleCard(bundle)
                }
            }
        }
    }

    private func bundleCard(_ bundle: PointBundle) -> some View {
        let storeKit = StoreManager.shared
        let livePrice = storeKit.displayPrice(for: bundle.id)
        return Button {
            Task { await storeKit.purchase(bundle) }
        } label: {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 11, weight: .bold))
                    Text("+\(bundle.grant)")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                }
                .foregroundColor(.white)
                Text(bundle.label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                Text(livePrice ?? bundle.priceTag)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.black.opacity(0.35)))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .opacity(storeKit.isPurchasing ? 0.6 : 1.0)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: bundle.highlight
                                ? [Color(red: 1.00, green: 0.78, blue: 0.20),
                                   Color(red: 0.95, green: 0.50, blue: 0.10)]
                                : [Color(red: 0.55, green: 0.30, blue: 0.78),
                                   Color(red: 0.32, green: 0.18, blue: 0.55)],
                            startPoint: .top, endPoint: .bottom)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(bundle.highlight ? 0.55 : 0.30),
                                    lineWidth: 1)
                    )
                    .shadow(color: (bundle.highlight ? Color.yellow : Color.purple).opacity(0.4),
                            radius: 6, x: 0, y: 0)
            )
            .overlay(alignment: .topTrailing) {
                if bundle.highlight {
                    Text("HOT")
                        .font(.system(size: 8, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.yellow))
                        .padding(6)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(storeKit.isPurchasing)
    }

    @ViewBuilder
    private func section(title: String, subtitle: String, items: [BazaarItem]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text("· \(subtitle)")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.55))
            }
            VStack(spacing: 8) {
                ForEach(items) { item in
                    row(for: item)
                }
            }
        }
    }

    @ViewBuilder
    private func row(for item: BazaarItem) -> some View {
        let ownedPerm = item.kind == .permanent && store.ownsPermanent(item)
        let activeBuff = item.kind == .runBuff && vm.activeBazaarPerks.contains(item)
        let affordable = canAfford(item)
        let needsGame = !inGame
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.tint.opacity(0.18))
                    .frame(width: 48, height: 48)
                Image(systemName: item.icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(item.tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayName)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text(item.sanskritName)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(item.tint.opacity(0.85))
                Text(item.summary)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(2)
            }
            Spacer(minLength: 6)
            actionButton(for: item,
                         ownedPerm: ownedPerm,
                         activeBuff: activeBuff,
                         affordable: affordable,
                         needsGame: needsGame)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity((ownedPerm || activeBuff) ? 0.04 : 0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke((ownedPerm || activeBuff) ? Color.green.opacity(0.45)
                                                          : item.tint.opacity(0.30),
                                lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private func actionButton(for item: BazaarItem,
                              ownedPerm: Bool,
                              activeBuff: Bool,
                              affordable: Bool,
                              needsGame: Bool) -> some View {
        if ownedPerm {
            statusPill("Owned", icon: "checkmark.seal.fill", color: .green)
        } else if activeBuff {
            statusPill("Active", icon: "bolt.fill", color: .green)
        } else if needsGame {
            statusPill("In-game", icon: "play.slash.fill", color: .gray)
        } else {
            Button {
                // Stay-open behaviour: every purchase keeps the Bazaar sheet
                // up so the player can stack multiple buys (gold pouch +
                // wave tribute + jyotisha blessing in one visit) without
                // re-opening the storefront each time. Tap outside or the
                // Close button to dismiss.
                _ = vm.buyBazaarItem(item)
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 9))
                    Text("\(item.cost)")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule().fill(affordable ? item.tint : Color.gray.opacity(0.45))
                )
            }
            .buttonStyle(.plain)
            .disabled(!affordable)
            .opacity(affordable ? 1.0 : 0.6)
        }
    }

    private func statusPill(_ text: String, icon: String, color: Color) -> some View {
        Label(text, systemImage: icon)
            .labelStyle(.titleAndIcon)
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(color.opacity(0.15)))
    }
}

// MARK: - Amrita Kalash (score-gated life-revival relic, threshold = GameViewModel.amritaKalashCost)

/// Standalone floating God Mode button — completely separate from any
/// HUD row so it doesn't read as another toggle. Sits above the BottomBar
/// in the bottom-right corner with a distinct sunburst gold look.
/// Banner shown when the player long-presses a tooltip-equipped UI
/// element. Auto-dismisses after a few seconds via TooltipManager.tick.
struct TooltipBanner: View {
    let payload: TooltipPayload

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: payload.icon)
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundColor(payload.tint)
                Text(payload.title)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.55))
            }
            Text(payload.body)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.88))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: 360)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(payload.tint.opacity(0.65), lineWidth: 1.2)
                )
                .shadow(color: payload.tint.opacity(0.5), radius: 8)
        )
        .padding(.horizontal, 16)
    }
}

/// View modifier — long-press to summon a tooltip describing this element.
/// Long-press is used (not tap) so that elements with their own button
/// actions (Upgrade, Build, Pralay, Wall, etc.) don't see the static
/// tooltip race with — and overwrite — their richer per-tap banners (cost
/// breakdowns, shortfalls, success messages). For info-only pills with no
/// button action, use the `.infoTap(...)` modifier below to make a single
/// tap show the same static tooltip immediately.
struct TooltipModifier: ViewModifier {
    let title: String
    let body: String
    var icon: String = "info.circle.fill"
    var tint: Color = .cyan
    var maxDuration: TimeInterval? = nil

    func body(content: Content) -> some View {
        content.simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    TooltipManager.shared.show(title: title,
                                               body: body,
                                               icon: icon,
                                               tint: tint,
                                               maxDuration: maxDuration)
                    HapticsEngine.shared.towerFire()
                }
        )
    }
}

/// Long-press info modifier for static pills. Single tap is intentionally
/// NOT a trigger — the universal control across the whole game is
/// "long-press anything to learn about it". See the in-app tip banner that
/// fires once on first launch for the player.
struct InfoTapModifier: ViewModifier {
    let title: String
    let body: String
    var icon: String = "info.circle.fill"
    var tint: Color = .cyan
    var maxDuration: TimeInterval? = nil

    func body(content: Content) -> some View {
        content.simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    TooltipManager.shared.show(title: title,
                                               body: body,
                                               icon: icon,
                                               tint: tint,
                                               maxDuration: maxDuration)
                }
        )
    }
}

extension View {
    /// Add an info tooltip that surfaces on long-press. Use this on views
    /// that have their OWN tap action (Buttons, sliders, etc.) so the
    /// long-press path doesn't compete with the action. `maxDuration`
    /// caps the on-screen time (otherwise it scales with reading time).
    func tooltip(_ title: String, _ body: String,
                 icon: String = "info.circle.fill",
                 tint: Color = .cyan,
                 maxDuration: TimeInterval? = nil) -> some View {
        modifier(TooltipModifier(title: title, body: body, icon: icon,
                                 tint: tint, maxDuration: maxDuration))
    }

    /// Single-tap-to-show-info variant — for static pills / badges / icons
    /// that have no other tap action. Tap fires the tooltip immediately.
    /// `maxDuration` caps the on-screen time.
    func infoTap(_ title: String, _ body: String,
                 icon: String = "info.circle.fill",
                 tint: Color = .cyan,
                 maxDuration: TimeInterval? = nil) -> some View {
        modifier(InfoTapModifier(title: title, body: body, icon: icon,
                                 tint: tint, maxDuration: maxDuration))
    }
}

/// Surfaces a tooltip banner that lists the *full* resource breakdown for
/// an action — each resource line annotated with ✓/✗ and the player's
/// current stock, plus a header that calls out what's missing. Used on
/// every "build / upgrade / place" button so the player always sees the
/// exact cost before (or after) committing.
@MainActor
enum CostAnnouncer {
    static func announce(title: String,
                         cost: Resources,
                         stock: Resources,
                         affordable: Bool,
                         tint: Color,
                         icon: String) {
        var lines: [String] = []
        var shortKinds: [String] = []
        let entries: [(String, Int, Int)] = [
            ("Gold",    cost.gold,    stock.gold),
            ("Metal",   cost.metal,   stock.metal),
            ("Tech",    cost.tech,    stock.tech),
            ("Jotisha", cost.jotisha, stock.jotisha),
            ("Veda",    cost.veda,    stock.veda)
        ]
        for (name, need, have) in entries where need > 0 {
            let short = have < need
            let marker = short ? "✗" : "✓"
            lines.append("\(marker) \(name): need \(need), have \(have)")
            if short {
                shortKinds.append("\(name) (-\(need - have))")
            }
        }
        let header: String
        if affordable {
            header = "Cost breakdown — all resources available."
        } else if shortKinds.isEmpty {
            header = "Cost breakdown:"
        } else {
            header = "Short on: \(shortKinds.joined(separator: ", "))."
        }
        let body = lines.isEmpty
            ? "Free — no resource cost."
            : ([header] + lines).joined(separator: "\n")
        TooltipManager.shared.show(title: title,
                                   body: body,
                                   icon: icon,
                                   tint: tint)
    }
}

/// Comprehensive in-game help — explains every game element with tips.
/// Organised into sections so the player can scroll to what they need.
/// Shown ONCE on the very first app launch (gated by `hasSeenCulturalDisclaimer`
/// in UserDefaults). Acknowledges that the game draws on Indian itihāsa with
/// reverence — pre-empts cultural-sensitivity concerns. Must be tapped to
/// dismiss; the player explicitly closes it before reaching the game.
struct CulturalDisclaimerOverlay: View {
    var onAcknowledge: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.92)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.78, blue: 0.20).opacity(0.50),
                                    Color(red: 0.70, green: 0.20, blue: 0.55).opacity(0.20),
                                    .clear
                                ],
                                center: .center, startRadius: 4, endRadius: 50
                            )
                        )
                        .frame(width: 92, height: 92)
                    Text("ॐ")
                        .font(.system(size: 56, weight: .heavy, design: .serif))
                        .foregroundColor(.yellow.opacity(0.95))
                        .shadow(color: .orange, radius: 6)
                }
                .accessibilityHidden(true)

                Text("Inspired with reverence")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Text("""
Anta Yuga draws on the storytelling tradition of Indian itihāsa — the Ramayana, the Mahabharata, and the Puranas. The names of deities, asuras, astras, ages, and dynasties are used with respect for the cultural and religious traditions from which they originate.

Nothing in this game is intended to make light of any community's beliefs.
""")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .lineSpacing(3)

                Button(action: onAcknowledge) {
                    Text("I understand")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(
                            Capsule().fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.00, green: 0.85, blue: 0.40),
                                        Color(red: 1.00, green: 0.55, blue: 0.10)
                                    ],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                        )
                        .shadow(color: .orange.opacity(0.4), radius: 8)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(28)
            .frame(maxWidth: 460)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(red: 0.08, green: 0.04, blue: 0.18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.00, green: 0.85, blue: 0.40).opacity(0.5),
                                        Color(red: 0.70, green: 0.20, blue: 0.55).opacity(0.4)
                                    ],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: .black.opacity(0.6), radius: 30)
            .padding(.horizontal, 24)
        }
    }
}

struct HelpOverlay: View {
    @Binding var presented: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture { presented = false }

            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "book.fill")
                        .foregroundColor(.cyan)
                    Text("Guide Book")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Button { presented = false } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)

                Divider().background(Color.white.opacity(0.2))

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        helpSection(
                            icon: "flag.checkered", tint: .cyan,
                            title: "Goal",
                            body: """
                            Defend the central tower (Sudarshan relic) through 14 waves. The final wave brings Kali Yuga — only the Sudarshan Chakra (fully charged) can kill him.

                            Tip: every leaked enemy chips the central tower's HP. Lose all HP → game over.
                            """)

                        helpSection(
                            icon: "sparkles", tint: .yellow,
                            title: "The Tale — A Story From the Wheel",
                            body: """
                            In the first age, when the world was new and dharma walked on four bright legs, Vishnu the Preserver set a sliver of his own thought into the heart of all things. He called it the Sudarshan — the disc of right-seeing — and he set it spinning at the centre of a path that mortals would one day walk. "While it turns," he said, "the wheel of time cannot fall."

                            For three ages it spun, and for three ages it sang, and the world prospered. But beneath the world, in the gulfs no mantra had ever lit, the asuras heard the song — and they HATED it.

                            "If the disc stops," they whispered, "the End may begin."

                            And so they came. Not all at once — for the song was strong — but in waves, age after age, century shrunk into wave, each one harder than the last.

                            FIRST came the small hungers: Pishacha the flesh-eater, Rakshasa the night-walker, Daitya the proud, Asura the ambitious. You — heir of one of the nine great dynasties (Raghuvansh of Rama's line, Maurya of the iron empire, Pal of the patron-sages, and the others) — raised your first towers. Dart-archers from the village smithies, fire-cones from the temple flame. Wave by wave, you learned: a single tower is a single prayer; many towers are a chorus.

                            Then in TRETA, the corrupted heroes came. Mahishasura, the buffalo-king the goddess slew in another telling — here he returns, +20% over his old strength because the Yug itself empowers him. Ravana, ten-headed, lord of Lanka, whom Rama once felled — he marches at the centre tower now, axe in every hand. Putana, the wet-nurse of poisons. Each demands a specific astra: Trishul for Ravana, Agneyastra for the cold ones, Drishti to even SEE the invisible Mayavi. The Treta page you turn unlocks the second-tier astras (Aindra, Suryastra, Sheetastra, Vajrastra) but also strengthens every enemy by 20%. Knowledge is purchased with risk.

                            By DVAPARA — the Half-Age — the line is creaking. Vritra the drought-snake coils around your gold mines and chokes them silent. Raktabija bleeds, and every drop is another Raktabija. Bhasmasura burns towers down to their first tier. Mani Murta lumbers through, dropping a single power-stone from her gem-flesh as she dies — Chuni for damage, Panna for speed, Nila for reach, Raktamukhi for all three. You attach them to towers, knowing the bond is timed: the stone will leave when its hours run out. You unlock the third-tier astras (Shakti, Rudra, Narayana) and the fourth-tier ultimates (Sudarshana Chakra, Bhambhrastra, Pashupatastra, Brahmasira) — divine weapons that sweep the full field. But the enemy ramp is now +50%. The Anta is close.

                            And at the centre — through every wave — the disc spins quieter and quieter. You FEED it. Gold drops into the well of its hub. The charge climbs: 12%, 24%, 47%, 78% … and at 100%, the world holds its breath.

                            Then W14.

                            The sky bruises black. A voice from beneath the foundation of years:

                            "कलिः अहम् — धर्मस्य अन्तः समागतः!"
                            ("I am Kali Yuga — the end of dharma has come!")

                            Kali Yuga walks the path. He is taller than the towers. His eyes are the void between stars. He is patient because he has waited four ages for this hour, and no astra you have built can kill him — they merely sting. He stops at each tower he reaches, and he EATS it — and grows. +8% maximum HP. +12% damage. Each tower lost makes the next one fall faster.

                            But — the disc.

                            The Sudarshan ignites. Vishnu's own discus rises from the relic and SPINS, burning Kali Yuga at 1,650 damage every second. The chakra is divine, but it is also alive — it drains its own charge by 1.4% per second as it burns. Feed it. KEEP feeding it. The Recharge bar at the top of the screen is your last prayer. Every coin you slip into the disc is one more arc of light against the End.

                            If your chakra holds, if your defenders hold, if your dynasty holds — Kali Yuga falls. The wheel does not stop. Dharma keeps its one trembling leg.

                            "धर्मो रक्षति रक्षितः" — "Dharma protects those who protect it."

                            Begin again, defender. The wheel always turns.
                            """)

                        helpSection(
                            icon: "book.pages.fill", tint: .orange,
                            title: "Lore Notes — The Anta Yuga",
                            body: """
                            THE COSMIC WHEEL — In the Sanatana cosmology, time turns in a great cycle of four Yugas (ages):
                            • SATYA YUGA — the Age of Truth. Dharma stands on all four legs. Beings live long and righteously. The gods walk the earth.
                            • TRETA YUGA — the Age of Three-Quarters. Dharma loses one leg. Heroes still rise — Rama, Hanuman, the Ramayana unfolds here.
                            • DVAPARA YUGA — the Age of Halves. Dharma stands on two legs. The Mahabharata is fought, Krishna walks the world.
                            • KALI YUGA — the Anta Yuga, the END AGE. Dharma stands on one trembling leg. Greed, deceit, and decay rule. This is the age the demons hunger to drag the world into completely.

                            THE PROPHECY — The Sudarshan Chakra of Vishnu — the spinning disc that severs ego from soul — was set into the heart of the world as a final ward. So long as it spins, the descent into total Kali Yuga can be slowed. But the asura legions know this. Wave after wave they march on the relic, each age sending more terrible champions:

                            • SATYA WAVES (W1-W3): the lesser demons probe your line — Pishacha, Rakshasa, Daitya, Asura. Easy to repel.
                            • TRETA WAVES (W4-W6): heroes of myth are corrupted. Mahishasura the buffalo demon, Ravana the ten-headed king, Indrajit the conqueror of Indra, Tarakasura, Putana the demoness — they come WITH their mythic power, +20% over Satya creatures.
                            • DVAPARA WAVES (W7-W13): the war intensifies. Vritra the drought-serpent stalks your gold mines. Raktabija — every drop of his blood spawns another. Bhasmasura's ash aura reverts towers to their primitive form. Adaptive difficulty climbs (+50%). The relic must be CHARGED here — feed it gold so the chakra can wake when the End arrives.
                            • W14 — THE ANTA YUGA — Kali Yuga himself walks the path. "कलिः अहम् — धर्मस्य अन्तः समागतः!" ("I am Kali Yuga — the end of dharma has come!"). 600,000 HP of cosmic dissolution AND he regenerates 500 HP/sec — no single weapon can fell him. Not the chakra alone. Not Durga alone. Not the central tower alone. Only the convergence of the chakra burn, the Durga Combined Strike, the central relic's retaliation, AND your regular tower fire will end the End Age. He EATS towers as he marches, growing +8% maxHP and +12% damage with each kill. The chakra drains as it burns — keep feeding it gold from the Recharge bar at top of screen. If the chakra drops to 0%, Kali eats freely. If every weapon strikes together, dharma endures.

                            YOUR ROLE — You are the last defender of the wheel of dharma. The relic is the world. The towers are mortal vows. The chakra is divine will. The end has come — but it does not have to arrive.

                            "धर्मो रक्षति रक्षितः" — "Dharma protects those who protect it."
                            """)

                        helpSection(
                            icon: "hand.tap.fill", tint: .cyan,
                            title: "Controls — Taps & Gestures",
                            body: """
                            EVERY visible element responds to TAP for info.

                            SINGLE TAP:
                            • Empty slot → opens the Build menu (towers + buildings).
                            • Tower → opens the Tower menu (upgrade, relocate, sell, stones, auras) + shows quick stats banner.
                            • Building → opens the Building menu (upgrade, sell).
                            • Central Sudarshan relic → shows its full story banner (HP, role, how to charge it).
                            • HUD pills (lives, score, race, age, resources, stones) → instant info banner.
                            • Boss enemy on the field → re-summons its info card.
                            • Upgrade buttons (tower / building / stone / aura) → either UPGRADES if affordable OR pops a banner listing every resource you need + what you're short on (✓/✗ per resource).
                            • Pralay / Wall / Feed buttons → if locked, banner explains the exact reason (wave too low / no stone / no gold / etc.).

                            LONG PRESS (0.5s hold):
                            • ANY button (Pause / Mute / Restart / Speed / Bazaar / Stones shop / etc.) → shows that button's info tooltip WITHOUT firing its action. Use this to peek before tapping.
                            • Tower path card in Build menu → opens the Astra Codex (lore + lineage).

                            HOLD (drag-and-hold):
                            • Feed button on Sudarshan → drips a Feed every 0.35s while held. Release to stop. Hands-free charging.

                            DISMISS:
                            • Tap any info banner (or its ✗) to dismiss early. Banners auto-dismiss after 6-18s scaled by text length.
                            • Tap outside Guide Book / Bazaar / Stone Shop → closes the overlay.
                            """)

                        helpSection(
                            icon: "rectangle.3.group.fill", tint: .cyan,
                            title: "Reading the HUD",
                            body: """
                            TOP HUD — Row 1:
                            • ❤ Lives — central tower HP. At 0 = Game Over.
                            • ⭐ Score — run score. 2,000 unlocks Amrita Kalash.
                            • Race pill — your dynasty's signature power.
                            • +N% pill — adaptive difficulty multiplier.
                            • 📖 Guide, 🔊 Mute, ⏸ Pause, ⏩ Speed, ↺ Restart.
                            • Yug + Wave pill — current Yug and wave number.

                            TOP HUD — Row 2 (horizontal scroll):
                            • 🏪 Bazaar — points shop.
                            • Resource pills: gold / metal / tech / jotisha / veda.
                            • 💎 Stones — stone shop + your inventory pills.
                            • Quick-Build tower icons (7 paths).
                            • Quick-Build building icons (5 production + 1 endgame).
                            • Auto, Aura, Wall toggles.

                            BOTTOM BAR:
                            • Advance to next Yug button (when affordable).
                            • Next Wave (or Start Defence) button.
                            • Auto-start countdown badge (cancellable).
                            • Pralay (cosmic dissolution) button — right side.

                            CENTRE OF FIELD:
                            • Sudarshan Relic at path's end — central tower.
                            • In Dvapara: Feed / Burst / HP / charge meter around it.
                            • In W14: spinning chakra animation + recharge bar at top of screen.

                            FLOATING:
                            • Amrita Kalash icon (top centre) — appears once score ≥ 2,000.
                            • Boss info card (top right) — auto-appears for ~5s on each boss spawn.
                            """)

                        helpSection(
                            icon: "burst.fill", tint: .brown,
                            title: "Towers",
                            body: """
                            • Tap any open slot → build menu opens.
                            • 7 tower paths: Archer, Fire, Water, Ice, Divine, Maya, Sensory.
                            • Each path has 3 or 4 tiers — upgrade for more damage / range / effects.
                            • Trishul, Agneyastra and Sheetastra unlock only at later Yugs.
                            • Maya path is fully Dvapara-locked (lock badge shows on the card).

                            Tips:
                            • Towers heal between waves and gain +12% HP per wave survived.
                            • Each kill adds +6 HP and +0.1 attack (veteran bonus). A yellow badge shows kill count.
                            • Tap a tower → Relocate (T1 free, T2/T3 charge a small fee). Stones, kills, auras are preserved.
                            """)

                        helpSection(
                            icon: "building.2.fill", tint: .yellow,
                            title: "Resource Buildings",
                            body: """
                            • 5 kinds: Gold Mine, Foundry (metal), Tech Lab, Observatory (jotisha), Gurukul (veda).
                            • Buildings only produce during active waves (3× rate during the Sudarshan endgame).
                            • Gold Mine has a 4-tier upgrade (L1 → L2 → L3 → L4); all others are 3-tier.
                            • Buildings are invulnerable — bosses can't smash them.

                            Tips:
                            • Stacking the same building costs more each time (no "free pair"). Upgrade existing instead.
                            • Plant at least 1 gold mine W1 — Wave Tribute bazaar perk + 2-3 L3 mines covers most of the run.
                            """)

                        helpSection(
                            icon: "sparkles", tint: .orange,
                            title: "Enemies",
                            body: """
                            • Fodder: Pishacha (basic), Rakshasa, Daitya, Asura, Vetala, Mayavi (invisible).
                            • Mid-bosses (Mahishasura, Indrajit, Tarakasura, Bhasmasura, Raktabija, Putana, Vritra, Ravana) — each demands a specific astra mix.
                            • Resource Bearers (Lobha Yaksha, Loha Asura, Yantra Pishacha, Tara Devi, Rishi Atma) — drop bonus resources.
                            • Mani Murta — drops a random power stone on kill.
                            • Kali Yuga — final boss at W14. Only Sudarshan Chakra kills him.

                            Tips:
                            • Tap a boss on the field to bring back its info card.
                            • Wounded bosses do up to 60% more breach damage to the central tower — finish them, don't maim them.
                            • Mayavi/Indrajit are invisible — build Drishti (sensory) towers to reveal them.
                            """)

                        helpSection(
                            icon: "diamond.fill", tint: Color(red: 0.95, green: 0.55, blue: 0.85),
                            title: "Power Stones",
                            body: """
                            • 4 kinds: Chuni (+damage), Panna (+fire rate), Nila (+range), Raktamukhi (+all stats).
                            • Stones are STONE-ONLY now — gold/metal/etc. can't pay for stone jobs.
                            • Obtain stones two ways:
                              - Kill Mani Murta (drops 1 random stone)
                              - Buy with gold from the "💎 Stones" button in the HUD
                            • Attached stones are TIMED — they auto-remove when the timer expires. Higher level = longer:
                              - Chuni: L1 20s · L3 60s
                              - Panna: L1 24s · L3 72s
                              - Nila: L1 28s · L3 84s
                              - Raktamukhi: L1 40s · L3 120s

                            Tip: refresh a stone (re-attach) to extend the timer.
                            """)

                        helpSection(
                            icon: "cross.case.fill", tint: Color(red: 0.30, green: 0.95, blue: 0.55),
                            title: "Auras (Heal + Shield)",
                            body: """
                            • Open the TowerMenu → toggle Heal (Treta+) or Shield (Dvapara+) aura on any tower.
                            • Heal aura restores nearby tower HP during waves.
                            • Shield aura grants 25%-70% damage reduction to nearby towers.
                            • 4 tiers each — L4 = "Sanjivani" / "Lakshman Rekha" (mythic-strength).
                            • Pay jotisha + veda for upgrades.

                            HUD: turn ON the "Aura" toggle (locked until Treta) → towers auto-buy aura tiers between waves if affordable.
                            """)

                        helpSection(
                            icon: "shield.lefthalf.filled", tint: .green,
                            title: "Wall (Emergency Shield)",
                            body: """
                            • Wall button in HUD row 2. Costs a STONE (not gold) and runs on a timer.
                            • Spends your HIGHEST-tier stone (Raktamukhi > Nila > Panna > Chuni).
                            • Duration scales with stone used:
                              - Chuni → 10s wall
                              - Panna → 14s wall
                              - Nila → 18s wall
                              - Raktamukhi → 28s wall
                            • Effect: instantly heals every tower to full and grants a 5,000 HP shield that absorbs damage before HP.
                            • Progress bar appears under the button during wall.
                            """)

                        helpSection(
                            icon: "sun.max.fill", tint: Color(red: 1.0, green: 0.85, blue: 0.25),
                            title: "Pralay (Cosmic Dissolution)",
                            body: """
                            • Pinned bottom-right of the BottomBar. Unlocks at W8.
                            • PREMIUM cost: 3,500 g + 400 metal + 300 tech + 400 jotisha + 400 veda.
                            • For 12 seconds, every resource building fires divine beams at enemies (240 damage per shot, 0.4s cadence, 320px range).
                            • Kali Yuga is immune (chakra-only kill).

                            Tip: with this cost, you can only afford 1-2 activations in the whole run. Save it for the W12-W13 bossfest or a true panic moment.
                            """)

                        helpSection(
                            icon: "circle.hexagongrid.fill", tint: .yellow,
                            title: "Sudarshan Chakra",
                            body: """
                            • The central tower at the path's end. Always charging from W1.
                            • Tap "Feed" (or HOLD it) to spend resources and fill the charge bar.
                            • At ≥20% charge, "Burst" appears — discharges 20% of charge as area damage to all non-Kali-Yuga enemies.
                            • At 100% charge + Kali Yuga on field → chakra ignites and burns him down. Victory.

                            Tip: bursts kill mid-bosses fast. Don't hoard charge — keep bursting if needed.
                            """)

                        helpSection(
                            icon: "storefront.fill", tint: Color(red: 0.55, green: 0.30, blue: 0.78),
                            title: "Bazaar (Points Shop)",
                            body: """
                            • Tap the storefront pill in HUD row 2.
                            • Spend Bazaar Points (earned per kill + wave clear) on:
                              - Instant items (gold, veda, metal, lives boost)
                              - Run Buffs (Wave Tribute = +2000g/wave; Wave Veda Tithe = +30v/wave)
                              - Permanent Perks (carry over runs — bonus starting lives, etc.)

                            Tip: Wave Tribute pays for itself within 2 waves. Buy it W1.
                            """)

                        helpSection(
                            icon: "chart.line.uptrend.xyaxis", tint: .orange,
                            title: "Adaptive Difficulty",
                            body: """
                            • The "+N%" badge in HUD row 1 shows current enemy power bonus.
                            • When defence is dominating, enemy HP and damage climb (capped 2.4×).
                            • When the line is leaking, the multiplier eases back.
                            • Color: green (low) → yellow → orange → red (cap).

                            Reward: gold + Bazaar points scale UP with the multiplier — harder kills pay more.
                            """)

                        helpSection(
                            icon: "play.square.fill", tint: .cyan,
                            title: "HUD Controls",
                            body: """
                            • Auto — auto-start next wave (countdown badge appears).
                            • Aura — auto-buy heal/shield aura tiers (Treta+).
                            • Wall — spend a stone for a timed shield (see Wall section).
                            • Pause — freeze game, plan in peace.
                            • Speed — cycles 1× → 2× → 4× → 8×.
                            • Restart — destroys current run (confirmation required).
                            """)

                        helpSection(
                            icon: "calendar", tint: Color(red: 0.80, green: 0.60, blue: 1.00),
                            title: "Yugs (Ages)",
                            body: """
                            • Satya Yug — start. Most T1 towers available.
                            • Treta Yug — Heal Aura, Agneyastra, Sheetastra, all T2 astras unlock. (1,000g + 400m + 200j + 50v)
                            • Dvapara Yug — Shield Aura, Trishul, all Maya tier, T3 + T4 ultimates. (3,000g + 1,000m + 600t + 400j + 500v)

                            ⚠ Advancing a Yug ALSO makes enemies stronger from the next wave on:
                              - Treta: enemies +20% HP & damage, plus a Raktabija appears every wave.
                              - Dvapara: enemies +50% HP & damage, plus a Vritra appears every wave too.
                            The age pill shows the current %.

                            Tip: rush Treta by W3, Dvapara by W7 — but only if your tower lineup can absorb the bump. Build the T2/T3 you unlocked before letting the new enemies hit.
                            """)

                        helpSection(
                            icon: "person.3.fill", tint: .cyan,
                            title: "Races / Dynasties",
                            body: """
                            Pick on the title screen. Each grants a UNIQUE passive power for the entire run.

                            • RAGHUVANSH — +25% damage to every BOSS. Boss-melter.
                            • MAURYA — +30% projectile speed across every astra.
                            • GUPTA — every tower can target invisible enemies (skip Drishti path).
                            • PRATIHARA — +30% starting tower HP.
                            • RASHTRAKUTA — −25% building cost. Economy-first.
                            • PAL — −25% stone cost. ★ Beginner-friendly. Stone builds.
                            • CHOLA — +1% gold + Bazaar pts per kill. Snowball.
                            • SEN — +1 chain target on Aindra / Naga Pasha. ★ Beginner-friendly. Trash-clear.
                            • AHOM — +4.5 HP/sec tower regen + 25% aura range. Defensive grinder.

                            Tap your race pill in the HUD for the full story.
                            """)

                        helpSection(
                            icon: "scroll.fill", tint: .orange,
                            title: "Astra Codex (Lore)",
                            body: """
                            • Long-press any tower path card in the Build menu → opens a lore card describing the astra, its deity, mythological origin, and gameplay role.
                            • Each astra has a Sanskrit name, a deity association, and a one-line mantra.
                            • Browse before buying — the codex tells you which astra fits which enemy archetype.
                            """)

                        helpSection(
                            icon: "circle.hexagonpath.fill", tint: .yellow,
                            title: "Sudarshan — Phases",
                            body: """
                            The central tower goes through phases:

                            1) DORMANT (Satya / Treta): just a relic with HP. Tap for info.
                            2) CHARGING (Dvapara unlocked): Feed button appears. Tap to feed 250g per tap. Hold for auto-feed every 0.35s.
                            3) BURST READY (≥20% charge): Burst button shows on left side. Tap to discharge 20% as AoE — kills mid-bosses fast.
                            4) MATURED (100% + Kali Yuga on field): spinning chakra animation. Burns Kali Yuga at 1,650 DPS while draining its own charge ~1.4%/s. Keep tapping the top-screen Recharge bar to maintain the burn.
                            5) VICTORY: chakra finishes Kali Yuga. Run complete.

                            ⚠ Burn STOPS at 0% — don't let it empty during the fight or Kali Yuga starts eating towers again.
                            """)

                        helpSection(
                            icon: "sparkle", tint: Color(red: 0.85, green: 0.15, blue: 0.95),
                            title: "Divine Path — The Three-Way Balance",
                            body: """
                            The DIVINE path (Trishul → Vajrastra → Narayana → Pashupatastra) is the KEY strategic line because it simultaneously feeds THREE systems — each balanced against Kali Yuga's power.

                            1) CENTRAL TOWER MAX HP (permanent +40 each):
                            Every divine tower you BUILD permanently grants the central Sudarshan relic +40 max HP AND +40 current HP. The bond persists even if the tower later dies.
                              • 0 divine = ~60 lives (Kali Yuga shreds in 3 seconds)
                              • 2 divine = ~140 lives (survives ~9 seconds)
                              • 4 divine = ~220 lives (survives ~22 seconds)
                              • 6 divine = ~300 lives (effectively safe)

                            2) CENTRAL TOWER REGEN (dynamic +3 HP/sec EACH):
                            Every CURRENTLY ALIVE divine tower heals the relic +3 HP/sec during waves.
                              • 4 alive → 12 HP/sec regen vs Kali Yuga's 22 dps bite → net 10 dps damage
                              • 6 alive → 18 HP/sec → net 4 dps — Kali Yuga barely chips
                              • 8 alive → 24 HP/sec → STALEMATE / heal-through
                            Lose a divine tower and the regen drops with it — protect them!

                            3) CHAKRA BURN BOOST (dynamic +15% EACH):
                            Every alive divine tower amplifies the Sudarshan Chakra's burn by 15%.
                              • Base chakra = 1100 DPS × 1.5 (Kali Yuga multiplier) = 1650 DPS → 115 s to kill Kali Yuga
                              • 4 alive divine = +60% = 2640 DPS → 72 s
                              • 6 alive divine = +90% = 3135 DPS → 60 s
                              • 8 alive divine = +120% = 3630 DPS → 52 s

                            4) DIVINE POINTS (Parijata empowerment):
                            Divine-path tower lands killing blow on a card-worthy boss → +1 divine point → +12% Parijata production. Parijata stays INACTIVE until your first divine tower is placed.

                            ⚠ The signature glyphs on the field tell you whose blow it is:
                              • श्री (Shree) — Sudarshana Chakra
                              • भम्भ्र (Bhambhra) — Bhambhrastra (fire T4)
                              • ॐ (Om) — Pashupatastra (Shiva's mantra)
                            """)

                        helpSection(
                            icon: "burst.fill", tint: Color(red: 1.0, green: 0.55, blue: 0.20),
                            title: "दुर्गा — Trimurti Combined Strike",
                            body: """
                            When THREE distinct divine astra KINDS are alive on the field at the same time AND Kali Yuga is in the fight, a दुर्गा STRIKE button appears at the top of the screen.

                            • The four divine kinds are: Trishul, Vajrastra, Narayana, Pashupatastra.
                            • You need any THREE of them alive simultaneously — different tiers on the same kind don't count as different kinds.
                            • Tap the button → three beams converge from those towers on Kali Yuga, a Durga trishul-yantra blooms on him, and 18,000 chunk damage lands (plus splash on any enemy within 100px).
                            • Cooldown: 8 seconds between strikes.

                            Strategy: this is your hammer for the W14 endgame. Keep three different divine tower kinds healthy through the fight to fire repeatedly. Lose one and the button greys out.
                            """)

                        helpSection(
                            icon: "sparkle", tint: Color(red: 0.85, green: 0.15, blue: 0.95),
                            title: "Divine Points & Parijata Briksha",
                            body: """
                            Divine Points (DP) are earned every time a DIVINE-PATH tower lands the killing blow on a boss. The DP counter appears in the HUD next to your race pill as soon as you bank the first one.

                            What they DO: each point empowers the PARIJATA BRIKSHA — the divine wish-tree building (gold 2,500 + 200 metal + 200 tech + 200 jotisha + 200 veda) — by +12% production. The Parijata is INACTIVE until you have at least one divine tower placed, and only appears in the Build menu during the Sudarshan endgame.

                            • 0 DP → Parijata = 1× production
                            • 5 DP → Parijata = 1.6×
                            • 10 DP → Parijata = 2.2×
                            • 15 DP → Parijata = 2.8×

                            Tip: plant the Parijata as soon as it unlocks (Sudarshan empowered phase) and aim every boss kill at it via a divine astra to compound the wish-tree's universal output.
                            """)

                        helpSection(
                            icon: "scalemass.fill", tint: .orange,
                            title: "The Divine Balance",
                            body: """
                            Stacking the divine line is powerful — but not free. The asura host learns from divine resistance:

                            • Every divine-path tower you BUILD this run adds +6% to enemy HP & damage in every subsequent wave.
                            • Caps at +60% (10 divine towers).
                            • Stacks on top of the existing adaptive multiplier and the per-Yug enemy power bonus.

                            So 4 divine towers = +24% enemy power, but the chakra burns 60% faster, the relic gains +160 max HP + 12 HP/sec regen, AND every boss kill from a divine tower banks Divine Points + a special-attack charge on the tower itself. The trade is intentional: bigger divine commitment, harder waves, mightier endgame.
                            """)

                        helpSection(
                            icon: "exclamationmark.triangle.fill", tint: .red,
                            title: "Kali Yuga — Anta-Yuga Final Boss",
                            body: """
                            Kali Yuga is the FULL force the End Age demands. NO SINGLE WEAPON CAN END HIM. Chakra alone falls short, Durga alone falls short, central tower alone falls short — all of them have to land together.

                            • 600,000 HP — a deep well; no one weapon drains it.
                            • REGENERATES 500 HP/sec — net chakra DPS has to OUTPACE his self-heal.
                            • 960 damage per tower attack — every tower he eats hurts double.
                            • 22 base damage per bite on the CENTRAL RELIC (× rage). The relic's 600 DPS retaliation chips back when he's within 80px.
                            • Eats your towers: +8% maxHP / +12% damage per kill.

                            WHY NO SINGLE WEAPON SUFFICES (numbers at 6 alive divine towers):
                              • CHAKRA alone: 3,135 - 500 regen = 2,635 net DPS. 600k / 2,635 = 228 s — relic dies first.
                              • DURGA alone: 18k per fire on 8 s cd = ~225 DPS average, − 500 regen = NEGATIVE. Can never finish him.
                              • CENTRAL RETALIATION alone: 1,500 DPS - 500 regen = 1,000 net only while Kali Yuga sits at the centre. 600k / 1,000 = 600 s — relic dies first.

                            WHY THEY WIN TOGETHER (≈ 100 s fight, 6 alive divine):
                              • Chakra: 2,635 × 100 = 263,500
                              • Durga (12 fires): 12 × 18,000 = 216,000
                              • Central retaliation in the last ~30 s of the march: 1,500 × 30 = 45,000
                              • Regular tower fire (T4 ultimates, special-charge boss astras): ~80,000
                              • TOTAL: ~604,500 → just barely over 600,000.

                            Lose any one of those layers and the fight tips toward Kali Yuga. Build ≥3 distinct divine kinds, keep them alive, feed the chakra, and time Durga strikes on cooldown.
                            """)

                        helpSection(
                            icon: "sun.max.fill", tint: Color(red: 1.0, green: 0.85, blue: 0.25),
                            title: "Pralay — Escalating Cost",
                            body: """
                            Pralay is no longer a flat one-time price. Every activation multiplies the next one by 1.75×:

                            • Use 1: 3,500 g + 400 m + 300 t + 400 j + 400 v
                            • Use 2: 6,125 g + 700 m + 525 t + 700 j + 700 v
                            • Use 3: 10,719 g + 1,225 m + 919 t + 1,225 j + 1,225 v
                            • Use 4: 18,758 g + 2,144 m + 1,608 t + 2,144 j + 2,144 v
                            • Use 5: 32,827 g + 3,751 m + 2,813 t + 3,751 j + 3,751 v

                            Strategy: 2 uses is comfortable. 3 is a stretch. 4 is "I am playing for the spectacle". Save it for the worst moment — the LAST attack of your run will be the most expensive.
                            """)

                        helpSection(
                            icon: "lightbulb.fill", tint: .yellow,
                            title: "Strategy Tips",
                            body: """
                            • W1-W3: build 2-3 darts + 1 gold mine. Cheap and safe.
                            • W4-W6: upgrade to T2 astras. Stack a Drishti tower to reveal Mayavi/Indrajit.
                            • W7: Boon wave — kill bearers for free resources.
                            • W8-W10: unlock Dvapara. Pour gold into Sudarshan. Build a Trishul or Maya path.
                            • W11-W13: prepare a T4 ultimate (Pashupatastra / Sudarshana / Bhambhrastra) — only the chakra+T4 combo handles W14.

                            Survival:
                            • Heal aura on every tower — passive HP regen during fights.
                            • Lakshman Rekha (Shield L4) on chokepoint towers — 70% damage reduction.
                            • Wall on bossfest waves — 5,000 HP shield per tower lasts 10-28s.
                            """)

                        helpSection(
                            icon: "hands.sparkles.fill", tint: .yellow,
                            title: "Reverence",
                            body: """
                            Anta Yuga is a work of interactive fiction inspired by Indian itihāsa — the Ramayana, the Mahabharata, and the Puranas. The names of deities, asuras, astras, ages, and dynasties used throughout the game are drawn from public-domain source material that has belonged to a living tradition for thousands of years.

                            We use them with respect:
                            • The astras (Sudarshana, Pashupatastra, Brahmasira, Bhambhrastra, and others) appear as the divine weapons they are in the source texts — wielded against asuras to protect dharma.
                            • The asuras (Mahishasura, Ravana, Indrajit, Vritra, Bhasmasura, Putana, Kali Yuga) are depicted as the antagonists they are in the itihāsa, not as caricatures.
                            • The Yugas (Satya, Treta, Dvapara, Kali) are used as the cosmic ages they name in scripture — markers of the cycle of time.
                            • The दुर्गा-Strike combination attack invokes the Goddess by name to call her protection over the moment dharma is in greatest danger — Wave 14, the End Age. We mean it as homage, not as decoration.

                            If you feel any element of this game has misrepresented the tradition, write to sasmalgiri@gmail.com — we will listen, and where you are right, we will revise. Nothing here is intended to make light of any community's beliefs.

                            — EcoSanskriti Innovation
                            """)
                    }
                    .padding(14)
                }
            }
            .frame(maxWidth: 440, maxHeight: 640)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(red: 0.06, green: 0.05, blue: 0.12).opacity(0.97))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.cyan.opacity(0.5), lineWidth: 1.5)
                    )
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 30)
        }
    }

    private func helpSection(icon: String, tint: Color, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(tint)
                Text(title)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }
            Text(body)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.85))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(tint.opacity(0.35), lineWidth: 1)
                )
        )
    }
}

/// Global stone shop — opens from the HUD's "Stones" pill. Lets the
/// player buy stones with gold without first selecting a tower. Each
/// row shows the stone's tagline, inventory count, and the gold price.
struct StoneShopOverlay: View {
    let vm: GameViewModel
    @Binding var presented: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { presented = false }

            VStack(spacing: 10) {
                HStack {
                    Image(systemName: "diamond.fill")
                        .foregroundColor(Color(red: 0.95, green: 0.55, blue: 0.85))
                    Text("Power Stone Shop")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        presented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
                Text("Use gold to bank stones. Spend them on tower attach/upgrade or wall activation.")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Divider().background(Color.white.opacity(0.2))

                ForEach(StoneKind.allCases) { kind in
                    let price = GameViewModel.goldPriceForStone(kind)
                    let canBuy = vm.canBuyStone(kind)
                    HStack(spacing: 10) {
                        Image(systemName: kind.symbol)
                            .font(.system(size: 22))
                            .foregroundColor(kind.color)
                            .frame(width: 32)
                        VStack(alignment: .leading, spacing: 1) {
                            HStack(spacing: 4) {
                                Text(kind.displayName)
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundColor(.white)
                                Text(kind.tagline)
                                    .font(.system(size: 9))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            Text("Owned: \(vm.stoneCount(kind))")
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .foregroundColor(.white.opacity(0.75))
                        }
                        Spacer()
                        Button {
                            vm.buyStone(kind)
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "plus.circle.fill")
                                Text("\(price)")
                                    .monospacedDigit()
                                Image(systemName: "dollarsign.circle.fill")
                                    .foregroundColor(.yellow)
                            }
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(canBuy ? kind.color.opacity(0.55) : Color.gray.opacity(0.4)))
                            .overlay(Capsule().stroke(canBuy ? Color.white.opacity(0.7) : Color.clear, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .disabled(!canBuy)
                        .opacity(canBuy ? 1.0 : 0.55)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(14)
            .frame(maxWidth: 360)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.07, green: 0.05, blue: 0.13).opacity(0.96))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(red: 0.95, green: 0.55, blue: 0.85).opacity(0.65), lineWidth: 1.5)
                    )
            )
            .padding(.horizontal, 16)
        }
    }
}

struct GodModeFloatingButton: View {
    let vm: GameViewModel
    @State private var pulse: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let active = vm.isGodModeActive
        let affordable = vm.canActivateGodMode()
        let unlocked = vm.wave >= GameViewModel.godModeUnlockWave
        // Escalating cost — each prior use multiplies it by 1.75×.
        let cost = vm.nextGodModeCost
        Button {
            // Silent — tap activates Pralay if unlocked AND affordable AND
            // not already active. Otherwise no-op. Long-press the button
            // for the locked / cost / status tooltip.
            if !active && unlocked && affordable {
                vm.activateGodMode()
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: active ? "sun.max.fill" : "sparkles")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(active ? .black : .yellow)
                Text(active
                     ? String(format: "%.0fs", vm.godModeTimer)
                     : (unlocked ? "Pralay" : "W\(GameViewModel.godModeUnlockWave)"))
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(active ? .black : .white)
                    .monospacedDigit()
                if !active && unlocked {
                    HStack(spacing: 2) {
                        Text("\(cost.gold)")
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.yellow)
                    }
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                }
            }
            .frame(width: 64, height: 64)
            .background(
                Circle()
                    .fill(active
                          ? Color(red: 1.0, green: 0.85, blue: 0.25)
                          : Color.black.opacity(0.75))
            )
            .overlay(
                Circle()
                    .stroke(active ? Color.white
                                   : (affordable ? Color(red: 1.0, green: 0.85, blue: 0.25)
                                                 : Color.gray.opacity(0.5)),
                            lineWidth: 2)
            )
            .shadow(color: active ? Color.yellow.opacity(0.7 + 0.3 * pulse)
                                  : (affordable ? Color.yellow.opacity(0.4) : .clear),
                    radius: active ? 10 : 6)
            .opacity(active || affordable ? 1.0 : 0.55)
        }
        .buttonStyle(.plain)
        .tooltip(active ? "Pralay Active" : (unlocked ? "Pralay — Cosmic Dissolution" : "Pralay Locked"),
                 pralayTooltipBody(active: active, affordable: affordable, unlocked: unlocked, cost: cost),
                 icon: active ? "sun.max.fill" : "sparkles",
                 tint: Color(red: 1.0, green: 0.85, blue: 0.25))
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = 1
            }
        }
        .onChange(of: vm.wave) { _, w in
            if w >= GameViewModel.godModeUnlockWave {
                HintsStore.shared.trigger(.godModeUnlock)
            }
        }
    }

    private func pralayTooltipBody(active: Bool, affordable: Bool, unlocked: Bool, cost: Resources) -> String {
        if active {
            return String(format: "Pralay active — \"cosmic dissolution\". All towers fire at max rate, deal massive damage, ignore range limits. %.0fs remaining.", vm.godModeTimer)
        }
        if !unlocked {
            return "Locked until wave \(GameViewModel.godModeUnlockWave). Pralay is your panic button against the Kali Yuga final boss."
        }
        let costStr = "\(Int(cost.gold))g + \(Int(cost.metal))m + \(Int(cost.tech))t + \(Int(cost.jotisha))j + \(Int(cost.veda))v"
        let prefix = affordable ? "READY." : "Not enough resources."
        let dur = Int(GameViewModel.godModeDuration)
        return "\(prefix) Cost: \(costStr). Activates Pralay (cosmic dissolution) for \(dur)s — every tower fires at max rate, massive damage, full-field range. Save for the boss."
    }
}

struct AmritaKalashButton: View {
    let vm: GameViewModel
    @State private var glow: Double = 0
    @State private var consumed: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            // Brief consume animation, then apply the effect.
            withAnimation(.easeOut(duration: 0.25)) { consumed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                vm.useAmritaKalash()
                withAnimation(.easeIn(duration: 0.15)) { consumed = false }
            }
        } label: {
            VStack(spacing: 4) {
                kalashIcon
                    .frame(width: 64, height: 78)
                    .scaleEffect(consumed ? 1.4 : 1.0)
                    .opacity(consumed ? 0.0 : 1.0)
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.cyan)
                    Text("\(GameViewModel.amritaKalashCost) → +\(GameViewModel.amritaKalashLifeGain) lives")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.black.opacity(0.55)))
                .overlay(Capsule().stroke(Color.yellow.opacity(0.55), lineWidth: 1))
            }
        }
        .buttonStyle(.plain)
        // Once tapped, the 250 ms consume animation is in flight — disable
        // the button so a quick second tap can't double-spend 10 000 points.
        .disabled(consumed)
        .tooltip("Amrita Kalash",
                 "Spend \(GameViewModel.amritaKalashCost) run score to gain +\(GameViewModel.amritaKalashLifeGain) lives. The divine nectar pot — emergency life refill before the boss.",
                 icon: "drop.fill", tint: .yellow)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glow = 1
            }
        }
    }

    /// Stylized golden kalash pot with glowing crown (amrita / nectar).
    private var kalashIcon: some View {
        ZStack {
            // Outer divine halo, pulses softly
            Circle()
                .fill(RadialGradient(colors: [
                    Color.yellow.opacity(0.55 + 0.25 * glow),
                    Color.orange.opacity(0.20),
                    .clear
                ], center: .center, startRadius: 4, endRadius: 50))
                .frame(width: 110, height: 110)
                .blendMode(.plusLighter)

            // Pot body
            Path { p in
                let w: CGFloat = 56
                let h: CGFloat = 60
                let cx: CGFloat = 32, cy: CGFloat = 46
                p.move(to: CGPoint(x: cx - w/2, y: cy + 4))
                p.addQuadCurve(to: CGPoint(x: cx + w/2, y: cy + 4),
                               control: CGPoint(x: cx, y: cy + h * 0.65))
                p.addLine(to: CGPoint(x: cx + w/2 - 8, y: cy - h * 0.30))
                p.addQuadCurve(to: CGPoint(x: cx - w/2 + 8, y: cy - h * 0.30),
                               control: CGPoint(x: cx, y: cy - h * 0.45))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [
                Color(red: 1.0, green: 0.88, blue: 0.45),
                Color(red: 0.85, green: 0.55, blue: 0.15),
                Color(red: 0.50, green: 0.28, blue: 0.05)
            ], startPoint: .top, endPoint: .bottom))
            .shadow(color: .orange.opacity(0.8), radius: 4)
            .overlay(
                Path { p in
                    let w: CGFloat = 56
                    let cx: CGFloat = 32, cy: CGFloat = 46
                    p.move(to: CGPoint(x: cx - w/2 + 4, y: cy + 4))
                    p.addLine(to: CGPoint(x: cx + w/2 - 4, y: cy + 4))
                }
                .stroke(Color.white.opacity(0.7), lineWidth: 1)
            )

            // Neck ring
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(colors: [Color.yellow, .orange],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 38, height: 6)
                .offset(y: -12)
                .shadow(color: .orange, radius: 2)

            // Crown / mango leaves
            Path { p in
                let cx: CGFloat = 32, cy: CGFloat = 18
                p.move(to: CGPoint(x: cx - 14, y: cy + 4))
                p.addQuadCurve(to: CGPoint(x: cx - 2, y: cy - 10),
                               control: CGPoint(x: cx - 8, y: cy - 4))
                p.addQuadCurve(to: CGPoint(x: cx + 2, y: cy - 10),
                               control: CGPoint(x: cx, y: cy - 14))
                p.addQuadCurve(to: CGPoint(x: cx + 14, y: cy + 4),
                               control: CGPoint(x: cx + 8, y: cy - 4))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [.green, Color(red: 0.10, green: 0.45, blue: 0.18)],
                                 startPoint: .top, endPoint: .bottom))
            .shadow(color: .green.opacity(0.6), radius: 2)

            // Nectar light bursting from the top
            Circle()
                .fill(RadialGradient(colors: [
                    Color.white.opacity(0.95),
                    Color.yellow.opacity(0.85),
                    .clear
                ], center: .center, startRadius: 1, endRadius: 10))
                .frame(width: 16, height: 16)
                .offset(y: -22)
                .shadow(color: .yellow, radius: 6)

            // Tiny "+" hint
            Image(systemName: "heart.fill")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(.red.opacity(0.95))
                .offset(y: 44)
                .shadow(color: .red, radius: 3)
        }
        .frame(width: 64, height: 78)
    }
}

// MARK: - Floating damage number

/// A short-lived "+50" / "120" text that drifts upward from a hit enemy.
struct DamageNumberView: View {
    let number: DamageNumber

    var body: some View {
        let progress = number.age / DamageNumber.lifetime
        let drift = -28.0 * progress
        let alpha = 1.0 - progress * 0.95
        Text("\(number.value)")
            .font(.system(size: number.isCrit ? 17 : 13,
                          weight: number.isCrit ? .heavy : .bold,
                          design: .rounded))
            .monospacedDigit()
            .foregroundColor(number.isCrit ? .yellow : .white)
            .shadow(color: number.color.opacity(0.9), radius: 3)
            .shadow(color: .black.opacity(0.7), radius: 1)
            .position(x: number.position.x, y: number.position.y + drift - 8)
            .opacity(alpha)
            .scaleEffect(1.0 + (number.isCrit ? 0.25 : 0.10) * (1.0 - progress))
    }
}

// MARK: - Always-on Sudarshan relic

/// Dormant Sudarshan relic shown at the path end from W1. Carries the
/// player's HP (vm.lives / vm.maxLives) and flashes red when an enemy
/// reaches it — driven by vm.relicHitFlash.
struct SudarshanRelicView: View {
    let vm: GameViewModel
    @State private var glow: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let hitFrac = vm.relicHitFlash / 0.45   // 1.0 at moment of hit, 0 after
        let hpFrac = vm.maxLives > 0
            ? max(0, min(1, Double(vm.lives) / Double(vm.maxLives)))
            : 0
        ZStack {
            // Damage flash overlay
            if hitFrac > 0 {
                Circle()
                    .fill(Color.red.opacity(0.55 * hitFrac))
                    .frame(width: 74, height: 74)
                    .blendMode(.plusLighter)
            }
            // Soft golden halo — shrunk so labels and slot info around the
            // relic render cleanly.
            Circle()
                .fill(RadialGradient(colors: [
                    Color.yellow.opacity(0.30 + 0.10 * glow),
                    Color.orange.opacity(0.12),
                    .clear
                ], center: .center, startRadius: 3, endRadius: 34))
                .frame(width: 64, height: 64)
                .blendMode(.plusLighter)
            // Inner disc
            Circle()
                .fill(RadialGradient(colors: [
                    Color(red: 1.00, green: 0.88, blue: 0.45),
                    Color(red: 0.50, green: 0.28, blue: 0.05),
                    .black
                ], center: .center, startRadius: 2, endRadius: 20))
                .frame(width: 40, height: 40)
                .overlay(Circle().stroke(Color.yellow.opacity(0.7), lineWidth: 1.0))
                .shadow(color: .orange.opacity(0.6), radius: 3)
            // Yantra centerpiece
            Image(systemName: "circle.hexagongrid.fill")
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(.yellow.opacity(0.95))
                .shadow(color: .orange, radius: 2)
            // HP bar — color shifts green → yellow → red
            VStack(spacing: 1) {
                Text("\(vm.lives)/\(vm.maxLives)")
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 2)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.65))
                        .frame(width: 56, height: 4)
                    Capsule()
                        .fill(hpFrac > 0.5 ? Color.green
                              : hpFrac > 0.25 ? Color.yellow : Color.red)
                        .frame(width: 56 * CGFloat(hpFrac), height: 4)
                }
                .overlay(Capsule().stroke(Color.white.opacity(0.5), lineWidth: 0.5))
            }
            .offset(y: 30)
            // Caption
            Text("Sudarshan")
                .font(.system(size: 8, weight: .heavy, design: .rounded))
                .foregroundColor(.yellow)
                .shadow(color: .black, radius: 2)
                .offset(y: 44)
        }
        .frame(width: 56, height: 56)
        .scaleEffect(1.0 + 0.10 * CGFloat(hitFrac))
        // No inline tooltip — the wrapping Button in gameView fires the
        // info banner on tap so we don't double-call TooltipManager.show.
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                glow = 1
            }
        }
    }
}

// MARK: - Sudarshan endgame views

/// Inactive center tower that accepts resource taps to charge the chakra.
struct SudarshanCenterTowerView: View {
    let vm: GameViewModel
    @State private var pulse: Double = 0
    @State private var holdTask: Task<Void, Never>? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Interval between auto-taps while the Feed button is held down. 0.35 s
    /// is fast enough to feel responsive without burning resources too fast
    /// for the player to notice they're going broke.
    private static let holdTapInterval: UInt64 = 350_000_000

    var body: some View {
        let hpFrac = vm.maxLives > 0
            ? max(0, min(1, Double(vm.lives) / Double(vm.maxLives)))
            : 0
        let centerLabel: String = {
            if vm.sudarshanCharge < 1.0 {
                return "\(Int(vm.sudarshanCharge * 100))%"
            } else if vm.finalBoss == nil {
                return "Wait W\(GameViewModel.kaliYugaArrivalWave)"
            } else {
                return "Ready"
            }
        }()
        // Cross/cardinal layout — relic centered, HP on top, Feed on the
        // right, Burst on the left, charge label below. Uses every side
        // around the central tower so the open space pays off.
        ZStack {
            // Center — the Sudarshan relic ring (48 px).
            ZStack {
                Circle()
                    .stroke(Color.yellow.opacity(0.22), lineWidth: 3)
                    .frame(width: 48, height: 48)
                Circle()
                    .trim(from: 0, to: vm.sudarshanCharge)
                    .stroke(
                        AngularGradient(colors: [.yellow, .orange, .red, .yellow],
                                        center: .center),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-90))
                Circle()
                    .fill(RadialGradient(colors: [
                        Color.yellow.opacity(0.5 + 0.2 * pulse),
                        Color(red: 0.4, green: 0.18, blue: 0.05),
                        .black
                    ], center: .center, startRadius: 2, endRadius: 22))
                    .frame(width: 38, height: 38)
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.yellow.opacity(0.95))
                    .shadow(color: .orange, radius: 2)
            }
            .contentShape(Circle())
            .tooltip("Sudarshan Relic",
                     "The relic at the path centre — your defence's heart. Enemies that breach the path damage it. Tap/hold the relic itself to Feed gold and charge the Sudarshana Chakra. Feeding closes at W\(GameViewModel.kaliYugaArrivalWave) when Kali Yuga arrives.",
                     icon: "circle.hexagongrid.fill", tint: .yellow)
            // Hold-to-feed gesture lives on the relic itself now. Drips one
            // tap on touchdown, then every ~0.35 s while held. Disabled once
            // Kali Yuga has arrived or the chakra is already full.
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard holdTask == nil else { return }
                        let disabled = vm.sudarshanCharge >= 1.0
                            || vm.wave >= GameViewModel.kaliYugaArrivalWave
                        guard !disabled else { return }
                        let okay = vm.tapSudarshan()
                        guard okay else { return }
                        let task = Task { @MainActor in
                            while !Task.isCancelled {
                                try? await Task.sleep(nanoseconds: Self.holdTapInterval)
                                if Task.isCancelled { break }
                                if vm.sudarshanCharge >= 1.0
                                    || vm.wave >= GameViewModel.kaliYugaArrivalWave { break }
                                _ = vm.tapSudarshan()
                            }
                        }
                        holdTask = task
                    }
                    .onEnded { _ in
                        holdTask?.cancel()
                        holdTask = nil
                    }
            )

            // Top — central tower HP readout + bar.
            VStack(spacing: 1) {
                HStack(spacing: 3) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.red)
                    Text("\(vm.lives)/\(vm.maxLives)")
                        .font(.system(size: 8, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 2)
                }
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.7))
                        .frame(width: 60, height: 4)
                    Capsule()
                        .fill(hpFrac > 0.5 ? Color.green
                              : hpFrac > 0.25 ? Color.yellow : Color.red)
                        .frame(width: 60 * CGFloat(hpFrac), height: 4)
                }
                .overlay(Capsule().stroke(Color.white.opacity(0.4), lineWidth: 0.5))
            }
            .offset(y: -42)
            .tooltip("Relic HP \(vm.lives)/\(vm.maxLives)",
                     "Central tower hit points. Each enemy that breaches the path deals damage (scaled by wave). At 0 → Game Over. Heal aura towers nearby will slowly restore it.",
                     icon: "heart.fill", tint: .red)

            // Bottom — charge % label, plus the Awaiting-Kali caption when
            // the chakra is sitting full.
            VStack(spacing: 1) {
                Text(centerLabel)
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 2)
                if vm.sudarshanCharge >= 1.0 && vm.finalBoss == nil {
                    Text("W\(GameViewModel.kaliYugaArrivalWave)")
                        .font(.system(size: 7, weight: .heavy, design: .rounded))
                        .foregroundColor(.yellow.opacity(0.9))
                }
            }
            .offset(y: 38)
            .tooltip("Chakra Charge \(Int(vm.sudarshanCharge * 100))%",
                     "Feed the relic gold to fill this bar. At 100% the Sudarshana Chakra is ready. You also need to reach W\(GameViewModel.kaliYugaArrivalWave) to summon Kali Yuga and end the run.",
                     icon: "circle.hexagongrid.fill", tint: .yellow)

            // Feed is now baked into the relic itself — tap/hold the
            // central Sudarshan to feed gold. No visual caption: the
            // affordance is documented in the relic's tooltip + the
            // in-game guide so the cardinal layout stays clean.

            // Left side — Burst button (only when chakra has enough charge).
            if vm.canFireSudarshanBurst() {
                Button {
                    vm.fireSudarshanBurst()
                } label: {
                    VStack(spacing: 1) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12))
                        Text("Burst")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                        Text("\(Int(GameViewModel.sudarshanBurstCost * 100))%")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(LinearGradient(colors: [.red, .orange],
                                                      startPoint: .top,
                                                      endPoint: .bottom))
                    )
                    .overlay(Capsule().stroke(Color.yellow.opacity(0.7), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .offset(x: -64)
                .tooltip("Sudarshan Burst",
                         "Spend \(Int(GameViewModel.sudarshanBurstCost * 100))% of the chakra's charge to nuke nearby enemies with a divine burst. Useful when the path is choked but you don't want to dip below the W\(GameViewModel.kaliYugaArrivalWave) requirement.",
                         icon: "bolt.fill", tint: .orange)
            }
        }
        .frame(width: 200, height: 130)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulse = 1
            }
        }
        .onDisappear {
            // Defensive: if the player lifts off-screen / pushes a sheet /
            // the relic transitions out of .charging while held, the
            // DragGesture's onEnded may not fire. Cancel the loop here so
            // a Task isn't left hammering the VM in the background.
            holdTask?.cancel()
            holdTask = nil
        }
    }
}

/// The Sudarshan Chakra: a rotating disc rendered over the path centre
/// during the maturation phase. Visual-only; damage is in runSudarshanPhase.
struct SudarshanChakraView: View {
    let vm: GameViewModel

    var body: some View {
        GeometryReader { geo in
            let centre = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [
                        Color.yellow.opacity(0.6), Color.orange.opacity(0.3), .clear
                    ], center: .center, startRadius: 10, endRadius: 200))
                    .frame(width: 320, height: 320)
                    .blendMode(.plusLighter)
                ForEach(0..<12, id: \.self) { i in
                    Rectangle()
                        .fill(LinearGradient(colors: [.white, .yellow, .red],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: 4, height: 90)
                        .offset(y: -55)
                        .rotationEffect(.degrees(Double(i) * 30))
                        .shadow(color: .yellow, radius: 6)
                }
                Circle()
                    .stroke(LinearGradient(colors: [.white, .yellow], startPoint: .top, endPoint: .bottom),
                            lineWidth: 4)
                    .frame(width: 120, height: 120)
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 60, weight: .heavy))
                    .foregroundColor(.yellow)
                    .shadow(color: .orange, radius: 12)
            }
            .rotationEffect(.degrees(vm.chakraAngle))
            .position(centre)
        }
    }
}

/// Durga Combined Strike — the in-game animation that triggers when the
/// player has three distinct divine astra kinds alive AND Kali Yuga is on
/// the field. Three light-beams converge from divine towers onto Kali, a
/// Durga trishul-yantra symbol blooms at impact, and the chunk damage is
/// applied in the GameViewModel. Visual ONLY — game logic lives in
/// `fireTrimurtiStrike()`.
struct TrimurtiStrikeOverlay: View {
    let vm: GameViewModel

    private static let phase1End = 0.30   // beams converge
    private static let phase2End = 0.65   // Sanskrit reveal
    // phase 3: shockwave (0.65 → 1.0)

    var body: some View {
        let total = GameViewModel.trimurtiStrikeLifetime
        let t = max(0, min(1, 1.0 - vm.trimurtiStrikeTimer / total))
        let target = vm.trimurtiStrikeTarget

        // Sub-phase progressions
        let beamProgress = min(1, t / Self.phase1End)
        let revealProgress = max(0, min(1, (t - Self.phase1End) / (Self.phase2End - Self.phase1End)))
        let burstProgress = max(0, min(1, (t - Self.phase2End) / (1.0 - Self.phase2End)))

        // Alpha for the beams: bright while shooting in, fades while
        // Sanskrit writes itself, gone by impact.
        let beamAlpha = beamProgress < 1 ? beamProgress : max(0, 1 - revealProgress * 1.4)

        ZStack {
            // ─── Phase 1: convergence beams ─────────────────────────────
            ForEach(0..<vm.trimurtiStrikeOrigins.count, id: \.self) { idx in
                let origin = vm.trimurtiStrikeOrigins[idx]
                BeamShape(from: origin, to: target, t: beamProgress)
                    .stroke(
                        LinearGradient(colors: [
                            Color(red: 1.0, green: 0.92, blue: 0.45).opacity(beamAlpha),
                            Color(red: 1.0, green: 0.55, blue: 0.20).opacity(beamAlpha),
                            Color(red: 0.85, green: 0.15, blue: 0.95).opacity(beamAlpha * 0.85)
                        ], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .shadow(color: .yellow.opacity(beamAlpha), radius: 10)
                    .blendMode(.plusLighter)
            }
            // Three glowing orbs at the divine-tower origins — punch-in
            // signal as the beams launch.
            ForEach(0..<vm.trimurtiStrikeOrigins.count, id: \.self) { idx in
                let origin = vm.trimurtiStrikeOrigins[idx]
                Circle()
                    .fill(RadialGradient(colors: [
                        Color.white.opacity(beamAlpha),
                        Color(red: 1.0, green: 0.55, blue: 0.20).opacity(beamAlpha * 0.8),
                        .clear
                    ], center: .center, startRadius: 2, endRadius: 24))
                    .frame(width: 48, height: 48)
                    .position(origin)
                    .blendMode(.plusLighter)
            }

            // ─── Phase 2: gathering energy + Sanskrit reveal ────────────
            ZStack {
                // Rotating divine mandala — 24 outer ticks build a ring.
                ForEach(0..<24, id: \.self) { i in
                    Rectangle()
                        .fill(LinearGradient(colors: [
                            Color(red: 1.0, green: 0.55, blue: 0.20)
                                .opacity(revealProgress * (0.8 - 0.6 * burstProgress)),
                            .clear
                        ], startPoint: .center, endPoint: .top))
                        .frame(width: 2, height: 18 + 12 * burstProgress)
                        .offset(y: -(110 + 30 * burstProgress))
                        .rotationEffect(.degrees(Double(i) * 15 + Double(t) * 720))
                }
                // Outer flame-ring halo
                Circle()
                    .fill(RadialGradient(colors: [
                        Color(red: 1.0, green: 0.55, blue: 0.20)
                            .opacity(revealProgress * 0.85 - burstProgress * 0.4),
                        Color(red: 0.85, green: 0.15, blue: 0.95)
                            .opacity(revealProgress * 0.45),
                        .clear
                    ], center: .center, startRadius: 6,
                       endRadius: 120 + 60 * burstProgress))
                    .frame(width: 260, height: 260)
                    .blendMode(.plusLighter)
                // 12-spoke flame ring around Durga
                ForEach(0..<12, id: \.self) { i in
                    Image(systemName: "flame.fill")
                        .font(.system(size: 22 + 6 * revealProgress, weight: .heavy))
                        .foregroundColor(.orange.opacity(revealProgress))
                        .offset(y: -(70 + 18 * burstProgress))
                        .rotationEffect(.degrees(Double(i) * 30 + Double(t) * 360))
                        .shadow(color: .red.opacity(revealProgress), radius: 5)
                }
                // Trishul-yantra in the centre — grows as the reveal builds.
                Image(systemName: "burst.fill")
                    .font(.system(size: 80 * (0.5 + 0.7 * revealProgress), weight: .heavy))
                    .foregroundColor(.white.opacity(revealProgress))
                    .shadow(color: .yellow.opacity(revealProgress), radius: 18)
                    .shadow(color: .red.opacity(revealProgress * 0.7), radius: 6)
                // Sanskrit दुर्गा — writes itself letter by letter and
                // BLOOMS at impact (phase 3).
                durgaSanskrit(reveal: revealProgress, burst: burstProgress)
                    .offset(y: 56 + 12 * revealProgress)
            }
            .position(target)
            .scaleEffect(0.4 + 0.7 * revealProgress + 0.25 * burstProgress)

            // ─── Phase 3: shockwave explosion ───────────────────────────
            if burstProgress > 0 {
                // Outer ring expands and fades
                Circle()
                    .stroke(LinearGradient(colors: [
                        .white.opacity(1.0 - burstProgress),
                        Color(red: 1.0, green: 0.55, blue: 0.20).opacity(1.0 - burstProgress),
                        Color(red: 0.85, green: 0.15, blue: 0.95).opacity(0.7 * (1.0 - burstProgress))
                    ], startPoint: .top, endPoint: .bottom),
                            lineWidth: 4 * (1.0 - burstProgress))
                    .frame(width: 100 + 280 * burstProgress,
                           height: 100 + 280 * burstProgress)
                    .position(target)
                    .blendMode(.plusLighter)
                // Inner brilliant flash
                Circle()
                    .fill(RadialGradient(colors: [
                        .white.opacity(1.0 - burstProgress),
                        Color(red: 1.0, green: 0.85, blue: 0.25)
                            .opacity(0.8 * (1.0 - burstProgress)),
                        .clear
                    ], center: .center, startRadius: 4, endRadius: 80))
                    .frame(width: 160, height: 160)
                    .position(target)
                    .blendMode(.plusLighter)
                // Eight outward shrapnel sparks
                ForEach(0..<8, id: \.self) { i in
                    let angle = Double(i) * .pi / 4
                    let dist = 40 + 180 * burstProgress
                    Circle()
                        .fill(Color(red: 1.0, green: 0.85, blue: 0.25)
                            .opacity(1.0 - burstProgress))
                        .frame(width: 8 * (1.0 - burstProgress * 0.5),
                               height: 8 * (1.0 - burstProgress * 0.5))
                        .position(x: target.x + cos(angle) * dist,
                                  y: target.y + sin(angle) * dist)
                        .blendMode(.plusLighter)
                }
            }
        }
        .allowsHitTesting(false)
    }

    /// Writes the Sanskrit syllables of "दुर्गा" with a typewriter feel —
    /// letter by letter during reveal, then a bright bloom on impact.
    @ViewBuilder
    private func durgaSanskrit(reveal: Double, burst: Double) -> some View {
        let letters = ["दु", "र्", "गा"]
        let visibleCount = max(0, min(3, Int(reveal * 3.5)))
        HStack(spacing: 6) {
            ForEach(0..<letters.count, id: \.self) { i in
                Text(letters[i])
                    .font(.system(size: 36 + 18 * burst,
                                  weight: .heavy, design: .serif))
                    .foregroundColor(.white.opacity(i < visibleCount ? 1.0 : 0))
                    .shadow(color: Color(red: 1.0, green: 0.85, blue: 0.25)
                        .opacity(i < visibleCount ? 1.0 - burst * 0.4 : 0),
                            radius: 8 + 4 * burst)
                    .shadow(color: Color(red: 0.85, green: 0.15, blue: 0.95)
                        .opacity(i < visibleCount ? 0.6 : 0),
                            radius: 4)
                    .scaleEffect(i < visibleCount
                                 ? 1.0 + 0.4 * burst
                                 : 0.4)
            }
        }
    }
}

/// Animated stroked line from `from` → `to`. `t` is 0..1 — the stroke
/// "shoots" from origin to target as t advances.
struct BeamShape: Shape {
    var from: CGPoint
    var to: CGPoint
    var t: Double

    var animatableData: Double {
        get { t }
        set { t = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: from)
        let tt = CGFloat(min(1, t * 1.4))   // overshoot to convergence early
        p.addLine(to: CGPoint(
            x: from.x + (to.x - from.x) * tt,
            y: from.y + (to.y - from.y) * tt
        ))
        return p
    }
}

/// Pre-Kali दुर्गा-Strike PROGRESS pill. Shows the three Trimurti role
/// slots and whether each is filled. Visible from W11 onward (when the
/// Parijata also unlocks) so the player can see what still needs to be
/// built BEFORE Kali Yuga arrives at W14.
struct TrimurtiProgressPill: View {
    let vm: GameViewModel

    var body: some View {
        let alive = Set(vm.towers.filter { $0.hp > 0 }.map { $0.kind })
        let hasSudarshana = alive.contains(.sudarshanaChakra)
        let hasPashupata  = alive.contains(.pashupatastra)
        let hasFireOrMaya = alive.contains(.brahmashirsha) || alive.contains(.brahmasiraAstra)
        let filledCount = [hasSudarshana, hasPashupata, hasFireOrMaya].filter { $0 }.count
        let allReady = filledCount == 3

        VStack(spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: "burst.fill")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundColor(.white)
                Text("दुर्गा STRIKE")
                    .font(.system(size: 11, weight: .heavy, design: .serif))
                    .foregroundColor(.white)
                Text(allReady ? "ARMED — awaiting an enemy" : "Building roles \(filledCount)/3")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundColor(allReady ? .yellow : .white.opacity(0.85))
            }
            HStack(spacing: 5) {
                roleChip(name: "श्री Sudarshana", filled: hasSudarshana)
                roleChip(name: "ॐ Pashupatastra", filled: hasPashupata)
                roleChip(name: "भ Bhambhrastra / Brahmasira", filled: hasFireOrMaya)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(LinearGradient(
                colors: allReady
                    ? [Color(red: 1.0, green: 0.55, blue: 0.20),
                       Color(red: 0.85, green: 0.15, blue: 0.95)]
                    : [Color.black.opacity(0.85), Color.black.opacity(0.75)],
                startPoint: .leading, endPoint: .trailing))
        )
        .overlay(Capsule().stroke(
            allReady ? Color.yellow.opacity(0.85)
                     : Color.white.opacity(0.45),
            lineWidth: 1.2))
        .shadow(color: allReady ? .yellow.opacity(0.6) : .clear, radius: 5)
        .infoTap("दुर्गा Combined Strike — Building roles",
                 "The flagship attack auto-fires every 8 s whenever ALL THREE roles are alive on the field AND there's at least one enemy to hit. NO Kali Yuga required — strikes land on the toughest enemy on the field at any wave.\n\n" +
                 "  • श्री Sudarshana Chakra (arrow T4) — required\n" +
                 "  • ॐ Pashupatastra (divine T4) — required\n" +
                 "  • भ Bhambhrastra (fire T4) OR Brahmasira Astra (maya T4) — either fills the third\n\n" +
                 "When fired, each contributor pools its full effective damage at a single point, the engine doubles the sum, and lands it on the target with a 100 px splash. A शंख (conch) plays as the दुर्गा syllable blooms.",
                 icon: "burst.fill",
                 tint: Color(red: 1.0, green: 0.55, blue: 0.20),
                 maxDuration: 5.0)
    }

    private func roleChip(name: String, filled: Bool) -> some View {
        HStack(spacing: 3) {
            Image(systemName: filled ? "checkmark.circle.fill" : "circle.dashed")
                .font(.system(size: 9, weight: .heavy))
                .foregroundColor(filled ? .green : .white.opacity(0.45))
            Text(name)
                .font(.system(size: 8, weight: .heavy, design: .rounded))
                .foregroundColor(filled ? .white : .white.opacity(0.55))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(Capsule().fill(
            filled ? Color.green.opacity(0.20) : Color.white.opacity(0.08)
        ))
        .overlay(Capsule().stroke(
            filled ? Color.green.opacity(0.55) : Color.white.opacity(0.2),
            lineWidth: 0.7))
    }
}

/// Passive दुर्गा-Strike indicator. The combined strike fires AUTO-
/// MATICALLY whenever the cooldown is fresh and the three divine kinds
/// stand alive — this pill just tells the player what's happening:
/// "firing" while the animation envelope plays, "next in Xs" otherwise.
struct TrimurtiStrikeIndicator: View {
    let vm: GameViewModel
    @State private var pulse: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let cooldown = vm.trimurtiStrikeCooldown
        let firing = vm.trimurtiStrikeTimer > 0
        HStack(spacing: 6) {
            Image(systemName: "burst.fill")
                .font(.system(size: 16, weight: .heavy))
                .foregroundColor(.white)
                .shadow(color: .yellow.opacity(0.8 + 0.2 * pulse), radius: 5)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("दुर्गा STRIKE")
                        .font(.system(size: 12, weight: .heavy, design: .serif))
                        .foregroundColor(.white)
                    if firing {
                        Text("FIRING")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                    } else if cooldown > 0 {
                        Text(String(format: "%.0fs", cooldown))
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.yellow)
                    }
                }
                Text(firing ? "Three powers convergence — Trimurti strikes Kali Yuga!"
                            : "Auto-fires the moment cooldown clears")
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule().fill(LinearGradient(
                colors: [Color(red: 1.0, green: 0.55, blue: 0.20),
                         Color(red: 0.85, green: 0.15, blue: 0.95)],
                startPoint: .leading, endPoint: .trailing))
        )
        .overlay(Capsule().stroke(Color.yellow.opacity(0.85), lineWidth: 1.5))
        .shadow(color: .yellow.opacity(0.6 + 0.3 * pulse), radius: 6)
        .infoTap("दुर्गा Combined Strike (auto-fire)",
                 "FLAGSHIP attack. Activates AUTOMATICALLY when ALL THREE Trimurti roles stand alive on the field AND Kali Yuga is in the fight:\n" +
                 "  • Sudarshana Chakra (arrow T4) — required\n" +
                 "  • Pashupatastra (divine T4) — required\n" +
                 "  • Bhambhrastra (fire T4) OR Brahmasira Astra (maya T4) — either fills the third role\n\n" +
                 "Each batch pools its FULL damage at a single point. Total strike damage = (sum of their effective damages) × 2. Lands on Kali Yuga plus a 100 px splash. " +
                 "8 s cooldown. " +
                 (vm.lastTrimurtiStrikeDamage > 0
                  ? "Last strike: \(Int(vm.lastTrimurtiStrikeDamage)) dmg."
                  : "Build the three roles to see the शंख call."),
                 icon: "burst.fill",
                 tint: Color(red: 1.0, green: 0.55, blue: 0.20),
                 maxDuration: 5.0)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = 1
            }
        }
    }
}

/// Recharge bar for the Sudarshan Chakra while it's actively burning
/// (.matured). Sits near the top of the screen so the player can keep
/// topping the charge up — the chakra drains itself while it burns, and
/// once it reaches 0 the burn stops cold and Kali Yuga eats freely.
struct ChakraRechargeBar: View {
    let vm: GameViewModel
    @State private var pulse: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let charge = vm.sudarshanCharge
        let empty = charge <= 0
        let affordable = vm.stock.canAfford(GameViewModel.sudarshanTapCost)
        let cost = GameViewModel.sudarshanTapCost.gold
        Button {
            _ = vm.tapSudarshan()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(empty ? .red : .yellow)
                    .shadow(color: empty ? .red : .yellow, radius: 4 * pulse)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Text("Chakra")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        Text("\(Int(charge * 100))%")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(empty ? .red : .yellow)
                        if empty {
                            Text("BURN STOPPED")
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .foregroundColor(.red)
                                .padding(.horizontal, 4).padding(.vertical, 1)
                                .background(Capsule().fill(Color.red.opacity(0.2)))
                        }
                    }
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.black.opacity(0.65))
                            .frame(width: 120, height: 5)
                        Capsule()
                            .fill(LinearGradient(colors: empty
                                                 ? [.red, .orange]
                                                 : [.yellow, .orange],
                                                 startPoint: .leading,
                                                 endPoint: .trailing))
                            .frame(width: 120 * CGFloat(charge), height: 5)
                    }
                    .overlay(Capsule().stroke(Color.white.opacity(0.35), lineWidth: 0.5))
                }
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(affordable ? .yellow : .gray)
                Text("\(cost)g")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(Color.black.opacity(0.85))
                    .overlay(Capsule().stroke(
                        empty ? Color.red.opacity(0.9)
                              : Color.yellow.opacity(0.75),
                        lineWidth: 1.5))
                    .shadow(color: empty ? .red.opacity(0.6) : .yellow.opacity(0.4),
                            radius: 4 + 4 * pulse)
            )
        }
        .buttonStyle(.plain)
        .disabled(!affordable || charge >= 1.0)
        .tooltip("Recharge Sudarshan Chakra",
                 "The chakra drains its own charge while burning Kali Yuga. Tap to feed \(cost)g and bump the meter back up. If the bar empties, the burn STOPS until you refill it — and Kali Yuga grows stronger every tower he eats in the meantime.",
                 icon: "circle.hexagongrid.fill", tint: .yellow)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulse = 1
            }
        }
    }
}

/// Rahu intervenes: full-screen eclipse animation that plays for ~3 s while
/// the Amrit Kalash is devoured and Kali Yuga is reborn empowered.
struct RahuEclipseOverlay: View {
    let vm: GameViewModel
    @State private var angle: Double = 0

    var body: some View {
        let progress = max(0, min(1, 1.0 - vm.rahuTimer / GameViewModel.rahuLifetime))
        ZStack {
            Color.black.opacity(0.55 + 0.30 * progress).ignoresSafeArea()
            // Eclipse — black disc covering a glowing corona
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [
                        Color.yellow.opacity(0.95),
                        Color.orange.opacity(0.55),
                        Color.red.opacity(0.25),
                        .clear
                    ], center: .center, startRadius: 60, endRadius: 220))
                    .frame(width: 360, height: 360)
                    .blendMode(.plusLighter)
                Circle()
                    .fill(Color.black)
                    .frame(width: 220 + 30 * sin(angle * .pi / 180), height: 220 + 30 * sin(angle * .pi / 180))
                    .shadow(color: .black, radius: 30)
                // Rahu silhouette — a snarling SF symbol stand-in
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 90, weight: .heavy))
                    .foregroundColor(.white.opacity(0.85))
                    .shadow(color: .red, radius: 8)
                    .rotationEffect(.degrees(angle * 0.5))
            }
            VStack(spacing: 8) {
                Spacer()
                Text("राहु ग्रहणम्")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(.yellow)
                    .shadow(color: .black, radius: 4)
                Text("Rahu devours the Amrit Kalash…")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.85))
                Text("Kali Yuga is reborn empowered.")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.red)
                    .padding(.bottom, 80)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: GameViewModel.rahuLifetime).repeatCount(1)) {
                angle = 360
            }
        }
    }
}

/// Trimurti combined-astra charge UI — appears in .empoweredBoss phase
/// at the same centre position as the Sudarshan disc. Higher-cost taps.
struct TrimurtiCenterTowerView: View {
    let vm: GameViewModel
    @State private var pulse: Double = 0
    @State private var spinAngle: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // Charge is 0…1; we drive every visual off of it so the relic
        // visibly intensifies as the player feeds resources.
        let charge = vm.trimurtiCharge
        let intensity = CGFloat(charge)                  // 0 at empty, 1 at full
        let strong   = max(0, charge - 0.33) * 1.5       // kicks in at 33%
        let surge    = max(0, charge - 0.66) * 3.0       // kicks in at 66%
        let ready    = charge >= 1.0

        VStack(spacing: 6) {
            ZStack {
                // Orbiting embers — start appearing at ~20% charge.
                if charge > 0.20 {
                    ForEach(0..<8, id: \.self) { i in
                        let a = Double(i) * 45 + spinAngle
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 2 + 2 * intensity, height: 2 + 2 * intensity)
                            .offset(
                                x: cos(a * .pi / 180) * (50 + 8 * intensity),
                                y: sin(a * .pi / 180) * (50 + 8 * intensity)
                            )
                            .opacity(intensity)
                            .shadow(color: .yellow, radius: 3 + 3 * intensity)
                    }
                }

                // Outer charge ring — thickens as charge grows.
                Circle()
                    .stroke(Color.red.opacity(0.25), lineWidth: 6)
                    .frame(width: 104, height: 104)
                Circle()
                    .trim(from: 0, to: charge)
                    .stroke(
                        AngularGradient(colors: [.red, .orange, .yellow, .white, .red],
                                        center: .center),
                        style: StrokeStyle(lineWidth: 6 + 3 * intensity, lineCap: .round)
                    )
                    .frame(width: 104, height: 104)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Color.yellow.opacity(Double(intensity)), radius: 6 * Double(intensity))

                // Dashed mid-ring fades in at 33% and counter-rotates.
                if strong > 0 {
                    Circle()
                        .stroke(Color.yellow.opacity(Double(strong)),
                                style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(spinAngle))
                }
                // Bright inner ring fades in at 66%, spinning the other way.
                if surge > 0 {
                    Circle()
                        .stroke(Color.white.opacity(Double(min(surge, 0.85))),
                                style: StrokeStyle(lineWidth: 1.2, dash: [3, 5]))
                        .frame(width: 76, height: 76)
                        .rotationEffect(.degrees(-spinAngle * 1.7))
                }

                // Inner radial fill — gets brighter, redder, more pulse the more charged.
                Circle()
                    .fill(RadialGradient(colors: [
                        Color.red.opacity(0.45 + 0.45 * Double(intensity) + 0.20 * pulse),
                        Color.orange.opacity(0.35 + 0.30 * Double(intensity)),
                        .black
                    ], center: .center, startRadius: 4, endRadius: 44))
                    .frame(width: 86, height: 86)

                // Trimurti emblem grows and brightens with charge.
                Image(systemName: "burst.fill")
                    .font(.system(size: 30 + 8 * intensity, weight: .heavy))
                    .foregroundColor(ready ? .white : .yellow)
                    .shadow(color: ready ? .white : .red, radius: 6 + 6 * Double(intensity))

                // At 100% charge: explosive outer halo + 6 vajra rays.
                if ready {
                    Circle()
                        .stroke(Color.white.opacity(0.85), lineWidth: 2)
                        .frame(width: 120 + 8 * pulse, height: 120 + 8 * pulse)
                        .blendMode(.plusLighter)
                    ForEach(0..<6, id: \.self) { i in
                        Rectangle()
                            .fill(LinearGradient(colors: [.white, .yellow, .clear],
                                                 startPoint: .top, endPoint: .bottom))
                            .frame(width: 3, height: 54)
                            .offset(y: -78)
                            .rotationEffect(.degrees(Double(i) * 60 + spinAngle))
                            .opacity(0.55 + 0.45 * pulse)
                            .shadow(color: .white, radius: 6)
                    }
                }

                Text(ready ? "READY" : "\(Int(charge * 100))%")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .offset(y: 42)
                    .shadow(color: .black, radius: 2)
            }
            // At full charge the button becomes the manual FIRE trigger.
            if vm.trimurtiCharge >= 1.0 {
                Button {
                    vm.fireTrimurtiManually()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "burst.fill")
                            .font(.system(size: 14, weight: .heavy))
                        Text("FIRE TRIMURTI")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        Capsule().fill(LinearGradient(colors: [
                            Color.yellow, Color.orange
                        ], startPoint: .top, endPoint: .bottom))
                    )
                    .overlay(Capsule().stroke(Color.white.opacity(0.9), lineWidth: 1.5))
                    .shadow(color: .yellow.opacity(0.9), radius: 8)
                    .scaleEffect(1.0 + 0.05 * pulse)
                }
                .buttonStyle(.plain)
            } else {
                let cost = GameViewModel.trimurtiTapCost
                let canAfford = vm.stock.canAfford(cost)
                Button {
                    vm.tapTrimurti()
                } label: {
                    VStack(spacing: 3) {
                        HStack(spacing: 5) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 12, weight: .bold))
                            Text("Charge Trimurti")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                        }
                        // Explicit per-tap cost — every resource icon + value so
                        // the player sees exactly what each tap drains.
                        ResourceCostRow(cost: cost, size: 9, available: vm.stock)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(LinearGradient(colors: [
                            Color(red: 0.85, green: 0.12, blue: 0.12),
                            Color(red: 0.55, green: 0.05, blue: 0.05)
                        ], startPoint: .top, endPoint: .bottom))
                    )
                    .overlay(Capsule().stroke(Color.yellow.opacity(0.75), lineWidth: 1))
                    .opacity(canAfford ? 1.0 : 0.55)
                }
                .buttonStyle(.plain)
                .disabled(!canAfford)
            }
            Text("Sudarshan + Brahmastra + Trishul")
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(.white.opacity(0.65))

            // Sudarshan HP bar — the relic itself takes hits when every
            // other defence has fallen. If it empties, the run is lost.
            let frac = max(0, min(1, vm.sudarshanHP / vm.sudarshanMaxHP))
            VStack(spacing: 1) {
                Text("Sudarshan \(Int(vm.sudarshanHP))/\(Int(vm.sudarshanMaxHP))")
                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 120, height: 6)
                    Capsule()
                        .fill(frac > 0.5 ? Color.yellow
                              : frac > 0.25 ? Color.orange : Color.red)
                        .frame(width: 120 * CGFloat(frac), height: 6)
                }
                .overlay(Capsule().stroke(Color.white.opacity(0.55), lineWidth: 0.6))
            }
            .padding(.top, 4)

            // Sudarshan-heal action — competes with Trimurti taps for the
            // same resource pool. Shown only when the relic is damaged.
            if vm.canHealSudarshan {
                Button {
                    vm.healSudarshan()
                } label: {
                    VStack(spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "cross.case.fill")
                            Text("Heal Sudarshan +\(Int(GameViewModel.sudarshanHealAmount))")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                        }
                        ResourceCostRow(cost: GameViewModel.sudarshanHealCost, size: 8, available: vm.stock)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(LinearGradient(colors: [
                            Color(red: 0.20, green: 0.55, blue: 0.95),
                            Color(red: 0.10, green: 0.30, blue: 0.70)
                        ], startPoint: .top, endPoint: .bottom))
                    )
                    .overlay(Capsule().stroke(Color.white.opacity(0.65), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(!vm.stock.canAfford(GameViewModel.sudarshanHealCost))
                .opacity(vm.stock.canAfford(GameViewModel.sudarshanHealCost) ? 1 : 0.45)
                .padding(.top, 2)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulse = 1
            }
            withAnimation(.linear(duration: 7).repeatForever(autoreverses: false)) {
                spinAngle = 360
            }
        }
    }
}

/// Final victory screen — shown when Kali Yuga falls.
struct VictoryOverlay: View {
    let vm: GameViewModel

    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Dharma Prevails")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(.yellow)
                    .shadow(color: .orange, radius: 8)
                Text("विजयः सत्यस्य")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                Text("Score: \(vm.score) · Wave \(vm.wave)")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                HStack(spacing: 10) {
                    Button {
                        vm.fullReset()
                    } label: {
                        Text("Play Again")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Color.yellow)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    Button { exit(0) } label: {
                        Text("Exit")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Color(red: 0.55, green: 0.10, blue: 0.10))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(26)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.black.opacity(0.88))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.yellow.opacity(0.7), lineWidth: 2)
                    )
                    .shadow(color: .yellow.opacity(0.6), radius: 16)
            )
        }
    }
}

// MARK: - Background

struct SpaceBackground: View {
    var body: some View {
        ZStack {
            if AssetCatalog.has(AssetName.fieldBackground) {
                Image(AssetName.fieldBackground)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.02, green: 0.02, blue: 0.10),
                        Color(red: 0.06, green: 0.01, blue: 0.18)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                StarsCanvas()
            }
        }
    }
}

struct StarsCanvas: View {
    var body: some View {
        Canvas { ctx, size in
            var seed: UInt64 = 0xC0DE_F00D
            func next() -> Double {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                return Double(seed >> 11) / Double(UInt64.max >> 11)
            }
            for _ in 0..<140 {
                let x = next() * Double(size.width)
                let y = next() * Double(size.height)
                let s = 0.6 + next() * 1.8
                let alpha = 0.35 + next() * 0.55
                let rect = CGRect(x: x, y: y, width: s, height: s)
                ctx.fill(Path(ellipseIn: rect), with: .color(.white.opacity(alpha)))
            }
        }
    }
}

#Preview {
    ContentView()
}

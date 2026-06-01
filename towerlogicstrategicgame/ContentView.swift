//
//  ContentView.swift
//  towerlogicstrategicgame
//

import SwiftUI

// MARK: - Root view

struct ContentView: View {
    @State private var vm = GameViewModel()

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
            }
            .task { await runGameLoop() }
        }
        .preferredColorScheme(.dark)
    }

    @State private var showBazaarInGame = false

    @ViewBuilder
    private func gameView(geo: GeometryProxy) -> some View {
        ZStack {
            GameField(vm: vm)
                .contentShape(Rectangle())
                .onTapGesture { vm.deselectAll() }

            VStack(spacing: 0) {
                TopHUD(vm: vm, showBazaar: $showBazaarInGame)
                Spacer()
                BottomBar(vm: vm)
            }

            // Amrita Kalash — appears in top-middle once the player can afford it.
            if vm.canUseAmritaKalash && !vm.isGameOver {
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
            }

            if let id = vm.selectedTowerID,
               let tower = vm.towers.first(where: { $0.id == id }) {
                TowerMenu(vm: vm, tower: tower)
                    .padding(.bottom, 80)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .transition(.opacity)
            }

            if let id = vm.selectedBuildingID,
               let building = vm.buildings.first(where: { $0.id == id }) {
                BuildingMenu(vm: vm, building: building)
                    .padding(.bottom, 80)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .transition(.opacity)
            }

            if let banner = vm.newAgeBanner {
                AgeBanner(age: banner)
                    .padding(.top, 110)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            if vm.resourceWaveBanner {
                ResourceWaveBanner()
                    .padding(.top, 110)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Sudarshan endgame UI — center-of-screen relic, charging meter
            // and tap-to-feed button. Active any time Dvapara is unlocked.
            if vm.sudarshanPhase == .charging {
                SudarshanCenterTowerView(vm: vm)
                    .position(vm.sudarshanPosition)
                    .allowsHitTesting(true)
            }
            // Chakra animation — spins on the path centre while maturation runs.
            if vm.sudarshanPhase == .matured {
                SudarshanChakraView(vm: vm)
                    .allowsHitTesting(false)
            }
            // Rahu devours the Amrit Kalash and resurrects Kali Yuga.
            if vm.sudarshanPhase == .rahuEclipse {
                RahuEclipseOverlay(vm: vm)
                    .allowsHitTesting(false)
            }
            // Empowered phase: Trimurti combined-astra charge UI.
            if vm.sudarshanPhase == .empoweredBoss {
                TrimurtiCenterTowerView(vm: vm)
                    .position(vm.sudarshanPosition)
                    .allowsHitTesting(true)
            }

            if vm.sudarshanPhase == .victory {
                VictoryOverlay(vm: vm)
            }

            if vm.isGameOver {
                GameOverOverlay(vm: vm)
            }

            if showBazaarInGame {
                BazaarOverlay(vm: vm, presented: $showBazaarInGame)
            }
        }
        .onAppear { vm.configure(size: geo.size) }
        .onChange(of: geo.size) { _, newSize in
            vm.reconfigure(size: newSize)
        }
        .onChange(of: showBazaarInGame) { _, isOpen in
            vm.isPaused = isOpen
        }
    }

    private func runGameLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 16_000_000)
            vm.update(now: Date().timeIntervalSinceReferenceDate)
        }
    }
}

// MARK: - Race Selection

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
    let vm: GameViewModel

    var body: some View {
        ZStack {
            PathShape(points: vm.pathPoints)
                .stroke(
                    Color.white.opacity(0.08),
                    style: StrokeStyle(lineWidth: 44, lineCap: .round, lineJoin: .round)
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
                            withAnimation(.easeOut(duration: 0.15)) {
                                vm.selectedSlotIndex = slot.index
                                vm.selectedTowerID = nil
                                vm.selectedBuildingID = nil
                            }
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
                .position(tower.position)
                .onTapGesture {
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
                    .allowsHitTesting(false)
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

    var body: some View {
        HStack(spacing: 5) {
            if cost.gold > 0    { entry(.gold, cost.gold) }
            if cost.metal > 0   { entry(.metal, cost.metal) }
            if cost.tech > 0    { entry(.tech, cost.tech) }
            if cost.jotisha > 0 { entry(.jotisha, cost.jotisha) }
            if cost.veda > 0    { entry(.veda, cost.veda) }
        }
    }

    private func entry(_ kind: ResourceKind, _ value: Int) -> some View {
        HStack(spacing: 1) {
            Image(systemName: kind.symbol)
                .font(.system(size: size))
                .foregroundColor(kind.color)
            Text("\(value)")
                .font(.system(size: size + 1, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Top HUD

struct TopHUD: View {
    let vm: GameViewModel
    @Binding var showBazaar: Bool
    @State private var muted: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            // Row 1: lives, score, race, age, mute
            HStack(spacing: 6) {
                pill(icon: "heart.fill", color: .red, text: "\(vm.lives)")
                pill(icon: "star.fill", color: .cyan, text: "\(vm.score)")
                if let race = vm.race {
                    pill(icon: race.symbol, color: race.color, text: race.displayName)
                }
                Spacer()
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
                Button {
                    muted.toggle()
                    SoundEngine.shared.setMuted(muted)
                } label: {
                    Image(systemName: muted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(muted ? .gray : .cyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.55))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                // Game-speed toggle: 1× ↔ 2×
                Button {
                    vm.toggleGameSpeed()
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: vm.gameSpeed >= 1.99 ? "forward.fill" : "play.fill")
                            .font(.system(size: 10, weight: .semibold))
                        Text(vm.gameSpeed >= 1.99 ? "2×" : "1×")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                    }
                    .foregroundColor(vm.gameSpeed >= 1.99 ? .yellow : .cyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                pill(icon: vm.currentAge.symbol, color: vm.currentAge.color,
                     text: "\(vm.currentAge.shortName) • W\(vm.wave)")
            }

            // Row 2: 5 resources
            HStack(spacing: 5) {
                ForEach(ResourceKind.allCases) { kind in
                    resourcePill(kind: kind)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
    }

    private func pill(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).foregroundColor(color)
            Text(text).foregroundColor(.white)
        }
        .font(.system(size: 12, weight: .semibold, design: .rounded))
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.55))
        .clipShape(Capsule())
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
    }
}

// MARK: - Bottom bar

struct BottomBar: View {
    let vm: GameViewModel

    var body: some View {
        VStack(spacing: 6) {
            if let next = vm.nextAgeToPurchase {
                ageUpgradeButton(next: next)
            }
            HStack {
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

                Spacer()

                Text(hintText)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(12)
    }

    private func ageUpgradeButton(next: Age) -> some View {
        let cost = vm.ageUpgradeCost(to: next)
        let affordable = vm.canPurchaseNextAge()
        return HStack(spacing: 6) {
            Button {
                vm.purchaseNextAge()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: next.symbol).foregroundColor(next.color)
                    Text("Advance to \(next.shortName) Yug")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    ResourceCostRow(cost: cost, size: 9)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(affordable ? next.color.opacity(0.32) : Color.black.opacity(0.5))
                .overlay(Capsule().stroke(next.color.opacity(affordable ? 0.9 : 0.3), lineWidth: 1))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!affordable)
            .opacity(affordable ? 1 : 0.65)
            Spacer()
        }
    }

    private var buttonText: String {
        if vm.isWaveActive { return "Wave \(vm.wave) active" }
        return vm.wave == 0 ? "Start Defence" : "Next Wave"
    }

    private var hintText: String {
        if vm.wave == 0 { return "Build a mine first\nthen start defence" }
        if vm.isWaveActive { return "Mines produce\nduring wave" }
        return "Upgrade or expand"
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
                            vm.buildTower(at: slotIndex, path: path)
                        } label: {
                            towerPathCard(path)
                        }
                        .buttonStyle(.plain)
                        .disabled(!vm.canAffordPath(path))
                        .opacity(vm.canAffordPath(path) ? 1 : 0.45)
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.4)
                                .onEnded { _ in
                                    codexAstra = path.astras[0]
                                }
                        )
                    }
                }
                Text("Long-press a tower to view its codex · Heal/Shield unlock as aura toggles")
                    .font(.system(size: 8))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            } else {
                HStack(spacing: 5) {
                    ForEach(BuildingKind.allCases) { kind in
                        Button {
                            vm.placeBuilding(at: slotIndex, kind: kind)
                        } label: {
                            buildingCard(kind)
                        }
                        .buttonStyle(.plain)
                        .disabled(!vm.canAffordBuilding(kind))
                        .opacity(vm.canAffordBuilding(kind) ? 1 : 0.45)
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
        let cost = vm.effectiveCost(of: base)
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
            ResourceCostRow(cost: cost, size: 8)
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

    private func buildingCard(_ kind: BuildingKind) -> some View {
        VStack(spacing: 2) {
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
                Text("+1/s \(kind.resource.displayName.prefix(1))")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            ResourceCostRow(cost: kind.cost, size: 8)
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

            // Stone slot section
            stoneSection

            // Heal / Shield aura toggles — unlocked by age, replace the
            // removed Sanjivani and Rekha tower paths.
            auraSection

            HStack(spacing: 10) {
                upgradeButton
                Button {
                    vm.sellTower(id: tower.id)
                } label: {
                    sellTile(value: vm.effectiveSellValue(of: tower))
                }
                .buttonStyle(.plain)
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
        // Don't render the row at all if no age that unlocks an aura is open.
        if healUnlocked || shieldUnlocked {
            HStack(spacing: 8) {
                if healUnlocked {
                    auraToggle(
                        icon: "cross.case.fill",
                        title: "Heal",
                        active: tower.healAuraActive,
                        color: Color(red: 0.30, green: 0.95, blue: 0.55),
                        cost: GameViewModel.healAuraCost,
                        canEnable: vm.canEnableHealAura(on: tower)
                    ) {
                        vm.enableHealAura(towerID: tower.id)
                    }
                }
                if shieldUnlocked {
                    auraToggle(
                        icon: "shield.checkered",
                        title: "Shield",
                        active: tower.shieldAuraActive,
                        color: .cyan,
                        cost: GameViewModel.shieldAuraCost,
                        canEnable: vm.canEnableShieldAura(on: tower)
                    ) {
                        vm.enableShieldAura(towerID: tower.id)
                    }
                }
            }
        }
    }

    private func auraToggle(
        icon: String,
        title: String,
        active: Bool,
        color: Color,
        cost: Resources,
        canEnable: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                    if active {
                        Text("Active")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                    } else {
                        ResourceCostRow(cost: cost, size: 7)
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
        .disabled(active || !canEnable)
        .opacity(active ? 1.0 : (canEnable ? 1.0 : 0.45))
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
                            vm.upgradeStone(towerID: tower.id)
                        } label: {
                            VStack(spacing: 1) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.green)
                                ResourceCostRow(cost: stone.kind.cost(forLevel: stone.level + 1), size: 7)
                            }
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(Color.black.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .disabled(!vm.canUpgradeStone(tower))
                        .opacity(vm.canUpgradeStone(tower) ? 1 : 0.5)
                    }
                    Button {
                        vm.removeStone(towerID: tower.id)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.red.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(stone.kind.color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(stone.kind.color.opacity(0.55), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if showStonePicker {
                HStack(spacing: 5) {
                    ForEach(StoneKind.allCases) { kind in
                        Button {
                            vm.attachStone(towerID: tower.id, kind: kind)
                            showStonePicker = false
                        } label: {
                            stonePickerCard(kind)
                        }
                        .buttonStyle(.plain)
                        .disabled(!vm.stock.canAfford(kind.cost(forLevel: 1)))
                        .opacity(vm.stock.canAfford(kind.cost(forLevel: 1)) ? 1 : 0.45)
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
            }
        }
    }

    private func stonePickerCard(_ kind: StoneKind) -> some View {
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
            ResourceCostRow(cost: kind.cost(forLevel: 1), size: 7)
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

    @ViewBuilder
    private var upgradeButton: some View {
        if let next = tower.nextAstra, let reqAge = tower.requiredAgeForNextTier {
            let ageReady = vm.isUnlocked(reqAge)
            let cost = vm.effectiveUpgradeCost(of: tower)
            let affordable = vm.stock.canAfford(cost)
            let enabled = ageReady && affordable

            Button {
                vm.upgradeTower(id: tower.id)
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
                        ResourceCostRow(cost: cost, size: 8)
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
            .disabled(!enabled)
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
        }
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
                statTile(
                    icon: "arrow.up.right.circle.fill",
                    value: String(format: "+%.1f/s",
                                  building.genPerSec * (vm.race?.genMultiplier(for: building.kind.resource) ?? 1.0)),
                    label: building.kind.resource.displayName
                )
            }

            HStack(spacing: 10) {
                if building.level < 3 {
                    Button {
                        vm.upgradeBuilding(id: building.id)
                    } label: {
                        upgradeTile(building: building)
                    }
                    .buttonStyle(.plain)
                    .disabled(!vm.canUpgradeBuilding(building))
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
                }

                Button {
                    vm.sellBuilding(id: building.id)
                } label: {
                    sellTile(value: building.sellValue)
                }
                .buttonStyle(.plain)
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
            ResourceCostRow(cost: building.upgradeCost, size: 8)
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
                vm.buyBazaarItem(item)
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

// MARK: - Amrita Kalash (5000-point life-revival relic)

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
                    Image(systemName: "sparkle").font(.system(size: 9, weight: .bold))
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

// MARK: - Sudarshan endgame views

/// Inactive center tower that accepts resource taps to charge the chakra.
struct SudarshanCenterTowerView: View {
    let vm: GameViewModel
    @State private var pulse: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Outer charge ring
                Circle()
                    .stroke(Color.yellow.opacity(0.22), lineWidth: 5)
                    .frame(width: 96, height: 96)
                Circle()
                    .trim(from: 0, to: vm.sudarshanCharge)
                    .stroke(
                        AngularGradient(colors: [.yellow, .orange, .red, .yellow],
                                        center: .center),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .frame(width: 96, height: 96)
                    .rotationEffect(.degrees(-90))
                // Inner dormant disc
                Circle()
                    .fill(RadialGradient(colors: [
                        Color.yellow.opacity(0.5 + 0.2 * pulse),
                        Color(red: 0.4, green: 0.18, blue: 0.05),
                        .black
                    ], center: .center, startRadius: 4, endRadius: 40))
                    .frame(width: 80, height: 80)
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundColor(.yellow.opacity(0.95))
                    .shadow(color: .orange, radius: 4)
                Text(vm.sudarshanCharge >= 1.0 ? "Ready" : "\(Int(vm.sudarshanCharge * 100))%")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .offset(y: 32)
                    .shadow(color: .black, radius: 2)
            }

            Button {
                vm.tapSudarshan()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                    Text("Feed")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                    HStack(spacing: 1) {
                        Text("300")
                        Image(systemName: "dollarsign.circle.fill").foregroundColor(.yellow)
                        Text("·30")
                        Image(systemName: "shield.lefthalf.filled").foregroundColor(.gray)
                    }
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color(red: 0.55, green: 0.30, blue: 0.78)))
                .overlay(Capsule().stroke(Color.yellow.opacity(0.6), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(vm.sudarshanCharge >= 1.0 && vm.finalBoss == nil)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulse = 1
            }
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color.red.opacity(0.25), lineWidth: 6)
                    .frame(width: 104, height: 104)
                Circle()
                    .trim(from: 0, to: vm.trimurtiCharge)
                    .stroke(
                        AngularGradient(colors: [.red, .orange, .yellow, .white, .red],
                                        center: .center),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 104, height: 104)
                    .rotationEffect(.degrees(-90))
                Circle()
                    .fill(RadialGradient(colors: [
                        Color.red.opacity(0.65 + 0.25 * pulse),
                        Color.orange.opacity(0.4),
                        .black
                    ], center: .center, startRadius: 4, endRadius: 44))
                    .frame(width: 86, height: 86)
                // Trimurti emblem — three weapons interlocked (simplified)
                Image(systemName: "burst.fill")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundColor(.yellow)
                    .shadow(color: .red, radius: 6)
                Text(vm.trimurtiCharge >= 1.0 ? "Fire" : "\(Int(vm.trimurtiCharge * 100))%")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .offset(y: 38)
                    .shadow(color: .black, radius: 2)
            }
            Button {
                vm.tapTrimurti()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                    Text("Charge Trimurti")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                    Text("300g·30×4")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 11)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(LinearGradient(colors: [
                        Color(red: 0.85, green: 0.12, blue: 0.12),
                        Color(red: 0.55, green: 0.05, blue: 0.05)
                    ], startPoint: .top, endPoint: .bottom))
                )
                .overlay(Capsule().stroke(Color.yellow.opacity(0.7), lineWidth: 1))
            }
            .buttonStyle(.plain)
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
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulse = 1
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

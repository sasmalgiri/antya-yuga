//
//  HapticsEngine.swift
//  AntaYuga
//
//  Thin wrapper around UIImpactFeedbackGenerator / UINotificationFeedbackGenerator
//  with throttling so rapid-fire events (tower shots) don't drain the haptic
//  motor. No-op on macOS / visionOS.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

final class HapticsEngine: @unchecked Sendable {
    static let shared = HapticsEngine()

    /// Toggle from the settings UI later if needed.
    var enabled: Bool = true

    #if canImport(UIKit)
    private let light  = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy  = UIImpactFeedbackGenerator(style: .heavy)
    private let notif  = UINotificationFeedbackGenerator()
    #endif

    private var lastFireTap: TimeInterval = 0

    private init() {
        #if canImport(UIKit)
        light.prepare()
        medium.prepare()
        heavy.prepare()
        notif.prepare()
        #endif
    }

    /// Throttled to one tap per 80 ms so a wave of tower fires doesn't lock
    /// the haptic engine.
    func towerFire() {
        guard enabled else { return }
        let now = Date().timeIntervalSinceReferenceDate
        guard now - lastFireTap > 0.08 else { return }
        lastFireTap = now
        #if canImport(UIKit)
        light.impactOccurred(intensity: 0.45)
        #endif
    }

    func enemyKilled() {
        guard enabled else { return }
        #if canImport(UIKit)
        medium.impactOccurred(intensity: 0.55)
        #endif
    }

    func bossKilled() {
        guard enabled else { return }
        #if canImport(UIKit)
        heavy.impactOccurred()
        #endif
    }

    func amritaKalashUsed() {
        guard enabled else { return }
        #if canImport(UIKit)
        notif.notificationOccurred(.success)
        #endif
    }

    func victory() {
        guard enabled else { return }
        #if canImport(UIKit)
        notif.notificationOccurred(.success)
        #endif
    }

    func gameOver() {
        guard enabled else { return }
        #if canImport(UIKit)
        notif.notificationOccurred(.error)
        #endif
    }
}

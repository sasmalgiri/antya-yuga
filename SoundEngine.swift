//
//  SoundEngine.swift
//  towerlogicstrategicgame
//
//  Synthesizes unique tones per astra via AVAudioEngine.
//

import AVFoundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

enum SoundWaveform {
    case sine
    case square
    case triangle
    case noise
}

struct SoundProfile {
    var frequency: Double
    var duration: Double
    var waveform: SoundWaveform
    var volume: Double = 0.25
    var sweepTo: Double? = nil
    var harmonic: Double? = nil // optional second tone mixed in
}

final class SoundEngine: @unchecked Sendable {
    static let shared = SoundEngine()

    private let engine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
    private let format: AVAudioFormat
    private var players: [AVAudioPlayerNode] = []
    private var playerIndex: Int = 0
    private var enabled: Bool = true
    private(set) var isMuted: Bool = false
    private var lastPlayTime: [String: TimeInterval] = [:]

    private init() {
        format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!

        configureAudioSession()

        engine.attach(mixer)
        engine.connect(mixer, to: engine.mainMixerNode, format: format)

        for _ in 0..<12 {
            let p = AVAudioPlayerNode()
            engine.attach(p)
            engine.connect(p, to: mixer, format: format)
            players.append(p)
        }

        do {
            try engine.start()
        } catch {
            enabled = false
        }
    }

    func setMuted(_ muted: Bool) {
        isMuted = muted
    }

    func toggleMute() {
        isMuted.toggle()
    }

    // MARK: - Public play API

    func playFire(for kind: TowerKind, now: TimeInterval) {
        guard enabled, !isMuted else { return }
        let key = "fire-\(kind.rawValue)"
        // Throttle to avoid audio spam: at most one of each kind every 50ms
        if let last = lastPlayTime[key], now - last < 0.05 { return }
        lastPlayTime[key] = now
        play(profile: profile(for: kind))
    }

    func playSelect() {
        guard enabled, !isMuted else { return }
        play(profile: SoundProfile(frequency: 880, duration: 0.05, waveform: .sine, volume: 0.12))
    }

    func playBuildPlaced() {
        guard enabled, !isMuted else { return }
        play(profile: SoundProfile(frequency: 440, duration: 0.10, waveform: .triangle, volume: 0.20, sweepTo: 660))
    }

    func playWaveStart() {
        guard enabled, !isMuted else { return }
        play(profile: SoundProfile(frequency: 220, duration: 0.20, waveform: .triangle, volume: 0.25, sweepTo: 660))
    }

    func playEnemyDeath() {
        guard enabled, !isMuted else { return }
        play(profile: SoundProfile(frequency: 300, duration: 0.08, waveform: .square, volume: 0.15, sweepTo: 120))
    }

    func playGameOver() {
        guard enabled, !isMuted else { return }
        play(profile: SoundProfile(frequency: 330, duration: 0.6, waveform: .triangle, volume: 0.35, sweepTo: 80))
    }

    func playAgeUnlocked() {
        guard enabled, !isMuted else { return }
        play(profile: SoundProfile(frequency: 523, duration: 0.30, waveform: .sine, volume: 0.30, sweepTo: 1046, harmonic: 659))
    }

    // MARK: - Tone profiles per tower kind

    private func profile(for kind: TowerKind) -> SoundProfile {
        switch kind {
        // Arrow path: clicks/twangs
        case .dart:
            return SoundProfile(frequency: 1500, duration: 0.05, waveform: .square, volume: 0.12)
        case .aindrastra:
            return SoundProfile(frequency: 700, duration: 0.12, waveform: .square, volume: 0.18, sweepTo: 1400)
        case .sudarshanaChakra:
            return SoundProfile(frequency: 400, duration: 0.18, waveform: .sine, volume: 0.25, sweepTo: 900, harmonic: 600)

        // Fire path: low growls
        case .agneyastra:
            return SoundProfile(frequency: 220, duration: 0.15, waveform: .triangle, volume: 0.22, sweepTo: 130)
        case .suryastra:
            return SoundProfile(frequency: 660, duration: 0.18, waveform: .triangle, volume: 0.28, harmonic: 330)
        case .brahmashirsha:
            return SoundProfile(frequency: 90, duration: 0.30, waveform: .sine, volume: 0.40, sweepTo: 40)

        // Water path: fluid sweeps
        case .varunastra:
            return SoundProfile(frequency: 350, duration: 0.18, waveform: .sine, volume: 0.22, sweepTo: 200)
        case .nagaPasha:
            return SoundProfile(frequency: 500, duration: 0.20, waveform: .triangle, volume: 0.22, sweepTo: 180)
        case .garudastra:
            return SoundProfile(frequency: 200, duration: 0.22, waveform: .sine, volume: 0.30, sweepTo: 700, harmonic: 1000)

        // Ice path: high crystalline
        case .sheetastra:
            return SoundProfile(frequency: 1800, duration: 0.08, waveform: .sine, volume: 0.18)
        case .twashtar:
            return SoundProfile(frequency: 1400, duration: 0.18, waveform: .sine, volume: 0.22, sweepTo: 2200)
        case .mohiniAstra:
            return SoundProfile(frequency: 700, duration: 0.25, waveform: .sine, volume: 0.25, sweepTo: 1600, harmonic: 1100)

        // Divine path: powerful tones
        case .trishul:
            return SoundProfile(frequency: 330, duration: 0.12, waveform: .square, volume: 0.25, harmonic: 660)
        case .vajrastra:
            return SoundProfile(frequency: 880, duration: 0.10, waveform: .noise, volume: 0.35)
        case .pashupatastra:
            return SoundProfile(frequency: 55, duration: 0.50, waveform: .sine, volume: 0.5, sweepTo: 880, harmonic: 220)

        // Sensory path: soft chimes (rare, only when scanning)
        case .bala:
            return SoundProfile(frequency: 1100, duration: 0.08, waveform: .sine, volume: 0.10)
        case .atibala:
            return SoundProfile(frequency: 1300, duration: 0.10, waveform: .sine, volume: 0.10, harmonic: 1700)
        case .divyaDrishti:
            return SoundProfile(frequency: 1500, duration: 0.12, waveform: .sine, volume: 0.12, harmonic: 2000)

        // Healer: ascending warm chime
        case .aushadhi:
            return SoundProfile(frequency: 520, duration: 0.20, waveform: .sine, volume: 0.18, sweepTo: 780)
        case .sanjivaniBooti:
            return SoundProfile(frequency: 440, duration: 0.30, waveform: .sine, volume: 0.22, sweepTo: 880, harmonic: 660)
        case .amritKalash:
            return SoundProfile(frequency: 392, duration: 0.45, waveform: .sine, volume: 0.28, sweepTo: 1175, harmonic: 783)

        // Barrier: low resonant hum
        case .surakshaRekha:
            return SoundProfile(frequency: 165, duration: 0.18, waveform: .triangle, volume: 0.18, harmonic: 330)
        case .lakshmanRekha:
            return SoundProfile(frequency: 130, duration: 0.25, waveform: .triangle, volume: 0.22, harmonic: 260)
        case .vajraKavach:
            return SoundProfile(frequency: 98, duration: 0.35, waveform: .sine, volume: 0.30, harmonic: 196)
        }
    }

    // MARK: - Buffer synthesis

    private func play(profile: SoundProfile) {
        let sampleRate: Double = 44100
        let frameCount = AVAudioFrameCount(profile.duration * sampleRate)
        guard frameCount > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        let data = buffer.floatChannelData![0]
        let f0 = profile.frequency
        let f1 = profile.sweepTo ?? profile.frequency
        let totalSamples = Int(frameCount)
        let totalSamplesD = Double(totalSamples)

        for i in 0..<totalSamples {
            let t = Double(i) / sampleRate
            let progress = Double(i) / totalSamplesD
            let f = f0 + (f1 - f0) * progress
            let env = envelope(t: t, duration: profile.duration)
            var sample = waveSample(frequency: f, time: t, waveform: profile.waveform)
            if let h = profile.harmonic {
                let hs = waveSample(frequency: h, time: t, waveform: profile.waveform)
                sample = (sample + hs * 0.6) / 1.6
            }
            data[i] = Float(sample * env * profile.volume)
        }

        let player = players[playerIndex]
        playerIndex = (playerIndex + 1) % players.count
        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        player.play()
    }

    private func waveSample(frequency: Double, time: Double, waveform: SoundWaveform) -> Double {
        switch waveform {
        case .sine:
            return sin(2 * .pi * frequency * time)
        case .square:
            return sin(2 * .pi * frequency * time) >= 0 ? 1 : -1
        case .triangle:
            let phase = frequency * time
            return 2 * abs(2 * (phase - floor(phase + 0.5))) - 1
        case .noise:
            return Double.random(in: -1...1)
        }
    }

    private func envelope(t: Double, duration: Double) -> Double {
        let attack = min(0.005, duration * 0.1)
        let release = duration * 0.4
        if t < attack { return t / attack }
        if t > duration - release {
            let rel = max(0, (duration - t) / release)
            return rel
        }
        return 1.0
    }

    private func configureAudioSession() {
        #if os(iOS) || os(tvOS) || os(visionOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        #endif
    }
}

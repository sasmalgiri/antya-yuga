//
//  SoundEngine.swift
//  towerlogicstrategicgame
//
//  Procedurally synthesized tones for towers, hits, deaths, etc., plus
//  AVSpeechSynthesizer-driven Sanskrit slokas for major game events
//  (wave start, wave clear, boss kill, defeat, age unlock).
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

/// Major game events that get a Sanskrit-sloka voice line.
enum SlokaEvent {
    case waveStart
    case waveClear
    case bossKill
    case ageUnlock
    case amritaKalash
    case gameOver        // mocking taunt — asuras have won
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

    // Background music
    private let musicPlayer = AVAudioPlayerNode()
    private let musicMixer  = AVAudioMixerNode()
    private var musicBuffer: AVAudioPCMBuffer? = nil
    private var currentMusicAgeRaw: Int = -1

    // TTS for slokas
    private let speech = AVSpeechSynthesizer()
    private var lastSlokaAt: [SlokaEvent: TimeInterval] = [:]
    /// Minimum gap between any two slokas of the same event (seconds) so
    /// rapid-fire waves / kills don't stack voice lines on top of one another.
    private let slokaCooldown: TimeInterval = 4.0

    private init() {
        format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!

        configureAudioSession()

        engine.attach(mixer)
        engine.connect(mixer, to: engine.mainMixerNode, format: format)
        // Master mixer level — keep synth bed under the spoken slokas so
        // voice lines remain intelligible.
        mixer.outputVolume = 0.85

        for _ in 0..<12 {
            let p = AVAudioPlayerNode()
            engine.attach(p)
            engine.connect(p, to: mixer, format: format)
            players.append(p)
        }

        // Music chain — separate mixer so we can keep it quiet under SFX.
        engine.attach(musicMixer)
        engine.attach(musicPlayer)
        engine.connect(musicMixer, to: engine.mainMixerNode, format: format)
        engine.connect(musicPlayer, to: musicMixer, format: format)
        musicMixer.outputVolume = 0.18

        do {
            try engine.start()
        } catch {
            enabled = false
        }
    }

    func setMuted(_ muted: Bool) {
        isMuted = muted
        if muted {
            stopMusic()
            let synth = self.speech
            DispatchQueue.global(qos: .userInitiated).async {
                synth.stopSpeaking(at: .immediate)
            }
        }
    }

    func toggleMute() {
        setMuted(!isMuted)
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
        play(profile: SoundProfile(frequency: 880, duration: 0.05, waveform: .sine, volume: 0.10))
    }

    func playBuildPlaced() {
        guard enabled, !isMuted else { return }
        play(profile: SoundProfile(frequency: 440, duration: 0.10, waveform: .triangle, volume: 0.18, sweepTo: 660))
    }

    func playWaveStart() {
        guard enabled, !isMuted else { return }
        play(profile: SoundProfile(frequency: 220, duration: 0.20, waveform: .triangle, volume: 0.22, sweepTo: 660))
        speakSloka(.waveStart)
    }

    func playWaveClear() {
        guard enabled, !isMuted else { return }
        play(profile: SoundProfile(frequency: 523, duration: 0.20, waveform: .sine, volume: 0.25, sweepTo: 1046))
        speakSloka(.waveClear)
    }

    /// Generic death sound (back-compat). Prefer the kind-specific overload.
    func playEnemyDeath() {
        guard enabled, !isMuted else { return }
        play(profile: SoundProfile(frequency: 300, duration: 0.08, waveform: .square, volume: 0.12, sweepTo: 120))
    }

    /// Plays a kind-specific death sound (deep thud for bosses, sizzle for fire-imm,
    /// crystalline for ice-imm, drip for blood demon, etc.). For boss-tier kills
    /// also speaks a Sanskrit victory sloka.
    func playEnemyDeath(kind: EnemyKind) {
        guard enabled, !isMuted else { return }
        play(profile: deathProfile(for: kind))
        if kind.isBoss {
            speakSloka(.bossKill)
        }
    }

    func playGameOver() {
        guard enabled, !isMuted else { return }
        // Deep descending dirge first; the mocking sloka follows.
        play(profile: SoundProfile(frequency: 330, duration: 0.6, waveform: .triangle, volume: 0.32, sweepTo: 80))
        speakSloka(.gameOver)
    }

    func playAgeUnlocked() {
        guard enabled, !isMuted else { return }
        play(profile: SoundProfile(frequency: 523, duration: 0.30, waveform: .sine, volume: 0.28, sweepTo: 1046, harmonic: 659))
        speakSloka(.ageUnlock)
    }

    func playAmritaKalash() {
        guard enabled, !isMuted else { return }
        // Bell-like chime
        play(profile: SoundProfile(frequency: 784, duration: 0.55, waveform: .sine, volume: 0.30, harmonic: 1175))
        speakSloka(.amritaKalash)
    }

    // MARK: - Sanskrit sloka voice lines

    /// Picks a sloka for the event, applies cooldown, and speaks it via
    /// AVSpeechSynthesizer using the Hindi voice (closest readily-available
    /// pronunciation for Devanagari).
    private func speakSloka(_ event: SlokaEvent) {
        let now = Date().timeIntervalSinceReferenceDate
        if let last = lastSlokaAt[event], now - last < slokaCooldown { return }
        lastSlokaAt[event] = now

        let lines: [String] = slokas(for: event)
        guard let pick = lines.randomElement() else { return }
        let utt = AVSpeechUtterance(string: pick)
        utt.voice = AVSpeechSynthesisVoice(language: "hi-IN")
        // Tweak rate & pitch per mood
        switch event {
        case .gameOver:
            // Slow, deep, mocking — the asuras gloat
            utt.rate  = AVSpeechUtteranceMinimumSpeechRate + (AVSpeechUtteranceDefaultSpeechRate - AVSpeechUtteranceMinimumSpeechRate) * 0.45
            utt.pitchMultiplier = 0.65
            utt.volume = 1.0
        case .bossKill:
            utt.rate  = AVSpeechUtteranceDefaultSpeechRate * 0.95
            utt.pitchMultiplier = 1.15
            utt.volume = 0.95
        case .amritaKalash:
            utt.rate  = AVSpeechUtteranceDefaultSpeechRate * 0.90
            utt.pitchMultiplier = 1.10
            utt.volume = 0.95
        default:
            utt.rate  = AVSpeechUtteranceDefaultSpeechRate * 1.0
            utt.pitchMultiplier = 1.0
            utt.volume = 0.85
        }
        // The 4-second cooldown above already prevents pile-up. Speaking is
        // dispatched off the main thread to avoid priority-inversion when
        // AVSpeechSynthesizer's internal worker is at default QoS.
        let synth = self.speech
        DispatchQueue.global(qos: .userInitiated).async {
            synth.speak(utt)
        }
    }

    /// Pool of Sanskrit slokas per event — short, ~3-6 syllables so they
    /// fit between gameplay beats. Devanagari + Latin fallback.
    private func slokas(for event: SlokaEvent) -> [String] {
        switch event {
        case .waveStart:
            return [
                "जयतु धर्मः",     // Jayatu Dharmaḥ — "Victory to Dharma"
                "उत्तिष्ठ वीर",  // Uttiṣṭha vīra — "Arise, warrior"
                "रणे जय"          // Raṇe jaya — "Victory in battle"
            ]
        case .waveClear:
            return [
                "विजयोऽस्तु",     // Vijayo'stu — "May victory be ours"
                "जय जय",          // Jaya Jaya — "Victory victory"
                "शत्रवो नष्टाः"    // Śatravo naṣṭāḥ — "Foes destroyed"
            ]
        case .bossKill:
            return [
                "हर हर महादेव",   // Har Har Mahadev
                "जय जय महाकाली", // Jaya Jaya Mahākālī
                "धर्मो रक्षति"     // Dharmo rakṣati — "Dharma protects"
            ]
        case .ageUnlock:
            return [
                "नूतनम् युगम्",   // Nūtanam yugam — "A new age"
                "उत्थानम्"         // Utthānam — "Ascent"
            ]
        case .amritaKalash:
            return [
                "अमृतम् लभस्व",  // Amṛtam labhasva — "Receive the nectar"
                "जीवनम् नवीनम्"  // Jīvanam navīnam — "New life"
            ]
        case .gameOver:
            // Mocking taunts spoken by the victorious asuras
            return [
                "हा हा हा! त्वम् पराजितः",  // Ha ha ha! You are defeated.
                "मम विजयः",                  // Mama vijayaḥ — "My victory"
                "दुर्बलोऽसि",                 // Durbalo'si — "You are weak"
                "अद्य अहम् विजयी"            // Adya aham vijayī — "Today I am victorious"
            ]
        }
    }

    // MARK: - Tone profiles per tower kind

    private func profile(for kind: TowerKind) -> SoundProfile {
        switch kind {
        // Arrow path: clicks/twangs
        case .dart:
            return SoundProfile(frequency: 1500, duration: 0.05, waveform: .square, volume: 0.10)
        case .aindrastra:
            return SoundProfile(frequency: 700, duration: 0.12, waveform: .square, volume: 0.15, sweepTo: 1400)
        case .sudarshanaChakra:
            return SoundProfile(frequency: 400, duration: 0.18, waveform: .sine, volume: 0.22, sweepTo: 900, harmonic: 600)

        // Fire path: low growls
        case .agneyastra:
            return SoundProfile(frequency: 220, duration: 0.15, waveform: .triangle, volume: 0.18, sweepTo: 130)
        case .suryastra:
            return SoundProfile(frequency: 660, duration: 0.18, waveform: .triangle, volume: 0.24, harmonic: 330)
        case .brahmashirsha:
            return SoundProfile(frequency: 90, duration: 0.30, waveform: .sine, volume: 0.35, sweepTo: 40)

        // Water path: fluid sweeps
        case .varunastra:
            return SoundProfile(frequency: 350, duration: 0.18, waveform: .sine, volume: 0.18, sweepTo: 200)
        case .nagaPasha:
            return SoundProfile(frequency: 500, duration: 0.20, waveform: .triangle, volume: 0.20, sweepTo: 180)
        case .garudastra:
            return SoundProfile(frequency: 200, duration: 0.22, waveform: .sine, volume: 0.26, sweepTo: 700, harmonic: 1000)

        // Ice path: high crystalline
        case .sheetastra:
            return SoundProfile(frequency: 1800, duration: 0.08, waveform: .sine, volume: 0.15)
        case .twashtar:
            return SoundProfile(frequency: 1400, duration: 0.18, waveform: .sine, volume: 0.18, sweepTo: 2200)
        case .mohiniAstra:
            return SoundProfile(frequency: 700, duration: 0.25, waveform: .sine, volume: 0.22, sweepTo: 1600, harmonic: 1100)

        // Divine path: powerful tones
        case .trishul:
            return SoundProfile(frequency: 330, duration: 0.12, waveform: .square, volume: 0.22, harmonic: 660)
        case .vajrastra:
            return SoundProfile(frequency: 880, duration: 0.10, waveform: .noise, volume: 0.30)
        case .pashupatastra:
            return SoundProfile(frequency: 55, duration: 0.50, waveform: .sine, volume: 0.42, sweepTo: 880, harmonic: 220)

        // Sensory path: soft chimes (rare, only when scanning)
        case .bala:
            return SoundProfile(frequency: 1100, duration: 0.08, waveform: .sine, volume: 0.08)
        case .atibala:
            return SoundProfile(frequency: 1300, duration: 0.10, waveform: .sine, volume: 0.08, harmonic: 1700)
        case .divyaDrishti:
            return SoundProfile(frequency: 1500, duration: 0.12, waveform: .sine, volume: 0.10, harmonic: 2000)

        // Healer: ascending warm chime
        case .aushadhi:
            return SoundProfile(frequency: 520, duration: 0.20, waveform: .sine, volume: 0.15, sweepTo: 780)
        case .sanjivaniBooti:
            return SoundProfile(frequency: 440, duration: 0.30, waveform: .sine, volume: 0.18, sweepTo: 880, harmonic: 660)
        case .amritKalash:
            return SoundProfile(frequency: 392, duration: 0.45, waveform: .sine, volume: 0.24, sweepTo: 1175, harmonic: 783)

        // Barrier: low resonant hum
        case .surakshaRekha:
            return SoundProfile(frequency: 165, duration: 0.18, waveform: .triangle, volume: 0.15, harmonic: 330)
        case .lakshmanRekha:
            return SoundProfile(frequency: 130, duration: 0.25, waveform: .triangle, volume: 0.18, harmonic: 260)
        case .vajraKavach:
            return SoundProfile(frequency: 98, duration: 0.35, waveform: .sine, volume: 0.25, harmonic: 196)
        }
    }

    // MARK: - Enemy-death tone profiles

    /// Death tone tuned per enemy so the player hears *what* just died.
    /// Volumes are kept under 0.22 so slokas / fire SFX stay on top.
    private func deathProfile(for kind: EnemyKind) -> SoundProfile {
        switch kind {
        // Basic foes — quick low pops
        case .pishacha:
            return SoundProfile(frequency: 520, duration: 0.06, waveform: .square, volume: 0.10, sweepTo: 220)
        case .rakshasa:
            return SoundProfile(frequency: 360, duration: 0.10, waveform: .square, volume: 0.13, sweepTo: 110)
        case .daitya:
            return SoundProfile(frequency: 260, duration: 0.16, waveform: .triangle, volume: 0.16, sweepTo: 80)
        case .asura:
            return SoundProfile(frequency: 300, duration: 0.14, waveform: .square, volume: 0.16, sweepTo: 90)
        case .vetala:
            return SoundProfile(frequency: 1400, duration: 0.18, waveform: .sine, volume: 0.14, sweepTo: 400)
        case .mayavi:
            return SoundProfile(frequency: 880, duration: 0.10, waveform: .sine, volume: 0.12, sweepTo: 1320)

        // Bosses — long deep thunder
        case .mahishasura:
            return SoundProfile(frequency: 140, duration: 0.45, waveform: .triangle, volume: 0.22, sweepTo: 50, harmonic: 80)
        case .indrajit:
            return SoundProfile(frequency: 200, duration: 0.40, waveform: .sine, volume: 0.20, sweepTo: 60, harmonic: 100)
        case .ravana:
            return SoundProfile(frequency: 90, duration: 0.70, waveform: .triangle, volume: 0.28, sweepTo: 32, harmonic: 55)
        case .tarakasura:
            return SoundProfile(frequency: 160, duration: 0.45, waveform: .square, volume: 0.22, sweepTo: 55)
        case .vritra:
            return SoundProfile(frequency: 70, duration: 0.80, waveform: .sine, volume: 0.30, sweepTo: 24, harmonic: 45)

        // Resource bearers — coin-drop chimes
        case .lobhaYaksha:
            return SoundProfile(frequency: 1320, duration: 0.18, waveform: .sine, volume: 0.18, sweepTo: 880, harmonic: 1760)
        case .lohaAsura:
            return SoundProfile(frequency: 900, duration: 0.18, waveform: .square, volume: 0.18, sweepTo: 400)
        case .yantraPishacha:
            return SoundProfile(frequency: 1200, duration: 0.14, waveform: .triangle, volume: 0.16, sweepTo: 600, harmonic: 800)
        case .taraDevi:
            return SoundProfile(frequency: 1100, duration: 0.20, waveform: .sine, volume: 0.18, harmonic: 1650)
        case .rishiAtma:
            return SoundProfile(frequency: 660, duration: 0.25, waveform: .sine, volume: 0.18, sweepTo: 1320, harmonic: 990)

        // Specialist demons — themed tones
        case .raktabija:
            // Wet drip, lots of harmonic — blood
            return SoundProfile(frequency: 420, duration: 0.20, waveform: .triangle, volume: 0.18, sweepTo: 110, harmonic: 280)
        case .bhasmasura:
            // Sizzle out — fire dying
            return SoundProfile(frequency: 1600, duration: 0.18, waveform: .noise, volume: 0.16)
        case .putana:
            // Cursed exhale — high to low whisper
            return SoundProfile(frequency: 900, duration: 0.22, waveform: .triangle, volume: 0.16, sweepTo: 220)
        case .kaliYuga:
            // Apocalyptic boom — very low, very long, with sub-harmonic.
            return SoundProfile(frequency: 60, duration: 1.20, waveform: .sine, volume: 0.40, sweepTo: 20, harmonic: 35)
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

    // MARK: - Background music (procedural drone per Yuga)

    /// Plays a calm sustained drone whose root pitch tracks the player's
    /// current age. Loops seamlessly until stopped or `setMusicAge` swaps it.
    func setMusicAge(_ age: Age) {
        guard enabled, !isMuted else { return }
        guard age.rawValue != currentMusicAgeRaw else { return }
        currentMusicAgeRaw = age.rawValue
        // Drone root frequencies — calm, low, dharmic
        let root: Double
        switch age {
        case .ancient: root = 110.0   // A2
        case .middle:  root = 146.83  // D3 — brighter age
        case .modern:  root = 164.81  // E3 — most intense
        }
        let duration: Double = 4.0   // 4-second seamless loop
        let buffer = renderDrone(root: root, fifth: root * 1.5, duration: duration)
        musicBuffer = buffer
        musicPlayer.stop()
        musicPlayer.scheduleBuffer(buffer, at: nil, options: [.loops], completionHandler: nil)
        if !musicPlayer.isPlaying { musicPlayer.play() }
    }

    func stopMusic() {
        musicPlayer.stop()
        currentMusicAgeRaw = -1
    }

    /// Two-voice drone — root + perfect fifth — mixed at low level.
    private func renderDrone(root: Double, fifth: Double, duration: Double) -> AVAudioPCMBuffer {
        let sampleRate: Double = 44100
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        let total = Int(frameCount)
        for i in 0..<total {
            let t = Double(i) / sampleRate
            // Gentle 0.5 Hz amplitude wobble for organic feel.
            let wob = 0.85 + 0.15 * sin(2 * .pi * 0.5 * t)
            let s1 = sin(2 * .pi * root * t)
            let s2 = sin(2 * .pi * fifth * t)
            let s3 = sin(2 * .pi * root * 2 * t) * 0.35  // octave shimmer
            let mix = (s1 + s2 * 0.6 + s3) / 2.0
            data[i] = Float(mix * wob * 0.25)
        }
        return buffer
    }

    private func configureAudioSession() {
        #if os(iOS) || os(tvOS) || os(visionOS)
        let session = AVAudioSession.sharedInstance()
        // .playback so TTS goes through speaker even on silent switch (game audio).
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        #endif
    }
}

//
//  SimplePiano.swift
//  MusicNote
//
//  Created by Jeremy Bastidas on 11/28/25.
//

//
//  SamplePiano.swift
//  MusicNote
//
//  Rock-solid WAV one-shot piano player
//

import AVFoundation
import QuartzCore

final class SamplePiano {
    static let shared = SamplePiano()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let serial = DispatchQueue(label: "SamplePiano.serial")

    // Stability controls
    private var lastPlayTime: Double = 0
    private let retriggerMin: Double = 0.12   // 120 ms debounce
    private var currentBuffer: AVAudioPCMBuffer?

    // Loaded samples: "C4" -> buffer
    private var buffers: [String: AVAudioPCMBuffer] = [:]

    private init() {
        configureSession()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
        loadSamples()
        startEngine()
    }

    // MARK: - Audio session

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default)
            try session.setPreferredSampleRate(48_000)
            try session.setPreferredIOBufferDuration(0.005)
            try session.setActive(true)
        } catch {
            print("❌ Audio session error:", error.localizedDescription)
        }
    }

    private func startEngine() {
        do {
            try engine.start()
        } catch {
            print("❌ Engine failed to start:", error.localizedDescription)
        }
    }

    // MARK: - Load WAVs

    private func loadSamples() {
        let names = [
            "A2","A3","A4","A5","A6",
            "B2","B3","B4","B5","B6",
            "C2","C3","C4","C5","C6",
            "D2","D3","D4","D5",
            "E2","E3","E4","E5",
            "F2","F3","F4","F5",
            "G2","G3","G4","G5"
        ]

        for name in names {
            guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
                continue
            }
            do {
                let file = try AVAudioFile(forReading: url)
                guard let buffer = AVAudioPCMBuffer(
                    pcmFormat: file.processingFormat,
                    frameCapacity: AVAudioFrameCount(file.length)
                ) else { continue }

                try file.read(into: buffer)
                buffers[name] = buffer
            } catch {
                print("⚠️ Failed loading \(name).wav:", error.localizedDescription)
            }
        }

        print("✅ Loaded \(buffers.count) piano samples")
    }

    // MARK: - Playback

    func play(token: String, velocity: UInt8 = 100) {
        serial.async { [weak self] in
            guard let self = self else { return }
            guard let normalized = token.normalizedNote else {
                print("⚠️ Invalid note token:", token)
                return
            }

            // Drop sharps/flats for now (C#4 → C4, Bb3 → B3)
            let naturalKey = normalized
                .replacingOccurrences(of: "#", with: "")
                .replacingOccurrences(of: "B", with: "B") // no-op, clarity

            guard let buffer = self.buffers[naturalKey] else {
                print("⚠️ Missing sample for \(naturalKey)")
                return
            }

            let now = CACurrentMediaTime()
            if now - self.lastPlayTime < self.retriggerMin { return }
            self.lastPlayTime = now

            if !self.engine.isRunning {
                self.startEngine()
            }

            // Monophonic safety
            self.player.stop()
            self.player.play()
            self.player.scheduleBuffer(buffer, at: nil, options: []) {
                // nothing needed
            }

            // Simple velocity scaling
            let gain = Float(max(1, min(127, Int(velocity)))) / 127.0
            self.player.volume = gain
        }
    }
}

extension String {
    /// Converts "Bb4" → "A#4", trims spaces, uppercase
    var normalizedNote: String? {
        let s = self.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        let replacements: [String: String] = [
            "CB":"B",
            "DB":"C#",
            "EB":"D#",
            "FB":"E",
            "GB":"F#",
            "AB":"G#",
            "BB":"A#"
        ]

        for (flat, sharp) in replacements {
            if s.hasPrefix(flat) {
                return s.replacingOccurrences(of: flat, with: sharp)
            }
        }

        return s
    }
}

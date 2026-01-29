//
//  PitchPlayer.swift
//  MusicNote
//
//  Created by Jeremy Bastidas on 6/6/25.
//
import AVFoundation

final class PitchPlayer {
    static let shared = PitchPlayer()

    private let engine = AVAudioEngine()
    private let sampler = AVAudioUnitSampler()

    private init() {
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)
        try? engine.start()

        // Try our bundled SF2 first
        var sfLoaded = false
        if let url = Bundle.main.url(forResource: "GeneralUser-GS", withExtension: "sf2") {
            do {
                try sampler.loadSoundBankInstrument(
                    at: url,
                    program: 2,                                   // acoustic grand
                    bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                    bankLSB: 0)
                sfLoaded = true
                print("✅ Loaded sound‑font:", url.lastPathComponent)
            } catch {
                print("⚠️  Could not load SF2:", error.localizedDescription)
            }
        } else {
            print("⚠️  GeneralUser GS.sf2 not found in bundle; falling back to system piano")
        }

        // Fallback: Apple system DLS piano
        if !sfLoaded {
            if let sysURL = URL(string: "/System/Library/Sounds/gs_instruments.dls") {
                try? sampler.loadSoundBankInstrument(
                    at: sysURL,
                    program: 2,
                    bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                    bankLSB: 0)
                print("🟡 Using system DLS piano")
            }
        }
    }

    func play(midi: UInt8, velocity: UInt8 = 100, duration: Double = 0.5) {
        sampler.startNote(midi, withVelocity: velocity, onChannel: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.sampler.stopNote(midi, onChannel: 0)
        }
    }
}

extension String {
    /// Converts "C4", "F#3", etc. to MIDI note number
    var midiNumber: UInt8? {
        let map = ["C":0,"C#":1,"D":2,"D#":3,"E":4,"F":5,"F#":6,
                   "G":7,"G#":8,"A":9,"A#":10,"B":11]
        var name = self
        guard let octaveChar = self.last, let octave = Int(String(octaveChar)) else { return nil }
        name.removeLast()
        guard let semitone = map[name] else { return nil }
        return UInt8(semitone + (octave + 1) * 12)
    }
}

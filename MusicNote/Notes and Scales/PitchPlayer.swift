//
//  PitchPlayer.swift
//  MusicNote
//
//  Thin façade over SamplePiano (no AVAudioEngine here)
//

import Foundation

final class PitchPlayer {
    static let shared = PitchPlayer()
    private init() {}

    /// Plays a musical note token such as "C4", "F#3", or "Bb4"
    func play(token: String, velocity: UInt8 = 110, duration: Double = 0.9) {
        SamplePiano.shared.play(token: token, velocity: velocity)
    }
}

//
//  IntervalTrainer.swift
//  MusicNote
//
//  Created by Jeremy Bastidas on 6/16/25.
//

import Foundation

struct IntervalStat: Codable {
    var correct = 0
    var attempts = 0
    var bestSpeed: Double = .greatestFiniteMagnitude   // sec per note
}

final class IntervalTrainer {
    static let shared = IntervalTrainer()
    private var dict: [Interval: IntervalStat] = [:]

    // Order in which intervals unlock
    private let unlockOrder: [Interval] = [
        .P5, .M3, .P4, .M2, .m3, .M6, .m6, .P8, .m2, .M7, .m7, .unison
    ]
    
    /// Intervals already available to the learner
    private var unlocked: Set<Interval> = [.P5, .M3]
    
    /// Current pool exposed to UI
    var currentPool: [Interval] { Array(unlocked) }

    private let saveURL = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("intervalStats.json")

    private init() { load() }

    func record(_ ivl: Interval, correct: Bool, elapsed: TimeInterval) {
        var stat = dict[ivl] ?? IntervalStat()
        stat.attempts += 1
        if correct { stat.correct += 1 }
        stat.bestSpeed = min(stat.bestSpeed, elapsed)
        dict[ivl] = stat
        maybeUnlockNext(for: ivl)
        save()
    }

    func stat(for ivl: Interval) -> IntervalStat { dict[ivl] ?? IntervalStat() }

    // persistence
    private struct Payload: Codable {
        var stats: [Interval: IntervalStat]
        var unlocked: [Interval]
    }
    
    private func save() {
        let payload = Payload(stats: dict, unlocked: Array(unlocked))
        if let data = try? JSONEncoder().encode(payload) {
            try? data.write(to: saveURL)
        }
    }
    
    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let payload = try? JSONDecoder().decode(Payload.self, from: data) else { return }
        dict = payload.stats
        unlocked = Set(payload.unlocked)
    }
    
    /// Unlock the next interval in sequence once `ivl` reaches ≥90 % accuracy with ≥10 attempts.
    private func maybeUnlockNext(for ivl: Interval) {
        guard let idx = unlockOrder.firstIndex(of: ivl),
              idx + 1 < unlockOrder.count else { return }
        
        // Only if current interval is mastered
        let st = dict[ivl] ?? IntervalStat()
        guard st.attempts >= 10,
              Double(st.correct) / Double(st.attempts) >= 0.9 else { return }
        
        let next = unlockOrder[idx + 1]
        if !unlocked.contains(next) {
            unlocked.insert(next)
            save()
            print("🎉 Unlocked interval:", next.rawValue)
        }
    }
}

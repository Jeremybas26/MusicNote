//
//  ChordStatsManager.swift
//  MusicNote
//
//  Created by Jeremy Bastidas on 1/3/26.
//
import Foundation

struct ChordStat {
    var correct: Int
    var total: Int

    var accuracy: Double {
        total == 0 ? 0 : Double(correct) / Double(total)
    }
}

final class ChordStatsManager {

    static let shared = ChordStatsManager()
    private init() {}

    private let defaults = UserDefaults.standard

    // MARK: - Keys
    private func numeralKey(_ numeral: String) -> String {
        "chord_stat_numeral_\(numeral)"
    }

    private func inversionKey(_ inversion: ChordInversion) -> String {
        "chord_stat_inversion_\(inversion.rawValue)"
    }

    // MARK: - Record Attempt
    func recordAttempt(
        numeral: String,
        inversion: ChordInversion,
        wasCorrect: Bool
    ) {
        update(key: numeralKey(numeral), wasCorrect: wasCorrect)
        update(key: inversionKey(inversion), wasCorrect: wasCorrect)
    }

    private func update(key: String, wasCorrect: Bool) {
        let correctKey = "\(key)_correct"
        let totalKey = "\(key)_total"

        let total = defaults.integer(forKey: totalKey) + 1
        defaults.set(total, forKey: totalKey)

        if wasCorrect {
            let correct = defaults.integer(forKey: correctKey) + 1
            defaults.set(correct, forKey: correctKey)
        }
    }

    // MARK: - Read Stats
    func statForNumeral(_ numeral: String) -> ChordStat {
        stat(for: numeralKey(numeral))
    }

    func statForInversion(_ inversion: ChordInversion) -> ChordStat {
        stat(for: inversionKey(inversion))
    }

    private func stat(for baseKey: String) -> ChordStat {
        let correct = defaults.integer(forKey: "\(baseKey)_correct")
        let total = defaults.integer(forKey: "\(baseKey)_total")
        return ChordStat(correct: correct, total: total)
    }
}

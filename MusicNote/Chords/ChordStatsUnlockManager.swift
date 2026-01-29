//
//  ChordStatsUnlockManager.swift
//  MusicNote
//
//  Created by Jeremy Bastidas on 1/6/26.
//

import Foundation

final class ChordStatsUnlockManager {

    static let shared = ChordStatsUnlockManager()
    private init() {}

    private let defaults = UserDefaults.standard
    private let unlockKey = "chord_stats_unlocked_date"

    var isUnlockedToday: Bool {
        guard let date = defaults.object(forKey: unlockKey) as? Date else {
            return false
        }
        return Calendar.current.isDateInToday(date)
    }

    func unlockForToday() {
        defaults.set(Date(), forKey: unlockKey)
    }
}

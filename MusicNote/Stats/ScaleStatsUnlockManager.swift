//
//  ScaleStatsUnlockManager.swift
//  MusicNote
//
//  Created by Jeremy Bastidas on 1/3/26.
//
import Foundation

// MARK: - Scale Stats Daily Unlock
final class ScaleStatsUnlockManager {

    static let shared = ScaleStatsUnlockManager()
    private init() {}

    private let unlockedKey = "scaleStatsUnlockedDate"

    var isUnlockedToday: Bool {
        guard let date = UserDefaults.standard.object(forKey: unlockedKey) as? Date else {
            return false
        }
        return Calendar.current.isDateInToday(date)
    }

    func unlockForToday() {
        UserDefaults.standard.set(Date(), forKey: unlockedKey)
    }
}

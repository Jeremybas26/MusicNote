import Foundation
//
//  PianoUnlockManager.swift
//  MusicNote
//
//  Created by Jeremy Bastidas on 1/15/26.
//

@MainActor
final class PianoUnlockManager {
    static let shared = PianoUnlockManager()
    private let key = "pianoUnlockedDate"

    var isUnlockedToday: Bool {
        if SubscriptionManager.shared.isPro { return true }
        guard let date = UserDefaults.standard.object(forKey: key) as? Date else {
            return false
        }
        return Calendar.current.isDateInToday(date)
    }

    func unlockForToday() {
        UserDefaults.standard.set(Date(), forKey: key)
    }
}

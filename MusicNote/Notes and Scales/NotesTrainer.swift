//
//  NotesTrainer.swift
//  MusicNote
//
//  Created by Jeremy Bastidas on 1/3/26.
//
import Foundation
import CoreData

// MARK: - Adaptive Trainer Model
final class NotesTrainer {

        struct NoteStat: Codable {
            var correct: Int = 0
            var total: Int = 0
            var totalTime: Double = 0    // cumulative reaction time (s)
            var fastestTime: Double = 0  // best (lowest) reaction time (s); 0 if none yet
            var lastSeen: Date = .distantPast     // NEW – time this note was last shown

            // Derived metrics
            var avgTime: Double  { total == 0 ? 0 : totalTime / Double(total) }
            var avgSpeed: Double { avgTime == 0 ? 0 : 1.0 / avgTime }        // notes per second
            var topSpeed: Double { fastestTime == 0 ? 0 : 1.0 / fastestTime }
            var accuracy: Double {                // NEW – 0‥1 helper
                total == 0 ? 1 : Double(correct) / Double(total)
            }
        }

    static let shared = NotesTrainer()

    enum Stage: String, Codable { case treble, bass, combined }

    private(set) var stage: Stage = .treble

    private let trebleSeq = ["C","D","E","F","G","A","B"]
    private let bassSeq   = ["C","D","E","F","G","A","B"]   // letter names; images handled later

    // Per‑letter stats
    private var stats: [String: NoteStat] = [:]

    // Index of *next* note to unlock in each clef
    private var trebleUnlocked = AppSettings.shared.initialUnlockedCount
    private var bassUnlocked   = AppSettings.shared.initialUnlockedCount

    private init() {
        // Per‑letter stats:
        (trebleSeq + bassSeq).forEach { stats[$0] = .init() }
        load()         // ← NEW: bring back saved progress
    }

    /// Called after every attempt
    func record(guess letter: String, correct: Bool, reactionTime rt: Double) {
        guard var s = stats[letter] else { return }
        s.total += 1
        s.totalTime += rt
        s.lastSeen = Date()      // NEW – remember when we asked this note
        if correct {
            s.correct += 1
            if s.fastestTime == 0 || rt < s.fastestTime {
                s.fastestTime = rt          // update best time
            }
        }
        stats[letter] = s
        // --- Persist raw attempt for history (guarded) ---
        let ctx = PersistenceController.shared.container.viewContext
        if let _ = ctx.persistentStoreCoordinator?.managedObjectModel.entitiesByName["Attempt"] {
            let attempt = Attempt(context: ctx)
            attempt.date    = Date()
            attempt.letter  = letter
            attempt.correct = correct
            attempt.rt      = rt
            do {
                try ctx.save()
            } catch {
                print("❌ CoreData save failed:", error.localizedDescription)
            }
        } else {
            print("⚠️ CoreData model missing 'Attempt' entity; skipping save")
        }
        checkUnlockProgress()
        save()
    }

    /// Returns the pool of currently active letters based on stage/unlocked counts
    func activeLetters() -> [String] {
        switch stage {
        case .treble:
            return Array(trebleSeq.prefix(trebleUnlocked))
        case .bass:
            return Array(bassSeq.prefix(bassUnlocked))
        case .combined:
            return trebleSeq + bassSeq
        }
    }

    func stat(for letter: String) -> NoteStat {
        stats[letter] ?? .init()
    }

    /// Accuracy percentage for a letter
    private func accuracy(of letter: String) -> Double {
        let s = stats[letter] ?? .init()
        return s.total == 0 ? 0 : Double(s.correct) / Double(s.total)
    }

    /// Unlock logic: >90 % accuracy after ≥10 attempts unlocks next note
    private func checkUnlockProgress() {
        switch stage {
        case .treble:
            let currentLetters = activeLetters()
            guard let lastLetter = currentLetters.last, let st = stats[lastLetter] else { return }
            // If last unlocked letter >=2 and its accuracy ≥90% with ≥10 attempts, unlock next
            if st.total >= 10 && accuracy(of: lastLetter) >= 0.9 && trebleUnlocked < trebleSeq.count {
                trebleUnlocked += 1
            }
            // When all treble mastered -> move to bass
            if trebleUnlocked == trebleSeq.count &&
                trebleSeq.allSatisfy({ stats[$0]!.total >= 10 && accuracy(of: $0) >= 0.9 }) {
                stage = .bass
                bassUnlocked = 2   // start bass with C,D
            }
        case .bass:
            let currentLetters = activeLetters()
            guard let lastLetter = currentLetters.last, let st = stats[lastLetter] else { return }
            if st.total >= 10 && accuracy(of: lastLetter) >= 0.9 && bassUnlocked < bassSeq.count {
                bassUnlocked += 1
            }
            if bassUnlocked == bassSeq.count &&
                bassSeq.allSatisfy({ stats[$0]!.total >= 10 && accuracy(of: $0) >= 0.9 }) {
                stage = .combined
            }
        case .combined:
            break
        }
    }

    // MARK: - Manual unlock
    func setInitialUnlocked(count n: Int) {
        let capped = max(2, min(n, trebleSeq.count))
        // Apply to both clefs so Learn/Practice honor the same cap immediately
        trebleUnlocked = capped
        bassUnlocked   = capped
        save()
    }

    // MARK: - Persistence
    // MARK: - Full Reset
    func resetAllProgress() {
        // Reset stats
        stats.keys.forEach { stats[$0] = .init() }
        stage = .treble
        trebleUnlocked = AppSettings.shared.initialUnlockedCount
        bassUnlocked   = AppSettings.shared.initialUnlockedCount

        // Clear CoreData attempts if they exist
        let ctx = PersistenceController.shared.container.viewContext
        if let _ = ctx.persistentStoreCoordinator?.managedObjectModel.entitiesByName["Attempt"] {
            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Attempt")
            let req = NSBatchDeleteRequest(fetchRequest: fetch)
            try? ctx.execute(req)
            try? ctx.save()
        }

        // Reset streaks
        let ud = UserDefaults.standard
        ud.removeObject(forKey: "streakCurrent")
        ud.removeObject(forKey: "streakLongest")
        ud.removeObject(forKey: "streakLastDate")

        save()
    }
    private struct Saved: Codable {
        let stats: [String: NoteStat]
        let stage: Stage
        let trebleUnlocked: Int
        let bassUnlocked: Int
    }
    private let storeKey = "notesTrainerData"

    private func save() {
        let payload = Saved(stats: stats,
                            stage: stage,
                            trebleUnlocked: trebleUnlocked,
                            bassUnlocked: bassUnlocked)
        if let data = try? JSONEncoder().encode(payload) {
            UserDefaults.standard.set(data, forKey: storeKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storeKey),
              let saved = try? JSONDecoder().decode(Saved.self, from: data) else { return }
        stats = saved.stats
        stage = saved.stage
        trebleUnlocked = saved.trebleUnlocked
        bassUnlocked = saved.bassUnlocked
        // If user changed the settings later, ensure at least that many are unlocked
        let desired = AppSettings.shared.initialUnlockedCount
        trebleUnlocked = max(trebleUnlocked, desired)
        bassUnlocked   = max(bassUnlocked,   desired)
        // Ensure a minimum of 2 to avoid empty pools on fresh device
        trebleUnlocked = max(2, trebleUnlocked)
        bassUnlocked   = max(2, bassUnlocked)
    }

}

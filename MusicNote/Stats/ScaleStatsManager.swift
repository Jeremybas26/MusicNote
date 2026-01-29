//
//  ScaleStatsManager.swift
//  MusicNote
//
//  Created by Jeremy Bastidas on 1/3/26.
//

import Foundation

// MARK: - Scale Stats (Per Major Scale)
final class ScaleStatsManager {

    static let shared = ScaleStatsManager()
    private init() { load() }

    struct ScaleStat: Codable {
        var correct: Int = 0
        var total: Int = 0
        var accuracy: Double {
            total == 0 ? 1.0 : Double(correct) / Double(total)
        }
    }

    private var stats: [String: ScaleStat] = [:]   // key = scale name
    private let storeKey = "scaleStatsData"

    func record(scaleName: String, correct: Bool) {
        var s = stats[scaleName] ?? ScaleStat()
        s.total += 1
        if correct { s.correct += 1 }
        stats[scaleName] = s
        save()
    }

    func stat(for scaleName: String) -> ScaleStat {
        stats[scaleName] ?? ScaleStat()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: storeKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storeKey),
              let decoded = try? JSONDecoder().decode([String: ScaleStat].self, from: data)
        else { return }
        stats = decoded
    }
}

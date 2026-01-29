//
//  AppSettings.swift
//  MusicNote
//
//  Created by Jeremy Bastidas on 1/3/26.
//

import Foundation
import SwiftUI

// MARK: - App Settings
enum ButtonLayout: String { case piano, alphabetical }

final class AppSettings {
    static let shared = AppSettings()
    var layout: ButtonLayout = .piano
    /// How many notes should start unlocked in Learn mode (7 = default ALL notes unlocked)
    var initialUnlockedCount: Int = 7   // default to ALL notes unlocked
    /// Use adaptive (Keybr-style) selection in Learn mode
    var adaptiveSelection: Bool = false
    var soundEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "soundEnabled") }
    }
    private init() {}
}

struct StatsGlassButton: View {
    var tap: () -> Void
    var body: some View {
        if #available(iOS 26.0, *) {
            Button("Stats", action: tap)
                .buttonStyle(.glass)
                .foregroundColor(.blue)
                .font(.system(size: 20, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
        } else {
            Button("Stats", action: tap)
                .foregroundColor(.blue)
                .font(.system(size: 20, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
        }
    }
}
// MARK: - GlassMenuButton (for reference: update button text color to blue)
struct GlassMenuButton: View {
    let title: String
    let tap: () -> Void
    var body: some View {
        if #available(iOS 26.0, *) {
            Button(title, action: tap)
                .buttonStyle(.glass)
                .foregroundColor(.blue)
                .font(.system(size: 20, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
        } else {
            Button(title, action: tap)
                .foregroundColor(.blue)
                .font(.system(size: 20, weight: .semibold))
                .padding()
        }
    }
}

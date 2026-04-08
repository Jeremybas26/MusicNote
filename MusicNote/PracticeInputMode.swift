//
//  PracticeInputMode.swift
//  MusicNote
//
//  Created by Jeremy Bastidas on 1/15/26.
//

import UIKit

enum PracticeInputMode { case buttons, piano }

// MARK: - PianoInputHandling

/// Adopted by any practice VC that supports switching between button and piano input.
/// Implement the three required methods; everything else is provided by the extension.
protocol PianoInputHandling: AnyObject {
    var pianoView: PianoKeyboardView { get }
    var inputMode: PracticeInputMode { get set }
    var inputToggleButton: UIButton { get }

    /// Called when the user presses a piano key. Contains the per-VC response logic.
    func pianoNotePressed(_ note: String)

    /// Reveal the practice button UI (answer buttons / grid).
    func showPracticeButtons()

    /// Hide the practice button UI (answer buttons / grid).
    func hidePracticeButtons()
}

extension PianoInputHandling where Self: UIViewController {

    // MARK: Note Normalization

    /// Strips octave digits, converts unicode accidentals to ASCII,
    /// and maps flat spellings to their sharp equivalents.
    func normalize(_ note: String) -> String {
        var s = note
            .replacingOccurrences(of: "♯", with: "#")
            .replacingOccurrences(of: "♭", with: "b")
        for digit in "0123456789" {
            s = s.replacingOccurrences(of: String(digit), with: "")
        }
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        let upper = trimmed.prefix(1).uppercased() + trimmed.dropFirst()
        switch upper {
        case "Db": return "C#"
        case "Eb": return "D#"
        case "Gb": return "F#"
        case "Ab": return "G#"
        case "Bb": return "A#"
        case "Cb": return "B"
        case "Fb": return "E"
        case "E#": return "F"
        case "B#": return "C"
        default:   return upper
        }
    }

    // MARK: Setup

    /// Wires `pianoView.onNotePressed` → `pianoNotePressed(_:)`. Call once in `viewDidLoad`.
    func setupPianoCallbacks() {
        pianoView.onNotePressed = { [weak self] note in
            self?.pianoNotePressed(note)
        }
    }

    // MARK: Input Toggle

    /// Checks Pro / daily-unlock status; shows a rewarded ad if needed, then calls `switchInputMode()`.
    /// Wire your `inputToggleButton` action to call this.
    func handleInputToggleTapped() {
        Task { @MainActor in
            if SubscriptionManager.shared.isPro || PianoUnlockManager.shared.isUnlockedToday {
                switchInputMode()
                return
            }
            RewardedAdManager.shared.show(
                from: self,
                onReward: { [weak self] in
                    PianoUnlockManager.shared.unlockForToday()
                    self?.switchInputMode()
                },
                onFail: { [weak self] in
                    let alert = UIAlertController(
                        title: "Ad not ready",
                        message: "Try again in a moment.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                }
            )
        }
    }

    /// Toggles between `.buttons` and `.piano` modes, updating button title and view visibility.
    func switchInputMode() {
        if inputMode == .buttons {
            inputMode = .piano
            hidePracticeButtons()
            pianoView.isHidden = false
            inputToggleButton.setTitle("🔘 Buttons", for: .normal)
        } else {
            inputMode = .buttons
            showPracticeButtons()
            pianoView.isHidden = true
            inputToggleButton.setTitle("🎹 Piano", for: .normal)
        }
    }
}

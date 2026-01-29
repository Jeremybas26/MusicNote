//
//  IntervalPracticeViewController.swift
//  MusicNote
//
//  Created by Jeremy Bastidas on 6/7/25.
//

import UIKit

/// Basic set of diatonic and perfect intervals we want to drill.
/// Extend later with diminished / augmented if needed.
enum Interval: String, CaseIterable, Codable {
    case unison = "P1"
    case m2, M2, m3, M3
    case P4
    case P5
    case m6, M6, m7, M7
    case P8
    
    /// Semitone distance above root (C‑based).
    var semitones: Int {
        switch self {
        case .unison: return 0
        case .m2: return 1; case .M2: return 2
        case .m3: return 3; case .M3: return 4
        case .P4: return 5
        case .P5: return 7
        case .m6: return 8; case .M6: return 9
        case .m7: return 10; case .M7: return 11
        case .P8: return 12
        }
    }
}

/// Simple model holding the current question.
struct IntervalQuestion {
    let root: String     // e.g. "C4"
    let interval: Interval
    /// Expected answer label (M3, P5, etc.)
    var answer: String { interval.rawValue }
    /// Image asset that shows *both* notes on the correct clef.
    var imageName: String  // e.g. "interval_C4_E4"
}

final class IntervalPracticeViewController: UIViewController {
    
    private func applyAppBackground() {
        view.backgroundColor = UIColor.systemGray6
    }
    
    // MARK: - UI
    
    private let clefImageView = UIImageView()
    private let noteImageView = UIImageView()   // composite interval image
    private var answerButtons: [UIButton] = []
    
    // MARK: - State
    
    private var current: IntervalQuestion?
    private var options: [Interval] { IntervalTrainer.shared.currentPool.sorted { $0.rawValue < $1.rawValue } }
    private var shownAt = Date()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        applyAppBackground()                         // unified gray bg

        // Show nav‑bar Back if this VC is the root of a modal nav stack
        if navigationController?.viewControllers.first == self,
           presentingViewController != nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: "Back",
                style: .plain,
                target: self,
                action: #selector(closeSelf))
        }
        title = "Intervals"
        layoutUI()
        showNext()
    }
    
    // MARK: - Layout
    
    private func layoutUI() {
        let stack = UIStackView(arrangedSubviews: [clefImageView, noteImageView])
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        clefImageView.contentMode = .scaleAspectFit
        noteImageView.contentMode = .scaleAspectFit
        
        // Interval choice buttons
        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 8
        grid.distribution = .fillEqually
        view.addSubview(grid)
        grid.translatesAutoresizingMaskIntoConstraints = false
        
        // Build 2‑row grid (5 + 5)
        let topRow = UIStackView(); topRow.axis = .horizontal; topRow.spacing = 6; topRow.distribution = .fillEqually
        let bottomRow = UIStackView(); bottomRow.axis = .horizontal; bottomRow.spacing = 6; bottomRow.distribution = .fillEqually
        grid.addArrangedSubview(topRow); grid.addArrangedSubview(bottomRow)
        
        for (index, ivl) in Interval.allCases.enumerated() {
            let b = UIButton(type: .system)
            b.setTitle(ivl.rawValue, for: .normal)
            b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
            b.addTarget(self, action: #selector(optionTapped(_:)), for: .touchUpInside)
            b.backgroundColor = .clear
            b.layer.cornerRadius = 8
            b.applyLiquidGlass()
            answerButtons.append(b)
            (index < 5 ? topRow : bottomRow).addArrangedSubview(b)
        }
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            clefImageView.widthAnchor.constraint(equalToConstant: 40),
            clefImageView.heightAnchor.constraint(equalToConstant: 120),
            noteImageView.widthAnchor.constraint(equalToConstant: 200),
            noteImageView.heightAnchor.constraint(equalToConstant: 120),
            
            grid.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 40),
            grid.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            grid.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            grid.heightAnchor.constraint(equalToConstant: 120)
        ])
    }
    
    // MARK: - Question generation
    
    private func showNext() {
        current = makeRandomQuestion()
        guard let q = current else { return }
        shownAt = Date()
        
        // update button labels to reflect current unlocked pool
        for (idx, btn) in answerButtons.enumerated() {
            if idx < options.count {
                btn.isHidden = false
                btn.setTitle(options[idx].rawValue, for: .normal)
            } else {
                btn.isHidden = true
            }
        }
        
        noteImageView.image = UIImage(named: q.imageName)
        if q.imageName.hasPrefix("treble_") {
            clefImageView.image = UIImage(named: "treble")
        } else {
            clefImageView.image = UIImage(named: "bass")
        }
        
        playInterval(root: q.root, interval: q.interval)
    }
    
    private func makeRandomQuestion() -> IntervalQuestion {
        // For demo: pick a random root among natural notes C4‑B4
        let letters = ["C","D","E","F","G","A","B"]
        let rootLetter = letters.randomElement()!
        let root = rootLetter + "4"
        let pool = IntervalTrainer.shared.currentPool
        let ivl = pool.randomElement() ?? .P5
        
        let topNote = intervalNote(root: root, interval: ivl)
        let clefPrefix = root.hasPrefix("C") || root.hasPrefix("D") || root.hasPrefix("E") || root.hasPrefix("F") || root.hasPrefix("G") || root.hasPrefix("A") || root.hasPrefix("B") ? "treble_" : "bass_"
        let imgName = "interval_\(root)_\(topNote)"   // customize to your assets
        
        return IntervalQuestion(root: root, interval: ivl, imageName: clefPrefix + imgName)
    }
    
    private func midiToName(_ midi: UInt8) -> String {
        let names = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
        let note = names[Int(midi % 12)]
        let octave = Int(midi / 12) - 1
        return "\(note)\(octave)"
    }
    
    private func playInterval(root: String, interval: Interval) {
        PitchPlayer.shared.play(token: root, velocity: 100, duration: 0.4)

        let topNote = intervalNote(root: root, interval: interval)
        PitchPlayer.shared.play(token: topNote, velocity: 100, duration: 0.4)
    }

    private func intervalNote(root: String, interval: Interval) -> String {
        let chromatic = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]

        let letter = root.dropLast()
        let octave = Int(root.suffix(1)) ?? 4

        guard let startIndex = chromatic.firstIndex(of: String(letter)) else {
            return root
        }

        let totalSemitones = startIndex + interval.semitones
        let note = chromatic[totalSemitones % 12]
        let octaveOffset = totalSemitones / 12

        return "\(note)\(octave + octaveOffset)"
    }
    
    // MARK: - Interaction
    
    @objc private func optionTapped(_ sender: UIButton) {
        guard let idx = answerButtons.firstIndex(of: sender),
              let q = current else { return }
        
        guard idx < options.count else { return }
        let choice = options[idx].rawValue
        if choice == q.answer {
            let elapsed = Date().timeIntervalSince(shownAt)
            IntervalTrainer.shared.record(q.interval, correct: true, elapsed: elapsed)
            DailyStreakManager.shared.registerPractice()    // counts streak
            sender.tintColor = .systemGreen
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                sender.tintColor = .label
                self?.showNext()
            }
        } else {
            let elapsed = Date().timeIntervalSince(shownAt)
            IntervalTrainer.shared.record(q.interval, correct: false, elapsed: elapsed)
            sender.tintColor = .systemRed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                sender.tintColor = .label
            }
        }
    }
    @objc private func closeSelf() {
        dismiss(animated: true)
    }
    // MARK: - Navigation
}

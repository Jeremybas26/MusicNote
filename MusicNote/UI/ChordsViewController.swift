//
//  PracticeChordsViewController.swift
//  MusicNote
//
//  Created by Jeremy Bastidas on 1/3/26.
//

import UIKit

final class ChordsViewController: UIViewController {
    
    // UI
    private let imageContainer = PracticeImageContainerView()
    private let instructionLabel = UILabel()
    
    private let numeralStack = UIStackView()
    private let inversionStack = UIStackView()
    
    private let practiceHeader = PracticeHeaderView()
    
    private let scoreLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .semibold)
        l.text = "0/0"
        return l
    }()
    private var totalAttempts = 0
    private var correctAttempts = 0
    
    private var isTimedRun = false
    private var timeRemaining: Int = 60
    private var timer: Timer?
    private let timerLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .medium)
        l.textColor = .secondaryLabel
        l.textAlignment = .left
        l.text = "Timed Run"
        l.isHidden = true
        return l
    }()
    
    private var selectedDuration: Int = 60
    
    private let timedRunButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("⏱ Timed Run", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        b.contentHorizontalAlignment = .left
        return b
    }()
    private let intervalButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("🔁 Interval Switch", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        b.contentHorizontalAlignment = .left
        b.tintColor = .systemBlue
        return b
    }()
    
    private let romanNumerals = ["I","ii","iii","IV","V","vi","vii°"]
    private let allKeys: [ChordKey] = [
        .c, .g, .d, .a, .e, .b,
        .fsharp, .csharp,
        .f, .bflat, .eflat, .aflat
    ]
    
    // MARK: - Input Mode
    var inputMode: PracticeInputMode = .buttons

    let inputToggleButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("🎹 Piano", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        b.tintColor = .systemBlue
        b.applyLiquidGlass()
        return b
    }()

    let pianoView = PianoKeyboardView()
    
    // Data
    private var chords: [ChordPractice] = []
    private var currentChord: ChordPractice?
    
    private var gotNumeralCorrect = false
    private var gotInversionCorrect = false

    // MARK: - Piano Chord Tracking
    private var requiredChordNotes: Set<String> = []
    private var playedChordNotes: Set<String> = []
    
    // MARK: - Interval Switcher (Infinite Practice)
    private lazy var intervalController = PracticeIntervalController {
        self.loadNextChord()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Removed navigation bar usage and redundant scoreLabel setup
        
        view.backgroundColor = .systemGray6
        
        practiceHeader.setPracticeMode(.chords)
        
        inputToggleButton.addTarget(self, action: #selector(inputToggleTapped), for: .touchUpInside)
        
        practiceHeader.onSelectPractice = { [weak self] mode in
            guard let nav = self?.navigationController else { return }
            switch mode {
            case .notes:
                nav.setViewControllers([LearningViewController()], animated: false)
            case .scales:
                nav.setViewControllers([PracticeScalesViewController()], animated: false)
            case .chords:
                return
            }
        }
        
        practiceHeader.onTapStats = { [weak self] in
            self?.navigationController?.pushViewController(StatsViewController(), animated: true)
        }
        
        practiceHeader.onTapSettings = { [weak self] in
            self?.navigationController?.pushViewController(SettingsViewController(), animated: true)
        }
        
        practiceHeader.onTapGoPro = { [weak self] in
            let vc = GoProViewController()
            self?.present(vc, animated: true)
        }
        
        practiceHeader.updateStreak(DailyStreakManager.shared.current)
        practiceHeader.setProEnabled(SubscriptionManager.shared.isPro)
        
        timedRunButton.addTarget(self, action: #selector(timedRunTapped), for: .touchUpInside)
        intervalButton.addTarget(self, action: #selector(intervalTapped), for: .touchUpInside)
        
        
        setupUI()
        loadNextChord()

        setupPianoCallbacks()
    }
    
    private func setupUI() {
        practiceHeader.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(practiceHeader)
        
        instructionLabel.text = ""
        instructionLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = 2
        
        imageContainer.translatesAutoresizingMaskIntoConstraints = false
        
        numeralStack.axis = .horizontal
        numeralStack.spacing = 8
        numeralStack.distribution = .fillEqually
        
        inversionStack.axis = .horizontal
        inversionStack.spacing = 8
        inversionStack.distribution = .fillEqually
        
        [
            timedRunButton,
            intervalButton,
            timerLabel,
            scoreLabel,
            instructionLabel,
            imageContainer,
            numeralStack,
            inversionStack,
            inputToggleButton,
            pianoView
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            practiceHeader.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            practiceHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            practiceHeader.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            timedRunButton.topAnchor.constraint(equalTo: practiceHeader.bottomAnchor, constant: 8),
            timedRunButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            timedRunButton.trailingAnchor.constraint(lessThanOrEqualTo: scoreLabel.leadingAnchor, constant: -12),
            
            intervalButton.topAnchor.constraint(equalTo: timedRunButton.bottomAnchor, constant: 8),
            intervalButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            intervalButton.trailingAnchor.constraint(lessThanOrEqualTo: scoreLabel.leadingAnchor, constant: -12),
            
            timerLabel.centerYAnchor.constraint(equalTo: timedRunButton.centerYAnchor),
            timerLabel.leadingAnchor.constraint(equalTo: timedRunButton.trailingAnchor, constant: 8),
            
            scoreLabel.topAnchor.constraint(equalTo: practiceHeader.bottomAnchor, constant: 16),
            scoreLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            instructionLabel.topAnchor.constraint(equalTo: intervalButton.bottomAnchor, constant: 24),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            imageContainer.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 24),
            imageContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageContainer.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            imageContainer.heightAnchor.constraint(equalToConstant: 220),
            
            // Numeral and inversion stacks
            numeralStack.topAnchor.constraint(equalTo: imageContainer.bottomAnchor, constant: 24),
            numeralStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            numeralStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            inversionStack.topAnchor.constraint(equalTo: numeralStack.bottomAnchor, constant: 16),
            inversionStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            inversionStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Input toggle button and piano view
            inputToggleButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            inputToggleButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            inputToggleButton.heightAnchor.constraint(equalToConstant: 36),
            inputToggleButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 110),
            
            pianoView.topAnchor.constraint(equalTo: imageContainer.bottomAnchor, constant: 24),
            pianoView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            pianoView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            pianoView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80)
        ])
        
        pianoView.isHidden = true
        
        buildButtons()
    }
    
    private func buildButtons() {
        romanNumerals.forEach {
            let b = makeButton(title: $0)
            b.addTarget(self, action: #selector(numeralTapped(_:)), for: .touchUpInside)
            numeralStack.addArrangedSubview(b)
        }
        
        ["Root","1st","2nd"].forEach {
            let b = makeButton(title: $0)
            b.addTarget(self, action: #selector(inversionTapped(_:)), for: .touchUpInside)
            inversionStack.addArrangedSubview(b)
        }
    }
    
    private func makeButton(title: String) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.layer.cornerRadius = 10
        b.layer.borderWidth = 1
        b.layer.borderColor = UIColor.systemGray.cgColor
        b.applyLiquidGlass()
        return b
    }
    
    private func loadNextChord() {
        gotNumeralCorrect = false
        gotInversionCorrect = false
        resetButtons()

        let randomKey = allKeys.randomElement()!
        chords = ChordLibrary.all(for: randomKey)
        currentChord = chords.randomElement()

        imageContainer.setImage(named: currentChord?.imageName)

        // 🎹 Piano mode reset
        playedChordNotes.removeAll()

        requiredChordNotes = Set(
            ChordLibrary.notes(
                for: currentChord!.numeral,
                in: randomKey,
                inversion: currentChord!.inversion
            ).map { normalize($0) }
        )

        pianoView.resetHighlights()
    }
    
    @objc private func numeralTapped(_ sender: UIButton) {
        guard let title = sender.currentTitle,
              let chord = currentChord else { return }
        
        if title == chord.numeral {
            sender.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.35)
            gotNumeralCorrect = true
            
            if gotInversionCorrect {
                advanceIfReady()
            }
        } else {
            sender.backgroundColor = UIColor.systemRed.withAlphaComponent(0.35)
        }
    }
    
    @objc private func inversionTapped(_ sender: UIButton) {
        guard let title = sender.currentTitle,
              let chord = currentChord else { return }
        
        if title == chord.inversion.rawValue {
            sender.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.35)
            gotInversionCorrect = true
            
            if gotNumeralCorrect {
                advanceIfReady()
            }
        } else {
            sender.backgroundColor = UIColor.systemRed.withAlphaComponent(0.35)
        }
    }
    
    private func advanceIfReady() {
        guard isTimedRun else { return }
        guard let chord = currentChord else { return }
        
        let wasCorrect = gotNumeralCorrect && gotInversionCorrect
        
        // Record stats once per completed chord
        ChordStatsManager.shared.recordAttempt(
            numeral: chord.numeral,
            inversion: chord.inversion,
            wasCorrect: wasCorrect
        )
        
        totalAttempts += 1
        if wasCorrect {
            correctAttempts += 1
        }
        scoreLabel.text = "\(correctAttempts)/\(totalAttempts)"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.loadNextChord()
        }
    }
    
    private func resetButtons() {
        (numeralStack.arrangedSubviews + inversionStack.arrangedSubviews).forEach {
            $0.backgroundColor = .clear
        }
    }
    
    private func startTimedRun() {
        intervalController.stop()
        timeRemaining = selectedDuration
        updateTimerLabel()
        timerLabel.isHidden = false
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
    }
    
    @objc private func tick() {
        guard isTimedRun else { return }
        timeRemaining -= 1
        updateTimerLabel()
        if timeRemaining <= 0 {
            endTimedRun()
        }
    }
    
    private func updateTimerLabel() {
        timerLabel.text = "⏱ \(timeRemaining)s"
    }
    
    private func endTimedRun() {
        timer?.invalidate()
        timer = nil
        isTimedRun = false
        timerLabel.isHidden = true
        let alert = UIAlertController(
            title: "Timed Run Complete",
            message: "Score: \(correctAttempts)/\(totalAttempts)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Restart", style: .default) { _ in
            self.correctAttempts = 0
            self.totalAttempts = 0
            self.scoreLabel.text = "0/0"
            self.isTimedRun = true
            self.startTimedRun()
            self.loadNextChord()
        })
        alert.addAction(UIAlertAction(title: "Done", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc private func timedRunTapped() {
        let ac = UIAlertController(
            title: "Timed Run",
            message: "How long?",
            preferredStyle: .actionSheet
        )
        ac.setValue(
            NSAttributedString(
                string: "Timed Run",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
                ]
            ),
            forKey: "attributedTitle"
        )
        
        ac.setValue(
            NSAttributedString(
                string: "How long?",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 13),
                    .foregroundColor: UIColor.secondaryLabel
                ]
            ),
            forKey: "attributedMessage"
        )
        ac.addAction(UIAlertAction(title: "30 seconds", style: .default) { _ in
            self.selectedDuration = 30
            self.correctAttempts = 0
            self.totalAttempts = 0
            self.scoreLabel.text = "0/0"
            self.isTimedRun = true
            self.startTimedRun()
            self.loadNextChord()
        })
        ac.addAction(UIAlertAction(title: "60 seconds", style: .default) { _ in
            self.selectedDuration = 60
            self.correctAttempts = 0
            self.totalAttempts = 0
            self.scoreLabel.text = "0/0"
            self.isTimedRun = true
            self.startTimedRun()
            self.loadNextChord()
        })
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = ac.popoverPresentationController {
            popover.sourceView = timedRunButton
            popover.sourceRect = CGRect(
                x: timedRunButton.bounds.midX,
                y: timedRunButton.bounds.maxY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = [.up]
        }
        present(ac, animated: true)
    }
    
    @objc private func intervalTapped() {
        let ac = UIAlertController(
            title: "Interval Switch",
            message: "Switch every…",
            preferredStyle: .actionSheet
        )
        
        if let popover = ac.popoverPresentationController {
            popover.sourceView = intervalButton
            popover.sourceRect = CGRect(
                x: intervalButton.bounds.midX,
                y: intervalButton.bounds.maxY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = [.up]
        }
        
        [5, 10, 15, 30].forEach { seconds in
            ac.addAction(UIAlertAction(title: "\(seconds) seconds", style: .default) { _ in
                // Stop timed run if active
                self.timer?.invalidate()
                self.isTimedRun = false
                self.timerLabel.isHidden = true
                
                self.intervalController.start(interval: TimeInterval(seconds))
                self.loadNextChord() // immediate switch
            })
        }
        
        ac.addAction(UIAlertAction(title: "Stop Interval", style: .destructive) { _ in
            self.intervalController.stop()
        })
        
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        intervalController.stop()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        practiceHeader.updateStreak(DailyStreakManager.shared.current)
        practiceHeader.setProEnabled(SubscriptionManager.shared.isPro)
    }
    // MARK: - Input Mode Actions
    @objc private func inputToggleTapped() {
        handleInputToggleTapped()
    }
// MARK: - Piano Chord Handler
private func handlePianoChordNote(_ note: String) {
    guard inputMode == .piano else { return }

    let normalized = normalize(note)

    // DEBUG (remove later)
    print("🎹 Piano pressed:", note, "→", normalized)
    print("🎼 Required notes:", requiredChordNotes)

    guard requiredChordNotes.contains(normalized) else {
        pianoView.showIncorrect(note: note)
        return
    }

    pianoView.showCorrect(note: note)

    if !playedChordNotes.contains(normalized) {
        playedChordNotes.insert(normalized)
    }

    if playedChordNotes == requiredChordNotes {
        completeChordViaPiano()
    }
}

private func completeChordViaPiano() {
    guard let chord = currentChord else { return }

    // Record stats
    ChordStatsManager.shared.recordAttempt(
        numeral: chord.numeral,
        inversion: chord.inversion,
        wasCorrect: true
    )

    correctAttempts += 1
    totalAttempts += 1
    scoreLabel.text = "\(correctAttempts)/\(totalAttempts)"

    DailyStreakManager.shared.registerPractice()

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        self.loadNextChord()
    }
}
}

// MARK: - ChordPractice note extraction (runtime-safe)
private extension ChordPractice {

    /// Attempts to pull a `[String]` note list from `ChordPractice`
    /// without requiring a specific stored-property name
    var noteStrings: [String] {
        let mirror = Mirror(reflecting: self)

        // Prefer properties whose label contains "note"
        for child in mirror.children {
            guard let label = child.label?.lowercased() else { continue }
            if label.contains("note"),
               let arr = child.value as? [String] {
                return arr
            }
        }

        // Fallback: first `[String]` property
        for child in mirror.children {
            if let arr = child.value as? [String] {
                return arr
            }
        }

        return []
    }
}

// MARK: - PianoInputHandling
extension ChordsViewController: PianoInputHandling {
    func pianoNotePressed(_ note: String) { handlePianoChordNote(note) }
    func showPracticeButtons() { numeralStack.isHidden = false; inversionStack.isHidden = false }
    func hidePracticeButtons() { numeralStack.isHidden = true; inversionStack.isHidden = true }
}

//
//  LearningViewController.swift
//  MusicNote
//
//  Created by Jeremy Bastidas on 1/3/26.
//
import UIKit

class LearningViewController: UIViewController {

    // UI
    private let imageContainer = PracticeImageContainerView()
    private let stackContainer = UIStackView()
    private var buttons: [UIButton] = []
    private let scoreLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .semibold)
        l.text = "0/0"
        return l
    }()
    private let practiceHeader = PracticeHeaderView()
    // Timed Run UI
    private let timerButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("⏱︎ Timed Run", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        return b
    }()
    private let intervalButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("🔁 Interval Switch", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        b.tintColor = .systemBlue
        b.contentHorizontalAlignment = .leading
        return b
    }()
    private let timerLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .semibold)
        l.textColor = .label
        l.text = "0:30"
        l.isHidden = true
        return l
    }()

    // Diagnostic badge for missing note assets
    private let assetBadge: UIButton = {
        let b = UIButton(type: .system)
        b.setTitleColor(.systemRed, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        b.isHidden = true
        return b
    }()

    // Data
    private let trainer = NotesTrainer.shared
    private var current: (letter: String, image: String)?
    private var correctCount = 0
    private var totalCount = 0
    private var noteShownAt: Date?

    // Diagnostics for missing assets
    private var expectedLearnCount: Int = 0
    private var learnMissingAssets: [String] = []
    private var warnedLearnMissing = false

    // Timed‑run state
    private var runTimer: Timer?
    private var timeRemaining: Int = 0
    private var isTimedRun: Bool = false
    private var runCorrect: Int = 0
    private var runTotal: Int = 0
    // Presentation guard to avoid double-present crashes
    private var isPresentingAlert = false

    // MARK: - Interval Switcher (Infinite Practice)
    private lazy var intervalController = PracticeIntervalController {
        self.showNext()
    }

    // MARK: - Input Mode State and Views
    private enum PracticeInputMode {
        case buttons
        case piano
    }

    private var inputMode: PracticeInputMode = .buttons

    private let inputToggleButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("🎹 Piano", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        b.tintColor = .systemBlue
        b.applyLiquidGlass()
        return b
    }()

    private let pianoView = PianoKeyboardView()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Nav‑bar Back if modal‑root
        if navigationController?.viewControllers.first == self,
           presentingViewController != nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: "Back", style: .plain,
                target: self, action: #selector(closeSelf))
        }
        view.backgroundColor = UIColor.systemGray6

        view.addSubview(practiceHeader)
        practiceHeader.translatesAutoresizingMaskIntoConstraints = false

        practiceHeader.onTapStats = { [weak self] in
            let vc = StatsViewController()
            self?.navigationController?.pushViewController(vc, animated: true)
        }

        practiceHeader.onTapSettings = { [weak self] in
            let vc = SettingsViewController()
            self?.navigationController?.pushViewController(vc, animated: true)
        }

        practiceHeader.onTapGoPro = { [weak self] in
            let vc = GoProViewController()
            self?.present(vc, animated: true)
        }

        practiceHeader.onSelectPractice = { [weak self] mode in
            guard let nav = self?.navigationController else { return }
            switch mode {
            case .notes:
                return
            case .scales:
                nav.setViewControllers([PracticeScalesViewController()], animated: false)
            case .chords:
                nav.setViewControllers([ChordsViewController()], animated: false)
            }
        }

        practiceHeader.setPracticeMode(.notes)
        practiceHeader.setProEnabled(SubscriptionManager.shared.isPro)
        practiceHeader.updateStreak(DailyStreakManager.shared.current)

        NSLayoutConstraint.activate([
            practiceHeader.topAnchor.constraint(equalTo: view.topAnchor, constant: 64),
            practiceHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            practiceHeader.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        view.addSubview(scoreLabel)
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scoreLabel.topAnchor.constraint(equalTo: practiceHeader.bottomAnchor, constant: 8),
            scoreLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        // Missing-assets badge
        view.addSubview(assetBadge)
        assetBadge.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            assetBadge.centerYAnchor.constraint(equalTo: scoreLabel.centerYAnchor),
            assetBadge.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
        ])
        assetBadge.addTarget(self, action: #selector(showLearnMissingAssets), for: .touchUpInside)

        // Timer label (countdown)
        view.addSubview(timerLabel)
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            timerLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 8),
            timerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
        ])

        // Timed‑Run button
        timerButton.addTarget(self, action: #selector(startTimedTapped), for: .touchUpInside)
        view.addSubview(timerButton)
        timerButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            timerButton.topAnchor.constraint(equalTo: practiceHeader.bottomAnchor, constant: 8),
            timerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            timerButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 130),
            timerButton.heightAnchor.constraint(equalToConstant: 36)
        ])
        timerButton.applyLiquidGlass()

        // Interval Button
        intervalButton.addTarget(self, action: #selector(intervalTapped), for: .touchUpInside)
        view.addSubview(intervalButton)
        intervalButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            intervalButton.topAnchor.constraint(equalTo: timerButton.bottomAnchor, constant: 2),
            intervalButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            intervalButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 160),
            intervalButton.heightAnchor.constraint(equalToConstant: 36)
        ])

        // Input Toggle Button and Piano View
        inputToggleButton.addTarget(self, action: #selector(inputToggleTapped(_:)), for: .touchUpInside)
        view.addSubview(inputToggleButton)
        inputToggleButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(pianoView)
        pianoView.translatesAutoresizingMaskIntoConstraints = false
        pianoView.isHidden = true
        pianoView.onNotePressed = { [weak self] note in
            self?.handlePianoNote(note)
        }

        NSLayoutConstraint.activate([
            inputToggleButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            inputToggleButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            inputToggleButton.heightAnchor.constraint(equalToConstant: 36),

            // pianoView.topAnchor.constraint(equalTo: imageContainer.bottomAnchor, constant: 32), // Moved to layoutUI()
            pianoView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            pianoView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            pianoView.heightAnchor.constraint(equalToConstant: 220)
        ])

        layoutUI()
        rebuildButtons()
        showNext()
        updateScoreLabel()
        DispatchQueue.main.async { [weak self] in
            self?.maybeWarnLearnMissing()
        }
    }

// MARK: - Piano Input Handler
private func handlePianoNote(_ note: String) {
    guard let current = current else { return }

    totalCount += 1
    let isCorrect = (note == current.letter)
    pianoView.flash(note: note, correct: isCorrect)

    if isTimedRun {
        runTotal += 1
        if isCorrect { runCorrect += 1 }
    }

    if isCorrect {
        correctCount += 1
        DailyStreakManager.shared.registerPractice()

        if AppSettings.shared.soundEnabled,
           let token = current.image.split(separator: "_").last.map(String.init) {
            PitchPlayer.shared.play(token: token)
        }

        updateScoreLabel()
        showNext()
    } else {
        updateScoreLabel()
    }
}

    // Build the pool of (letter, imageName) pairs — Learn mode shows ALL notes
    private func buildNotePool() -> [(String, String)] {
        // NEW: assets already include clef, and you have naturals from C4…C6 (treble) and C2…C4 (bass)
        let treble = ["C4","D4","E4","F4","G4",
                      "C5","D5","E5","F5","G5","A5","B5",
                      "C6"]
        let bass   = ["C2","D2","E2","F2","G2",
                      "C3","D3","E3","F3","G3","A3","B3",
                      "C4"]

        var pool: [(String,String)] = []
        for note in treble {
            let letter = String(note.dropLast())   // "C4" -> "C"
            pool.append((letter, "treble_\(note)"))
        }
        for note in bass {
            let letter = String(note.dropLast())
            pool.append((letter, "bass_\(note)"))
        }

        // Filter to images that exist; log missing for troubleshooting
        let available = pool.filter { UIImage(named: $0.1) != nil }
        expectedLearnCount = pool.count
        learnMissingAssets = pool.filter { UIImage(named: $0.1) == nil }.map { $0.1 }
        let final = available.isEmpty ? pool : available

        // Update badge
        assetBadge.setTitle("Assets: \(final.count)/\(expectedLearnCount)", for: .normal)
        assetBadge.isHidden = learnMissingAssets.isEmpty
        print("[Learn] note assets found: \(final.count) / \(expectedLearnCount)")
        if !learnMissingAssets.isEmpty {
            print("⚠️ Missing note assets in Learn (\(learnMissingAssets.count)):", learnMissingAssets.joined(separator: ", "))
        }
        return final
    }

    private func maybeWarnLearnMissing() {
        guard !warnedLearnMissing, !learnMissingAssets.isEmpty else { return }
        warnedLearnMissing = true
        let found = buildNotePool().count
        let msg = "Found \(found) of \(expectedLearnCount) note images.\n\nMissing:\n" + learnMissingAssets.joined(separator: ", ")
        let alert = UIAlertController(title: "Missing Note Images", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        presentSafely(alert)
    }

    @objc private func showLearnMissingAssets() {
        guard !learnMissingAssets.isEmpty else { return }
        let found = buildNotePool().count
        let msg = "Found \(found) of \(expectedLearnCount) note images.\n\nMissing (\(learnMissingAssets.count)):\n" + learnMissingAssets.joined(separator: ", ")
        let alert = UIAlertController(title: "Missing Note Images", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        presentSafely(alert)
    }

    private func layoutUI() {
        // Add the image container for note images
        view.addSubview(imageContainer)
        imageContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageContainer.topAnchor.constraint(equalTo: practiceHeader.bottomAnchor, constant: 72),
            imageContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageContainer.widthAnchor.constraint(equalTo: view.widthAnchor),
            imageContainer.heightAnchor.constraint(equalToConstant: 220)
        ])

        // Add pianoView top constraint after imageContainer is in hierarchy
        NSLayoutConstraint.activate([
            pianoView.topAnchor.constraint(equalTo: imageContainer.bottomAnchor, constant: 32)
        ])

        stackContainer.axis = .vertical
        stackContainer.spacing = 12
        stackContainer.distribution = .fillEqually
        view.addSubview(stackContainer)
        stackContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackContainer.topAnchor.constraint(equalTo: imageContainer.bottomAnchor, constant: 60),
            stackContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    // MARK: - Letter Ordering (Learn Mode)

    private func orderedLetters() -> [String] {
        switch AppSettings.shared.layout {
        case .piano:
            // Piano order: C D E F G A B
            return ["C", "D", "E", "F", "G", "A", "B"]
        case .alphabetical:
            // Alphabetical: A B C D E F G
            return ["A", "B", "C", "D", "E", "F", "G"]
        }
    }

    private func rebuildButtons() {
        // Remove old
        stackContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
        buttons.forEach { $0.removeFromSuperview() }
        buttons = []

        // We always want 7 letters shown in Learn mode, arranged as:
        // Piano (C…B):  C D E  /  F G A B
        // Alphabet (A…G): A B C / D E F G
        let letters = orderedLetters()              // returns either C…B or A…G
        let topRowLetters = Array(letters.prefix(3))
        let bottomRowLetters = Array(letters.dropFirst(3))  // should be 4

        // --- Button sizing: match both rows ---
        let buttonHeight: CGFloat = 70
        let buttonWidth: CGFloat = {
            // 4 columns, 3 gaps of 12, container has 32 horizontal padding
            let totalSpacing: CGFloat = 12 * 3
            let totalPadding: CGFloat = 16 * 2
            let screenWidth = UIScreen.main.bounds.width
            let containerWidth = screenWidth - totalPadding
            let w = (containerWidth - totalSpacing) / 4
            return w
        }()

        // Set stackContainer alignment after axis, spacing, distribution
        stackContainer.axis = .vertical
        stackContainer.spacing = 12
        stackContainer.distribution = .fillEqually
        stackContainer.alignment = .fill

        // --- Row 1: 3 buttons with equal spacing (no spacers, fixed widths) ---
        let row1 = UIStackView()
        row1.axis = .horizontal
        row1.spacing = 4
        row1.distribution = .equalSpacing
        row1.alignment = .center

        for letter in topRowLetters {
            let btn = UIButton(type: .system)
            btn.setTitle(letter, for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .bold)
            btn.layer.cornerRadius = 8
            btn.layer.borderWidth = 1
            btn.layer.borderColor = UIColor.systemGray.cgColor
            btn.addTarget(self, action: #selector(noteTapped(_:)), for: .touchUpInside)
            buttons.append(btn)
            row1.addArrangedSubview(btn)
            btn.applyLiquidGlass()
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true
            btn.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        }
        let row1Width = (buttonWidth * 3) + (row1.spacing * 2)
        row1.translatesAutoresizingMaskIntoConstraints = false

        // --- Row 2: 4 buttons, equal spacing ---
        let row2 = UIStackView()
        row2.axis = .horizontal
        row2.spacing = 12
        row2.distribution = .equalSpacing
        row2.alignment = .center

        for letter in bottomRowLetters {
            let btn = UIButton(type: .system)
            btn.setTitle(letter, for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .bold)
            btn.layer.cornerRadius = 8
            btn.layer.borderWidth = 1
            btn.layer.borderColor = UIColor.systemGray.cgColor
            btn.addTarget(self, action: #selector(noteTapped(_:)), for: .touchUpInside)
            buttons.append(btn)
            row2.addArrangedSubview(btn)
            btn.applyLiquidGlass()
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true
            btn.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        }

        // Add rows
        stackContainer.addArrangedSubview(row1)
        stackContainer.addArrangedSubview(row2)

        NSLayoutConstraint.activate([
            row1.centerXAnchor.constraint(equalTo: stackContainer.centerXAnchor),
            row1.widthAnchor.constraint(equalToConstant: row1Width)
        ])

        // Fixed heights to keep rows consistent
        row1.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        row2.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
    }

    // Adaptive selection based on accuracy, speed, and time since last seen
    private func weightedRandomNote() -> (letter: String, image: String) {
        let pool = buildNotePool()
        guard !pool.isEmpty else { return ("C", "treble_C5") }

        // If adaptive selection is OFF -> simple uniform random across ALL notes
        if AppSettings.shared.adaptiveSelection == false {
            return pool.randomElement()!
        }

        // Adaptive ON: epsilon‑greedy (explore 25% of the time)
        if Double.random(in: 0...1) < 0.25 {
            return pool.randomElement()!
        }

        // Compute a per-letter score (higher = needs practice)
        func score(_ letter: String) -> Double {
            let s = trainer.stat(for: letter)
            let errorWeight = 1 - s.accuracy
            let speedWeight = min(s.avgTime / 2.0, 1.0)
            let ageSec = Date().timeIntervalSince(s.lastSeen)
            let ageWeight = min(ageSec / 60.0, 1.0)
            return (errorWeight * 0.6) + (speedWeight * 0.3) + (ageWeight * 0.1) + 0.01
        }

        // Rank letters by score, then pick uniformly from notes that belong to the top letters
        let letters = Set(pool.map { $0.0 })
        let rankedLetters = letters.sorted { score($0) > score($1) }
        let topLetters = Array(rankedLetters.prefix(5))
        let candidates = pool.filter { topLetters.contains($0.0) }
        return candidates.randomElement() ?? pool.randomElement()!
    }

    private func showNext() {
        let pool = buildNotePool()
        guard !pool.isEmpty else {
            print("⚠️ Learn pool empty; no assets available to show")
            return
        }
        noteShownAt = Date()
        current = weightedRandomNote()
        guard let pair = current else { return }
        DispatchQueue.main.async { [weak self] in
            self?.imageContainer.setImage(named: pair.image)
        }
    }

    @objc private func noteTapped(_ sender: UIButton) {
        guard let guess = sender.currentTitle, let current = current else { return }
        let rt = noteShownAt.map { Date().timeIntervalSince($0) } ?? 0

        totalCount += 1
        // Count this attempt for the current timed run, if any
        if isTimedRun {
            runTotal += 1
        }
        if guess == current.letter {
            correctCount += 1
            if isTimedRun {
                runCorrect += 1
            }
            DailyStreakManager.shared.registerPractice()
            if let token = current.image.split(separator: "_").last.map(String.init) {
                if AppSettings.shared.soundEnabled {
                    PitchPlayer.shared.play(token: token)
                }
            }
            sender.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.3)
        } else {
            sender.backgroundColor = UIColor.systemRed.withAlphaComponent(0.3)
        }
        trainer.record(guess: current.letter, correct: guess == current.letter, reactionTime: rt)
        updateScoreLabel()

        // If new letters unlocked, rebuild UI
        if trainer.activeLetters().count != buttons.count {
            rebuildButtons()
        }

        if guess == current.letter {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.resetButtons()
                self.showNext()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                sender.backgroundColor = .clear
            }
        }
    }
    // MARK: - Timed Run (Learn Mode)
    @objc private func startTimedTapped() {
        let chooser = UIAlertController(title: "Timed Run", message: "How long?", preferredStyle: .actionSheet)
        [("30 s", 30), ("60 s", 60)].forEach { (title, secs) in
            chooser.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.startTimedRun(duration: secs)
            })
        }
        chooser.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let pop = chooser.popoverPresentationController {
            pop.sourceView = timerButton
            pop.sourceRect = timerButton.bounds
            pop.permittedArrowDirections = [.up, .down]
        }
        presentSafely(chooser)
    }

    @objc private func intervalTapped() {
        let chooser = UIAlertController(
            title: "Interval Switch",
            message: "Switch every…",
            preferredStyle: .actionSheet
        )

        if let pop = chooser.popoverPresentationController {
            pop.sourceView = intervalButton
            pop.sourceRect = intervalButton.bounds
            pop.permittedArrowDirections = [.up, .down]
        }

        [5, 10, 15, 30].forEach { seconds in
            chooser.addAction(UIAlertAction(title: "\(seconds) seconds", style: .default) { _ in
                // Stop timed run if active
                self.runTimer?.invalidate()
                self.isTimedRun = false
                self.timerLabel.isHidden = true

                self.intervalController.start(interval: TimeInterval(seconds))
                self.showNext() // immediate switch
            })
        }

        chooser.addAction(UIAlertAction(
            title: "Stop Interval",
            style: .destructive
        ) { _ in
            self.intervalController.stop()
        })

        chooser.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        presentSafely(chooser)
    }

    private func startTimedRun(duration: Int) {
        intervalController.stop()
        runTimer?.invalidate()
        isTimedRun = true
        timeRemaining = duration
        runCorrect = 0
        runTotal = 0
        timerLabel.isHidden = false
        updateTimerLabel()
        // Kick off the 1s countdown
        runTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        // Ensure a fresh prompt
        showNext()
    }

    private func updateTimerLabel() {
        let m = timeRemaining / 60
        let s = timeRemaining % 60
        timerLabel.text = String(format: "%d:%02d", m, s)
    }

    private func tick() {
        guard timeRemaining > 0 else { endTimedRun(); return }
        timeRemaining -= 1
        DispatchQueue.main.async { [weak self] in
            self?.updateTimerLabel()
        }
        if timeRemaining <= 0 { endTimedRun() }
    }

    private func endTimedRun() {
        runTimer?.invalidate()
        runTimer = nil
        isTimedRun = false
        timerLabel.isHidden = true
        let wrong = runTotal - runCorrect
        let pct = runTotal == 0 ? 0 : Int((Double(runCorrect)/Double(runTotal)) * 100.0)
        let msg = "Correct: \(runCorrect)\nWrong: \(wrong)\nTotal: \(runTotal)\nAccuracy: \(pct)%"
        let alert = UIAlertController(title: "Time's up!", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Try Again", style: .default, handler: { [weak self] _ in
            self?.startTimedTapped()
        }))
        alert.addAction(UIAlertAction(title: "Done", style: .cancel))
        presentSafely(alert)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        runTimer?.invalidate()
        runTimer = nil
        isTimedRun = false
        timerLabel.isHidden = true
        intervalController.stop()
        pianoView.isHidden = true
        stackContainer.isHidden = false
        inputMode = .buttons
        inputToggleButton.setTitle("🎹 Piano", for: .normal)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        practiceHeader.setProEnabled(SubscriptionManager.shared.isPro)
        practiceHeader.updateStreak(DailyStreakManager.shared.current)
    }

    deinit {
        runTimer?.invalidate()
        runTimer = nil
    }

    // Helper to safely present alerts and avoid double-presenting
    private func presentSafely(_ ac: UIAlertController) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard self.presentedViewController == nil,
                  self.view.window != nil,
                  self.isPresentingAlert == false else { return }
            self.isPresentingAlert = true
            self.present(ac, animated: true) { [weak self] in
                // Clear flag when the alert disappears
                ac.view.superview?.isHidden = false
                self?.isPresentingAlert = false
            }
        }
    }


    private func resetButtons() {
        buttons.forEach { $0.backgroundColor = .clear }
    }

    private func updateScoreLabel() {
        scoreLabel.text = "\(correctCount)/\(totalCount)"
    }

    @objc private func closeSelf() {
        dismiss(animated: true)
    }
}

// MARK: - Note token → MIDI helper (file-scope)
fileprivate extension String {
    /// Parses tokens like "C4", "D#3", "Db5" into a MIDI note number (0…127).
    /// Scientific pitch notation assumed (C4 = 60).
    var midiFromNoteToken: UInt8? {
        let s = self.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !s.isEmpty else { return nil }
        let chars = Array(s)
        guard let letter = chars.first, "ABCDEFG".contains(letter) else { return nil }

        var i = 1
        var accidental = 0
        if i < chars.count {
            if chars[i] == "#" { accidental = 1; i += 1 }
            else if chars[i] == "B" { accidental = -1; i += 1 } // 'b' flat (uppercased)
        }
        guard i < chars.count, let octave = Int(String(chars[i...])) else { return nil }

        let baseMap: [Character:Int] = ["C":0,"D":2,"E":4,"F":5,"G":7,"A":9,"B":11]
        guard let base = baseMap[letter] else { return nil }

        let semitone = base + accidental
        let midi = (octave + 1) * 12 + semitone
        guard midi >= 0 && midi <= 127 else { return nil }
        return UInt8(midi)
    }
}


// MARK: - Input Mode Toggle Logic
extension LearningViewController {
    @objc private func inputToggleTapped(_ sender: UIButton) {
        Task { @MainActor in
            if SubscriptionManager.shared.isPro ||
               PianoUnlockManager.shared.isUnlockedToday {

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

    private func switchInputMode() {
        if inputMode == .buttons {
            inputMode = .piano
            stackContainer.isHidden = true
            pianoView.isHidden = false
            inputToggleButton.setTitle("🔘 Buttons", for: .normal)
        } else {
            inputMode = .buttons
            pianoView.isHidden = true
            stackContainer.isHidden = false
            inputToggleButton.setTitle("🎹 Piano", for: .normal)
        }
    }
}

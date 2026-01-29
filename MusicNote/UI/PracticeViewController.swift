//
//  PracticeViewController.swift
//  MusicNote
//
//  Created by Jeremy Bastidas on 1/3/26.
//

import UIKit

// MARK: - PracticeScalesViewController
final class PracticeScalesViewController: UIViewController {

    // MARK: - Debug flag for scales
    private let debugScales = true

    private let practiceHeader = PracticeHeaderView()

    private let imageContainer = PracticeImageContainerView()
    private let buttonsStack = UIStackView()

    private var currentScaleIndex = Int.random(in: 0..<majorScales.count)
    private var scale: Scale { majorScales[currentScaleIndex] }
    private let instructionLabel = UILabel()

    // --- Counter state for correct/total guesses ---
    private var scaleCorrectCount = 0
    private var scaleTotalCount = 0

    // MARK: - Timed Run
    private var isTimedRun = true
    private var selectedDuration: Int = 60
    private var timeRemaining: Int = 60
    private var timer: Timer?

    // MARK: - Interval Switcher (Infinite Practice)
    private lazy var intervalController = PracticeIntervalController {
        self.advanceScale()
    }

    private let timerLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .medium)
        l.textColor = .systemBlue
        l.text = "⏱ 60s"
        l.isHidden = true
        return l
    }()

    private let timedRunButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("⏱ Timed Run", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        b.tintColor = .systemBlue
        b.contentHorizontalAlignment = .leading
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    private let intervalButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("🔁 Interval Switch", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        b.tintColor = .systemBlue
        b.contentHorizontalAlignment = .leading
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let scaleScoreLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .semibold)
        l.text = "0/0"
        l.textAlignment = .right
        return l
    }()

    // MARK: - Piano/Buttons Input Mode
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
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let pianoView = PianoKeyboardView()

    // --- Piano scale tracking state ---
    private var requiredScaleNotes: Set<String> = []
    private var playedScaleNotes: Set<String> = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6

        practiceHeader.setPracticeMode(.scales)

        practiceHeader.onTapStats = { [weak self] in
            guard let self = self else { return }
            let vc = StatsViewController()
            self.navigationController?.pushViewController(vc, animated: true)
        }

        practiceHeader.onTapSettings = { [weak self] in
            guard let self = self else { return }
            let vc = SettingsViewController()
            self.navigationController?.pushViewController(vc, animated: true)
        }

        practiceHeader.onSelectPractice = { [weak self] mode in
            guard let nav = self?.navigationController else { return }
            switch mode {
            case .notes:
                nav.setViewControllers([LearningViewController()], animated: false)
            case .scales:
                return
            case .chords:
                nav.setViewControllers([ChordsViewController()], animated: false)
            }
        }

        timedRunButton.addTarget(self, action: #selector(timedRunTapped), for: .touchUpInside)
        intervalButton.addTarget(self, action: #selector(intervalTapped), for: .touchUpInside)

        inputToggleButton.addTarget(
            self,
            action: #selector(inputToggleTapped),
            for: .touchUpInside
        )

        if navigationController?.viewControllers.first == self,
           presentingViewController != nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: "Back", style: .plain,
                target: self, action: #selector(closeSelf))
        }

        setupUI()
        pianoView.onNotePressed = { [weak self] note in
            self?.handlePianoScaleNote(note)
        }
        loadScale()
        updateScaleScoreLabel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        practiceHeader.updateStreak(DailyStreakManager.shared.current)
        practiceHeader.setProEnabled(SubscriptionManager.shared.isPro)
    }

    private func setupUI() {
        practiceHeader.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(practiceHeader)

        instructionLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = 2
        instructionLabel.textColor = .secondaryLabel
        instructionLabel.text = ""
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionLabel)

        view.addSubview(timerLabel)
        view.addSubview(timedRunButton)
        view.addSubview(intervalButton)
        timerLabel.translatesAutoresizingMaskIntoConstraints = false

        // Add score label after instructionLabel
        view.addSubview(scaleScoreLabel)
        scaleScoreLabel.translatesAutoresizingMaskIntoConstraints = false

        buttonsStack.axis = .vertical
        buttonsStack.spacing = 12

        imageContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageContainer)
        buttonsStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonsStack)

        view.addSubview(inputToggleButton)
        pianoView.translatesAutoresizingMaskIntoConstraints = false
        pianoView.isHidden = true
        view.addSubview(pianoView)

        NSLayoutConstraint.activate([
            practiceHeader.topAnchor.constraint(equalTo: view.topAnchor, constant: 64),
            practiceHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            practiceHeader.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            timedRunButton.topAnchor.constraint(equalTo: practiceHeader.bottomAnchor, constant: 8),
            timedRunButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            timedRunButton.widthAnchor.constraint(equalToConstant: 120),

            intervalButton.topAnchor.constraint(equalTo: timedRunButton.bottomAnchor, constant: 8),
            intervalButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            intervalButton.widthAnchor.constraint(equalToConstant: 160),

            timerLabel.centerYAnchor.constraint(equalTo: timedRunButton.centerYAnchor),
            timerLabel.leadingAnchor.constraint(equalTo: timedRunButton.trailingAnchor, constant: 8),

            // Counter label (top-right)
            scaleScoreLabel.topAnchor.constraint(equalTo: practiceHeader.bottomAnchor, constant: 8),
            scaleScoreLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            instructionLabel.topAnchor.constraint(equalTo: timedRunButton.bottomAnchor, constant: 16),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            imageContainer.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 24),
            imageContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageContainer.heightAnchor.constraint(equalToConstant: 220),

            buttonsStack.topAnchor.constraint(equalTo: imageContainer.bottomAnchor, constant: 24),
            buttonsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buttonsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            inputToggleButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            inputToggleButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            pianoView.topAnchor.constraint(equalTo: imageContainer.bottomAnchor, constant: 24),
            pianoView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            pianoView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            pianoView.heightAnchor.constraint(equalToConstant: 220)
        ])
    }

    private func setButton(_ button: UIButton, correct: Bool) {
        let color = correct ? UIColor.systemGreen : UIColor.systemRed
        button.backgroundColor = color.withAlphaComponent(0.35)
    }

    // MARK: - Scale name sort helper (A-G, accidentals after natural)
    private func orderedScaleNames() -> [String] {
        // Desired natural order
        let naturals = ["A","B","C","D","E","F","G"]

        return majorScales
            .map { $0.name }
            .sorted { a, b in
                // Extract base letter (A–G)
                let baseA = a.first.map(String.init) ?? ""
                let baseB = b.first.map(String.init) ?? ""

                let idxA = naturals.firstIndex(of: baseA) ?? 99
                let idxB = naturals.firstIndex(of: baseB) ?? 99
                if idxA != idxB { return idxA < idxB }

                // Same base letter → natural first, then flats, then sharps
                let isFlatA = a.contains("b")
                let isSharpA = a.contains("#")
                let isFlatB = b.contains("b")
                let isSharpB = b.contains("#")

                let rankA = isFlatA ? 1 : (isSharpA ? 2 : 0)
                let rankB = isFlatB ? 1 : (isSharpB ? 2 : 0)

                return rankA < rankB
            }
    }

    private func loadScale() {

        if debugScales {
            print("🎼 LOAD SCALE")
            print("   index:", currentScaleIndex)
            print("   name:", scale.name)
            print("   image:", scale.imageName)
        }

        buttonsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        imageContainer.setImage(named: scale.imageName)

        playedScaleNotes.removeAll()
        requiredScaleNotes = Set(scaleNoteStrings(for: scale).map { normalize($0) })
        pianoView.resetHighlights()

        let scaleNames = orderedScaleNames()

        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 10
        grid.distribution = .fillEqually

        let columns = 3
        var currentRow: UIStackView?

        for (index, name) in scaleNames.enumerated() {
            if index % columns == 0 {
                currentRow = UIStackView()
                currentRow?.axis = .horizontal
                currentRow?.spacing = 10
                currentRow?.distribution = .fillEqually
                if let row = currentRow {
                    grid.addArrangedSubview(row)
                }
            }

            let b = UIButton(type: .system)
            b.setTitle(name, for: .normal)
            b.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
            b.layer.cornerRadius = 10
            b.layer.borderWidth = 1
            b.layer.borderColor = UIColor.systemGray.cgColor
            b.contentEdgeInsets = UIEdgeInsets(top: 8, left: 6, bottom: 8, right: 6)
            b.addTarget(self, action: #selector(scaleNameTapped(_:)), for: .touchUpInside)
            b.applyLiquidGlass()

            currentRow?.addArrangedSubview(b)
        }

        buttonsStack.addArrangedSubview(grid)
    }

    @objc private func scaleNameTapped(_ sender: UIButton) {
        guard isTimedRun else { return }
        guard let title = sender.currentTitle else { return }

        scaleTotalCount += 1
        let isCorrect = (title == scale.name)

        // Record scale stats (always saved)
        ScaleStatsManager.shared.record(
            scaleName: scale.name,
            correct: isCorrect
        )

        if isCorrect {
            scaleCorrectCount += 1
            setButton(sender, correct: true)
            DailyStreakManager.shared.registerPractice()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.advanceScale()
            }
        } else {
            setButton(sender, correct: false)
        }

        updateScaleScoreLabel()
    }

    private func updateScaleScoreLabel() {
        scaleScoreLabel.text = "\(scaleCorrectCount)/\(scaleTotalCount)"
    }

    private func pickNextScaleIndex() -> Int {
        if debugScales {
            print("🎲 PICK NEXT SCALE (current:", currentScaleIndex, ")")
        }
        if majorScales.count <= 1 { return currentScaleIndex }
        var next = currentScaleIndex
        while next == currentScaleIndex {
            next = Int.random(in: 0..<majorScales.count)
        }
        if debugScales {
            print("   → next index:", next,
                  "name:", majorScales[next].name)
        }
        return next
    }

    private func advanceScale() {
        if debugScales {
            print("➡️ ADVANCING SCALE")
        }
        currentScaleIndex = pickNextScaleIndex()
        loadScale()
    }

    private func startTimedRun() {
        intervalController.stop()
        timeRemaining = selectedDuration
        updateTimerLabel()
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
            message: "Score: \(scaleCorrectCount)/\(scaleTotalCount)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Restart", style: .default) { _ in
            self.scaleCorrectCount = 0
            self.scaleTotalCount = 0
            self.updateScaleScoreLabel()
            self.isTimedRun = true
            self.timerLabel.isHidden = false
            self.startTimedRun()
            self.advanceScale()
        })
        alert.addAction(UIAlertAction(title: "Done", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func timedRunTapped() {
        let alert = UIAlertController(
            title: "Timed Run",
            message: "How long?",
            preferredStyle: .actionSheet
        )
        if let popover = alert.popoverPresentationController {
            popover.sourceView = timedRunButton
            popover.sourceRect = timedRunButton.bounds
            popover.permittedArrowDirections = .up
        }
        alert.addAction(UIAlertAction(title: "30 seconds", style: .default) { _ in
            self.selectedDuration = 30
            self.scaleCorrectCount = 0
            self.scaleTotalCount = 0
            self.updateScaleScoreLabel()
            self.isTimedRun = true
            self.timerLabel.isHidden = false
            self.startTimedRun()
            self.advanceScale()
        })
        alert.addAction(UIAlertAction(title: "60 seconds", style: .default) { _ in
            self.selectedDuration = 60
            self.scaleCorrectCount = 0
            self.scaleTotalCount = 0
            self.updateScaleScoreLabel()
            self.isTimedRun = true
            self.timerLabel.isHidden = false
            self.startTimedRun()
            self.advanceScale()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func intervalTapped() {
        let alert = UIAlertController(
            title: "Interval Switch",
            message: "Switch every…",
            preferredStyle: .actionSheet
        )

        if let popover = alert.popoverPresentationController {
            popover.sourceView = intervalButton
            popover.sourceRect = intervalButton.bounds
            popover.permittedArrowDirections = [.up, .down]
        }

        [5, 10, 15, 30].forEach { seconds in
            alert.addAction(UIAlertAction(title: "\(seconds) seconds", style: .default) { _ in
                self.timer?.invalidate()           // stop timed run timer if active
                self.isTimedRun = false
                self.timerLabel.isHidden = true

                self.intervalController.start(interval: TimeInterval(seconds))
                self.advanceScale()                // immediate switch
            })
        }

        alert.addAction(UIAlertAction(title: "Stop Interval", style: .destructive) { _ in
            self.intervalController.stop()
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        intervalController.stop()
        // Reset input mode to buttons when leaving
        inputMode = .buttons
        pianoView.isHidden = true
        buttonsStack.isHidden = false
        inputToggleButton.setTitle("🎹 Piano", for: .normal)
    }

    @objc private func closeSelf() { dismiss(animated: true) }
}

extension PracticeScalesViewController {

    @objc private func inputToggleTapped() {
        Task { @MainActor in
            if SubscriptionManager.shared.isPro ||
               PianoUnlockManager.shared.isUnlockedToday {

                self.switchInputMode()
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
            buttonsStack.isHidden = true
            pianoView.isHidden = false
            inputToggleButton.setTitle("🔘 Buttons", for: .normal)
        } else {
            inputMode = .buttons
            pianoView.isHidden = true
            buttonsStack.isHidden = false
            inputToggleButton.setTitle("🎹 Piano", for: .normal)
        }
    }
}

// MARK: - Piano scale input handlers
extension PracticeScalesViewController {
    private func handlePianoScaleNote(_ note: String) {
        guard inputMode == .piano else { return }

        let normalized = normalize(note)

        // Debug (optional, remove later)
        print("🎹 Piano:", note, "→", normalized)
        print("🎼 Required:", requiredScaleNotes)

        guard requiredScaleNotes.contains(normalized) else {
            pianoView.showIncorrect(note: note)
            return
        }

        pianoView.showCorrect(note: note)
        playedScaleNotes.insert(normalized)

        if playedScaleNotes == requiredScaleNotes {
            completeScaleViaPiano()
        }
    }

    private func completeScaleViaPiano() {
        scaleTotalCount += 1
        scaleCorrectCount += 1
        updateScaleScoreLabel()
        DailyStreakManager.shared.registerPractice()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.advanceScale()
        }
    }
}

// MARK: - Piano scale input handlers
extension PracticeScalesViewController {

    private func normalize(_ note: String) -> String {
        let cleaned = note
            .replacingOccurrences(of: "♯", with: "#")
            .replacingOccurrences(of: "♭", with: "b")
            .replacingOccurrences(of: "0", with: "")
            .replacingOccurrences(of: "1", with: "")
            .replacingOccurrences(of: "2", with: "")
            .replacingOccurrences(of: "3", with: "")
            .replacingOccurrences(of: "4", with: "")
            .replacingOccurrences(of: "5", with: "")
            .replacingOccurrences(of: "6", with: "")
            .replacingOccurrences(of: "7", with: "")
            .replacingOccurrences(of: "8", with: "")
            .replacingOccurrences(of: "9", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let upper = cleaned.prefix(1).uppercased() + cleaned.dropFirst()

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
        default:
            return upper
        }
    }
}

    // MARK: - Scale Notes Mapping Helper
    private func scaleNoteStrings(for scale: Scale) -> [String] {
        switch scale.name {
        case "C Major":  return ["C","D","E","F","G","A","B"]
        case "G Major":  return ["G","A","B","C","D","E","F#"]
        case "D Major":  return ["D","E","F#","G","A","B","C#"]
        case "A Major":  return ["A","B","C#","D","E","F#","G#"]
        case "E Major":  return ["E","F#","G#","A","B","C#","D#"]
        case "B Major":  return ["B","C#","D#","E","F#","G#","A#"]
        case "F# Major": return ["F#","G#","A#","B","C#","D#","E#"]
        case "C# Major": return ["C#","D#","E#","F#","G#","A#","B#"]

        case "F Major":  return ["F","G","A","Bb","C","D","E"]
        case "Bb Major": return ["Bb","C","D","Eb","F","G","A"]
        case "Eb Major": return ["Eb","F","G","Ab","Bb","C","D"]
        case "Ab Major": return ["Ab","Bb","C","Db","Eb","F","G"]

        default:
            return []
        }
    }

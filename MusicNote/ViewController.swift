//
//  ViewController.swift
//  MusicNote
//
//  Created by Jeremy Bastidas on 5/30/25.
//




import UIKit
import CoreData
import SwiftUI
import UserNotifications

// MARK: - Daily Streak Manager
final class DailyStreakManager {

    static let shared = DailyStreakManager()
    private init() {}

    private enum Key {
        static let current = "streakCurrent"
        static let longest = "streakLongest"
        static let last    = "streakLastDate"
    }

    /// Call when user answers a note correctly (first correct per session is enough)
    func registerPractice() {
        let ud = UserDefaults.standard
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        if let last = ud.object(forKey: Key.last) as? Date {
            let diff = cal.dateComponents([.day], from: last, to: today).day!
            switch diff {
            case 0:
                // already counted today – nothing
                return
            case 1:
                let newStreak = ud.integer(forKey: Key.current) + 1
                ud.set(newStreak, forKey: Key.current)
                ud.set(max(newStreak, ud.integer(forKey: Key.longest)), forKey: Key.longest)
            default:
                ud.set(1, forKey: Key.current)
            }
        } else {
            ud.set(1, forKey: Key.current)
        }
        ud.set(today, forKey: Key.last)
        scheduleTomorrowReminder()
    }

    private func scheduleTomorrowReminder() {
        // Ask permission only the first time
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }

        // Remove any existing daily reminder
        center.removePendingNotificationRequests(withIdentifiers: ["DailyPractice"])

        // Tomorrow at 19:00
        var comps = DateComponents()
        comps.hour = 19; comps.minute = 0

        // If it's already past 19:00 today, this will naturally be tomorrow, else tomorrow too
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

        let content = UNMutableNotificationContent()
        content.title = "Time to practice notes 🎶"
        content.body  = "Keep your streak alive!"
        content.sound = .default

        let req = UNNotificationRequest(identifier: "DailyPractice",
                                        content: content,
                                        trigger: trigger)
        center.add(req)
    }

    // Convenience accessors
    var current: Int { UserDefaults.standard.integer(forKey: Key.current) }
    var longest: Int { UserDefaults.standard.integer(forKey: Key.longest) }
}

// MARK: - Adaptive Trainer Model
fileprivate final class NotesTrainer {

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
    private var trebleUnlocked = 2  // start with C,D
    private var bassUnlocked = 0

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
        // --- Persist raw attempt for history ---
        let ctx = PersistenceController.shared.container.viewContext
        let attempt = Attempt(context: ctx)
        attempt.date    = Date()
        attempt.letter  = letter
        attempt.correct = correct
        attempt.rt      = rt
        try? ctx.save()
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
            // If last unlocked letter >=2 and its accuracy ≥90% with ≥10 attempts, unlock next
            let lastLetter = currentLetters.last!
            let st = stats[lastLetter]!
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
            let lastLetter = currentLetters.last!
            let st = stats[lastLetter]!
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
        if stage == .treble {
            trebleUnlocked = capped
        } else if stage == .bass {
            bassUnlocked = capped
        }
        save()
    }

    // MARK: - Persistence
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
        if stage == .treble { trebleUnlocked = max(trebleUnlocked, desired) }
        if stage == .bass   { bassUnlocked   = max(bassUnlocked,   desired) }
    }

}

// MARK: - App Settings
fileprivate enum ButtonLayout: String { case piano, alphabetical }

fileprivate final class AppSettings {
    static let shared = AppSettings()
    var layout: ButtonLayout = .piano
    /// How many notes should start unlocked in Learn mode (2 = default adaptive)
    var initialUnlockedCount: Int = 2
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
            // Fallback on earlier versions
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

class ViewController: UIViewController {

    // MARK: - UI Elements

    override func viewDidLoad() {
        super.viewDidLoad()

        // SwiftUI glass buttons (Practice, Learn, Settings, Intervals)
        let practiceHost = UIHostingController(
            rootView: GlassMenuButton(title: "Practice") { [weak self] in
                self?.openPractice()
            })
        let learnHost = UIHostingController(
            rootView: GlassMenuButton(title: "Learn") { [weak self] in
                self?.openLearn()
            })
        let settingsHost = UIHostingController(
            rootView: GlassMenuButton(title: "Settings") { [weak self] in
                self?.openSettings()
            })
        let intervalHost = UIHostingController(
            rootView: GlassMenuButton(title: "Intervals") { [weak self] in
                self?.openIntervals()
            })

        let hosts = [practiceHost, learnHost, settingsHost, intervalHost]
        hosts.forEach { host in
            addChild(host)
            view.addSubview(host.view)
            host.view.translatesAutoresizingMaskIntoConstraints = false
            host.didMove(toParent: self)
        }

        // Constraints (vertical stack style)
        NSLayoutConstraint.activate([
            practiceHost.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            practiceHost.view.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            learnHost.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            learnHost.view.topAnchor.constraint(equalTo: practiceHost.view.bottomAnchor, constant: 24),

            settingsHost.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            settingsHost.view.topAnchor.constraint(equalTo: learnHost.view.bottomAnchor, constant: 24),

            intervalHost.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            intervalHost.view.topAnchor.constraint(equalTo: settingsHost.view.bottomAnchor, constant: 24)
        ])

        // SwiftUI Stats button with native glass style (iOS 19+)
        let statsHost = UIHostingController(rootView: StatsGlassButton { [weak self] in
            self?.openStats()
        })
        addChild(statsHost)
        view.addSubview(statsHost.view)
        statsHost.view.translatesAutoresizingMaskIntoConstraints = false
        statsHost.didMove(toParent: self)

        // SwiftUI Speed‑Run button
        let speedHost = UIHostingController(
            rootView: GlassMenuButton(title: "Speed Run") { [weak self] in
                self?.openSpeedRun()
            })
        addChild(speedHost)
        view.addSubview(speedHost.view)
        speedHost.view.translatesAutoresizingMaskIntoConstraints = false
        speedHost.didMove(toParent: self)

        NSLayoutConstraint.activate([
            statsHost.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statsHost.view.topAnchor.constraint(equalTo: intervalHost.view.bottomAnchor, constant: 24),
            statsHost.view.widthAnchor.constraint(equalToConstant: 160),
            statsHost.view.heightAnchor.constraint(equalToConstant: 44),

            speedHost.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            speedHost.view.topAnchor.constraint(equalTo: statsHost.view.bottomAnchor, constant: 24),
            speedHost.view.widthAnchor.constraint(equalToConstant: 160),
            speedHost.view.heightAnchor.constraint(equalToConstant: 44)
        ])
        // Do any additional setup after loading the view.
    }

    // MARK: - Navigation
    @objc private func openSettings() {
        tabBarController?.selectedIndex = 2
    }

    @objc private func openPractice() {
        let chooser = UIAlertController(title: "Practice Length",
                                        message: "Choose a session duration",
                                        preferredStyle: .actionSheet)
        let options: [(String, Int)] = [("10 s",10), ("30 s",30), ("1 min",60)]
        for (title, sec) in options {
            chooser.addAction(UIAlertAction(title: title, style: .default) { _ in
                let vc = PracticeViewController(duration: sec)
                if let nav = self.navigationController {
                    nav.pushViewController(vc, animated: true)
                } else {
                    let nav = UINavigationController(rootViewController: vc)
                    nav.modalPresentationStyle = .fullScreen
                    self.present(nav, animated: true)
                }
            })
        }
        chooser.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(chooser, animated: true)
    }
    
    private func presentPractice(duration: Int) {
        let practiceVC = PracticeViewController(duration: duration)
        practiceVC.modalPresentationStyle = .fullScreen
        present(practiceVC, animated: true, completion: nil)
    }

    @objc private func openLearn() {
        let learnVC = LearningViewController()
        if let nav = navigationController {
            nav.pushViewController(learnVC, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: learnVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }

    @objc private func openStats() {
        tabBarController?.selectedIndex = 1
    }
    
    @objc private func openIntervals() {
        let ivlVC = IntervalPracticeViewController()
        if let nav = navigationController {
            nav.pushViewController(ivlVC, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: ivlVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }

    // MARK: - Speed‑Run
    @objc private func openSpeedRun() {
        // Let user pick a duration
        let chooser = UIAlertController(title: "Speed‑Run Length",
                                        message: nil,
                                        preferredStyle: .actionSheet)
        let options: [(String, Int)] = [("30 s",30), ("1 min",60)]
        for (title, sec) in options {
            chooser.addAction(UIAlertAction(title: title, style: .default) { _ in
                let vc = SpeedRunViewController(duration: sec)
                if let nav = self.navigationController {
                    nav.pushViewController(vc, animated: true)
                } else {
                    let nav = UINavigationController(rootViewController: vc)
                    nav.modalPresentationStyle = .fullScreen
                    self.present(nav, animated: true)
                }
            })
        }
        chooser.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(chooser, animated: true)
    }
}
// MARK: - Button order utility
fileprivate func orderedLetters() -> [String] {
    switch AppSettings.shared.layout {
    case .piano:
        return ["C","D","E","F","G","A","B"]
    case .alphabetical:
        return ["A","B","C","D","E","F","G"]
    }
}

class PracticeViewController: UIViewController {

    // UI components
    private let noteImageView = UIImageView()
    private let clefImageView = UIImageView()
    private let stackView = UIStackView()
    private var buttons: [UIButton] = []
    private let scoreLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .semibold)
        l.text = "0/0"
        return l
    }()
    private let gearButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("⚙︎", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        return b
    }()

    private let timerLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .semibold)
        l.textAlignment = .center
        return l
    }()
    
    private var countdownTimer: Timer?
    private var remainingSeconds: Int = 0
    private let sessionDuration: Int

    // Data
    private var allNotes: [(letter: String, image: String)] = []
    private var current: (letter: String, image: String)?
    private var correctCount = 0
    private var totalCount = 0

    init(duration: Int) {
        self.sessionDuration = duration
        self.remainingSeconds = duration
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Show a nav‑bar Back button if we're the root of a modal nav stack.
        if navigationController?.viewControllers.first == self,
           presentingViewController != nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: "Back",
                style: .plain,
                target: self,
                action: #selector(closeSelf))
        }
        view.backgroundColor = UIColor.systemGray6
        title = "Practice (\(sessionDuration)s)"
        navigationItem.rightBarButtonItem =
            UIBarButtonItem(title: "⚙︎", style: .plain,
                            target: self, action: #selector(openSettings))
        // Timer label centered at top
        view.addSubview(timerLabel)
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            timerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        timerLabel.text = "\(remainingSeconds)s"
        startTimer()
        setupNotes()
        layoutUI()
        showNext()
        updateScoreLabel()
    }

    // Build the pool of (letter, imageName) pairs
    private func setupNotes() {
        // Adjust these arrays if you added/removed images
        let treble = ["E4","F4","G4","A4","B4","C5","D5","E5","F5","G5","A5","B5","C6"]
        let bass   = ["E2","F2","G2","A2","B2","C3","D3","E3","F3","G3","A3","B3","C4"]
        allNotes = treble.map { (String($0.dropLast()), "treble_\($0)") } +
                   bass.map   { (String($0.dropLast()), "bass_\($0)") }
    }

    private func layoutUI() {
        // Clef + note stacked horizontally
        let noteStack = UIStackView(arrangedSubviews: [clefImageView, noteImageView])
        noteStack.axis = .horizontal
        noteStack.spacing = 6
        noteStack.alignment = .center
        view.addSubview(noteStack)
        noteStack.translatesAutoresizingMaskIntoConstraints = false
        clefImageView.contentMode = .scaleAspectFit
        noteImageView.contentMode = .scaleAspectFit
        NSLayoutConstraint.activate([
            noteStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            noteStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            clefImageView.widthAnchor.constraint(equalToConstant: 40),
            clefImageView.heightAnchor.constraint(equalToConstant: 120),
            noteImageView.widthAnchor.constraint(equalToConstant: 200),
            noteImageView.heightAnchor.constraint(equalToConstant: 120)
        ])

        // Vertical stack containing two rows
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.distribution = .fillEqually

        let letters = orderedLetters()
        buttons = letters.map {
            let b = UIButton(type: .system)
            b.setTitle($0, for: .normal)
            b.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .bold)
            b.layer.cornerRadius = 8
            b.layer.borderWidth = 1
            b.layer.borderColor = UIColor.systemGray.cgColor
            b.addTarget(self, action: #selector(noteTapped(_:)), for: .touchUpInside)
            return b
        }

        let row1 = UIStackView()
        row1.axis = .horizontal
        row1.spacing = 12
        row1.distribution = .fillEqually

        let row2 = UIStackView()
        row2.axis = .horizontal
        row2.spacing = 12
        row2.distribution = .fillEqually

        for (idx, btn) in buttons.enumerated() {
            if idx < 4 {
                row1.addArrangedSubview(btn)
            } else {
                row2.addArrangedSubview(btn)
            }
        }

        stackView.addArrangedSubview(row1)
        stackView.addArrangedSubview(row2)

        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: noteImageView.bottomAnchor, constant: 60),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])

        // Row heights for bigger buttons
        row1.heightAnchor.constraint(equalToConstant: 70).isActive = true
        row2.heightAnchor.constraint(equalToConstant: 70).isActive = true
    }
    @objc private func openSettings() {
        let settingsVC = SettingsViewController()
        settingsVC.modalPresentationStyle = .fullScreen
        present(settingsVC, animated: true)
    }

    // Handle button taps
    @objc private func noteTapped(_ sender: UIButton) {
        guard let guess = sender.currentTitle, let current = current else { return }

        totalCount += 1
        if guess == current.letter {
            correctCount += 1
            DailyStreakManager.shared.registerPractice()
            if let token = current.image.split(separator: "_").last.map(String.init),
               let midi = token.midiNumber {
                PitchPlayer.shared.play(midi: midi)
            }
            sender.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.3)
            // color logic continues
        } else {
            sender.backgroundColor = UIColor.systemRed.withAlphaComponent(0.3)
            // color logic continues
        }
        updateScoreLabel()
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

    private func resetButtons() {
        buttons.forEach { $0.backgroundColor = .clear }
    }

    // Show a random note image
    private func showNext() {
        current = allNotes.randomElement()
        guard let pair = current else { return }
        noteImageView.image = UIImage(named: pair.image)
        if pair.image.hasPrefix("treble_") {
            clefImageView.image = UIImage(named: "treble")
        } else {
            clefImageView.image = UIImage(named: "bass")
        }
    }
    
    private func startTimer() {
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.remainingSeconds -= 1
            self.timerLabel.text = "\(self.remainingSeconds)s"
            if self.remainingSeconds <= 0 {
                self.endSession()
            }
        }
    }
    
    private func endSession() {
        countdownTimer?.invalidate()
        buttons.forEach { $0.isUserInteractionEnabled = false }
        let percent = totalCount == 0 ? 0 : Int((Double(correctCount) / Double(totalCount)) * 100)
        let alert = UIAlertController(title: "Time's Up!",
                                      message: "Score: \(correctCount)/\(totalCount)\n\(percent)% correct",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Try Again", style: .default) { _ in
            self.correctCount = 0
            self.totalCount = 0
            self.updateScoreLabel()
            self.remainingSeconds = self.sessionDuration
            self.timerLabel.text = "\(self.remainingSeconds)s"
            self.buttons.forEach { $0.isUserInteractionEnabled = true }
            self.startTimer()
            self.showNext()
        })
        alert.addAction(UIAlertAction(title: "Home", style: .destructive) { _ in
            self.dismiss(animated: true, completion: nil)
        })
        present(alert, animated: true, completion: nil)
    }

    @objc private func closeSelf() {
        dismiss(animated: true)
    }

    private func updateScoreLabel() {
        scoreLabel.text = "\(correctCount)/\(totalCount)"
    }
}

class LearningViewController: UIViewController {

    // UI
    private let noteImageView = UIImageView()
    private let clefImageView = UIImageView()
    private let stackContainer = UIStackView()
    private var buttons: [UIButton] = []
    private let scoreLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .semibold)
        l.text = "0/0"
        return l
    }()
    private let gearButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("⚙︎", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        return b
    }()

    // Data
    private let trainer = NotesTrainer.shared
    private var current: (letter: String, image: String)?
    private var correctCount = 0
    private var totalCount = 0
    private var noteShownAt: Date?

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

        view.addSubview(scoreLabel)
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scoreLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            scoreLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        gearButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        view.addSubview(gearButton)
        gearButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            gearButton.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 8),
            gearButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        gearButton.applyLiquidGlass()
        layoutUI()
        rebuildButtons()
        showNext()
        updateScoreLabel()
    }

    // Build the pool of (letter, imageName) pairs based on trainer's active letters
    private func buildNotePool() -> [(String, String)] {
        // Use your image naming convention; for demo, map letter to all images in treble/bass for that letter
        let treble = ["E4","F4","G4","A4","B4","C5","D5","E5","F5","G5","A5","B5","C6"]
        let bass   = ["E2","F2","G2","A2","B2","C3","D3","E3","F3","G3","A3","B3","C4"]
        var pool: [(String,String)] = []
        let active = trainer.activeLetters()
        if trainer.stage == .treble || trainer.stage == .combined {
            for note in treble {
                let letter = String(note.dropLast())
                if active.contains(letter) {
                    pool.append((letter, "treble_\(note)"))
                }
            }
        }
        if trainer.stage == .bass || trainer.stage == .combined {
            for note in bass {
                let letter = String(note.dropLast())
                if active.contains(letter) {
                    pool.append((letter, "bass_\(note)"))
                }
            }
        }
        return pool
    }

    private func layoutUI() {
        // Clef + note side‑by‑side
        let noteStack = UIStackView(arrangedSubviews: [clefImageView, noteImageView])
        noteStack.axis = .horizontal
        noteStack.spacing = 6
        noteStack.alignment = .center
        view.addSubview(noteStack)
        noteStack.translatesAutoresizingMaskIntoConstraints = false
        clefImageView.contentMode = .scaleAspectFit
        noteImageView.contentMode = .scaleAspectFit
        NSLayoutConstraint.activate([
            noteStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            noteStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            clefImageView.widthAnchor.constraint(equalToConstant: 40),
            clefImageView.heightAnchor.constraint(equalToConstant: 120),
            noteImageView.widthAnchor.constraint(equalToConstant: 200),
            noteImageView.heightAnchor.constraint(equalToConstant: 120)
        ])

        stackContainer.axis = .vertical
        stackContainer.spacing = 12
        stackContainer.distribution = .fillEqually
        view.addSubview(stackContainer)
        stackContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackContainer.topAnchor.constraint(equalTo: noteStack.bottomAnchor, constant: 60),
            stackContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    private func rebuildButtons() {
        // Remove old
        stackContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
        buttons.forEach { $0.removeFromSuperview() }
        buttons = []

        let order = orderedLetters()
        let activeLetters = trainer.activeLetters().sorted { lhs, rhs in
            order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
        }
        // 4‑3 layout (max 7)
        let row1 = UIStackView()
        row1.axis = .horizontal; row1.spacing = 12; row1.distribution = .fillEqually
        let row2 = UIStackView()
        row2.axis = .horizontal; row2.spacing = 12; row2.distribution = .fillEqually

        for (idx, letter) in activeLetters.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(letter, for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .bold)
            btn.layer.cornerRadius = 8
            btn.layer.borderWidth = 1
            btn.layer.borderColor = UIColor.systemGray.cgColor
            btn.addTarget(self, action: #selector(noteTapped(_:)), for: .touchUpInside)
            buttons.append(btn)
            if idx < 4 {
                row1.addArrangedSubview(btn)
            } else {
                row2.addArrangedSubview(btn)
            }
            btn.applyLiquidGlass()
        }
        stackContainer.addArrangedSubview(row1)
        if !row2.arrangedSubviews.isEmpty {
            stackContainer.addArrangedSubview(row2)
            row2.heightAnchor.constraint(equalToConstant: 70).isActive = true
        }
        row1.heightAnchor.constraint(equalToConstant: 70).isActive = true
    }
    @objc private func openSettings() {
        let settingsVC = SettingsViewController()
        settingsVC.modalPresentationStyle = .fullScreen
        present(settingsVC, animated: true)
    }

    // Adaptive selection based on accuracy, speed, and time since last seen
    private func weightedRandomNote() -> (letter: String, image: String) {
        let pool = buildNotePool()
        guard !pool.isEmpty else { return pool.randomElement()! }

        // Helper to compute a score 0‥1  (higher = needs practice)
        func score(_ letter: String) -> Double {
            let s = trainer.stat(for: letter)
            let errorWeight = 1 - s.accuracy                       // 0‥1
            let speedWeight = min(s.avgTime / 2.0, 1.0)            // 0‥1 (2 s or more ⇒ 1)
            let ageSec      = Date().timeIntervalSince(s.lastSeen)
            let ageWeight   = min(ageSec / 60.0, 1.0)              // ≥60 s ⇒ 1
            return (errorWeight * 0.6) + (speedWeight * 0.3) + (ageWeight * 0.1) + 0.01
        }

        // Rank pool by score
        let ranked = pool.sorted { score($0.0) > score($1.0) }
        let topSlice = Array(ranked.prefix(3))   // top‑3 to avoid repetition
        return topSlice.randomElement() ?? ranked.first!
    }

    private func showNext() {
        noteShownAt = Date()
        let pool = buildNotePool()
        guard !pool.isEmpty else { return }
        current = weightedRandomNote()
        guard let pair = current else { return }
        noteImageView.image = UIImage(named: pair.image)
        if pair.image.hasPrefix("treble_") {
            clefImageView.image = UIImage(named: "treble")
        } else {
            clefImageView.image = UIImage(named: "bass")
        }
    }

    @objc private func noteTapped(_ sender: UIButton) {
        guard let guess = sender.currentTitle, let current = current else { return }
        let rt = noteShownAt.map { Date().timeIntervalSince($0) } ?? 0

        totalCount += 1
        if guess == current.letter {
            correctCount += 1
            DailyStreakManager.shared.registerPractice()
            if let token = current.image.split(separator: "_").last.map(String.init),
               let midi = token.midiNumber {
                PitchPlayer.shared.play(midi: midi)
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

class SettingsViewController: UIViewController {

    private let segmented: UISegmentedControl = {
        let s = UISegmentedControl(items: ["Piano (C…B)", "Alphabet (A…G)"])
        s.selectedSegmentIndex = AppSettings.shared.layout == .piano ? 0 : 1
        return s
    }()
    private let notesSegmented: UISegmentedControl = {
        let s = UISegmentedControl(items: ["2 notes","3 notes","5 notes","All"])
        return s
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemGray6

        // Nav‑bar Back if modal‑root
        if navigationController?.viewControllers.first == self,
           presentingViewController != nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: "Back", style: .plain,
                target: self, action: #selector(closeSelf))
        }

        segmented.addTarget(self, action: #selector(layoutChanged), for: .valueChanged)
        view.addSubview(segmented)
        segmented.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            segmented.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            segmented.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            segmented.widthAnchor.constraint(equalToConstant: 260)
        ])

        // Note‑count selector
        notesSegmented.selectedSegmentIndex = {
            switch AppSettings.shared.initialUnlockedCount {
            case 3: return 1
            case 5: return 2
            case 7: return 3
            default: return 0   // 2
            }
        }()
        notesSegmented.addTarget(self, action: #selector(notesChanged), for: .valueChanged)
        view.addSubview(notesSegmented)
        notesSegmented.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            notesSegmented.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            notesSegmented.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 40),
            notesSegmented.widthAnchor.constraint(equalToConstant: 260)
        ])
    }

    @objc private func layoutChanged() {
        AppSettings.shared.layout = segmented.selectedSegmentIndex == 0 ? .piano : .alphabetical
    }

    @objc private func notesChanged() {
        let newVal: Int
        switch notesSegmented.selectedSegmentIndex {
        case 1: newVal = 3
        case 2: newVal = 5
        case 3: newVal = 7
        default: newVal = 2
        }
        AppSettings.shared.initialUnlockedCount = newVal
        NotesTrainer.shared.setInitialUnlocked(count: newVal)
    }

    @objc private func closeSelf() {
        dismiss(animated: true)
    }
}


// MARK: - Progress graph
class ProgressViewController: UIViewController {
    private let backButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Back", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        return b
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemGray6

        backButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        view.addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
        ])

        // Inject Core‑Data context and wrap SwiftUI chart
        let root = ProgressChart()
            .environment(\.managedObjectContext,
                         PersistenceController.shared.container.viewContext)
        let host = UIHostingController(rootView: root)
        addChild(host)
        view.addSubview(host.view)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.didMove(toParent: self)

        // Ensure the back button stays on top
        view.bringSubviewToFront(backButton)
    }

    @objc private func close() {
        dismiss(animated: true)
    }
}

// MARK: - ProgressChart SwiftUI View
import Charts
struct ProgressChart: View {
    @State private var metric: Metric = .accuracy
    @FetchRequest(
        entity: Attempt.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Attempt.date, ascending: true)]
    ) var attempts: FetchedResults<Attempt>

    enum Metric: String, CaseIterable, Identifiable {
        case accuracy = "Accuracy"
        case speed = "Speed"
        var id: String { rawValue }
    }

    struct Point: Hashable {
        let period: Date
        let value: Double
        let letter: String
    }

    // Chart data points grouped by day and letter
    var pts: [Point] {
        struct DayLetter: Hashable {
            let day: Date
            let letter: String
        }

        let cal = Calendar.current
        let grouped = Dictionary(grouping: attempts) { att -> DayLetter in
            let day = cal.startOfDay(for: att.date ?? Date())
            return DayLetter(day: day, letter: att.letter ?? "?")
        }

        var points: [Point] = []
        for (key, rows) in grouped {
            switch metric {
            case .accuracy:
                let pct = Double(rows.filter { $0.correct }.count) /
                          Double(rows.count) * 100
                points.append(Point(period: key.day, value: pct, letter: key.letter))
            case .speed:
                let avgRT = rows.map { $0.rt }.reduce(0, +) / Double(rows.count)
                let speed = avgRT == 0 ? 0 : 1.0 / avgRT
                points.append(Point(period: key.day, value: speed, letter: key.letter))
            }
        }
        return points.sorted { $0.period < $1.period }
    }

    // MARK: - View

    var body: some View {
        VStack {
            Picker("Metric", selection: $metric) {
                ForEach(Metric.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Show chart or empty message
            if pts.isEmpty {
                Text("No history yet.\nDo a few Learn attempts, then come back!")
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                Chart {
                    ForEach(pts, id:\.self) { p in
                        LineMark(
                            x: .value("Date", p.period),
                            y: .value("Val", p.value)
                        )
                        .foregroundStyle(by: .value("Note", p.letter))
                        .symbol(by: .value("Note", p.letter))
                    }
                }
                .chartYScale(domain: metric == .speed ? 0...4 : 0...100)
                .padding()
            }
        }
        .onAppear {
            print("Bucket count:", pts.count)
        }
    }
}

// MARK: - Utility clamp
fileprivate extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Liquid-Glass style
import UIKit
extension UIButton {
    /// Adds a translucent blur and subtle border for a "liquid glass" look.
    func applyLiquidGlass() {
        // ─── Native Liquid‑Glass on iOS 19+ ─────────────────────────────
        if #available(iOS 19.0, *) {
            let existingTitle = title(for: .normal)
            let existingColor = tintColor
            var cfg = UIButton.Configuration.plain()
            cfg.cornerStyle = .capsule
            cfg.background.strokeColor = UIColor.white.withAlphaComponent(0.25)
            cfg.background.strokeWidth = 1
            cfg.title = existingTitle
            cfg.baseForegroundColor = existingColor
            configuration = cfg
            return
        }

        // ─── Fallback (iOS ≤18)  custom blur & gradient ────────────────
        if subviews.first(where: { $0 is UIVisualEffectView }) == nil {
            let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
            blur.isUserInteractionEnabled = false
            blur.frame = bounds
            blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            let vibrancy = UIVisualEffectView(effect:
                UIVibrancyEffect(blurEffect: blur.effect as! UIBlurEffect,
                                 style: .secondaryLabel))
            vibrancy.frame = blur.bounds
            vibrancy.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            blur.contentView.addSubview(vibrancy)

            insertSubview(blur, at: 0)
        }

        backgroundColor = .clear
        layer.cornerRadius = 14
        layer.masksToBounds = true
        layer.borderWidth  = 1.5
        layer.borderColor  = UIColor.white.withAlphaComponent(0.35).cgColor
        layer.shadowColor   = UIColor.white.withAlphaComponent(0.4).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius  = 4
        layer.shadowOffset  = .zero

        if layer.sublayers?.first(where: { $0.name == "glassGradient" }) == nil {
            let grad = CAGradientLayer()
            grad.name         = "glassGradient"
            grad.frame        = bounds
            grad.colors       = [
                UIColor.white.withAlphaComponent(0.25).cgColor,
                UIColor.white.withAlphaComponent(0.05).cgColor
            ]
            grad.locations    = [0, 1]
            grad.cornerRadius = 14
            layer.insertSublayer(grad, at: 1)
        }
    }
}


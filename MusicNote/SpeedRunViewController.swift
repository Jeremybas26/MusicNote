//
//  SpeedRunViewController.swift
//  MusicNote
//
//  Created by Jeremy Bastidas on 6/16/25.
//

import UIKit
import GameKit

/// A timed drill that counts how many notes you identify in `duration` seconds.
final class SpeedRunViewController: UIViewController {

    // MARK: - Configuration
    private let duration: Int
    private var remaining: Int
    private var timer: Timer?

    // MARK: - State
    private var correct = 0
    private var total   = 0
    private var current: (image: String, letter: String)?

    // MARK: - Timing
    private var shownAt = Date()

    // MARK: - UI
    private let timerLabel = UILabel()
    private let scoreLabel = UILabel()
    private let noteImageView = UIImageView()
    private let clefImageView = UIImageView()
    private var buttons: [UIButton] = []

    // MARK: - Init
    init(duration: Int) {
        self.duration  = duration
        self.remaining = duration
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - View Life‑cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemGray6
        title = "Speed Run"

        if navigationController?.viewControllers.first == self,
           presentingViewController != nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: "End", style: .plain,
                target: self, action: #selector(endRun))
        }

        buildUI()
        showNext()
        startTimer()
    }

    deinit { timer?.invalidate() }

    // MARK: - UI construction
    private func buildUI() {
        timerLabel.font = .monospacedDigitSystemFont(ofSize: 28, weight: .bold)
        timerLabel.textAlignment = .center
        timerLabel.text = "\(remaining)s"

        scoreLabel.font = .monospacedDigitSystemFont(ofSize: 22, weight: .medium)
        scoreLabel.textAlignment = .center
        scoreLabel.text = "0"

        clefImageView.contentMode = .scaleAspectFit
        noteImageView.contentMode = .scaleAspectFit

        let topStack = UIStackView(arrangedSubviews: [timerLabel, scoreLabel])
        topStack.axis = .horizontal
        topStack.alignment = .center
        topStack.distribution = .fillEqually
        topStack.spacing = 24

        let noteStack = UIStackView(arrangedSubviews: [clefImageView, noteImageView])
        noteStack.axis = .horizontal
        noteStack.alignment = .center
        noteStack.spacing = 8

        // Answer buttons
        let letters = ["C","D","E","F","G","A","B"]
        buttons = letters.map {
            let b = UIButton(type: .system)
            b.setTitle($0, for: .normal)
            b.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
            b.addTarget(self, action: #selector(noteTapped(_:)), for: .touchUpInside)
            b.applyLiquidGlass()
            return b
        }

        // 4 + 3 grid
        let topRow = UIStackView(arrangedSubviews: Array(buttons.prefix(4)))
        let botRow = UIStackView(arrangedSubviews: Array(buttons.suffix(3)))
        [topRow, botRow].forEach {
            $0.axis = .horizontal
            $0.spacing = 8
            $0.distribution = .fillEqually
        }

        let buttonGrid = UIStackView(arrangedSubviews: [topRow, botRow])
        buttonGrid.axis = .vertical
        buttonGrid.spacing = 10

        let root = UIStackView(arrangedSubviews: [topStack, noteStack, buttonGrid])
        root.axis = .vertical
        root.alignment = .center
        root.spacing = 32
        view.addSubview(root)
        root.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            root.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            root.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            noteImageView.widthAnchor.constraint(equalToConstant: 160),
            noteImageView.heightAnchor.constraint(equalToConstant: 120),
            clefImageView.widthAnchor.constraint(equalToConstant: 40)
        ])
    }

    // MARK: - Timer logic
    private func startTimer() {
        timerLabel.text = "\(remaining)s"
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            remaining -= 1
            timerLabel.text = "\(remaining)s"
            if remaining <= 0 {
                self.endRun()
            }
        }
    }

    // MARK: - Question generation
    private func showNext() {
        shownAt = Date()
        current = makeRandomPair()
        guard let pair = current else { return }
        noteImageView.image = UIImage(named: pair.image)
        if pair.image.hasPrefix("treble_") {
            clefImageView.image = UIImage(named: "treble")
        } else {
            clefImageView.image = UIImage(named: "bass")
        }
    }

    private func makeRandomPair() -> (image: String, letter: String) {
        let letters = ["C","D","E","F","G","A","B"]
        let letter = letters.randomElement()!
        let treble = Bool.random()
        let octave = treble ? (4...5).randomElement()! : (2...3).randomElement()!
        let imageName = (treble ? "treble_" : "bass_") + "\(letter)\(octave)"
        return (imageName, letter)
    }

    // MARK: - Interaction
    @objc private func noteTapped(_ sender: UIButton) {
        guard let title = sender.currentTitle,
              let current = current else { return }

        total += 1
        if title == current.letter {
            correct += 1
            sender.tintColor = .systemGreen
        } else {
            sender.tintColor = .systemRed
        }
        scoreLabel.text = "\(correct)"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            sender.tintColor = .label
            self.showNext()
        }
    }

    // MARK: - End
    @objc private func endRun() {
        timer?.invalidate()
        GameCenterManager.shared.report(score: correct, duration: duration)

        let msg = "You identified \(correct) notes in \(duration) seconds."
        let alert = UIAlertController(title: "Time’s up!", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Leaderboard", style: .default) { _ in
            GameCenterManager.shared.showLeaderboard(from: self)
        })
        alert.addAction(UIAlertAction(title: "Done", style: .default) { _ in
            self.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
}


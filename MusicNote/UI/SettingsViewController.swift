//
//  SettingsViewController.swift
//  MusicNote
//
//  Created by Jeremy Bastidas on 1/3/26.
//

import UIKit

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
    private let adaptiveLabel: UILabel = {
        let l = UILabel()
        l.text = "Adaptive (focus hard notes)"
        l.font = .systemFont(ofSize: 15)
        return l
    }()
    private let adaptiveSwitch: UISwitch = {
        let s = UISwitch()
        s.isOn = AppSettings.shared.adaptiveSelection
        return s
    }()
    private let soundLabel: UILabel = {
        let l = UILabel()
        l.text = "Sound"
        l.font = .systemFont(ofSize: 15)
        return l
    }()
    private let soundSwitch: UISwitch = {
        let s = UISwitch()
        s.isOn = AppSettings.shared.soundEnabled
        return s
    }()
    private let resetButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Reset Progress", for: .normal)
        b.setTitleColor(.systemRed, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        return b
    }()
    private let aboutLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.numberOfLines = 0
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        l.text = "MusicNote\nVersion \(v)"
        return l
    }()
    private let restoreButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Restore Purchases", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        return b
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

        // Adaptive selection toggle
        adaptiveSwitch.addTarget(self, action: #selector(adaptiveChanged), for: .valueChanged)
        view.addSubview(adaptiveLabel)
        view.addSubview(adaptiveSwitch)
        adaptiveLabel.translatesAutoresizingMaskIntoConstraints = false
        adaptiveSwitch.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            adaptiveLabel.topAnchor.constraint(equalTo: notesSegmented.bottomAnchor, constant: 40),
            adaptiveLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            adaptiveSwitch.centerYAnchor.constraint(equalTo: adaptiveLabel.centerYAnchor),
            adaptiveSwitch.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])

        // Sound toggle
        soundSwitch.addTarget(self, action: #selector(soundChanged), for: .valueChanged)
        view.addSubview(soundLabel)
        view.addSubview(soundSwitch)
        soundLabel.translatesAutoresizingMaskIntoConstraints = false
        soundSwitch.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            soundLabel.topAnchor.constraint(equalTo: adaptiveLabel.bottomAnchor, constant: 32),
            soundLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            soundSwitch.centerYAnchor.constraint(equalTo: soundLabel.centerYAnchor),
            soundSwitch.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])

        // Reset button
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
        view.addSubview(resetButton)
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            resetButton.topAnchor.constraint(equalTo: soundLabel.bottomAnchor, constant: 44),
            resetButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        // Restore Purchases button
        restoreButton.addTarget(self, action: #selector(restoreTapped), for: .touchUpInside)
        view.addSubview(restoreButton)
        restoreButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            restoreButton.topAnchor.constraint(equalTo: resetButton.bottomAnchor, constant: 24),
            restoreButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        // About/Version label at bottom
        view.addSubview(aboutLabel)
        aboutLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            aboutLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            aboutLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
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

    @objc private func adaptiveChanged() {
        AppSettings.shared.adaptiveSelection = adaptiveSwitch.isOn
    }

    @objc private func soundChanged() {
        AppSettings.shared.soundEnabled = soundSwitch.isOn
    }

    @objc private func resetTapped() {
        let alert = UIAlertController(
            title: "Reset Progress?",
            message: "This will erase all stats, streaks, and unlocked notes. This cannot be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { _ in
            NotesTrainer.shared.resetAllProgress()
        })
        present(alert, animated: true)
    }

    @objc private func closeSelf() {
        dismiss(animated: true)
    }

    @objc private func restoreTapped() {
        Task {
            await SubscriptionManager.shared.restore()
        }
    }
}




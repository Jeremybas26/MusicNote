//
//  PracticeHeaderView.swift
//  MusicNote
//
//  Created by Jeremy Bastidas on 1/14/26.
//

import UIKit

// MARK: - Practice Mode
enum PracticeMode {
    case notes
    case scales
    case chords

    var title: String {
        switch self {
        case .notes: return "Practice Notes"
        case .scales: return "Practice Scales"
        case .chords: return "Practice Chords"
        }
    }
}

// MARK: - PracticeHeaderView
final class PracticeHeaderView: UIView {

    // MARK: - Callbacks
    var onTapStats: (() -> Void)?
    var onTapSettings: (() -> Void)?
    var onTapGoPro: (() -> Void)?
    var onSelectPractice: ((PracticeMode) -> Void)?

    // MARK: - UI Elements

    private let streakLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.text = "🔥 0"
        return l
    }()

    private let statsButton: UIButton = {
        let b = UIButton(type: .system)
        if #available(iOS 26.0, *) {
            var config = UIButton.Configuration.glass()
            config.image = UIImage(systemName: "chart.bar.xaxis")
            config.baseForegroundColor = .systemBlue
            config.imageColorTransformer = .init { _ in .systemBlue }
            b.configuration = config
        } else {
            b.setImage(UIImage(systemName: "chart.bar.xaxis"), for: .normal)
            b.tintColor = .systemBlue
        }
        return b
    }()

    private let practiceButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Practice Notes ▾", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        return b
    }()

    private let proButton: UIButton = {
        let b = UIButton(type: .system)
        if #available(iOS 26.0, *) {
            var config = UIButton.Configuration.glass()
            config.title = "Go Pro"
            // Removed config.image line as per instructions
            config.imagePadding = 6
            config.baseForegroundColor = .label
            b.configuration = config
        } else {
            b.setTitle("Go Pro", for: .normal)
        }
        return b
    }()

    private let settingsButton: UIButton = {
        let b = UIButton(type: .system)
        if #available(iOS 26.0, *) {
            var config = UIButton.Configuration.glass()
            config.image = UIImage(systemName: "gearshape")
            config.baseForegroundColor = .systemBlue
            config.imageColorTransformer = .init { _ in .systemBlue }
            b.configuration = config
        } else {
            b.setImage(UIImage(systemName: "gearshape"), for: .normal)
            b.tintColor = .systemBlue
        }
        return b
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupActions()
        configurePracticeMenu()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = .clear
    }

    private func setupUI() {
        backgroundColor = .clear

        // Make the practice button larger
        practiceButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        practiceButton.setTitleColor(.systemBlue, for: .normal)

        let leftContainer = UIView()
        leftContainer.translatesAutoresizingMaskIntoConstraints = false
        leftContainer.addSubview(streakLabel)
        streakLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            streakLabel.leadingAnchor.constraint(equalTo: leftContainer.leadingAnchor),
            streakLabel.centerYAnchor.constraint(equalTo: leftContainer.centerYAnchor)
        ])

        let rightContainer = UIView()
        rightContainer.translatesAutoresizingMaskIntoConstraints = false

        let topRow = UIStackView(arrangedSubviews: [
            leftContainer,
            practiceButton,
            rightContainer
        ])
        topRow.axis = .horizontal
        topRow.alignment = .center

        NSLayoutConstraint.activate([
            leftContainer.widthAnchor.constraint(equalTo: rightContainer.widthAnchor)
        ])

        let bottomRightButtons = UIStackView(arrangedSubviews: [statsButton, settingsButton])
        bottomRightButtons.axis = .horizontal
        bottomRightButtons.spacing = 8
        bottomRightButtons.alignment = .center

        let bottomRow = UIStackView(arrangedSubviews: [
            proButton,
            UIView(),
            bottomRightButtons
        ])
        bottomRow.axis = .horizontal
        bottomRow.alignment = .center

        let container = UIStackView(arrangedSubviews: [
            topRow,
            bottomRow
        ])
        container.axis = .vertical
        container.spacing = 10
        container.translatesAutoresizingMaskIntoConstraints = false

        addSubview(container)
        layer.shadowOpacity = 0
        layer.cornerRadius = 0

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            container.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            container.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }

    private func setupActions() {
        statsButton.addTarget(self, action: #selector(statsTapped), for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        proButton.addTarget(self, action: #selector(goProTapped), for: .touchUpInside)
    }

    // MARK: - Practice Menu

    private func configurePracticeMenu() {
        let menu = UIMenu(children: [
            UIAction(title: "Practice Notes") { [weak self] _ in
                self?.selectPractice(.notes)
            },
            UIAction(title: "Practice Scales") { [weak self] _ in
                self?.selectPractice(.scales)
            },
            UIAction(title: "Practice Chords") { [weak self] _ in
                self?.selectPractice(.chords)
            }
        ])

        practiceButton.menu = menu
        practiceButton.showsMenuAsPrimaryAction = true
    }

    private func selectPractice(_ mode: PracticeMode) {
        practiceButton.setTitle("\(mode.title) ▾", for: .normal)
        onSelectPractice?(mode)
    }

    // MARK: - Public Updates

    func updateStreak(_ value: Int) {
        streakLabel.text = "🔥 \(value)"
    }

    func setPracticeMode(_ mode: PracticeMode) {
        practiceButton.setTitle("\(mode.title) ▾", for: .normal)
    }

    func setProEnabled(_ isPro: Bool) {
        if isPro {
            proButton.setTitle("PRO", for: .normal)
            proButton.setTitleColor(.systemYellow, for: .normal)
            proButton.isEnabled = false
        } else {
            proButton.setTitle("⭐ Go Pro", for: .normal)
            proButton.setTitleColor(.systemBlue, for: .normal)
            proButton.isEnabled = true
        }
    }

    // MARK: - Actions

    @objc private func statsTapped() {
        onTapStats?()
    }

    @objc private func settingsTapped() {
        onTapSettings?()
    }

    @objc private func goProTapped() {
        onTapGoPro?()
    }
}

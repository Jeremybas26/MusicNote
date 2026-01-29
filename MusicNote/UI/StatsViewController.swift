//
//  StatsViewController.swift
//  MusicNote
//
//  Created by Jeremy Bastidas on 1/3/26.
//

import UIKit

// MARK: - Stats Dashboard (Grid)
class StatsViewController: UIViewController, UICollectionViewDelegate {
    
    private var scalesIndexPaths: [IndexPath] = []
    
    // MARK: - Accuracy Color Helpers
    private func pastelAccuracyColor(_ accuracy: Double) -> UIColor {
        switch accuracy {
        case ..<0.60:
            return UIColor(red: 1.00, green: 0.82, blue: 0.82, alpha: 1)
        case 0.60..<0.90:
            return UIColor(red: 1.00, green: 0.94, blue: 0.78, alpha: 1)
        default:
            return UIColor(red: 0.80, green: 0.93, blue: 0.85, alpha: 1)
        }
    }
    
    private func pastelAccuracyBorderColor(_ accuracy: Double) -> UIColor {
        switch accuracy {
        case ..<0.60:
            return UIColor(red: 0.85, green: 0.40, blue: 0.40, alpha: 1)
        case 0.60..<0.90:
            return UIColor(red: 0.85, green: 0.70, blue: 0.35, alpha: 1)
        default:
            return UIColor(red: 0.35, green: 0.70, blue: 0.50, alpha: 1)
        }
    }
    
    private enum Section: Int, CaseIterable {
        case kpis
        case notes
        case scales
        case chordNumerals
        case chordInversions

        var title: String? {
            switch self {
            case .notes: return "Notes Stats"
            case .scales: return "Scales Stats"
            case .chordNumerals: return "Chord Stats"
            case .chordInversions: return nil
            default: return nil
            }
        }
    }
    private enum KPIType: Hashable { case streak, avgAccuracy
        var title: String { switch self { case .streak: return "Streak"; case .avgAccuracy: return "Avg Accuracy" } }
    }
    private enum Item: Hashable {
        case kpi(KPIType)
        case note(String)
        case scale(String)
        case chordNumeral(String)
        case chordInversion(ChordInversion)
        case lockedScaleStats
        case lockedChordStats
    }
    
    private let trainer = NotesTrainer.shared
    private var letters: [String] = []
    
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6
        title = "Your Stats"
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        collectionView.register(
            UICollectionViewCell.self,
            forCellWithReuseIdentifier: "Cell"
        )
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        configureDataSource()
        reloadData()
        RewardedAdManager.shared.load()
    }
    
    // MARK: - Collection View Delegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }

        switch item {

        case .scale:
            let unlocked = ScaleStatsUnlockManager.shared.isUnlockedToday
            if !unlocked {
                presentScaleUnlockSheet(from: collectionView)
            }

        case .lockedScaleStats:
            RewardedAdManager.shared.show(
                from: self,
                onReward: { [weak self] in
                    ScaleStatsUnlockManager.shared.unlockForToday()
                    self?.reloadData()
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

        case .lockedChordStats:
            RewardedAdManager.shared.show(
                from: self,
                onReward: { [weak self] in
                    ChordStatsUnlockManager.shared.unlockForToday()
                    self?.reloadData()
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

        default:
            break
        }
    }
    
    // (applyScaleLockUI and updateScalesLockState removed)
    
    private func configureDataSource() {
        let kpiReg = UICollectionView.CellRegistration<UICollectionViewCell, KPIType> { [weak self] cell, _, kpi in
            self?.configureTile(cell: cell, title: kpi.title, subtitle: self?.kpiValue(for: kpi) ?? "")
        }
        let noteReg = UICollectionView.CellRegistration<UICollectionViewCell, String> { [weak self] cell, _, letter in
            guard let self else { return }
            let stat = self.trainer.stat(for: letter)
            let sub = self.noteAccuracyText(letter)
            self.configureTile(
                cell: cell,
                title: letter,
                subtitle: sub,
                accuracy: stat.accuracy
            )
        }
        let scaleReg = UICollectionView.CellRegistration<UICollectionViewCell, String> { [weak self] cell, _, scaleName in
            guard let self else { return }

            let stat = ScaleStatsManager.shared.stat(for: scaleName)
            let pct = stat.total == 0 ? "—" : String(format: "%.0f%%", stat.accuracy * 100)
            let subtitle = "\(pct)  •  \(stat.correct)/\(stat.total)"

            self.configureTile(
                cell: cell,
                title: scaleName,
                subtitle: subtitle,
                accuracy: stat.accuracy
            )
        }
        let headerReg = UICollectionView.SupplementaryRegistration<StatsSectionHeader>(elementKind: UICollectionView.elementKindSectionHeader) { supp, _, indexPath in
            if let sec = Section(rawValue: indexPath.section) { supp.titleLabel.text = sec.title }
        }
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .kpi(let t):
                return collectionView.dequeueConfiguredReusableCell(using: kpiReg, for: indexPath, item: t)
            case .note(let L):
                return collectionView.dequeueConfiguredReusableCell(using: noteReg, for: indexPath, item: L)
            case .scale(let S):
                return collectionView.dequeueConfiguredReusableCell(using: scaleReg, for: indexPath, item: S)
            case .lockedScaleStats:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "Cell",
                    for: indexPath
                )

                (self as? StatsViewController)?.configureTile(
                    cell: cell,
                    title: "Unlock Scale Stats",
                    subtitle: "Watch 1 ad to unlock for today",
                    accuracy: nil
                )

                return cell
            case .chordNumeral(let numeral):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
                let stat = ChordStatsManager.shared.statForNumeral(numeral)
                let subtitle = stat.total == 0
                    ? "—"
                    : String(format: "%.0f%%  •  %d/%d",
                             stat.accuracy * 100,
                             stat.correct,
                             stat.total)
                (self as? StatsViewController)?.configureTile(
                    cell: cell,
                    title: numeral,
                    subtitle: subtitle,
                    accuracy: stat.accuracy
                )
                return cell
            case .chordInversion(let inversion):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
                let stat = ChordStatsManager.shared.statForInversion(inversion)
                let subtitle = stat.total == 0
                    ? "—"
                    : String(format: "%.0f%%  •  %d/%d",
                             stat.accuracy * 100,
                             stat.correct,
                             stat.total)
                (self as? StatsViewController)?.configureTile(
                    cell: cell,
                    title: inversion.rawValue,
                    subtitle: subtitle,
                    accuracy: stat.accuracy
                )
                return cell
            case .lockedChordStats:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "Cell",
                    for: indexPath
                )

                (self as? StatsViewController)?.configureTile(
                    cell: cell,
                    title: "Unlock Chord Stats",
                    subtitle: "Watch 1 ad to unlock for today",
                    accuracy: nil
                )

                return cell
            }
        }
        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: headerReg, for: indexPath)
        }
    }

    private func reloadData() {
        letters = trainer.activeLetters().sorted()
        let scaleNames = majorScales.map { $0.name }

        var snap = NSDiffableDataSourceSnapshot<Section, Item>()
        snap.appendSections([
            .kpis,
            .notes,
            .scales,
            .chordNumerals,
            .chordInversions
        ])

        snap.appendItems([.kpi(.streak), .kpi(.avgAccuracy)], toSection: .kpis)
        snap.appendItems(letters.map { .note($0) }, toSection: .notes)

        let scalesUnlocked =
            SubscriptionManager.shared.isPro ||
            ScaleStatsUnlockManager.shared.isUnlockedToday

        if scalesUnlocked {
            snap.appendItems(scaleNames.map { .scale($0) }, toSection: .scales)
        } else {
            snap.appendItems([.lockedScaleStats], toSection: .scales)
        }

        let chordUnlocked =
            SubscriptionManager.shared.isPro ||
            ChordStatsUnlockManager.shared.isUnlockedToday

        if chordUnlocked {
            let numerals = ["I","ii","iii","IV","V","vi","vii°"]
            let inversions = ChordInversion.allCases

            snap.appendItems(
                numerals.map { .chordNumeral($0) },
                toSection: .chordNumerals
            )

            snap.appendItems(
                inversions.map { .chordInversion($0) },
                toSection: .chordInversions
            )
        } else {
            snap.appendItems([.lockedChordStats], toSection: .chordNumerals)
        }

        // Track index paths for scale cells (no longer needed for lock overlays, but kept for consistency if needed elsewhere)
        scalesIndexPaths = scaleNames.indices.map {
            IndexPath(item: $0, section: Section.scales.rawValue)
        }

        dataSource.apply(snap, animatingDifferences: false)
    }

    private func configureTile(
        cell: UICollectionViewCell,
        title: String,
        subtitle: String,
        accuracy: Double? = nil
    ) {
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        if let acc = accuracy {
            container.backgroundColor = pastelAccuracyColor(acc)
            container.layer.borderWidth = 3
            container.layer.borderColor = pastelAccuracyBorderColor(acc).cgColor
        } else {
            container.backgroundColor = UIColor.white.withAlphaComponent(0.15)
            container.layer.borderWidth = 1
            container.layer.borderColor = UIColor.white.withAlphaComponent(0.35).cgColor
        }
        
        container.layer.cornerRadius = 14
        container.layer.masksToBounds = true
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        blur.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(blur)
        let titleLabel = UILabel(); titleLabel.font = .systemFont(ofSize: 18, weight: .semibold); titleLabel.text = title
        let subtitleLabel = UILabel(); subtitleLabel.font = .systemFont(ofSize: 13); subtitleLabel.textColor = .secondaryLabel; subtitleLabel.text = subtitle; subtitleLabel.numberOfLines = 2
        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel]); stack.axis = .vertical; stack.spacing = 6; stack.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(container); container.addSubview(stack)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            container.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
            blur.topAnchor.constraint(equalTo: container.topAnchor), blur.leadingAnchor.constraint(equalTo: container.leadingAnchor), blur.trailingAnchor.constraint(equalTo: container.trailingAnchor), blur.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12), stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12), stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12), stack.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -12)
        ])
    }

    private func kpiValue(for type: KPIType) -> String {
        switch type {
        case .streak:
            let cur = DailyStreakManager.shared.current
            let best = DailyStreakManager.shared.longest
            return best > 0 ? "\(cur) 🔥 (best \(best))" : "\(cur) 🔥"
        case .avgAccuracy:
            var correct = 0, total = 0
            for L in letters { let s = trainer.stat(for: L); correct += s.correct; total += s.total }
            let pct = total == 0 ? 0 : Int((Double(correct)/Double(total))*100)
            return "\(pct)%"
        }
    }

    private func noteAccuracyText(_ letter: String) -> String {
        let s = trainer.stat(for: letter)
        let pct = s.total == 0 ? "—" : String(format: "%.0f%%", Double(s.correct)/Double(s.total)*100)
        return "\(pct)  •  \(s.correct)/\(s.total)"
    }

    // Removed openGraph and Progress graph feature


    
    
    private func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { sectionIndex, _ in
            guard let sec = Section(rawValue: sectionIndex) else { return nil }
            func headerItem() -> NSCollectionLayoutBoundarySupplementaryItem {
                let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(32))
                return .init(layoutSize: size, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
            }
            switch sec {
            case .kpis:
                let item = NSCollectionLayoutItem(
                    layoutSize: .init(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .estimated(80)
                    )
                )
                item.contentInsets = .init(top: 8, leading: 8, bottom: 8, trailing: 8)

                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: .init(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .estimated(100)
                    ),
                    subitem: item,
                    count: 3
                )

                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = .init(top: 4, leading: 8, bottom: 8, trailing: 8)
                return section

            case .notes, .scales, .chordNumerals, .chordInversions:
                let item = NSCollectionLayoutItem(
                    layoutSize: .init(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .estimated(90)
                    )
                )
                item.contentInsets = .init(top: 8, leading: 8, bottom: 8, trailing: 8)

                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: .init(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .estimated(100)
                    ),
                    subitem: item,
                    count: 3
                )

                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = .init(top: 4, leading: 8, bottom: 8, trailing: 8)
                section.boundarySupplementaryItems = [headerItem()]
                return section
            }
        }
    }
    
    
    // MARK: - Stats Section Header (Reusable for Dashboard)
    final class StatsSectionHeader: UICollectionReusableView {
        let titleLabel = UILabel()
        override init(frame: CGRect) {
            super.init(frame: frame)
            titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
            titleLabel.textColor = .black
            addSubview(titleLabel)
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
                titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16)
            ])
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    }
}


// MARK: - Present bottom sheet for unlocking scales
extension StatsViewController {
    private func presentScaleUnlockSheet(from sourceView: UIView) {
        let ac = UIAlertController(
            title: "Unlock Scale Stats",
            message: "Watch 1 short ad to unlock all Scale stats for today.",
            preferredStyle: .actionSheet
        )

        ac.addAction(UIAlertAction(title: "Watch Ad to Unlock", style: .default) { [weak self] _ in
            guard let self else { return }

            RewardedAdManager.shared.show(
                from: self,
                onReward: { [weak self] in
                    guard let self else { return }
                    ScaleStatsUnlockManager.shared.unlockForToday()

                    // Fully refresh scale cells so lock overlays disappear
                    ScaleStatsUnlockManager.shared.unlockForToday()

                    var snapshot = self.dataSource.snapshot()

                    // Re-apply the SAME snapshot to force reconfiguration
                    self.dataSource.apply(snapshot, animatingDifferences: true)
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
        })

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // iPad safety
        if let pop = ac.popoverPresentationController {
            pop.sourceView = sourceView
            pop.sourceRect = CGRect(
                x: sourceView.bounds.midX,
                y: sourceView.bounds.midY,
                width: 1,
                height: 1
            )
        }

        present(ac, animated: true)
    }
}

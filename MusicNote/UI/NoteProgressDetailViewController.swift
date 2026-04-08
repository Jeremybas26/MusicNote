//
//  NoteProgressDetailViewController.swift
//  MusicNote
//
//  Created by Jeremy Bastidas on 1/3/26.
//

import UIKit
import SwiftUI
import Charts
import CoreData

// MARK: - Chart Data Model

struct DailyAccuracyPoint: Identifiable {
    let id = UUID()
    let date: Date
    let accuracy: Double
    let total: Int
}

// MARK: - SwiftUI Chart View

@available(iOS 16.0, *)
struct AccuracyBarChartView: View {
    let dataPoints: [DailyAccuracyPoint]
    let accentColor: Color

    var body: some View {
        Group {
            if dataPoints.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No session history yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Keep practicing to build a trend!")
                        .font(.caption)
                        .foregroundColor(.tertiary)
                }
                .frame(maxWidth: .infinity, minHeight: 160)
            } else {
                Chart(dataPoints) { point in
                    BarMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Accuracy %", point.accuracy * 100)
                    )
                    .foregroundStyle(
                        point.accuracy >= 0.90 ? Color.green :
                        point.accuracy >= 0.60 ? Color.yellow :
                        Color.red
                    )
                    .cornerRadius(5)
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                        AxisValueLabel { Text("\(value.as(Int.self) ?? 0)%") }
                        AxisGridLine()
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .frame(height: 180)
                .padding(.horizontal, 8)
            }
        }
    }
}

// MARK: - Detail View Controller

final class NoteProgressDetailViewController: UIViewController {

    private let itemTitle: String
    private let sectionTitle: String
    private let correct: Int
    private let total: Int
    private let letter: String?

    private var gradientLayer = CAGradientLayer()

    init(itemTitle: String, sectionTitle: String, correct: Int, total: Int, letter: String?) {
        self.itemTitle = itemTitle
        self.sectionTitle = sectionTitle
        self.correct = correct
        self.total = total
        self.letter = letter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = itemTitle
        setupGradient()

        // Match nav bar style
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white

        buildUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }

    private func setupGradient() {
        gradientLayer.colors = [
            UIColor(red: 0.07, green: 0.10, blue: 0.16, alpha: 1).cgColor,
            UIColor(red: 0.12, green: 0.14, blue: 0.20, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func buildUI() {
        let accuracy = total == 0 ? 0.0 : Double(correct) / Double(total)
        let accuracyPct = total == 0 ? "—" : String(format: "%.0f%%", accuracy * 100)
        let correctText = total == 0 ? "No attempts yet" : "\(correct) of \(total) correct"

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -32),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])

        // — Header card: accent bar + title + accuracy
        let headerCard = makeCard()
        let accentBar = UIView()
        accentBar.backgroundColor = accentColor(for: accuracy)
        accentBar.layer.cornerRadius = 3
        accentBar.translatesAutoresizingMaskIntoConstraints = false
        accentBar.widthAnchor.constraint(equalToConstant: 6).isActive = true

        let sectionTitleLabel = UILabel()
        sectionTitleLabel.text = sectionTitle
        sectionTitleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        sectionTitleLabel.textColor = .secondaryLabel

        let noteTitleLabel = UILabel()
        noteTitleLabel.text = itemTitle
        noteTitleLabel.font = .systemFont(ofSize: 48, weight: .bold)
        noteTitleLabel.textColor = .label

        let accuracyHeaderLabel = UILabel()
        accuracyHeaderLabel.text = "Accuracy"
        accuracyHeaderLabel.font = .systemFont(ofSize: 14, weight: .medium)
        accuracyHeaderLabel.textColor = .secondaryLabel

        let accuracyValueLabel = UILabel()
        accuracyValueLabel.text = accuracyPct
        accuracyValueLabel.font = .systemFont(ofSize: 36, weight: .bold)
        accuracyValueLabel.textColor = .label

        let correctLabel = UILabel()
        correctLabel.text = correctText
        correctLabel.font = .systemFont(ofSize: 14)
        correctLabel.textColor = .secondaryLabel

        let textStack = UIStackView(arrangedSubviews: [
            sectionTitleLabel, noteTitleLabel,
            accuracyHeaderLabel, accuracyValueLabel, correctLabel
        ])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.setCustomSpacing(12, after: noteTitleLabel)
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let headerRow = UIStackView(arrangedSubviews: [accentBar, textStack])
        headerRow.axis = .horizontal
        headerRow.spacing = 12
        headerRow.alignment = .top
        headerRow.translatesAutoresizingMaskIntoConstraints = false

        headerCard.addSubview(headerRow)
        NSLayoutConstraint.activate([
            headerRow.topAnchor.constraint(equalTo: headerCard.topAnchor, constant: 16),
            headerRow.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 16),
            headerRow.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -16),
            headerRow.bottomAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: -16),
            accentBar.heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
        contentStack.addArrangedSubview(headerCard)

        // — Chart card
        let chartCard = makeCard()
        let chartTitleLabel = UILabel()
        chartTitleLabel.text = "Daily Accuracy (last 14 days)"
        chartTitleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        chartTitleLabel.textColor = .label
        chartTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let dataPoints = fetchDailyAccuracy()

        if #available(iOS 16.0, *) {
            let chartView = AccuracyBarChartView(
                dataPoints: dataPoints,
                accentColor: swiftUIAccentColor(for: accuracy)
            )
            let hostVC = UIHostingController(rootView: chartView)
            hostVC.view.backgroundColor = .clear
            addChild(hostVC)
            hostVC.view.translatesAutoresizingMaskIntoConstraints = false
            chartCard.addSubview(chartTitleLabel)
            chartCard.addSubview(hostVC.view)
            hostVC.didMove(toParent: self)

            NSLayoutConstraint.activate([
                chartTitleLabel.topAnchor.constraint(equalTo: chartCard.topAnchor, constant: 16),
                chartTitleLabel.leadingAnchor.constraint(equalTo: chartCard.leadingAnchor, constant: 16),
                chartTitleLabel.trailingAnchor.constraint(equalTo: chartCard.trailingAnchor, constant: -16),
                hostVC.view.topAnchor.constraint(equalTo: chartTitleLabel.bottomAnchor, constant: 12),
                hostVC.view.leadingAnchor.constraint(equalTo: chartCard.leadingAnchor),
                hostVC.view.trailingAnchor.constraint(equalTo: chartCard.trailingAnchor),
                hostVC.view.bottomAnchor.constraint(equalTo: chartCard.bottomAnchor, constant: -16)
            ])
        } else {
            // Fallback for iOS < 16
            let fallbackLabel = UILabel()
            fallbackLabel.text = "Charts require iOS 16+"
            fallbackLabel.font = .systemFont(ofSize: 14)
            fallbackLabel.textColor = .secondaryLabel
            fallbackLabel.textAlignment = .center
            fallbackLabel.translatesAutoresizingMaskIntoConstraints = false
            chartCard.addSubview(chartTitleLabel)
            chartCard.addSubview(fallbackLabel)
            NSLayoutConstraint.activate([
                chartTitleLabel.topAnchor.constraint(equalTo: chartCard.topAnchor, constant: 16),
                chartTitleLabel.leadingAnchor.constraint(equalTo: chartCard.leadingAnchor, constant: 16),
                fallbackLabel.topAnchor.constraint(equalTo: chartTitleLabel.bottomAnchor, constant: 12),
                fallbackLabel.centerXAnchor.constraint(equalTo: chartCard.centerXAnchor),
                fallbackLabel.bottomAnchor.constraint(equalTo: chartCard.bottomAnchor, constant: -16)
            ])
        }
        contentStack.addArrangedSubview(chartCard)

        // — Progress & Trend card
        let trendCard = makeCard()
        let trendIcon = UIImageView(image: UIImage(systemName: "chart.line.uptrend.xyaxis"))
        trendIcon.tintColor = .systemBlue
        trendIcon.contentMode = .scaleAspectFit
        trendIcon.translatesAutoresizingMaskIntoConstraints = false
        trendIcon.widthAnchor.constraint(equalToConstant: 24).isActive = true
        trendIcon.heightAnchor.constraint(equalToConstant: 24).isActive = true

        let trendHeaderLabel = UILabel()
        trendHeaderLabel.text = "Progress & Trend"
        trendHeaderLabel.font = .systemFont(ofSize: 16, weight: .bold)
        trendHeaderLabel.textColor = .label

        let trendRow = UIStackView(arrangedSubviews: [trendIcon, trendHeaderLabel])
        trendRow.axis = .horizontal
        trendRow.spacing = 8
        trendRow.alignment = .center

        let trendDescLabel = UILabel()
        trendDescLabel.text = trendDescription(accuracy: accuracy, total: total, dataPoints: dataPoints)
        trendDescLabel.font = .systemFont(ofSize: 14)
        trendDescLabel.textColor = .secondaryLabel
        trendDescLabel.numberOfLines = 0

        let trendStack = UIStackView(arrangedSubviews: [trendRow, trendDescLabel])
        trendStack.axis = .vertical
        trendStack.spacing = 8
        trendStack.translatesAutoresizingMaskIntoConstraints = false

        trendCard.addSubview(trendStack)
        NSLayoutConstraint.activate([
            trendStack.topAnchor.constraint(equalTo: trendCard.topAnchor, constant: 16),
            trendStack.leadingAnchor.constraint(equalTo: trendCard.leadingAnchor, constant: 16),
            trendStack.trailingAnchor.constraint(equalTo: trendCard.trailingAnchor, constant: -16),
            trendStack.bottomAnchor.constraint(equalTo: trendCard.bottomAnchor, constant: -16)
        ])
        contentStack.addArrangedSubview(trendCard)
    }

    // MARK: - Helpers

    private func makeCard() -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        card.layer.cornerRadius = 16
        card.layer.masksToBounds = true
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        blur.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(blur)
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: card.topAnchor),
            blur.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        return card
    }

    private func accentColor(for accuracy: Double) -> UIColor {
        if total == 0 { return .systemGray }
        if accuracy >= 0.90 { return .systemGreen }
        if accuracy >= 0.60 { return .systemYellow }
        return .systemRed
    }

    private func swiftUIAccentColor(for accuracy: Double) -> Color {
        if total == 0 { return .gray }
        if accuracy >= 0.90 { return .green }
        if accuracy >= 0.60 { return .yellow }
        return .red
    }

    private func trendDescription(accuracy: Double, total: Int, dataPoints: [DailyAccuracyPoint]) -> String {
        if total == 0 {
            return "No attempts recorded yet. Start practicing to see your progress!"
        }
        if dataPoints.count < 2 {
            return "Early progress — keep practicing to build a stronger trend."
        }
        let recent = dataPoints.suffix(3).map { $0.accuracy }
        let older = dataPoints.prefix(dataPoints.count - 3).map { $0.accuracy }
        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let olderAvg = older.isEmpty ? recentAvg : older.reduce(0, +) / Double(older.count)
        let delta = recentAvg - olderAvg

        if delta > 0.05 {
            return String(format: "Great improvement! Your accuracy is trending up (+%.0f%% recently). Keep it up!", delta * 100)
        } else if delta < -0.05 {
            return String(format: "Accuracy dipped by %.0f%% recently. More practice will help solidify this item.", abs(delta) * 100)
        } else {
            return String(format: "Consistent performance at %.0f%%. Challenge yourself to push above 90%%!", accuracy * 100)
        }
    }

    // MARK: - Core Data Fetch

    private func fetchDailyAccuracy() -> [DailyAccuracyPoint] {
        guard let letter else { return [] }
        let ctx = PersistenceController.shared.container.viewContext
        let req: NSFetchRequest<Attempt> = Attempt.fetchRequest()
        req.predicate = NSPredicate(format: "letter == %@", letter)
        req.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        guard let attempts = try? ctx.fetch(req), !attempts.isEmpty else { return [] }

        let cal = Calendar.current
        let cutoff = cal.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let recent = attempts.filter { ($0.date ?? .distantPast) >= cutoff }

        var byDay: [Date: (correct: Int, total: Int)] = [:]
        for a in recent {
            let day = cal.startOfDay(for: a.date ?? Date())
            var entry = byDay[day] ?? (correct: 0, total: 0)
            entry.total += 1
            if a.correct { entry.correct += 1 }
            byDay[day] = entry
        }

        return byDay
            .sorted { $0.key < $1.key }
            .map { day, entry in
                DailyAccuracyPoint(
                    date: day,
                    accuracy: Double(entry.correct) / Double(entry.total),
                    total: entry.total
                )
            }
    }
}

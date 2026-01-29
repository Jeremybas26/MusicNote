//
//  ViewController.swift
//  MusicNote
//
//  Created by Jeremy Bastidas on 5/30/25.
//




import UIKit
import Combine
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

    /// Call once when app opens. Returns true if streak incremented today.
    @discardableResult
    func registerDailyOpen() -> Bool {
        let ud = UserDefaults.standard
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        var didIncrement = false

        if let last = ud.object(forKey: Key.last) as? Date {
            let diff = cal.dateComponents([.day], from: last, to: today).day ?? 0
            switch diff {
            case 0:
                return false   // already counted today
            case 1:
                let newStreak = ud.integer(forKey: Key.current) + 1
                ud.set(newStreak, forKey: Key.current)
                ud.set(max(newStreak, ud.integer(forKey: Key.longest)), forKey: Key.longest)
                didIncrement = true
            default:
                ud.set(1, forKey: Key.current)
                didIncrement = true
            }
        } else {
            ud.set(1, forKey: Key.current)
            didIncrement = true
        }

        ud.set(today, forKey: Key.last)
        return didIncrement
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



class ViewController: UIViewController {

    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Elements

    private let streakBadge: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.textAlignment = .center
        l.textColor = .systemOrange
        l.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.15)
        l.layer.cornerRadius = 14
        l.layer.masksToBounds = true
        l.text = "🔥 0"
        return l
    }()

    private let goProButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("⭐ Go Pro", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        b.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.25)
        b.setTitleColor(.label, for: .normal)
        b.layer.cornerRadius = 14
        b.layer.masksToBounds = true
        return b
    }()

    private let proBadge: UILabel = {
        let l = UILabel()
        l.text = "PRO"
        l.font = .systemFont(ofSize: 15, weight: .bold)
        l.textColor = UIColor.systemYellow
        l.textAlignment = .center
        l.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.18)
        l.layer.cornerRadius = 14
        l.layer.masksToBounds = true
        l.isHidden = true
        return l
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Add streak badge to view, top-left
        view.addSubview(streakBadge)
        streakBadge.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            streakBadge.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            streakBadge.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            streakBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            streakBadge.heightAnchor.constraint(equalToConstant: 28)
        ])

        view.addSubview(goProButton)
        goProButton.translatesAutoresizingMaskIntoConstraints = false
        goProButton.addTarget(self, action: #selector(goProTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            goProButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            goProButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            goProButton.heightAnchor.constraint(equalToConstant: 28),
            goProButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 90)
        ])

        view.addSubview(proBadge)
        proBadge.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            proBadge.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            proBadge.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            proBadge.heightAnchor.constraint(equalToConstant: 28),
            proBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])

        let didIncrement = DailyStreakManager.shared.registerDailyOpen()
        updateStreakBadge()
        updateProUI()

        // React to subscription state changes
        SubscriptionManager.shared.$isPro
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateProUI()
            }
            .store(in: &cancellables)

        if didIncrement {
            animateStreakPlusOne()
        }

        // SwiftUI glass buttons (Practice Notes, Practice Scales, Settings)
        let learnHost = UIHostingController(
            rootView: GlassMenuButton(title: "Practice Notes") { [weak self] in
                self?.openLearn()
            })
        let chordsHost = UIHostingController(
            rootView: GlassMenuButton(title: "Practice Chords") { [weak self] in
                let vc = ChordsViewController()
                vc.hidesBottomBarWhenPushed = true
                self?.navigationController?.pushViewController(vc, animated: true)
            }
        )
        let scalesHost = UIHostingController(
            rootView: GlassMenuButton(title: "Practice Scales") { [weak self] in
                self?.openScales()
            })
        let settingsHost = UIHostingController(
            rootView: GlassMenuButton(title: "Settings") { [weak self] in
                self?.openSettings()
            })

        let hosts = [learnHost, scalesHost, chordsHost, settingsHost]
        hosts.forEach { host in
            addChild(host)
            view.addSubview(host.view)
            host.view.translatesAutoresizingMaskIntoConstraints = false
            host.didMove(toParent: self)
        }

        // Constraints (vertical stack style)
        NSLayoutConstraint.activate([
            learnHost.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            learnHost.view.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        NSLayoutConstraint.activate([
            scalesHost.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scalesHost.view.topAnchor.constraint(equalTo: learnHost.view.bottomAnchor, constant: 24),
            // Allow button to size to text
            scalesHost.view.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            scalesHost.view.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
            scalesHost.view.heightAnchor.constraint(equalToConstant: 44)
        ])
        // Minimum width so text is always visible
        scalesHost.view.widthAnchor.constraint(greaterThanOrEqualToConstant: 200).isActive = true

        NSLayoutConstraint.activate([
            chordsHost.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            chordsHost.view.topAnchor.constraint(equalTo: scalesHost.view.bottomAnchor, constant: 24),
            chordsHost.view.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            chordsHost.view.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
            chordsHost.view.heightAnchor.constraint(equalToConstant: 44)
        ])
        chordsHost.view.widthAnchor.constraint(greaterThanOrEqualToConstant: 200).isActive = true

        // SwiftUI Stats button with native glass style (iOS 19+)
        let statsHost = UIHostingController(rootView: StatsGlassButton { [weak self] in
            self?.openStats()
        })
        addChild(statsHost)
        view.addSubview(statsHost.view)
        statsHost.view.translatesAutoresizingMaskIntoConstraints = false
        statsHost.didMove(toParent: self)

        NSLayoutConstraint.activate([
            // Stats directly under Chords
            statsHost.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statsHost.view.topAnchor.constraint(equalTo: chordsHost.view.bottomAnchor, constant: 24),
            statsHost.view.widthAnchor.constraint(equalToConstant: 160),
            statsHost.view.heightAnchor.constraint(equalToConstant: 44),

            // Settings under Stats
            settingsHost.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            settingsHost.view.topAnchor.constraint(equalTo: statsHost.view.bottomAnchor, constant: 24)
        ])
        // Do any additional setup after loading the view.
    }

    private func updateProUI() {
        let isPro = SubscriptionManager.shared.isPro
        goProButton.isHidden = isPro
        proBadge.isHidden = !isPro
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateProUI()
    }
    @objc private func goProTapped() {
        let vc = GoProViewController()
        vc.modalPresentationStyle = .formSheet
        present(vc, animated: true)
    }


    private func updateStreakBadge() {
        let streak = DailyStreakManager.shared.current
        streakBadge.text = "🔥 \(streak)"
    }

    private func animateStreakPlusOne() {
        let plus = UILabel()
        plus.text = "+1 🔥"
        plus.font = .systemFont(ofSize: 16, weight: .bold)
        plus.textColor = .systemOrange
        plus.alpha = 0
        plus.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)

        view.addSubview(plus)
        plus.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            plus.centerXAnchor.constraint(equalTo: streakBadge.centerXAnchor),
            plus.topAnchor.constraint(equalTo: streakBadge.bottomAnchor, constant: 4)
        ])

        UIView.animate(withDuration: 0.25, animations: {
            plus.alpha = 1
            plus.transform = .identity
        })

        UIView.animate(withDuration: 0.6, delay: 0.4, options: [.curveEaseOut], animations: {
            plus.alpha = 0
            plus.transform = CGAffineTransform(translationX: 0, y: -16)
        }, completion: { _ in
            plus.removeFromSuperview()
        })
    }
    @objc private func openScales() {
        let vc = PracticeScalesViewController()
        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }

    // MARK: - Navigation
    @objc private func openSettings() {
        let settingsVC = SettingsViewController()
        if let nav = navigationController {
            nav.pushViewController(settingsVC, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: settingsVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
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
        let statsVC = StatsViewController()
        if let nav = navigationController {
            nav.pushViewController(statsVC, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: statsVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
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
            var cfg = UIButton.Configuration.plain()
            cfg.cornerStyle = .capsule
            cfg.background.strokeColor = UIColor.white.withAlphaComponent(0.25)
            cfg.background.strokeWidth = 1
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



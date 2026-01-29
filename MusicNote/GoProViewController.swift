//
//  GoProViewController.swift
//  MusicNote
//
//  Created by Jeremy Bastidas on 1/8/26.
//


import UIKit

// MARK: - GoProButton

final class GoProButton: UIButton {

    private let titleLabelCustom: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18, weight: .semibold)
        l.textAlignment = .center
        l.textColor = .white
        l.isUserInteractionEnabled = false
        return l
    }()

    private let subtitleLabelCustom: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textAlignment = .center
        l.textColor = .white.withAlphaComponent(0.9)
        l.isUserInteractionEnabled = false
        return l
    }()

    init(title: String, subtitle: String) {
        super.init(frame: .zero)

        isUserInteractionEnabled = true
        backgroundColor = UIColor.systemBlue.withAlphaComponent(0.9)

        titleLabelCustom.text = title
        subtitleLabelCustom.text = subtitle

        let stack = UIStackView(arrangedSubviews: [
            titleLabelCustom,
            subtitleLabelCustom
        ])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isUserInteractionEnabled = false

        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            heightAnchor.constraint(equalToConstant: 50)
        ])

        layer.cornerRadius = 12
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted
                ? UIColor.systemBlue.withAlphaComponent(0.7)
                : UIColor.systemBlue.withAlphaComponent(0.9)
        }
    }
}

final class GoProViewController: UIViewController {

    // MARK: - UI

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "MusicNote Pro 🎶"
        l.font = .systemFont(ofSize: 28, weight: .bold)
        l.textAlignment = .center
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = """
        Unlock your full practice experience
        """
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.textAlignment = .center
        l.textColor = .secondaryLabel
        return l
    }()

    private let featuresLabel: UILabel = {
        let l = UILabel()
        l.text = """
        • No ads
        • Scale stats always visible
        • Chord stats always visible
        • Future piano mode included
        """
        l.font = .systemFont(ofSize: 17)
        l.numberOfLines = 0
        return l
    }()

    private let privacyURL = URL(string: "https://lace-reptile-120.notion.site/Music-Note-App-Support-Page-2be530bffe2a805cbf62c7cce91417ba")!
    private let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    private let legalLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.textAlignment = .center
        l.font = .systemFont(ofSize: 12)
        l.textColor = .secondaryLabel
        l.text = """
        Subscriptions auto-renew unless canceled at least 24 hours before the end of the current period.
        Manage subscriptions in iOS Settings.

        Privacy Policy | Terms of Use
        """
        l.isUserInteractionEnabled = true
        return l
    }()

    private let monthlyButton = GoProButton(
        title: "$2 / Month",
        subtitle: "Cancel anytime"
    )

    private let yearlyButton = GoProButton(
        title: "$20 / Year",
        subtitle: "Save over 15%"
    )

    private let restoreButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Restore Purchases", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 15)
        return b
    }()

    private let closeButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Close", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        return b
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        wireActions()

        monthlyButton.isEnabled = false
        yearlyButton.isEnabled = false

        Task {
            await SubscriptionManager.shared.loadProducts()
            print("🧪 Loaded products:", SubscriptionManager.shared.products.map { $0.id })

            let hasProducts = !SubscriptionManager.shared.products.isEmpty
            monthlyButton.isEnabled = hasProducts
            yearlyButton.isEnabled = hasProducts
        }
    }

    // MARK: - Setup

    private func setupUI() {
        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            subtitleLabel,
            featuresLabel,
            monthlyButton,
            yearlyButton,
            legalLabel,
            restoreButton,
            closeButton
        ])

        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func wireActions() {
        monthlyButton.addTarget(self, action: #selector(monthlyTapped), for: .touchUpInside)
        yearlyButton.addTarget(self, action: #selector(yearlyTapped), for: .touchUpInside)
        restoreButton.addTarget(self, action: #selector(restoreTapped), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(legalTapped))
        legalLabel.addGestureRecognizer(tap)
    }

    // MARK: - Actions

    @objc private func monthlyTapped() {
        attemptPurchase(productID: "com.BlankStudio.MusicNote")
    }

    @objc private func yearlyTapped() {
        attemptPurchase(productID: "com.BlankStudio.MusicNote.pro.yearly")
    }

    private func attemptPurchase(productID: String) {
        let products = SubscriptionManager.shared.products

        guard let product = products.first(where: { $0.id == productID }) else {
            let alert = UIAlertController(
                title: "Store not ready",
                message: "StoreKit products have not loaded yet.\n\nMake sure MusicNote.storekit is attached to the Run scheme and you are using the Simulator.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        Task {
            do {
                try await SubscriptionManager.shared.purchase(product)
                dismiss(animated: true)
            } catch {
                print("❌ Purchase failed:", error)
            }
        }
    }

    @objc private func restoreTapped() {
        Task {
            await SubscriptionManager.shared.restore()
        }
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func legalTapped() {
        let ac = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        ac.addAction(UIAlertAction(title: "Privacy Policy", style: .default) { _ in
            UIApplication.shared.open(self.privacyURL)
        })

        ac.addAction(UIAlertAction(title: "Terms of Use", style: .default) { _ in
            UIApplication.shared.open(self.termsURL)
        })

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}

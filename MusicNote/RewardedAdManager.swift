import GoogleMobileAds
import UIKit

final class RewardedAdManager: NSObject {
    static let shared = RewardedAdManager()
    private override init() {}

    private var rewardedAd: RewardedAd?
    private let adUnitID = "ca-app-pub-6461295911157308/9428730970"

    func load() {
        RewardedAd.load(with: adUnitID, request: Request()) { [weak self] ad, error in
            if let error = error {
                print("❌ Rewarded load failed:", error.localizedDescription)
                self?.rewardedAd = nil
                return
            }
            self?.rewardedAd = ad
            print("✅ Rewarded loaded")
        }
    }

    @MainActor
    func show(from vc: UIViewController, onReward: @escaping () -> Void, onFail: (() -> Void)? = nil) {
        if SubscriptionManager.shared.isPro {
            onReward()
            return
        }

        guard let ad = rewardedAd else {
            onFail?()
            load()
            return
        }

        ad.present(from: vc) {
            onReward()
        }

        // preload next
        rewardedAd = nil
        load()
    }
}

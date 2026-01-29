//
//  GameCenterManager.swift
//  MusicNote
//
//  Created by Jeremy Bastidas on 6/16/25.
//

import GameKit
import UIKit

/// Central wrapper for Game Center auth, score reporting, and UI.
final class GameCenterManager: NSObject, GKGameCenterControllerDelegate {
    
    static let shared = GameCenterManager()
    private override init() {}
    
    // MARK: - Authentication
    
    /// Presents the Game Center login flow if the player is not yet authenticated.
    func authenticate(from presenter: UIViewController) {
        GKLocalPlayer.local.authenticateHandler = { vc, error in
            if let vc {
                presenter.present(vc, animated: true)
            } else if let error {
                print("Game Center auth error:", error.localizedDescription)
            }
        }
    }
    
    // MARK: - Score Reporting
    
    /// Reports a `score` to the 30‑s or 60‑s speed‑run leaderboard.
    func report(score: Int, duration: Int) {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        let id = duration == 30 ? "com.musicnote.speedrun30"
                                : "com.musicnote.speedrun60"
        let gk = GKScore(leaderboardIdentifier: id)
        gk.value = Int64(score)
        GKScore.report([gk]) { error in
            if let error {
                print("Game Center report error:", error.localizedDescription)
            }
        }
    }
    
    // MARK: - Leaderboard UI
    
    func showLeaderboard(from presenter: UIViewController) {
        guard GKLocalPlayer.local.isAuthenticated else {
            authenticate(from: presenter)
            return
        }
        let gcVC = GKGameCenterViewController()
        gcVC.leaderboardIdentifier = "com.musicnote.speedrun30"
        gcVC.gameCenterDelegate = self
        presenter.present(gcVC, animated: true)
    }
    
    // MARK: - GKGameCenterControllerDelegate
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}

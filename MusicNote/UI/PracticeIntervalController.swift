//
//  PracticeIntervalController.swift
//  MusicNote
//
//  Created by Jeremy Bastidas on 1/13/26.
//

import Foundation

final class PracticeIntervalController {

    private var timer: Timer?
    private(set) var interval: TimeInterval = 10
    private let onFire: () -> Void

    init(onFire: @escaping () -> Void) {
        self.onFire = onFire
    }

    func start(interval: TimeInterval) {
        stop()
        self.interval = interval

        timer = Timer.scheduledTimer(
            withTimeInterval: interval,
            repeats: true
        ) { [weak self] _ in
            self?.onFire()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    var isRunning: Bool {
        timer != nil
    }
}

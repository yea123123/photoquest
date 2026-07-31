import Combine
import Foundation
import SwiftUI

/// «Фото-Рулетка»: крути барабан — выпадет предмет, на поиск и съёмку
/// которого даётся 45 секунд. Успех — +30 очков.
@MainActor
final class RouletteViewModel: ObservableObject {

    let timeLimit = 45

    /// 8 ключей на барабане (виден, пока идёт вращение).
    @Published private(set) var segments: [String] = []
    /// Текущий угол поворота барабана (градусы).
    @Published private(set) var rotation = 0.0
    @Published private(set) var spinning = false
    /// Цель, выпавшая на барабане (пустая, пока не выпала).
    @Published private(set) var targetKey = ""
    @Published private(set) var timeLeft = 45
    @Published private(set) var wins = 0
    /// Последняя награда (для всплывающей надписи «+30»).
    @Published private(set) var lastReward = 0

    private var timerTask: Task<Void, Never>?

    var targetKeywords: [String] {
        QuestKeywords.keywords(for: targetKey)
    }

    var canSpin: Bool {
        !spinning && targetKey.isEmpty
    }

    /// Крутим барабан: анимация 1.4 с, цель — сегмент, остановившийся у стрелки.
    func spin() {
        guard canSpin else { return }
        spinning = true
        targetKey = ""
        lastReward = 0
        segments = Array(QuestKeywords.all.keys.shuffled().prefix(8))

        let target = Int.random(in: 0..<8)
        let jitter = Double.random(in: -12...12)
        let targetAngle = ((360 - Double(target) * 45).truncatingRemainder(dividingBy: 360) + jitter)
        let currentNorm = rotation.truncatingRemainder(dividingBy: 360)
        var delta = 360.0 * 5 + (targetAngle - currentNorm)
        if delta < 0 { delta += 360 }

        withAnimation(.easeOut(duration: 1.4)) {
            rotation += delta
        }
        Task {
            try? await Task.sleep(nanoseconds: 1_450_000_000)
            guard spinning else { return }
            targetKey = segments[target]
            spinning = false
            startTimer()
        }
    }

    /// Фото засчитано: +30 очков, барабан снова можно крутить.
    func didCompleteShot() {
        guard !targetKey.isEmpty else { return }
        timerTask?.cancel()
        timerTask = nil
        wins += 1
        lastReward = 30
        GameStats.shared.addPoints(30)
        targetKey = ""
    }

    /// Время вышло: цель пропадает, барабан можно крутить заново.
    func timeout() {
        timerTask?.cancel()
        timerTask = nil
        targetKey = ""
    }

    private func startTimer() {
        timerTask?.cancel()
        timeLeft = timeLimit
        timerTask = Task {
            while !Task.isCancelled && timeLeft > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                timeLeft -= 1
                if timeLeft <= 0 {
                    timeout()
                }
            }
        }
    }
}

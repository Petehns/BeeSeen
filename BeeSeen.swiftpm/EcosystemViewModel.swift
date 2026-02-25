import SwiftUI
import UIKit

// MARK: - ViewModel

@MainActor
final class EcosystemViewModel: ObservableObject {

    // MARK: - Ecosystem Metrics

    @Published var beePopulation: Double = 1.0
    @Published var flowerHealth: Double  = 1.0
    @Published var biodiversity: Double  = 1.0
    @Published var pesticideLevel: Double = 0.0
    @Published var phase: EcosystemPhase = .abundance

    // MARK: - Visual Entities

    @Published var bees: [BeeEntity]            = []
    @Published var flowers: [FlowerEntity]       = []
    @Published var pollenParticles: [PollenParticle] = []
    @Published var beePollenParticles: [BeePollenParticle] = []
    @Published var pesticideClouds: [PesticideCloud] = []
    @Published var plantedFlowers: [PlantedFlower]   = []
    @Published var habitatBlocks: [HabitatBlock]     = []
    @Published var placedHabitatCount: Int = 0
    @Published var balanceRestored: Bool   = false

    // MARK: - UI State

    @Published var isPaused: Bool       = false
    @Published var showHint: Bool       = false
    @Published var phaseCompleted: Bool = false
    /// Index 0–3 = challenges 1–4; 4 = synthesis (Phase Final). Left panel only.
    @Published var currentChallengeIndex: Int = 0
    /// Simulation speed: 1, 2, or 3 (1x, 2x, 3x).
    @Published var timeSpeedMultiplier: Int = 1

    var hintText: String {
        switch phase {
        case .abundance:
            return "Observe the system in balance. Bees, pollen, and flowers are deeply interconnected. In 20 seconds, something will change."
        case .decline:
            return "Watch how rising pesticide levels drag bee populations down — and how falling bees accelerate flower loss. Nothing collapses alone."
        case .recovery:
            return "Tap gray clouds to cut pesticides. Tap empty areas to plant flowers and raise biodiversity. Drag brown blocks to the Habitat Zone to unlock a 1.7× recovery boost."
        }
    }

    func togglePause() {
        isPaused.toggle()
        triggerHaptic(style: .light)
    }

    func toggleHint() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            showHint.toggle()
        }
    }

    /// Cycles time speed: 1x → 2x → 3x → 1x.
    func cycleTimeSpeed() {
        timeSpeedMultiplier = (timeSpeedMultiplier % 3) + 1
        triggerHaptic(style: .light)
    }

    // MARK: - Internal

    private let dt: Double = 0.05
    private var phaseElapsed: Double = 0.0
    private var timerTask: Task<Void, Never>?

    // MARK: - Lifecycle

    func start() {
        initPhase1()
        startLoop()
    }

    // MARK: - Update Loop

    private func startLoop() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 50_000_000) // ~20 fps base
                guard let self else { return }
                let mult = self.timeSpeedMultiplier
                for _ in 0..<mult {
                    self.tick()
                }
            }
        }
    }

    private func tick() {
        guard !isPaused else { return }
        phaseElapsed += dt
        switch phase {
        case .abundance: tickAbundance()
        case .decline:   tickDecline()
        case .recovery:  tickRecovery()
        }
    }

    // MARK: - Phase 1: Abundance

    private func initPhase1() {
        beePopulation  = 1.0
        flowerHealth   = 1.0
        biodiversity   = 1.0
        pesticideLevel = 0.0
        phase          = .abundance
        phaseElapsed   = 0.0
        balanceRestored  = false
        phaseCompleted   = false

        bees            = (0..<20).map { _ in BeeEntity() }
        flowers         = (0..<16).map { _ in FlowerEntity() }
        pollenParticles = (0..<32).map { _ in PollenParticle() }
        pesticideClouds = []
        plantedFlowers  = []
        habitatBlocks   = []
        placedHabitatCount = 0

        // Assign each bee an initial flower target
        for i in bees.indices { assignNewTarget(beeIndex: i) }
    }

    private func tickAbundance() {
        moveBees()
        movePollen()
        moveBeePollen()

        if phaseElapsed >= 20.0 && !phaseCompleted {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                phaseCompleted = true
            }
            triggerHaptic(style: .light)
        }
    }

    // MARK: - Phase 2: Decline

    private func tickDecline() {
        pesticideLevel = min(1.0, pesticideLevel + dt * 0.018)

        let pesticideDamage = pesticideLevel * 0.016
        beePopulation = max(0.0, beePopulation - pesticideDamage * dt)

        if beePopulation < 0.3 {
            let flowerDecay = (0.3 - beePopulation) * 0.022
            flowerHealth = max(0.0, flowerHealth - flowerDecay * dt)
        }

        biodiversity = max(0.0, biodiversity - dt * 0.008)

        moveBees()
        movePollen()
        moveBeePollen()

        if beePopulation < 0.2 && !phaseCompleted {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                phaseCompleted = true
            }
            triggerHaptic(style: .light)
        }
    }

    // MARK: - Phase 3: Recovery

    private func initPhase3() {
        phase = .recovery
        pesticideClouds = (0..<7).map { _ in PesticideCloud() }
        habitatBlocks   = (0..<5).map { i in
            HabitatBlock(posX: 0.88, posY: 0.18 + Double(i) * 0.13)
        }
        plantedFlowers     = []
        placedHabitatCount = 0
        balanceRestored    = false
        phaseCompleted     = false
        currentChallengeIndex = 0

        // Re-assign targets so bees head toward remaining flowers
        for i in bees.indices { assignNewTarget(beeIndex: i) }
    }

    /// Advances to the next interactive challenge (left panel). 0→1→2→3→4 (synthesis).
    func advanceToNextChallenge() {
        currentChallengeIndex = min(4, currentChallengeIndex + 1)
        triggerHaptic(style: .light)
    }

    // MARK: - Phase Navigation

    /// Advances to the next phase (or restarts from the beginning).
    func advancePhase() {
        showHint       = false
        phaseCompleted = false

        withAnimation(.easeInOut(duration: 1.2)) {
            switch phase {
            case .abundance:
                phase        = .decline
                phaseElapsed = 0.0
            case .decline:
                initPhase3()
            case .recovery:
                initPhase1()
            }
        }
        triggerHaptic(style: .medium)
    }

    /// Goes back to the previous phase when possible.
    func goToPreviousPhase() {
        guard phase != .abundance else { return }
        showHint       = false
        phaseCompleted = false

        withAnimation(.easeInOut(duration: 1.2)) {
            switch phase {
            case .abundance:
                break
            case .decline:
                phase = .abundance
                phaseElapsed = 0.0
            case .recovery:
                phase = .decline
                phaseElapsed = 0.0
            }
        }
        triggerHaptic(style: .medium)
    }

    var hasPreviousPhase: Bool { phase != .abundance }

    private func tickRecovery() {
        let habitatBonus  = placedHabitatCount >= 3 ? 1.7 : 1.0
        let recoveryRate  = (1.0 - pesticideLevel) * biodiversity * habitatBonus * 0.009
        let decayRate     = pesticideLevel * 0.012
        let netRate       = recoveryRate - decayRate

        beePopulation = (beePopulation + netRate * dt).clamped(to: 0...1)

        if beePopulation > 0.25 {
            flowerHealth = min(1.0, flowerHealth + dt * 0.006 * beePopulation)
        }

        moveBees()
        movePesticideClouds()
        moveBeePollen()

        if beePopulation >= 0.8 && !balanceRestored {
            withAnimation(.easeInOut(duration: 1.2)) {
                balanceRestored = true
                phaseCompleted  = true
            }
            triggerHaptic(style: .medium)
        }
    }

    // MARK: - Entity Movement

    private func moveBees() {
        let maxSpeed      = 0.008   // normalized units per tick
        let steerStrength = 0.10    // how sharply bees turn toward target
        let arrivalRadius = 0.04    // distance at which bee "lands" on flower

        for i in bees.indices {

            // ── Pollinating (hovering at flower) ──────────────────────────
            if bees[i].isPollinating {
                bees[i].pollinatingTimer -= dt
                if bees[i].pollinatingTimer <= 0 {
                    // Leaving the flower: start a delayed pollen trail window
                    // 1s delay + 3s emission = 4s total window
                    bees[i].pollenTrailTime = 4.0
                    bees[i].isPollinating = false
                    assignNewTarget(beeIndex: i)
                }
                // Stay in place — no position update while hovering
                continue
            }

            // ── Post-flower pollen trail (starts 1s after leaving) ────────
            if bees[i].pollenTrailTime > 0 {
                bees[i].pollenTrailTime -= dt
                let elapsedSinceLeave = 4.0 - bees[i].pollenTrailTime

                if elapsedSinceLeave >= 1.0 {
                    // Emit a few tiny particles randomly during the 3s window
                    // Lower probability to avoid overdraw / performance issues.
                    if Double.random(in: 0...1) < 0.18 {
                        emitBeePollen(at: bees[i].posX, y: bees[i].posY)
                    }
                }
            }

            // ── Flying toward target flower ────────────────────────────────
            let dx   = bees[i].targetPosX - bees[i].posX
            let dy   = bees[i].targetPosY - bees[i].posY
            let dist = sqrt(dx * dx + dy * dy)

            if dist < arrivalRadius {
                // Arrived — begin pollination pause
                bees[i].isPollinating    = true
                bees[i].pollinatingTimer = Double.random(in: 1.5...3.5)
                bees[i].velX = 0
                bees[i].velY = 0
            } else {
                // Slow down smoothly as the bee approaches
                let approach  = dist < 0.12 ? dist / 0.12 : 1.0
                let speed     = maxSpeed * approach
                let desiredVX = (dx / dist) * speed
                let desiredVY = (dy / dist) * speed

                // Steering: blend current velocity toward desired
                bees[i].velX += (desiredVX - bees[i].velX) * steerStrength
                bees[i].velY += (desiredVY - bees[i].velY) * steerStrength

                // Tiny jitter for organic, wing-beat feel
                bees[i].velX += Double.random(in: -0.00012...0.00012)
                bees[i].velY += Double.random(in: -0.00012...0.00012)

                bees[i].velX = bees[i].velX.clamped(to: -maxSpeed...maxSpeed)
                bees[i].velY = bees[i].velY.clamped(to: -maxSpeed...maxSpeed)

                bees[i].posX += bees[i].velX
                bees[i].posY += bees[i].velY

                // Soft boundary push (avoids bees getting stuck on edges)
                if bees[i].posX < 0.03 { bees[i].velX += 0.001 }
                if bees[i].posX > 0.97 { bees[i].velX -= 0.001 }
                if bees[i].posY < 0.03 { bees[i].velY += 0.001 }
                if bees[i].posY > 0.97 { bees[i].velY -= 0.001 }

                bees[i].posX = bees[i].posX.clamped(to: 0.0...1.0)
                bees[i].posY = bees[i].posY.clamped(to: 0.0...1.0)
            }
        }
    }

    /// Picks a random flower (original or planted) and sets it as the bee's next target.
    private func assignNewTarget(beeIndex: Int) {
        var targets: [(Double, Double)] = flowers.map { ($0.posX, $0.posY) }
        if phase == .recovery {
            targets += plantedFlowers.map { ($0.posX, $0.posY) }
        }

        if let target = targets.randomElement() {
            bees[beeIndex].targetPosX = target.0
            bees[beeIndex].targetPosY = target.1
        } else {
            // No flowers available — wander to a random point
            bees[beeIndex].targetPosX = Double.random(in: 0.1...0.9)
            bees[beeIndex].targetPosY = Double.random(in: 0.1...0.9)
        }
    }

    private func movePollen() {
        for i in pollenParticles.indices {
            pollenParticles[i].posX += pollenParticles[i].velX
            pollenParticles[i].posY += pollenParticles[i].velY
            if pollenParticles[i].posY < -0.02
                || pollenParticles[i].posX < -0.05
                || pollenParticles[i].posX > 1.05 {
                pollenParticles[i].posY = 1.05
                pollenParticles[i].posX = Double.random(in: 0...1)
            }
        }
    }

    private func moveBeePollen() {
        guard !beePollenParticles.isEmpty else { return }

        for i in beePollenParticles.indices {
            beePollenParticles[i].life -= dt
            beePollenParticles[i].posX += beePollenParticles[i].velX
            beePollenParticles[i].posY += beePollenParticles[i].velY
        }

        beePollenParticles.removeAll { $0.life <= 0 }
    }

    private func emitBeePollen(at x: Double, y: Double) {
        // Hard cap to prevent runaway particle counts (keeps UI smooth)
        if beePollenParticles.count > 700 { return }

        // Emit a small cloud of particles from beneath the bee
        let count = Int.random(in: 3...6)
        let newParticles = (0..<count).map { _ in
            BeePollenParticle(originX: x, originY: y)
        }
        beePollenParticles.append(contentsOf: newParticles)
    }

    private func movePesticideClouds() {
        for i in pesticideClouds.indices {
            pesticideClouds[i].posX += pesticideClouds[i].velX
            pesticideClouds[i].posY += pesticideClouds[i].velY
            if pesticideClouds[i].posX < 0.05 || pesticideClouds[i].posX > 0.92 {
                pesticideClouds[i].velX *= -1
            }
            if pesticideClouds[i].posY < 0.05 || pesticideClouds[i].posY > 0.75 {
                pesticideClouds[i].velY *= -1
            }
        }
    }

    // MARK: - User Actions (Phase 3)

    func removePesticideCloud(id: UUID) {
        withAnimation(.easeOut(duration: 0.35)) {
            pesticideClouds.removeAll { $0.id == id }
        }
        pesticideLevel = max(0.0, pesticideLevel - 0.14)
        triggerHaptic(style: .light)
    }

    func plantFlower(posX: Double, posY: Double) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            plantedFlowers.append(PlantedFlower(posX: posX, posY: posY))
        }
        biodiversity = min(1.0, biodiversity + 0.06)
        triggerHaptic(style: .light)
    }

    func placeHabitatBlock(id: UUID) {
        guard let idx = habitatBlocks.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(.spring(response: 0.4)) {
            habitatBlocks[idx].isPlaced = true
        }
        placedHabitatCount = habitatBlocks.filter(\.isPlaced).count
        triggerHaptic(style: .medium)
    }

    // MARK: - Helpers

    private func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let gen = UIImpactFeedbackGenerator(style: style)
        gen.impactOccurred()
    }
}

// MARK: - Double Helpers

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.max(range.lowerBound, Swift.min(range.upperBound, self))
    }

    func wrapped(in range: ClosedRange<Double>) -> Double {
        let span = range.upperBound - range.lowerBound
        var v = self
        if v < range.lowerBound { v += span }
        if v > range.upperBound { v -= span }
        return v
    }
}

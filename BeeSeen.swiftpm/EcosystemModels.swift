import Foundation

// MARK: - Phase

enum EcosystemPhase: Equatable {
    case abundance
    case decline
    case recovery
}

// MARK: - Bee

struct BeeEntity: Identifiable, Sendable {
    let id: UUID = UUID()
    var posX: Double
    var posY: Double
    var velX: Double
    var velY: Double
    let size: Double

    // Pollination behaviour
    var targetPosX: Double
    var targetPosY: Double
    var isPollinating: Bool
    var pollinatingTimer: Double  // seconds remaining at current flower
    var pollenTrailTime: Double   // seconds remaining for post-flower pollen emission

    init() {
        posX = Double.random(in: 0.05...0.95)
        posY = Double.random(in: 0.05...0.95)
        velX = 0
        velY = 0
        size = Double.random(in: 9...15)
        // Temporary target — overwritten right after array creation
        targetPosX = Double.random(in: 0.05...0.95)
        targetPosY = Double.random(in: 0.05...0.95)
        isPollinating   = false
        pollinatingTimer = 0
        pollenTrailTime  = 0
    }
}

// MARK: - Flower

struct FlowerEntity: Identifiable, Sendable {
    let id: UUID = UUID()
    let posX: Double
    let posY: Double
    let size: Double

    init() {
        posX = Double.random(in: 0.05...0.92)
        posY = Double.random(in: 0.05...0.88)
        size = Double.random(in: 16...28)
    }
}

// MARK: - Pollen

struct PollenParticle: Identifiable, Sendable {
    let id: UUID = UUID()
    var posX: Double
    var posY: Double
    let velX: Double
    let velY: Double
    let opacity: Double
    let size: Double

    init() {
        posX = Double.random(in: 0...1)
        posY = Double.random(in: 0...1)
        velX = Double.random(in: -0.0008...0.0008)
        velY = Double.random(in: -0.0025...(-0.0006))
        opacity = Double.random(in: 0.25...0.65)
        size = Double.random(in: 3...7)
    }
}

// MARK: - Bee Pollen Burst

/// Extremely small, short–lived particles emitted when a bee leaves a flower.
struct BeePollenParticle: Identifiable, Sendable {
    let id: UUID = UUID()
    var posX: Double
    var posY: Double
    var velX: Double
    var velY: Double
    var life: Double
    let size: Double
    let opacity: Double

    init(originX: Double, originY: Double) {
        // Start just below the bee
        posX = originX + Double.random(in: -0.01...0.01)
        posY = originY + Double.random(in: 0.01...0.03)
        velX = Double.random(in: -0.0006...0.0006)
        velY = Double.random(in: 0.0002...0.0012)
        // Each particle lives a bit less than the 3s emission window,
        // so the cloud feels continuous but fades naturally.
        life = Double.random(in: 1.4...2.6)
        size = Double.random(in: 0.7...1.6)
        opacity = Double.random(in: 0.65...0.95)
    }
}

// MARK: - Pesticide Cloud

struct PesticideCloud: Identifiable, Sendable {
    let id: UUID = UUID()
    var posX: Double
    var posY: Double
    var velX: Double
    var velY: Double
    let width: Double
    let height: Double

    init() {
        posX = Double.random(in: 0.1...0.85)
        posY = Double.random(in: 0.08...0.68)
        velX = Double.random(in: -0.0008...0.0008)
        velY = Double.random(in: -0.0005...0.0005)
        width = Double.random(in: 72...112)
        height = Double.random(in: 36...56)
    }
}

// MARK: - Planted Flower

struct PlantedFlower: Identifiable, Sendable {
    let id: UUID = UUID()
    let posX: Double
    let posY: Double
    let size: Double

    init(posX: Double, posY: Double) {
        self.posX = posX
        self.posY = posY
        size = Double.random(in: 18...26)
    }
}

// MARK: - Habitat Block

struct HabitatBlock: Identifiable, Sendable {
    let id: UUID = UUID()
    let posX: Double
    let posY: Double
    var isPlaced: Bool = false

    init(posX: Double, posY: Double) {
        self.posX = posX
        self.posY = posY
    }
}

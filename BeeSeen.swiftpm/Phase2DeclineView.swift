import SwiftUI

// MARK: - Phase 2: Decline

struct Phase2DeclineView: View {
    @ObservedObject var vm: EcosystemViewModel

    private var visibleBeeCount: Int {
        max(1, Int(vm.beePopulation * Double(vm.bees.count)))
    }

    private var visiblePollenCount: Int {
        max(0, Int(vm.beePopulation * Double(vm.pollenParticles.count)))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Tree decaying with falling bee population
//                TreeFirstView(beePopulation: vm.beePopulation)
//                    .frame(width: 400)
//                    .position(
//                        x: geo.size.width * 0.16,
//                        y: geo.size.height * 0.54
//                    )
//                    .allowsHitTesting(false)
//                
//                TreeSecondView(beePopulation: vm.beePopulation)
//                    .frame(width: 300)
//                    .position(
//                        x: geo.size.width * 0.58,
//                        y: geo.size.height * 0.64
//                    )
//                    .allowsHitTesting(false)


                // Fading background pollen — fewer as bees decline
                ForEach(vm.pollenParticles.prefix(visiblePollenCount)) { pollen in
                    Circle()
                        .fill(
                            Color(hue: 0.11, saturation: 0.9, brightness: 1.0)
                                .opacity(pollen.opacity * vm.beePopulation)
                        )
                        .frame(width: pollen.size, height: pollen.size)
                        .position(
                            x: pollen.posX * geo.size.width,
                            y: pollen.posY * geo.size.height
                        )
                        .allowsHitTesting(false)
                }

                // Tiny pollen burst emitted from bees after leaving flowers
                ForEach(vm.beePollenParticles) { particle in
                    Circle()
                        .fill(
                            Color(hue: 0.14, saturation: 0.98, brightness: 1.0)
                                .opacity(particle.opacity)
                        )
                        .frame(width: particle.size, height: particle.size)
                        .position(
                            x: particle.posX * geo.size.width,
                            y: particle.posY * geo.size.height
                        )
                        .allowsHitTesting(false)
                }

                // Shrinking, desaturating flowers
                ForEach(vm.flowers) { flower in
                    let scale = 0.2 + vm.flowerHealth * 0.8
                    Circle()
                        .fill(Color.green.opacity(0.7 * vm.flowerHealth))
                        .frame(
                            width:  flower.size * scale,
                            height: flower.size * scale
                        )
                        .position(
                            x: flower.posX * geo.size.width,
                            y: flower.posY * geo.size.height
                        )
                        .animation(.easeInOut(duration: 1.2), value: vm.flowerHealth)
                        .allowsHitTesting(false)
                }

                // Disappearing bees — fewer and dimmer
                ForEach(vm.bees.prefix(visibleBeeCount)) { bee in
                    BeeShape(size: bee.size)
                        .scaleEffect(x: bee.velX < 0 ? -1 : 1, y: 1)
                        .scaleEffect(bee.isPollinating ? 1.25 : 1.0)
                        .animation(.easeInOut(duration: 0.35), value: bee.isPollinating)
                        .position(
                            x: bee.posX * geo.size.width,
                            y: bee.posY * geo.size.height
                        )
                        .opacity(0.45 + vm.beePopulation * 0.55)
                        .allowsHitTesting(false)
                }

                // Status panel
                VStack {
                    Spacer()
                    VStack(spacing: 14) {
                        Text("Pesticides are spreading…")
                            .font(.system(size: 14, weight: .thin, design: .serif))
                            .foregroundColor(.white.opacity(0.48))

                        VStack(spacing: 8) {
                            EcosystemBar(
                                label: "Bees",
                                value: vm.beePopulation,
                                color: Color(hue: 0.13, saturation: 0.9, brightness: 0.9)
                            )
                            EcosystemBar(
                                label: "Flowers",
                                value: vm.flowerHealth,
                                color: .green
                            )
                            EcosystemBar(
                                label: "Diversity",
                                value: vm.biodiversity,
                                color: .teal
                            )
                            EcosystemBar(
                                label: "Pesticides",
                                value: vm.pesticideLevel,
                                color: Color(white: 0.6)
                            )
                        }
                        .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 46)
                }
                .allowsHitTesting(false)
            }
        }
    }
}

// MARK: - Ecosystem Bar (shared with Phase 3)

struct EcosystemBar: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 10, weight: .light))
                .foregroundColor(.white.opacity(0.55))
                .frame(width: 62, alignment: .trailing)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(0.75))
                        .frame(width: geo.size.width * max(0, min(1, value)))
                        .animation(.easeInOut(duration: 0.6), value: value)
                }
            }
            .frame(height: 6)
        }
    }
}

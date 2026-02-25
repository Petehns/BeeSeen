import SwiftUI

// MARK: - Phase 1: Abundance

struct Phase1AbundanceView: View {
    @ObservedObject var vm: EcosystemViewModel

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Tree reacting to bee population (healthy in Phase 1)
//                TreeFirstView(beePopulation: vm.beePopulation)
//                    .frame(width: 400)
//                    .position(
//                        x: geo.size.width * 0.16,
//                        y: geo.size.height * 0.54
//                    )
//                    .allowsHitTesting(false)
//                
//                
//                TreeSecondView(beePopulation: vm.beePopulation)
//                    .frame(width: 300)
//                    .position(
//                        x: geo.size.width * 0.58,
//                        y: geo.size.height * 0.64
//                    )
//                    .allowsHitTesting(false)

                // Background pollen particles — drift upward
                ForEach(vm.pollenParticles) { pollen in
                    Circle()
                        .fill(
                            Color(hue: 0.11, saturation: 0.9, brightness: 1.0)
                                .opacity(pollen.opacity)
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
                            // acompanha a mesma faixa inferior usada para as flores
                            y: geo.size.height * (0.78 + particle.posY * 0.18)
                        )
                        .allowsHitTesting(false)
                }

                // Flowers — gentle pulse
                ForEach(vm.flowers) { flower in
                    PulsingFlower(size: flower.size)
                        .position(
                            x: flower.posX * geo.size.width,
                            // comprime todas as flores na faixa de baixo
                            y: geo.size.height * (0.78 + flower.posY * 0.18)
                        )
                        .allowsHitTesting(false)
                }

                // Bees — fly between flowers to simulate pollination
                ForEach(vm.bees) { bee in
                    BeeShape(size: bee.size)
                        .scaleEffect(x: bee.velX < 0 ? -1 : 1, y: 1)
                        .scaleEffect(bee.isPollinating ? 1.25 : 1.0)
                        .animation(.easeInOut(duration: 0.35), value: bee.isPollinating)
                        .position(
                            x: bee.posX * geo.size.width,
                            // usa a mesma transformação vertical das flores,
                            // garantindo que as abelhas "pousem" exatamente nelas
                            y: geo.size.height * (0.78 + bee.posY * 0.18)
                        )
                        .allowsHitTesting(false)
                }

                // Narrative label
                VStack {
                    Spacer()
                    Text("A thriving ecosystem.")
                        .font(.system(size: 15, weight: .thin, design: .serif))
                        .foregroundColor(.white.opacity(0.42))
                        .padding(.bottom, 46)
                }
                .allowsHitTesting(false)
            }
        }
    }
}

// MARK: - Shared Components (used across phases)

/// Healthy flower rendered with the Flower asset, gently pulsing.
struct PulsingFlower: View {
    let size: Double

    @State private var isExpanded = false
    @State private var duration: Double = 2.0

    var body: some View {
        Image("Flower")
            .resizable()
            .scaledToFit()
            .frame(width: 80, height: 80)
            .scaleEffect(isExpanded ? 1.12 : 0.93)
            .onAppear {
                duration = Double.random(in: 1.6...2.8)
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    isExpanded = true
                }
            }
    }
}

/// Bee rendered by swapping between BeeFirst and BeeSecond (wing flap).
struct BeeShape: View {
    let size: Double

    @State private var useSecondFrame = false

    var body: some View {
        Image(useSecondFrame ? "BeeSecond" : "BeeFirst")
            .resizable()
            .scaledToFit()
            .frame(width: 50, height: 30)
            .onReceive(
                Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
            ) { _ in
                // Sem animação/transição — troca seca de frame
                useSecondFrame.toggle()
            }
    }
}

/// Tree that visually decays as beePopulation falls (TreeFirst1 → TreeFirst5).
struct TreeFirstView: View {
    let beePopulation: Double

    private var imageName: String {
        switch beePopulation {
        case ..<0.2:
            return "TreeFirst5"
        case ..<0.4:
            return "TreeFirst4"
        case ..<0.6:
            return "TreeFirst3"
        case ..<0.8:
            return "TreeFirst2"
        default:
            return "TreeFirst1"
        }
    }

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
    }
}


struct TreeSecondView: View {
    let beePopulation: Double

    private var imageName: String {
        switch beePopulation {
        case ..<0.2:
            return "TreeSecond5"
        case ..<0.4:
            return "TreeSecond4"
        case ..<0.6:
            return "TreeSecond3"
        case ..<0.8:
            return "TreeSecond2"
        default:
            return "TreeSecond1"
        }
    }

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
    }
}

struct BackgroundView: View {
    let beePopulation: Double

    private var imageName: String {
        switch beePopulation {
        case ..<0.2:
            return "Background5"
        case ..<0.4:
            return "Background4"
        case ..<0.6:
            return "Background3"
        case ..<0.8:
            return "Background2"
        default:
            return "Background1"
        }
    }

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
    }
}

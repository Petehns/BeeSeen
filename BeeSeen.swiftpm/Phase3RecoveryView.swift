import SwiftUI

// MARK: - Phase 3: Recovery

struct Phase3RecoveryView: View {
    @ObservedObject var vm: EcosystemViewModel

    @State private var draggingId: UUID?    = nil
    @State private var dragPosition: CGPoint = .zero

    var body: some View {
        GeometryReader { geo in
            let zone = habitatZone(in: geo.size)

            ZStack {
                // Tree recovering as bee population rises again
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


                // ── Tap-to-plant background ───────────────────────────────
                // Lowest layer: catches taps on empty areas.
                // Higher-z interactive views (clouds, blocks) intercept their own taps first.
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        let inZoneArea  = location.y > zone.minY - 20
                        let inSidebar   = location.x > geo.size.width * 0.78
                        guard !inZoneArea && !inSidebar else { return }
                        vm.plantFlower(
                            posX: location.x / geo.size.width,
                            posY: location.y / geo.size.height
                        )
                    }

                // ── Tiny pollen burst emitted from bees after leaving flowers ──
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

                // ── Degraded original flowers ─────────────────────────────
                ForEach(vm.flowers) { flower in
                    let scale = 0.2 + vm.flowerHealth * 0.8
                    Circle()
                        .fill(Color.green.opacity(0.5 * vm.flowerHealth))
                        .frame(width: flower.size * scale, height: flower.size * scale)
                        .position(
                            x: flower.posX * geo.size.width,
                            y: flower.posY * geo.size.height
                        )
                        .animation(.easeInOut(duration: 1.2), value: vm.flowerHealth)
                        .allowsHitTesting(false)
                }

                // ── User-planted flowers ──────────────────────────────────
                ForEach(vm.plantedFlowers) { flower in
                    Image("Flower")
                        .resizable()
                        .scaledToFit()
                        .frame(width: flower.size, height: flower.size)
                        .position(
                            x: flower.posX * geo.size.width,
                            y: flower.posY * geo.size.height
                        )
                        .transition(.scale(scale: 0.01).combined(with: .opacity))
                        .allowsHitTesting(false)
                }

                // ── Recovering bees ───────────────────────────────────────
                let beeCount = max(0, Int(vm.beePopulation * Double(vm.bees.count)))
                ForEach(vm.bees.prefix(beeCount)) { bee in
                    BeeShape(size: bee.size)
                        .scaleEffect(x: bee.velX < 0 ? -1 : 1, y: 1)
                        .scaleEffect(bee.isPollinating ? 1.25 : 1.0)
                        .animation(.easeInOut(duration: 0.35), value: bee.isPollinating)
                        .position(
                            x: bee.posX * geo.size.width,
                            y: bee.posY * geo.size.height
                        )
                        .opacity(0.3 + vm.beePopulation * 0.7)
                        .allowsHitTesting(false)
                }

                // ── Habitat zone background ───────────────────────────────
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        Color(red: 0.45, green: 0.28, blue: 0.12)
                            .opacity(0.08 + Double(min(vm.placedHabitatCount, 5)) * 0.02)
                    )
                    .frame(width: zone.width, height: zone.height)
                    .position(x: zone.midX, y: zone.midY)
                    .allowsHitTesting(false)

                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        Color(red: 0.62, green: 0.42, blue: 0.22)
                            .opacity(0.45 + Double(min(vm.placedHabitatCount, 3)) * 0.1),
                        lineWidth: 1.5
                    )
                    .frame(width: zone.width, height: zone.height)
                    .position(x: zone.midX, y: zone.midY)
                    .allowsHitTesting(false)

                Text("Habitat Zone  \(vm.placedHabitatCount) / 3")
                    .font(.system(size: 10, weight: .light))
                    .foregroundColor(Color(red: 0.72, green: 0.52, blue: 0.32).opacity(0.85))
                    .position(x: zone.midX, y: zone.minY - 14)
                    .allowsHitTesting(false)

                // ── Placed blocks inside habitat zone ─────────────────────
                let placedBlocks = vm.habitatBlocks.filter(\.isPlaced).prefix(5)
                ForEach(Array(placedBlocks.enumerated()), id: \.element.id) { index, _ in
                    HabitatBlockShape()
                        .position(
                            x: zone.minX + 44.0 + Double(index % 3) * 68.0,
                            y: zone.midY
                        )
                        .allowsHitTesting(false)
                }

                // ── Pesticide clouds — tap to remove ─────────────────────
                ForEach(vm.pesticideClouds) { cloud in
                    PesticideCloudShape()
                        .frame(width: cloud.width, height: cloud.height)
                        .position(
                            x: cloud.posX * geo.size.width,
                            y: cloud.posY * geo.size.height
                        )
                        .transition(.scale.combined(with: .opacity))
                        .onTapGesture {
                            vm.removePesticideCloud(id: cloud.id)
                        }
                }

                // ── Draggable habitat blocks (right sidebar) ─────────────
                ForEach(vm.habitatBlocks) { block in
                    if !block.isPlaced {
                        let isDragging = draggingId == block.id
                        let displayPos: CGPoint = isDragging
                            ? dragPosition
                            : CGPoint(
                                x: block.posX * geo.size.width,
                                y: block.posY * geo.size.height
                            )

                        HabitatBlockShape()
                            .position(displayPos)
                            .scaleEffect(isDragging ? 1.14 : 1.0)
                            .shadow(
                                color: isDragging ? .black.opacity(0.35) : .clear,
                                radius: isDragging ? 10 : 0
                            )
                            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isDragging)
                            .zIndex(isDragging ? 20 : 5)
                            .transition(.scale.combined(with: .opacity))
                            .gesture(
                                DragGesture(minimumDistance: 2)
                                    .onChanged { value in
                                        if draggingId == nil { draggingId = block.id }
                                        if draggingId == block.id { dragPosition = value.location }
                                    }
                                    .onEnded { value in
                                        guard draggingId == block.id else { return }
                                        if zone.contains(value.location) {
                                            vm.placeHabitatBlock(id: block.id)
                                        }
                                        draggingId = nil
                                    }
                            )
                    }
                }

                // ── HUD overlay ───────────────────────────────────────────
                VStack {
                    HStack(alignment: .top) {
                        RecoveryStatsHUD(
                            beePopulation:  vm.beePopulation,
                            biodiversity:   vm.biodiversity,
                            pesticideLevel: vm.pesticideLevel
                        )
                        .padding(.leading, 16)
                        .padding(.top, 54)
                        Spacer()
                    }

                    Spacer()

                    if !vm.balanceRestored {
                        RecoveryInstructionsBar()
                            .padding(.bottom, 24)
                    }
                }
                .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Habitat Zone Geometry

    private func habitatZone(in size: CGSize) -> CGRect {
        let w = size.width  * 0.52
        let h = size.height * 0.15
        return CGRect(
            x: (size.width - w) / 2.0,
            y: size.height * 0.79,
            width:  w,
            height: h
        )
    }
}

// MARK: - Sub-views

/// Gray rounded rectangle representing a pesticide cloud.
struct PesticideCloudShape: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(Color(white: 0.52).opacity(0.60))
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            )
    }
}

/// Brown rounded rectangle for habitat blocks.
struct HabitatBlockShape: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color(red: 0.52, green: 0.33, blue: 0.18))
            .frame(width: 52, height: 28)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(
                        Color(red: 0.68, green: 0.48, blue: 0.28).opacity(0.5),
                        lineWidth: 1
                    )
            )
    }
}

/// HUD showing current ecosystem recovery metrics.
struct RecoveryStatsHUD: View {
    let beePopulation:  Double
    let biodiversity:   Double
    let pesticideLevel: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            statRow(label: "Bees",
                    value: beePopulation,
                    color: Color(hue: 0.13, saturation: 0.9, brightness: 0.9))
            statRow(label: "Flora",
                    value: biodiversity,
                    color: .green)
            statRow(label: "Clean",
                    value: 1.0 - pesticideLevel,
                    color: .teal)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.28))
        )
    }

    private func statRow(label: String, value: Double, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .light))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 34, alignment: .leading)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 56, height: 4)

                RoundedRectangle(cornerRadius: 2)
                    .fill(color.opacity(0.8))
                    .frame(width: 56 * max(0, min(1, value)), height: 4)
                    .animation(.easeInOut(duration: 0.5), value: value)
            }
        }
    }
}

/// Bottom instruction bar explaining Phase 3 mechanics.
struct RecoveryInstructionsBar: View {
    var body: some View {
        HStack(spacing: 14) {
            chip(symbol: "◻", text: "Tap clouds")
            chip(symbol: "●", text: "Tap to plant")
            chip(symbol: "▬", text: "Drag blocks")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.black.opacity(0.30))
        )
    }

    private func chip(symbol: String, text: String) -> some View {
        HStack(spacing: 5) {
            Text(symbol)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.65))
            Text(text)
                .font(.system(size: 10, weight: .light))
                .foregroundColor(.white.opacity(0.58))
        }
    }
}

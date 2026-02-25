import SwiftUI

// MARK: - Left Panel Root

struct LeftPanelView: View {
    @ObservedObject var vm: EcosystemViewModel
    @Binding var isSidebarVisible: Bool
    var topPadding: CGFloat = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Empurra o conteúdo para baixo da barra do sistema,
                // mas o fundo escuro cobre a área inteira até o topo.
//                Color.clear.frame(height: topPadding)

                TopNavBar(vm: vm, isSidebarVisible: $isSidebarVisible)
                
                CharacterBubble(phase: vm.phase)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    .animation(.easeInOut(duration: 0.5), value: vm.phase)

                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                phaseContent
                    .padding(.horizontal, 20)
                    .animation(.easeInOut(duration: 0.5), value: vm.phase)

                Spacer(minLength: 40)
            }
        }
        .background(Color(red: 0.09, green: 0.09, blue: 0.10))
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch vm.phase {
        case .abundance: Phase1NarrativeView()
        case .decline:   Phase2NarrativeView(vm: vm)
        case .recovery:  Phase3NarrativeView(vm: vm)
        }
    }
}

// MARK: - Character Avatar (geometric)

struct CharacterAvatar: View {
    let phase: EcosystemPhase

    private var bgColor: Color {
        switch phase {
        case .abundance: return Color(red: 0.22, green: 0.48, blue: 0.68)
        case .decline:   return Color(red: 0.52, green: 0.28, blue: 0.28)
        case .recovery:  return Color(red: 0.22, green: 0.48, blue: 0.68)
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(bgColor)
                .frame(width: 52, height: 52)

            // Body
            Circle()
                .fill(Color(red: 0.32, green: 0.60, blue: 0.32))
                .frame(width: 28, height: 28)
                .offset(y: 5)

            // Head
            Circle()
                .fill(Color(red: 0.38, green: 0.66, blue: 0.38))
                .frame(width: 20, height: 20)
                .offset(y: -8)

            // Left ear
            Circle()
                .fill(Color(red: 0.88, green: 0.52, blue: 0.58))
                .frame(width: 7, height: 7)
                .offset(x: -9, y: -14)

            // Right ear
            Circle()
                .fill(Color(red: 0.88, green: 0.52, blue: 0.58))
                .frame(width: 7, height: 7)
                .offset(x: 9, y: -14)

            // Eyes
            Circle()
                .fill(Color.white)
                .frame(width: 5, height: 5)
                .offset(x: -3.5, y: -9)
            Circle()
                .fill(Color.white)
                .frame(width: 5, height: 5)
                .offset(x: 3.5, y: -9)

            // Pupils
            Circle()
                .fill(Color(white: 0.15))
                .frame(width: 2.5, height: 2.5)
                .offset(x: -3, y: -9)
            Circle()
                .fill(Color(white: 0.15))
                .frame(width: 2.5, height: 2.5)
                .offset(x: 4, y: -9)
        }
        .animation(.easeInOut(duration: 0.5), value: phase)
    }
}

// MARK: - Character Bubble (avatar + speech)

struct CharacterBubble: View {
    let phase: EcosystemPhase

    private var bubbleColor: Color {
        switch phase {
        case .abundance: return Color(red: 0.22, green: 0.48, blue: 0.68)
        case .decline:   return Color(red: 0.52, green: 0.28, blue: 0.28)
        case .recovery:  return Color(red: 0.22, green: 0.48, blue: 0.68)
        }
    }

    private var message: LocalizedStringKey {
        switch phase {
        case .abundance:
            return "Hello! I'm **Natu**, your ecosystem guide. Right now, everything is in **perfect balance**. Watch carefully — this harmony is more fragile than it looks."
        case .decline:
            return "Something is **breaking down**. Do you see it? The pesticides are rising and the bees are disappearing. One thing pulling another."
        case .recovery:
            return "The ecosystem needs **your help**. You can't control the bees directly — but you can create the conditions they need to come back."
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            CharacterAvatar(phase: phase)

            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .lineSpacing(3)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(bubbleColor)
                )
        }
    }
}

// MARK: - Phase 1: Abundance Narrative

struct Phase1NarrativeView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            paragraph(
                "As you can see, the ecosystem is **flourishing**. Bees move freely through their habitat, flowers bloom at full health, and biodiversity is at its peak."
            )

            paragraph(
                "Bees are one of nature's most critical **pollinators**. Without them, flowers cannot reproduce — and entire food chains begin to collapse."
            )

            CalloutBox(
                text: "Watch the **pollen particles** drifting upward. Each one represents the invisible work bees do every single day.",
                color: .green
            )

            paragraph(
                "This balance is **fragile**. In a few moments, something will change. Notice how each element depends on the others — there are no isolated parts in an ecosystem."
            )

            footerNote("The simulation will transition to Phase 2 automatically.")
        }
    }
}

// MARK: - Phase 2: Decline Narrative

struct Phase2NarrativeView: View {
    @ObservedObject var vm: EcosystemViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            paragraph(
                "Pesticide levels are rising and **bees are disappearing**. As the bee population falls below 30%, flower health begins to decline — this is the cascade effect."
            )

            MetricsPanel(
                entries: [
                    .init(label: "Bees",       value: vm.beePopulation,   color: Color(hue: 0.13, saturation: 0.9, brightness: 0.9)),
                    .init(label: "Flowers",    value: vm.flowerHealth,    color: .green),
                    .init(label: "Diversity",  value: vm.biodiversity,    color: .teal),
                    .init(label: "Pesticides", value: vm.pesticideLevel,  color: Color(white: 0.62))
                ]
            )

            CalloutBox(
                text: "When bee population drops below **20%**, the ecosystem enters a critical state and Phase 3 begins.",
                color: Color(red: 0.75, green: 0.35, blue: 0.25)
            )

            paragraph(
                "This is a **systemic collapse**. Each element affects the others in a chain reaction. Nothing collapses alone."
            )
        }
    }
}

// MARK: - Phase 3: Recovery Narrative

struct Phase3NarrativeView: View {
    @ObservedObject var vm: EcosystemViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            paragraph(
                "The ecosystem is in critical state. Your actions can create the conditions for recovery — but the bees will return on their own **only when the system is ready**."
            )

            VStack(alignment: .leading, spacing: 12) {
                InstructionRow(
                    symbol:      "◻",
                    symbolColor: Color(white: 0.75),
                    title:       "Tap gray clouds",
                    description: "Each tap removes pesticide contamination. Reducing pesticide levels is the first step to bee recovery."
                )
                InstructionRow(
                    symbol:      "●",
                    symbolColor: .green,
                    title:       "Tap to plant flowers",
                    description: "New flowers increase biodiversity, which accelerates the rate at which bees recover."
                )
                InstructionRow(
                    symbol:      "▬",
                    symbolColor: Color(red: 0.62, green: 0.42, blue: 0.22),
                    title:       "Drag habitat blocks",
                    description: "Place 3 blocks in the Habitat Zone (bottom of the canvas) to unlock a 1.7× recovery multiplier."
                )
            }

            MetricsPanel(
                entries: [
                    .init(label: "Bees",       value: vm.beePopulation,          color: Color(hue: 0.13, saturation: 0.9, brightness: 0.9)),
                    .init(label: "Diversity",  value: vm.biodiversity,           color: .teal),
                    .init(label: "Clean air",  value: 1.0 - vm.pesticideLevel,   color: .green),
                    .init(label: "Habitat",    value: Double(vm.placedHabitatCount) / 3.0, color: Color(red: 0.62, green: 0.42, blue: 0.22))
                ]
            )

            CalloutBox(
                text: "You planted **\(vm.plantedFlowers.count)** flower\(vm.plantedFlowers.count == 1 ? "" : "s") and placed **\(vm.placedHabitatCount)/3** habitat blocks.",
                color: .teal
            )

            footerNote("Bees return automatically when the ecosystem is healthy again.")
        }
    }
}

// MARK: - Shared Panel Components

private func paragraph(_ text: LocalizedStringKey) -> some View {
    Text(text)
        .font(.system(size: 14))
        .foregroundColor(.white.opacity(0.85))
        .lineSpacing(4)
}

private func footerNote(_ text: String) -> some View {
    HStack(spacing: 6) {
        Rectangle()
            .fill(Color.white.opacity(0.12))
            .frame(maxWidth: .infinity, maxHeight: 1)
        Text(text)
            .font(.system(size: 11, weight: .light))
            .foregroundColor(.white.opacity(0.35))
            .fixedSize()
        Rectangle()
            .fill(Color.white.opacity(0.12))
            .frame(maxWidth: .infinity, maxHeight: 1)
    }
}

// MARK: - CalloutBox

struct CalloutBox: View {
    let text: LocalizedStringKey
    var color: Color = .blue

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 3)

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.78))
                .lineSpacing(3)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.10))
        )
    }
}

// MARK: - InstructionRow

struct InstructionRow: View {
    let symbol:      String
    let symbolColor: Color
    let title:       String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(symbolColor.opacity(0.14))
                    .frame(width: 34, height: 34)
                Text(symbol)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(symbolColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                Text(description)
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.white.opacity(0.58))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - MetricsPanel

struct MetricEntry {
    let label: String
    let value: Double
    let color: Color
}

struct MetricsPanel: View {
    let entries: [MetricEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current State")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.35))
                .textCase(.uppercase)
                .kerning(0.8)

            ForEach(entries, id: \.label) { entry in
                EcosystemBar(label: entry.label, value: entry.value, color: entry.color)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

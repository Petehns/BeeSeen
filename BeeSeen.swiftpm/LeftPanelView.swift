import SwiftUI
import UniformTypeIdentifiers
import AVFoundation
import Foundation

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
        case .abundance:
            Phase1ImportanceView()
        case .decline:
            Phase2DeclineCausesView(vm: vm)
        case .recovery:
            if vm.currentChallengeIndex >= 4 {
                PhaseFinalSynthesisView(vm: vm)
            } else {
                Phase3ChallengesView(vm: vm)
            }
        }
    }
}

// MARK: - Character Avatar

struct CharacterAvatar: View {
    let phase: EcosystemPhase

    var body: some View {
        Image("Michelle")
            .resizable()
            .scaledToFill()
            .frame(width: 52, height: 52)
            .clipShape(Circle())
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
            return "I'm **Michelle**, an environmental scientist. For years, I've been studying biodiversity in forest ecosystems. Recently, I began noticing something unsettling — fewer plants regenerating, fewer fruits forming. When I traced the pattern back, one connection stood out: the bees were disappearing. What you see here is the balance before that decline begins."
        case .decline:
            return "The model is running. The readings match what we see in the field: the system is under stress. My simulation has flagged it — **environment.status = .critical**."
        case .recovery:
            return "I need your help to **test the model**. We'll change one variable at a time, run the simulation, and see how it responds. The status you see is the diagnosis — not something we set by hand."
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

// MARK: - Phase 1 — The Importance of Bees

struct Phase1ImportanceView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionTitle("The importance of bees")

            paragraph(
                "Bees don't just make honey.\nThey connect flowers.\nThey turn pollen into fruit and seed.\nThey sustain what grows — and what we eat."
            )

            paragraph(
                "Pollination allows plants to reproduce. Nearly **75%** of the world's flowering plants depend, at least in part, on animal pollinators. Around **one third** of global food production relies on this process."
            )

            paragraph(
                "Without bees, biodiversity declines.\nFood systems weaken.\nEcosystems lose resilience."
            )

            CalloutBox(
                text: "On the right, the field is alive: bees pollinate, flowers bloom, fruits begin to form. This is the baseline — the state my simulation will later compare against.",
                color: .green
            )

            paragraph(
                "Cross-pollination strengthens genetic diversity. Genetic diversity strengthens ecosystems. And strong ecosystems sustain human life."
            )

            paragraph("Watch closely.\nThis is balance.\nAnd balance is not automatic.")

            footerNote("When ready, use the phase controls to move to the next part.")
        }
    }
}

// MARK: - Phase 2 — The Decline and the Simulation

struct Phase2DeclineCausesView: View {
    @ObservedObject var vm: EcosystemViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionTitle("The decline and the simulation")

            paragraph(
                "Something changed in the field. The air grew **denser**. The flowers grew fewer. Some bees did not return."
            )

            paragraph(
                "I built a **simulation** that models the main environmental variables: pesticide load, forest cover, plant diversity, and climate. The model doesn’t invent the decline — it reflects it."
            )

            paragraph(
                "When those variables push the system past a threshold, the simulation **diagnoses** the state. We don’t set that by hand; the model derives it from the inputs."
            )

            SimulationStatusLine(status: ".critical")
                .padding(.vertical, 4)

            MetricsPanel(
                entries: [
                    .init(label: "Bees",       value: vm.beePopulation,   color: Color(hue: 0.13, saturation: 0.9, brightness: 0.9)),
                    .init(label: "Flowers",    value: vm.flowerHealth,    color: .green),
                    .init(label: "Diversity",  value: vm.biodiversity,    color: .teal),
                    .init(label: "Pesticides", value: vm.pesticideLevel,  color: Color(white: 0.62))
                ]
            )

            CalloutBox(
                text: "Next, you’ll help me **test hypotheses**. We’ll adjust one variable, run the simulation, and see how the system — and the diagnosis — respond.",
                color: Color(red: 0.75, green: 0.35, blue: 0.25)
            )
        }
    }
}

// MARK: - Phase 3 — Interactive Challenges (left panel only)

struct Phase3ChallengesView: View {
    @ObservedObject var vm: EcosystemViewModel
    @State private var selectedChoice: String? = nil
    @State private var hasActed: Bool = false
    @State private var dropZoneTargeted: Bool = false
    @State private var isListeningForBlow: Bool = false
    @StateObject private var blowDetector = BlowMicDetector()

    private var index: Int { vm.currentChallengeIndex }
    private var challengeTitle: String {
        switch index {
        case 0: return "Challenge 1 — Pesticides"
        case 1: return "Challenge 2 — Habitat loss"
        case 2: return "Challenge 3 — Floral diversity"
        case 3: return "Challenge 4 — Climate"
        default: return "Challenge"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if index == 0 {
                phase3Intro
            }
            sectionTitle(challengeTitle)
            challengeSituation
            if !hasActed {
                choiceSection
                actionButton
            } else {
                consequenceSection
                michelleInterpretation
                educationalImpact
                simulationStatusAfterTest
                Button {
                    let good = selectedChoice == "A"
                    selectedChoice = nil
                    hasActed = false
                    vm.advanceToNextChallenge(goodChoice: good)
                } label: {
                    Text("Next challenge")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(red: 0.22, green: 0.48, blue: 0.68)))
                }
            }
        }
        .onChange(of: vm.currentChallengeIndex) { _ in
            selectedChoice = nil
            hasActed = false
            isListeningForBlow = false
            blowDetector.stop()
        }
    }

    @ViewBuilder private var phase3Intro: some View {
        CalloutBox(
            text: "The simulation is in **critical** state. We’ll test one variable at a time: you choose a value, run the test, and the model will show how the system — and its diagnosis — respond.",
            color: Color(red: 0.22, green: 0.48, blue: 0.68)
        )
        .padding(.bottom, 4)
    }

    @ViewBuilder private var challengeSituation: some View {
        switch index {
        case 0:
            VStack(alignment: .leading, spacing: 10) {
                paragraph("**Hypothesis:** Pesticides may be disrupting navigation. Bees exposed to certain chemicals lose the ability to find their way back. In the model, we can set the load and observe the outcome.")
                paragraph("**Test:** Choose a value for the simulation, then run the test (blow into the mic to activate).")
            }
        case 1:
            paragraph("**Hypothesis:** Habitat loss reduces nesting sites. **Test:** Set the variable and run the action.")
        case 2:
            paragraph("**Hypothesis:** Monoculture limits nutrition. **Test:** Set the variable and run the action.")
        case 3:
            paragraph("**Hypothesis:** Climate shift desynchronizes flowers and bees. **Test:** Set the variable and run the action.")
        default:
            paragraph("Choose a value and run the test.")
        }
    }

    @ViewBuilder private var choiceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Set variable in simulation:")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            HStack(spacing: 8) {
                choiceCard(code: choiceA, choice: "A")
                choiceCard(code: choiceB, choice: "B")
            }
            // Área vazia para o usuário soltar a escolha (drag and drop)
            executionDropZone
        }
    }

    @ViewBuilder private var executionDropZone: some View {
        let hasDropped = selectedChoice != nil
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(dropZoneTargeted ? 0.12 : 0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            dropZoneTargeted ? Color.white.opacity(0.35) : Color.white.opacity(0.12),
                            lineWidth: 1.5
                        )
                )
                .frame(minHeight: 52)
            if let choice = selectedChoice {
                Text(choice == "A" ? choiceA : choiceB)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            } else {
                Text("Drop choice here")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.35))
            }
        }
        .onDrop(of: [.plainText], isTargeted: $dropZoneTargeted) { providers in
            guard let provider = providers.first else { return false }
            provider.loadObject(ofClass: NSString.self) { obj, _ in
                guard let s = obj as? String, s == "A" || s == "B" else { return }
                DispatchQueue.main.async { selectedChoice = s }
            }
            return true
        }
    }

    private var choiceA: String {
        switch index {
        case 0: return "environment.pesticideLevel = .low"
        case 1: return "environment.forest = .preserve"
        case 2: return "environment.plants = .diverse"
        case 3: return "environment.climate = .stable"
        default: return ".optionA"
        }
    }

    private var choiceB: String {
        switch index {
        case 0: return "environment.pesticideLevel = .high"
        case 1: return "environment.forest = .clear"
        case 2: return "environment.plants = .monoculture"
        case 3: return "environment.climate = .warming"
        default: return ".optionB"
        }
    }

    private func choiceCard(code: String, choice: String) -> some View {
        let isDropped = selectedChoice == choice
        return Text(code)
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundColor(.white.opacity(0.85))
            .lineLimit(2)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.1)))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(isDropped ? Color.green.opacity(0.6) : Color.clear, lineWidth: 2)
            )
            .draggable(choice)
    }

    @ViewBuilder private var actionButton: some View {
        let actionLabel: String = {
            switch index {
            case 0: return "Blow into mic to activate"
            case 1: return "Hold button to restore"
            case 2: return "Shake iPad to spread seeds"
            case 3: return "Keep circle in balance"
            default: return "Activate"
            }
        }()
        let needsBlow = (index == 0)
        VStack(alignment: .leading, spacing: 10) {
            if needsBlow && isListeningForBlow {
                BlowMeterView(level: blowDetector.blowLevel)
            }
            Button {
                guard selectedChoice != nil else { return }
                if needsBlow {
                    if isListeningForBlow { return }
                    isListeningForBlow = true
                    blowDetector.start { success in
                        // Completion is already invoked on the main queue by BlowMicDetector.
                        isListeningForBlow = false
                        if success { hasActed = true }
                    }
                } else {
                    hasActed = true
                }
            } label: {
                HStack {
                    Image(systemName: isListeningForBlow && needsBlow ? "waveform" : "play.circle.fill")
                    Text(isListeningForBlow && needsBlow ? "Assopre até o verde" : actionLabel)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.white.opacity(selectedChoice != nil ? 1 : 0.4))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 8).fill(isListeningForBlow ? Color.blue.opacity(0.25) : Color.white.opacity(0.12)))
            }
            .disabled(selectedChoice == nil)
        }
    }

    @ViewBuilder private var consequenceSection: some View {
        let isGood = selectedChoice == "A"
        let text: String = {
            switch index {
            case 0: return isGood ? "The air clears. Flight finds its way again." : "The air weighs heavy. The field falls silent."
            case 1: return isGood ? "Where there is shelter, there is life." : "Without shelter, flight does not stay."
            case 2: return isGood ? "Diversity sustains flight." : "When all is the same, too much depends on too little."
            case 3: return isGood ? "Balance keeps time in tune." : "When time is off, the encounter fails."
            default: return ""
            }
        }()
        CalloutBox(text: LocalizedStringKey(text), color: isGood ? .green : Color(red: 0.75, green: 0.35, blue: 0.25))
    }

    @ViewBuilder private var michelleInterpretation: some View {
        let isGood = selectedChoice == "A"
        let text: String = {
            switch index {
            case 0: return isGood
                ? "Michelle: \"The model confirms it. Lower exposure — navigation holds. Pesticide load is one lever we can actually turn.\""
                : "Michelle: \"As we suspected. High load and the colony loses its bearings. The simulation is consistent with the field data.\""
            case 1: return isGood
                ? "Michelle: \"Shelter matters. The model shows recovery when we preserve habitat.\""
                : "Michelle: \"Without refuges, the population can’t hold. The diagnosis stays critical.\""
            case 2: return isGood
                ? "Michelle: \"Diversity feeds them. The run supports the hypothesis.\""
                : "Michelle: \"Monoculture weakens the system. One variable, clear effect.\""
            case 3: return isGood
                ? "Michelle: \"Stable climate keeps flowers and bees in sync. The model responds as expected.\""
                : "Michelle: \"Warming desynchronizes the system. We’re seeing it in the data.\""
            default: return ""
            }
        }()
        CalloutBox(text: LocalizedStringKey(text), color: Color(red: 0.22, green: 0.48, blue: 0.68))
    }

    @ViewBuilder private var simulationStatusAfterTest: some View {
        let status = vm.environmentStatusDisplay(includingCurrentGoodChoice: selectedChoice == "A")
        SimulationStatusLine(status: status)
    }

    @ViewBuilder private var educationalImpact: some View {
        let text: String = {
            switch index {
            case 0: return "Certain pesticides affect bees’ nervous systems; they lose the ability to navigate. That can wipe out whole colonies."
            case 1: return "Bees need places to nest. Habitat loss reduces reproduction; landscape fragmentation weakens colonies."
            case 2: return "A varied diet strengthens bees. Monoculture cuts the nutrients available. Diverse ecosystems are more resilient."
            case 3: return "Climate change shifts flowering times. Bees can emerge when flowers are not ready. That mismatch hurts pollination."
            default: return ""
            }
        }()
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.teal)
                .frame(width: 3)
            Text("Impact: \(text)")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.78))
                .lineSpacing(3)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.teal.opacity(0.10)))
    }
}

// MARK: - Phase Final — Synthesis

struct PhaseFinalSynthesisView: View {
    @ObservedObject var vm: EcosystemViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionTitle("Synthesis")

            paragraph(
                "The field you see is a **reflection of the choices** made. More or less life, depending on those decisions."
            )

            SimulationStatusLine(status: vm.environmentStatusDisplay())
                .padding(.vertical, 4)

            CalloutBox(
                text: "The model’s final diagnosis reflects the variables you set. Small decisions shape large ecosystems. Balance is not automatic — it is **built**.",
                color: Color(red: 0.22, green: 0.48, blue: 0.68)
            )

            paragraph(
                "You tested pesticides, habitat, diversity, and climate. Each factor is real. What happens next in the simulation is up to how the system responds on the right."
            )

            Button {
                vm.advancePhase()
            } label: {
                Text("Restart journey")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(red: 0.22, green: 0.48, blue: 0.68)))
            }
        }
    }
}

// MARK: - Simulation status (diagnosis from the model)

private func SimulationStatusLine(status: String) -> some View {
    HStack(spacing: 6) {
        Text("Diagnosis:")
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.white.opacity(0.5))
        Text("environment.status = \(status)")
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundColor(.orange.opacity(0.9))
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.06)))
}

// MARK: - Shared Panel Components

private func sectionTitle(_ text: String) -> some View {
    Text(text)
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(.white.opacity(0.5))
        .textCase(.uppercase)
        .kerning(0.8)
}

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

// MARK: - Medidor de sopro (vermelho → amarelo → verde)

struct BlowMeterView: View {
    let level: Float

    /// Cor do preenchimento: vermelho (baixo) → amarelo (médio) → verde (concluído).
    private var zoneColor: Color {
        if level < 0.2 { return Color.red }
        if level < 0.4 { return Color.yellow }
        return Color.green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Assopre no microfone")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    // Faixas: vermelho 20% | amarelo 20% | verde 60%
                    HStack(spacing: 0) {
                        Rectangle().fill(Color.red.opacity(0.7)).frame(width: w * 0.2)
                        Rectangle().fill(Color.yellow.opacity(0.7)).frame(width: w * 0.2)
                        Rectangle().fill(Color.green.opacity(0.7)).frame(width: w * 0.6)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    // Preenchimento até o nível atual
                    RoundedRectangle(cornerRadius: 6)
                        .fill(zoneColor)
                        .frame(width: max(0, w * CGFloat(level)))
                }
            }
            .frame(height: 22)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
            )
            HStack(spacing: 12) {
                label("Baixo", color: .red)
                label("Médio", color: .yellow)
                label("Concluído", color: .green)
            }
            .font(.system(size: 9, weight: .medium))
        }
    }

    private func label(_ text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text).foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - Blow-into-mic detector (Challenge 1)

/// Buffer thread-safe: só a thread de áudio escreve; o MainActor lê (evita EXC_BREAKPOINT).
private final class BlowLevelBuffer: @unchecked Sendable {
    let lock = NSLock()
    var rawLevel: Float = 0
    var greenCount: Int = 0
    var shouldTriggerSuccess: Bool = false
}

/// All engine, completion, and UI updates run on DispatchQueue.main.
/// @unchecked Sendable: thread safety is enforced manually via assert(Thread.isMainThread).
final class BlowMicDetector: ObservableObject, @unchecked Sendable {
    @Published var blowLevel: Float = 0

    private var engine: AVAudioEngine?
    private var completion: ((Bool) -> Void)?
    private let greenThreshold: Float = 0.4
    private let requiredGreenCount: Int = 10
    private var pollWorkItem: DispatchWorkItem?
    private var timeoutWorkItem: DispatchWorkItem?
    private let buffer = BlowLevelBuffer()

    func start(completion: @escaping @Sendable (Bool) -> Void) {
        DispatchQueue.main.async { [weak self] in
            self?.stop()
            self?.completion = completion
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    guard granted else {
                        self.completion?(false)
                        self.completion = nil
                        return
                    }
                    self.startEngine()
                }
            }
        }
    }

    private func startEngine() {
        assert(Thread.isMainThread)
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            completion?(false)
            completion = nil
            return
        }
        buffer.lock.lock()
        buffer.rawLevel = 0
        buffer.greenCount = 0
        buffer.shouldTriggerSuccess = false
        buffer.lock.unlock()
        blowLevel = 0

        let eng = AVAudioEngine()
        let input = eng.inputNode
        let format = input.outputFormat(forBus: 0)
        let threshold = greenThreshold
        let required = requiredGreenCount
        let buf = buffer

        input.installTap(onBus: 0, bufferSize: 1024, format: format) { audioBuffer, _ in
            let frameLength = Int(audioBuffer.frameLength)
            guard frameLength > 0,
                  let channelData = audioBuffer.floatChannelData?[0] else { return }
            var sum: Float = 0
            for i in 0..<frameLength { sum += abs(channelData[i]) }
            let avg = sum / Float(frameLength)
            let normalized = min(1.0, avg / 0.5)
            buf.lock.lock()
            buf.rawLevel = normalized
            if normalized >= threshold {
                buf.greenCount += 1
                if buf.greenCount >= required { buf.shouldTriggerSuccess = true }
            } else {
                buf.greenCount = 0
            }
            buf.lock.unlock()
        }
        do {
            try eng.start()
            self.engine = eng
        } catch {
            completion?(false)
            completion = nil
            return
        }

        let timeoutItem = DispatchWorkItem { [weak self] in
            self?.triggerSuccess(success: false)
        }
        timeoutWorkItem = timeoutItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 8, execute: timeoutItem)

        schedulePoll()
    }

    private func schedulePoll() {
        let item = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.pollLevel()
            if self.engine != nil, self.completion != nil {
                self.schedulePoll()
            }
        }
        pollWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: item)
    }

    private func pollLevel() {
        assert(Thread.isMainThread)
        buffer.lock.lock()
        let level = buffer.rawLevel
        let trigger = buffer.shouldTriggerSuccess
        if trigger { buffer.shouldTriggerSuccess = false }
        buffer.lock.unlock()
        blowLevel = level
        if trigger { triggerSuccess(success: true) }
    }

    private func triggerSuccess(success: Bool) {
        assert(Thread.isMainThread)
        pollWorkItem?.cancel()
        pollWorkItem = nil
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
        let comp = completion
        completion = nil
        comp?(success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.stopEngine()
        }
    }

    func stop() {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in self?.stop() }
            return
        }
        pollWorkItem?.cancel()
        pollWorkItem = nil
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
        stopEngine()
    }

    private func stopEngine() {
        assert(Thread.isMainThread)
        guard let eng = engine else { return }
        engine = nil
        completion = nil
        blowLevel = 0
        eng.inputNode.removeTap(onBus: 0)
        eng.stop()
    }
}

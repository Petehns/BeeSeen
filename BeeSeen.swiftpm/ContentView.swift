import SwiftUI

// MARK: - App Stage (before phases)

private enum AppStage {
    case start
    case intro
    case simulation
}

// MARK: - Root View

struct ContentView: View {
    @StateObject private var vm = EcosystemViewModel()
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var isSidebarVisible = true
    @State private var appStage: AppStage = .start

    var body: some View {
        Group {
            switch appStage {
            case .start:
                StartView(onBegin: { appStage = .intro })
            case .intro:
                IntroView(onStart: {
                    appStage = .simulation
                    vm.start()
                })
            case .simulation:
                simulationContent
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
    }

    @ViewBuilder
    private var simulationContent: some View {
        GeometryReader { geo in
            if sizeClass == .regular {
                splitLayout(geo: geo)
            } else {
                compactLayout(geo: geo)
            }
        }
    }

    // MARK: - Layouts

    private func splitLayout(geo: GeometryProxy) -> some View {
        let leftWidth   = min(geo.size.width * 0.42, 460.0)
        // Margem superior: garante que a UI fique abaixo da barra do sistema/Playgrounds
        // para os botões serem clicáveis (fullscreen sem sobreposição).
        let safeTop     = max(geo.safeAreaInsets.top, 56)
        let safeBottom  = geo.safeAreaInsets.bottom

        return HStack(spacing: 0) {
            if isSidebarVisible {
                LeftPanelView(vm: vm, isSidebarVisible: $isSidebarVisible, topPadding: safeTop)
                    .frame(width: leftWidth)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }

            ZStack(alignment: .topLeading) {
                ZStack(alignment: .bottom) {
                    canvasArea
                    BottomToolbarView(vm: vm)
                        .padding(.bottom, safeBottom)
                }

                if !isSidebarVisible {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isSidebarVisible = true
                        }
                    } label: {
                        Image(systemName: "sidebar.left")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 36, height: 36)
                    }
                    .padding(.leading, 12)
                    .padding(.top, safeTop)
                    .contentShape(Rectangle())
                    .zIndex(50)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isSidebarVisible)
    }

    private func compactLayout(geo: GeometryProxy) -> some View {
        ZStack(alignment: .bottom) {
            canvasArea
            BottomToolbarView(vm: vm)
                .padding(.bottom, geo.safeAreaInsets.bottom)
        }
    }

    // MARK: - Ecosystem Canvas

    private var canvasArea: some View {
        ZStack {
            EcosystemBackground(
                beePopulation: vm.beePopulation,
                flowerHealth:  vm.flowerHealth
            )

            phaseView
                .animation(.easeInOut(duration: 1.5), value: vm.phase)

            if vm.balanceRestored {
                BalanceRestoredOverlay()
                    .transition(.opacity)
                    .zIndex(90)
            }

            if vm.showHint {
                HintOverlayView(text: vm.hintText)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(80)
                    .padding(.bottom, 72)
            }

            PhaseIndicatorBadge(phase: vm.phase)
                .zIndex(10)
        }
        // Ensure the canvas fills available space without pushing the toolbar out
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    @ViewBuilder
    private var phaseView: some View {
        switch vm.phase {
        case .abundance:
            Phase1AbundanceView(vm: vm).transition(.opacity)
        case .decline:
            Phase2DeclineView(vm: vm).transition(.opacity)
        case .recovery:
            Phase3RecoveryView(vm: vm).transition(.opacity)
        }
    }
}

// MARK: - Top Navigation Bar

struct TopNavBar: View {
    @ObservedObject var vm: EcosystemViewModel
    @Binding var isSidebarVisible: Bool
    @State private var showCloseAlert = false
    @State private var showWaitForPhaseAlert = false

    private var title: String {
        switch vm.phase {
        case .abundance: return "The Thriving Ecosystem"
        case .decline:   return "The Declining Ecosystem"
        case .recovery:  return "Path to Recovery"
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left buttons
            HStack(spacing: 4) {
                navButton(icon: "xmark") {
                    showCloseAlert = true
                }
                navButton(icon: "sidebar.left") {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isSidebarVisible = false
                    }
                }
            }
            .padding(.leading, 12)

            Spacer()

            // Phase passer: title + left/right chevrons
            HStack(spacing: 10) {
                Button {
                    if vm.hasPreviousPhase {
                        vm.goToPreviousPhase()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(vm.hasPreviousPhase ? 0.6 : 0.25))
                        .frame(width: 36, height: 36)
                }
                .disabled(!vm.hasPreviousPhase)

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .animation(.easeInOut(duration: 0.5), value: vm.phase)

                Button {
                    if vm.phaseCompleted {
                        vm.advancePhase()
                    } else {
                        showWaitForPhaseAlert = true
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 36, height: 36)
                }
            }

            Spacer()

            // Right buttons
            HStack(spacing: 4) {
                navButton(icon: "plus",             action: {})
                navButton(icon: "ellipsis.circle",  action: {})
            }
            .padding(.trailing, 12)
        }
        .frame(height: 44)
        .background(Color(white: 0.12))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
        }
        .alert("Close app?", isPresented: $showCloseAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Close", role: .destructive) {
                exit(0)
            }
        } message: {
            Text("Do you want to exit the application?")
        }
        .alert("Wait for the phase to complete", isPresented: $showWaitForPhaseAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Complete the current phase before advancing. The \"Next Phase\" or \"Restart\" button will appear in the bottom toolbar when you can proceed.")
        }
    }

    private func navButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 36, height: 36)
        }
    }
}

// MARK: - Ecosystem Background

struct EcosystemBackground: View {
    let beePopulation: Double
    let flowerHealth:  Double

    var body: some View {
        BackgroundView(beePopulation: beePopulation)
            .scaledToFill()
            .allowsHitTesting(false)
    }
}

// MARK: - Balance Restored Overlay

struct BalanceRestoredOverlay: View {
    var body: some View {
        Text("Balance restored.")
            .font(.system(size: 24, weight: .thin, design: .serif))
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 30)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.30))
            )
    }
}

// MARK: - Phase Indicator Badge (canvas corner)

struct PhaseIndicatorBadge: View {
    let phase: EcosystemPhase

    private var label: String {
        switch phase {
        case .abundance: return "Abundance"
        case .decline:   return "Decline"
        case .recovery:  return "Recovery"
        }
    }

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text(label)
                    .font(.system(size: 10, weight: .light))
                    .foregroundColor(.white.opacity(0.38))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.black.opacity(0.18)))
                    .padding(.trailing, 16)
                    .padding(.top, 14)
            }
            Spacer()
        }
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.5), value: phase)
    }
}

// MARK: - Start Screen

struct StartView: View {
    var onBegin: () -> Void

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(red: 0.09, green: 0.09, blue: 0.10)
                    .ignoresSafeArea()

                VStack(spacing: 28) {
                    Spacer()

                    Text("BeeSeen")
                        .font(.system(size: 42, weight: .bold, design: .serif))
                        .foregroundColor(.white)

                    Text("A simulation about balance, biodiversity, and the invisible work of bees.")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 40)

                    Spacer()

                    Button(action: onBegin) {
                        Text("Begin the Simulation")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(red: 0.22, green: 0.48, blue: 0.68)))
                    }
                    .padding(.horizontal, 48)
                    .padding(.bottom, 60)
                }
            }
        }
    }
}

// MARK: - Intro Screen

struct IntroView: View {
    var onStart: () -> Void

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(red: 0.09, green: 0.09, blue: 0.10)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 20) {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            introParagraph("BeeSeen is an interactive environmental simulation.")
                            introParagraph("It was created to explore how changes in biodiversity — especially the decline of pollinators — affect ecosystems and food systems.")
                            introParagraph("Through a computational model, you will adjust environmental variables and observe how the system responds.")
                            introParagraph("Each decision represents real-world pressures.")
                            introParagraph("The outcomes reflect scientific relationships between pollination, habitat, climate, and agricultural practices.")
                            introParagraph("The goal is not to \"win.\"")
                            introParagraph("The goal is to understand balance.")
                        }
                        .padding(.horizontal, 28)
                        .padding(.top, 50)
                        .padding(.bottom, 24)
                    }

                    BlinkingHintText()
                        .padding(.bottom, 50)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { onStart() }
        }
    }

    private func introParagraph(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 16))
            .foregroundColor(.white.opacity(0.88))
            .lineSpacing(5)
    }
}

// MARK: - Blinking hint (opacity animation on main thread only)

struct BlinkingHintText: View {
    @State private var opacity: Double = 0.5

    var body: some View {
        Text("press the screen to start")
            .font(.system(size: 14, weight: .light))
            .foregroundColor(.white.opacity(opacity))
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: opacity)
            .onAppear { opacity = 0.95 }
            .frame(maxWidth: .infinity)
    }
}

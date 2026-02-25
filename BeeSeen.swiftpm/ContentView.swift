import SwiftUI

// MARK: - Root View

struct ContentView: View {
    @StateObject private var vm = EcosystemViewModel()
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var isSidebarVisible: Bool = true

    var body: some View {
        GeometryReader { geo in
            if sizeClass == .regular {
                splitLayout(geo: geo)
            } else {
                compactLayout(geo: geo)
            }
        }
        .ignoresSafeArea()
        .onAppear { vm.start() }
    }

    // MARK: - Layouts

    private func splitLayout(geo: GeometryProxy) -> some View {
        let leftWidth   = min(geo.size.width * 0.42, 460.0)
        let safeTop     = geo.safeAreaInsets.top
        let safeBottom  = geo.safeAreaInsets.bottom

        return HStack(spacing: 0) {
            if isSidebarVisible {
                LeftPanelView(vm: vm)
                    .frame(width: leftWidth)
                    .padding(.top, safeTop)
                    .transition(.move(edge: .leading))
            }

            ZStack(alignment: .bottom) {
                canvasArea
                BottomToolbarView(vm: vm)
                    .padding(.bottom, safeBottom)
            }
        }
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
    @State private var showExitAlert = false

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
                    showExitAlert = true
                }
                navButton(icon: "sidebar.left") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isSidebarVisible.toggle()
                    }
                }
            }
            .padding(.leading, 12)

            Spacer()

            // Title with phase arrows
            HStack(spacing: 10) {
                navButton(icon: "chevron.left",  action: {})

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .animation(.easeInOut(duration: 0.5), value: vm.phase)

                navButton(icon: "chevron.right", action: {})
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
        .alert("Exit App?", isPresented: $showExitAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Exit", role: .destructive) {
                exit(0)
            }
        } message: {
            Text("Are you sure you want to close the app?")
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

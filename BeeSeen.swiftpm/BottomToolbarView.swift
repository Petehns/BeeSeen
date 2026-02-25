import SwiftUI

// MARK: - Bottom Toolbar

struct BottomToolbarView: View {
    @ObservedObject var vm: EcosystemViewModel

    private var nextLabel: String {
        switch vm.phase {
        case .abundance: return "Next Phase"
        case .decline:   return "Next Phase"
        case .recovery:  return "Restart"
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left: Status / Pause circle button
            Button(action: { vm.togglePause() }) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                        )
                    Image(systemName: vm.isPaused ? "play.fill" : "timer")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                }
            }
            .padding(.leading, 24)

            Spacer()

            // Center: transforms into "Next Phase" when phase is complete
            if vm.phaseCompleted {
                Button(action: { vm.advancePhase() }) {
                    HStack(spacing: 8) {
                        Text(nextLabel)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.teal.opacity(0.85))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.5)
                            )
                    )
                }
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            } else {
                Button(action: { vm.togglePause() }) {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.blue)
                            .frame(width: 14, height: 14)

                        Text(vm.isPaused ? "Run" : "Stop")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                            )
                    )
                }
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            }

            Spacer()

            // Right: Hint button
            Button(action: { vm.toggleHint() }) {
                Text("Hint")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(vm.showHint ? 1.0 : 0.80))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(vm.showHint
                                  ? AnyShapeStyle(Color.blue.opacity(0.45))
                                  : AnyShapeStyle(.ultraThinMaterial))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(
                                        vm.showHint
                                            ? Color.blue.opacity(0.7)
                                            : Color.white.opacity(0.15),
                                        lineWidth: 0.5
                                    )
                            )
                    )
                    .animation(.easeInOut(duration: 0.2), value: vm.showHint)
            }
            .padding(.trailing, 24)
            
        }
        .frame(minWidth: 200)
        .frame(height: 62)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: vm.phaseCompleted)
        
    }
}

// MARK: - Hint Overlay

struct HintOverlayView: View {
    let text: String

    var body: some View {
        VStack {
            Spacer()
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.yellow.opacity(0.8))
                    .padding(.top, 1)

                Text(text)
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(.white.opacity(0.88))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.black.opacity(0.72))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
        }
    }
}

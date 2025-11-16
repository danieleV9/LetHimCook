import SwiftUI

struct FridgeAnimationView: View {
    @Binding var isOpen: Bool
    var allowsInteraction: Bool = true
    var onTap: (() -> Void)? = nil

    @State private var doorAngle: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var hingeJitter: Double = 0

    private let maxDoorAngle: Double = 78
    private let doorWidthRatio: CGFloat = 0.56

    private var doorProgress: Double {
        min(max(abs(doorAngle) / maxDoorAngle, 0), 1)
    }

    var body: some View {
        GeometryReader { geo in
            let doorWidth = geo.size.width * doorWidthRatio

            ZStack {
                Image("fridge_opened")
                    .resizable()
                    .scaledToFit()
                    .opacity(doorProgress)
                    .scaleEffect(1 + 0.02 * doorProgress)

                Image("fridge_closed")
                    .resizable()
                    .scaledToFit()

                Image("fridge_closed")
                    .resizable()
                    .scaledToFit()
                    .mask {
                        HStack(spacing: 0) {
                            Rectangle()
                                .frame(width: doorWidth)
                            Spacer(minLength: 0)
                        }
                    }
                    .rotation3DEffect(
                        .degrees(doorAngle + hingeJitter),
                        axis: (x: 0, y: 1, z: 0),
                        anchor: .leading,
                        anchorZ: 0,
                        perspective: 0.8
                    )
                    .shadow(color: .black.opacity(0.18 * (1 - doorProgress)), radius: 18, x: 16, y: 12)

                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.9), Color.white.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(10)
                    .opacity(glowOpacity)
                    .blur(radius: 14)
                    .blendMode(.screen)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                guard allowsInteraction else { return }
                onTap?()
            }
            .onChange(of: isOpen) { _, newValue in
                animateDoor(isOpening: newValue)
            }
            .task {
                animateDoor(isOpening: isOpen)
            }
        }
    }

    private func animateDoor(isOpening: Bool) {
        withAnimation(.interactiveSpring(response: 0.65, dampingFraction: 0.78, blendDuration: 0.25)) {
            doorAngle = isOpening ? -maxDoorAngle : 0
        }

        withAnimation(.easeInOut(duration: 0.45)) {
            glowOpacity = isOpening ? 0.9 : 0
        }

        guard isOpening else {
            hingeJitter = 0
            return
        }

        withAnimation(.easeOut(duration: 0.2)) {
            hingeJitter = -4
        }

        withAnimation(.easeOut(duration: 0.2).delay(0.15)) {
            hingeJitter = 0
        }
    }
}

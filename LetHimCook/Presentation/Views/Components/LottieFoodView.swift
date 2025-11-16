import SwiftUI
import Lottie

struct LottieFoodView: View {

    var body: some View {
        LottieView(animation: .named("lottie-food"))
            .playing(loopMode: .loop)
            .animationSpeed(0.7)
            .accessibilityLabel(Text("fridge_lottie_animation"))
    }
}

#Preview {
    LottieFoodView()
        .frame(height: 260)
        .padding()
}

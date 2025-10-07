import SwiftUI

struct AnimatedGradientBorder: View {
    var cornerRadius: CGFloat = 25
    var lineWidth: CGFloat = 2
    @State private var animateGradient = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .strokeBorder(
                AngularGradient(
                    gradient: Gradient(colors: [
                        Color.green.opacity(0.7),
                        Color.blue.opacity(0.7),
                        Color.purple.opacity(0.7),
                        Color.green.opacity(0.7)
                    ]),
                    center: .center,
                    angle: .degrees(animateGradient ? 360 : 0)
                ),
                lineWidth: lineWidth
            )
            .animation(Animation.linear(duration: 2).repeatForever(autoreverses: false), value: animateGradient)
            .onAppear {
                animateGradient = true
            }
    }
}
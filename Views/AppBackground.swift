import SwiftUI

/// Shared background for the caregiver-facing screens: warm gradient with a white arc.
struct AppBackground: View {

    var circleScale: CGFloat = 1.7
    var offsetY: CGFloat = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.99, green: 0.78, blue: 0.55),
                    Color(red: 0.96, green: 0.55, blue: 0.38),
                    Color(red: 0.93, green: 0.58, blue: 0.70)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.white.opacity(0.3), Color.white.opacity(0)],
                center: .topLeading,
                startRadius: 0,
                endRadius: 700
            )
            .ignoresSafeArea()

            Circle()
                .fill(.white)
                .scaleEffect(circleScale)
                .offset(y: offsetY)
                .shadow(color: Color(red: 0.6, green: 0.25, blue: 0.15).opacity(0.28), radius: 40)
                .ignoresSafeArea()
        }
    }
}

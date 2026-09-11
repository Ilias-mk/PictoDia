import SwiftUI

/// Main menu: entry point to the app's sections.
struct MenuView: View {

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                VStack(spacing: 24) {
                    Text("Vad vill du göra?")
                        .font(.system(size: 32, weight: .regular, design: .serif))
                        .foregroundStyle(.black)
                        .padding(.bottom, 12)

                    NavigationLink { ProfileView() } label: { menuLabel("PROFIL") }
                    NavigationLink { ScheduleInputView() } label: { menuLabel("SCHEMA") }
                    NavigationLink { SavedSchedulesView() } label: { menuLabel("SPARADE SCHEMAN") }
                    NavigationLink { AboutView() } label: { menuLabel("OM APPEN") }
                }
                .padding(.horizontal, 48)
            }
        }
    }

    /// Shared style for the menu buttons.
    private func menuLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.medium)
            .tracking(1.2)
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Capsule()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
            )
    }
}

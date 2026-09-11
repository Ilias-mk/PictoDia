import SwiftUI

/// Information about the app and pictogram attribution.
struct AboutView: View {

    var body: some View {
        ZStack {
            AppBackground(circleScale: 2.1)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    Text("Om appen")
                        .font(.system(size: 32, weight: .regular, design: .serif))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity, alignment: .center)
                    section(
                        title: "Om utvecklaren",
                        text: "Byggd av Ilias, student i datavetenskap vid Stockholms universitet (DSV). Detta är mitt första projekt i Swift och SwiftUI. Appen är utvecklad med spec-driven development: varje funktion har en skriven kravspecifikation i EARS-format och en teknisk plan innan en rad kod skrivs. Arkitekturen följer MVVM med beroendeinjektion i alla tjänster, vilket gör affärslogiken testbar utan nätverk — 26 enhetstester täcker kraven."
                    )

                    section(
                        title: "Vad appen gör",
                        text: "Beskriv dagens plan med några ord. Appen delar upp planen i steg och visar den som en bildsekvens, i kronologisk ordning."
                    )

                    section(
                        title: "Bildstöd",
                        text: "Pictogram från ARASAAC. Upphovsman: Sergio Palao. Licens: Creative Commons BY-NC-SA. Tillhör Aragóns regionregering."
                    )

                    section(
                        title: "Integritet",
                        text: "Texten du skriver skickas till en språkmodell för att tolkas. Ingen information sparas utanför din enhet."
                    )

                    Text("Prototyp — inte en medicinsk produkt.")
                        .font(.caption)
                        .foregroundStyle(Color(white: 0.55))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 12)
                }
                .padding(28)
            }
        }
    }

    private func section(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.black)
            Text(text)
                .font(.footnote)
                .foregroundStyle(Color(white: 0.35))
        }
    }
}

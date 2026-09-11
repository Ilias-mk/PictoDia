import SwiftUI

/// One row of the schedule: pictogram on top, event text below (RF-16).
struct PictogramRowView: View {
    let pictogram: Pictogram
    let number: Int

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("\(number)")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                Spacer()
            }

            if let url = pictogram.imageURL {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 160, height: 160)
            } else {
                // RF-13: generic icon when no pictogram is available
                Image(systemName: "questionmark.square.dashed")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .foregroundStyle(.secondary)
            }

            Text(pictogram.label)
                .font(.title2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

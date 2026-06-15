import SwiftUI

struct ImageRowView: View {
    let image: ImageListItemModel

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "photo.stack")
                .font(.title2)
                .foregroundColor(.purple)

            VStack(alignment: .leading, spacing: 2) {
                Text(image.shortName)
                    .font(.headline)
                    .lineLimit(1)
                if let platforms = image.variants?.map({ "\($0.platform.os)/\($0.platform.architecture)" }).joined(separator: ", ") {
                    Text(platforms)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(image.sizeFormatted)
                .font(.caption)
                .foregroundColor(.secondary)
                .monospaced()

            Text(image.creationDate, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

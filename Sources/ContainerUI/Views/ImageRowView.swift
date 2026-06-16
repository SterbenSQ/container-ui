import SwiftUI

struct ImageRowView: View {
    let image: ImageListItemModel

    var body: some View {
        HStack(spacing: 12) {
            if image.isPlaceholder {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 24, height: 24)
            } else {
                Image(systemName: "photo.stack")
                    .font(.title2)
                    .foregroundColor(.purple)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(image.isPlaceholder ? image.name : image.shortName)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundColor(image.isPlaceholder ? .secondary : .primary)

                if image.isPlaceholder {
                    Text("Pulling...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let platforms = image.variants?.map({ "\($0.platform.os)/\($0.platform.architecture)" }).joined(separator: ", ") {
                    Text(platforms)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if !image.isPlaceholder {
                Text(image.sizeFormatted)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospaced()

                Text(image.creationDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

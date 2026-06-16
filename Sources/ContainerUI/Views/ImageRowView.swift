import SwiftUI

enum PullState: Equatable {
    case none
    case pulling
    case failed(String) // error message
}

struct ImageRowView: View {
    let image: ImageListItemModel
    var pullState: PullState = .none
    var onRetry: (() -> Void)?
    var onRemove: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // Icon / spinner / error indicator
            Group {
                switch pullState {
                case .pulling:
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 24, height: 24)
                case .failed:
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .frame(width: 24, height: 24)
                case .none:
                    Image(systemName: "photo.stack")
                        .font(.title2)
                        .foregroundColor(.purple)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(image.isPlaceholder ? image.name : image.shortName)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundColor(textColor)

                switch pullState {
                case .pulling:
                    Text("Pulling...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                case .failed(let msg):
                    Text(msg)
                        .font(.caption)
                        .foregroundColor(.red)
                        .lineLimit(2)
                case .none:
                    if let platforms = image.variants?.map({ "\($0.platform.os)/\($0.platform.architecture)" }).joined(separator: ", ") {
                        Text(platforms)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            if pullState == .none {
                Text(image.sizeFormatted)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospaced()

                Text(image.creationDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Retry / Remove buttons on failure
            if pullState.isFailed, let onRetry = onRetry, let onRemove = onRemove {
                Button {
                    onRetry()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("Retry pull")

                Button {
                    onRemove()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("Remove")
            }
        }
        .padding(.vertical, 4)
    }

    private var textColor: Color {
        if case .failed = pullState { return .red }
        if image.isPlaceholder { return .secondary }
        return .primary
    }
}

extension PullState {
    var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }
}

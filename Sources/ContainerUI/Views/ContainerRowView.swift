import SwiftUI

struct ContainerRowView: View {
    let container: ContainerListItemModel
    var onDelete: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            // Container info
            VStack(alignment: .leading, spacing: 2) {
                Text(container.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(container.image)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // IP address
            if let ip = container.ipAddress {
                Text(ip)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospaced()
            }

            // Status badge
            Text(container.state.capitalized)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(statusColor.opacity(0.2))
                .foregroundColor(statusColor)
                .clipShape(Capsule())

            // Created date
            Text(container.created, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)

            // Delete button
            if let onDelete = onDelete {
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .help("Delete container")
            }
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        switch container.containerState {
        case .running: return .green
        case .stopped: return .red
        case .stopping: return .orange
        case .unknown: return .gray
        }
    }
}

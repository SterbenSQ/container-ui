import SwiftUI

struct ContainerRowView: View {
    let container: ContainerListItemModel
    var onDelete: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // Status dot with gradient + glow
            statusDot

            VStack(alignment: .leading, spacing: 2) {
                Text(container.name)
                    .font(.system(.headline, design: .rounded))
                    .lineLimit(1)
                Text(container.image)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if let ip = container.ipAddress {
                Text(ip)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospaced()
            }

            // Status badge with gradient
            Text(container.state.capitalized)
                .font(.caption2.weight(.medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .foregroundColor(.white)
                .background(statusGradient)
                .clipShape(Capsule())

            Text(container.created, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)

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

    private var statusDot: some View {
        Circle()
            .fill(statusGradient)
            .frame(width: 10, height: 10)
            .shadow(color: statusColor.opacity(0.5), radius: 4)
    }

    private var statusGradient: LinearGradient {
        switch container.containerState {
        case .running: return DT.Gradient.green
        case .stopped: return DT.Gradient.red
        case .stopping: return DT.Gradient.orange
        case .unknown: return LinearGradient(colors: [.gray, .gray.opacity(0.7)], startPoint: .top, endPoint: .bottom)
        }
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

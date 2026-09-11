import SwiftUI

struct ConnectionBadge: View {
    let state: ConnectionState

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.caption.weight(.semibold))

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(minHeight: 44)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("连接状态：\(label)")
    }

    private var label: String {
        switch state {
        case .notConfigured: "设置 iPhone"
        case .ready: "就绪"
        case .connecting: "正在连接…"
        case .active: "会话运行中"
        case .failed: "连接错误"
        }
    }

    private var color: Color {
        switch state {
        case .notConfigured: .orange
        case .ready: .green
        case .connecting: .blue
        case .active: .blue
        case .failed: .red
        }
    }
}

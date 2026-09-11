import SwiftUI

struct StatusCard: View {
    let state: ConnectionState

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private var title: String {
        switch state {
        case .notConfigured: "未配置"
        case .ready: "就绪"
        case .connecting: "正在连接"
        case .active: "位置会话运行中"
        case .failed: "连接错误"
        }
    }

    private var detail: String {
        switch state {
        case .notConfigured: "尚未添加配对支持。"
        case .ready: "已配对设备可用。"
        case .connecting: "漫游控制正在准备安全设备会话。"
        case .active: "漫游控制正在控制会话。"
        case .failed(let message): message
        }
    }

    private var iconName: String {
        switch state {
        case .notConfigured: "circle.dashed"
        case .ready: "checkmark.circle.fill"
        case .connecting: "arrow.triangle.2.circlepath"
        case .active: "location.fill"
        case .failed: "exclamationmark.triangle.fill"
        }
    }

    private var tint: Color {
        switch state {
        case .notConfigured: .secondary
        case .ready: .green
        case .connecting: .blue
        case .active: .blue
        case .failed: .red
        }
    }
}

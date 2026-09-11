import SwiftUI

struct MobileDataGuidanceView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let guidance: MobileDataGuidance
    let onOpenLocalDevVPN: () -> Void
    let onRetry: () -> Void
    let onUseMobileData: () -> Void
    let onMobileDataOff: () -> Void
    let onCancel: () -> Void
    let onDone: () -> Void

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView(.vertical, showsIndicators: false) {
                    content
                }
                .frame(maxHeight: 540)
            } else {
                content
            }
        }
        .padding(.horizontal, dynamicTypeSize.isAccessibilitySize ? 20 : 28)
        .padding(.top, 12)
        .padding(.bottom, 26)
        .frame(maxWidth: 520)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.24), radius: 28, y: 12)
    }

    private var content: some View {
        VStack(spacing: 22) {
            Capsule()
                .fill(.secondary.opacity(0.45))
                .frame(width: 38, height: 5)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: iconColours,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(
                        width: dynamicTypeSize.isAccessibilitySize ? 68 : 82,
                        height: dynamicTypeSize.isAccessibilitySize ? 68 : 82
                    )

                Image(systemName: iconSymbol)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 10) {
                Text(title)
                    .font(.title2.bold())

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if guidance == .connectionHelp {
                Label(
                    "漫游控制尚未找到 LocalDevVPN 的设备连接。",
                    systemImage: "lock.shield"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

                Button("重试", action: onRetry)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)

                Button("打开 LocalDevVPN", action: onOpenLocalDevVPN)
                    .buttonStyle(.bordered)

                Button("我正在使用移动数据", action: onUseMobileData)
                    .buttonStyle(.bordered)

                Button("取消", role: .cancel, action: onCancel)
                    .foregroundStyle(.secondary)
            } else if guidance == .turnOff {
                HStack(spacing: 9) {
                    ProgressView()
                    Text("正在检测此 iPhone…")
                        .font(.subheadline.weight(.semibold))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 11)
                .background(.thinMaterial, in: Capsule())

                Label(
                    "漫游控制应会自动继续。如果没有，请点击“继续”。",
                    systemImage: "checkmark.seal.fill"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

                Button("继续", action: onMobileDataOff)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)

                Button("打开 LocalDevVPN", action: onOpenLocalDevVPN)
                    .buttonStyle(.bordered)

                Button("取消", role: .cancel, action: onCancel)
                    .foregroundStyle(.secondary)
            } else {
                Label("位置控制已启动", systemImage: "location.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)

                Button("完成", action: onDone)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var title: String {
        switch guidance {
        case .connectionHelp:
            "仍在连接"
        case .turnOff:
            "关闭移动数据"
        case .turnBackOn:
            "重新打开移动数据"
        }
    }

    private var message: String {
        switch guidance {
        case .connectionHelp:
            "如果你使用的是 Wi‑Fi，请确认 LocalDevVPN 显示“已连接”，然后重试。仅在确实使用 4G 或 5G 时选择移动数据。"
        case .turnOff:
            "请确认 LocalDevVPN 已连接，短暂关闭移动数据后，再返回漫游控制。"
        case .turnBackOn:
            "安全位置会话已就绪。现在可以恢复移动数据，位置模拟会继续通过 5G 运行。"
        }
    }

    private var iconColours: [Color] {
        switch guidance {
        case .connectionHelp: [.purple, .indigo]
        case .turnOff: [.indigo, .blue]
        case .turnBackOn: [.green, .teal]
        }
    }

    private var iconSymbol: String {
        switch guidance {
        case .connectionHelp: "lock.shield.fill"
        case .turnOff: "antenna.radiowaves.left.and.right"
        case .turnBackOn: "checkmark"
        }
    }
}

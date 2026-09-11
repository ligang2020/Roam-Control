import SwiftUI

struct SessionRecoveryView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let recovery: SessionRecoveryRecord
    let isPaired: Bool
    let isResuming: Bool
    let isRestoring: Bool
    let errorMessage: String?
    let onResume: () -> Void
    let onRestore: () -> Void
    let onAlreadyRestored: () -> Void
    let onCancel: () -> Void

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
        .padding(.horizontal, dynamicTypeSize.isAccessibilitySize ? 20 : 26)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .frame(maxWidth: 520)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.24), radius: 28, y: 12)
    }

    private var content: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(.secondary.opacity(0.45))
                .frame(width: 38, height: 5)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(
                        width: dynamicTypeSize.isAccessibilitySize ? 66 : 78,
                        height: dynamicTypeSize.isAccessibilitySize ? 66 : 78
                    )

                Image(systemName: recovery.isWalkingRoute ? "figure.walk.motion" : "location.fill")
                    .font(.system(size: 31, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 9) {
                Text("上次会话已中断")
                    .font(.title2.bold())

                Text(summaryText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 10) {
                recoveryDetail(
                    title: recovery.isWalkingRoute ? "上次保存的位置" : "上次位置",
                    value: recovery.lastReportedLocation.name,
                    symbol: "mappin.and.ellipse"
                )

                if let destination = recovery.destination, recovery.isWalkingRoute {
                    recoveryDetail(
                        title: "目的地",
                        value: destination.name,
                        symbol: "flag.checkered"
                    )
                }

                recoveryDetail(
                    title: "上次活动时间",
                    value: recovery.updatedAt.formatted(date: .abbreviated, time: .shortened),
                    symbol: "clock"
                )
            }
            .padding(14)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            if isResuming || isRestoring {
                HStack(spacing: 10) {
                    ProgressView()
                    Text(isRestoring ? "正在恢复真实位置…" : "正在准备路线…")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)

                Button("取消", role: .cancel, action: onCancel)
                    .foregroundStyle(.secondary)
            } else {
                Button(action: onResume) {
                    Label(resumeTitle, systemImage: recovery.isWalkingRoute ? "figure.walk" : "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!isPaired)

                Button(role: .destructive, action: onRestore) {
                    Label("恢复真实位置", systemImage: "location.slash.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(!isPaired)

                Button("我的真实位置已恢复", action: onAlreadyRestored)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !isPaired {
                Label("请先配对此 iPhone，再继续或恢复会话。", systemImage: "iphone.and.arrow.forward")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("恢复过程只会短暂重新连接以清除模拟位置，不会自动启动任何操作。")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var summaryText: String {
        if let destination = recovery.destination, recovery.isWalkingRoute {
            return "步行前往 \(destination.name) 时，漫游控制未收到正常结束信号。你可以从上次保存的位置继续，或安全地恢复真实位置。"
        }

        return "位置 \(recovery.lastReportedLocation.name) 的会话未收到正常结束信号。请选择此 iPhone 接下来要执行的操作。"
    }

    private var resumeTitle: String {
        recovery.isWalkingRoute ? "继续步行" : "继续位置控制"
    }

    private func recoveryDetail(title: String, value: String, symbol: String) -> some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                HStack(alignment: .top, spacing: 11) {
                    Image(systemName: symbol)
                        .foregroundStyle(.blue)
                        .frame(width: 22)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(value)
                            .font(.caption.weight(.semibold))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(spacing: 11) {
                    Image(systemName: symbol)
                        .foregroundStyle(.blue)
                        .frame(width: 22)

                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 8)

                    Text(value)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(value)")
    }
}

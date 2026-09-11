import SwiftUI

struct ConnectionHealthView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var diagnostics = ConnectionDiagnosticsCoordinator()
    @State private var isShowingDeviceSetup = false

    var body: some View {
        List {
            Section("连接健康度") {
                healthRow(
                    title: "配对",
                    value: pairingValue,
                    symbol: pairingSymbol,
                    color: pairingColor
                )

                healthRow(
                    title: "LocalDevVPN",
                    value: localDevVPNValue,
                    symbol: localDevVPNSymbol,
                    color: localDevVPNColor
                )

                healthRow(
                    title: "位置会话",
                    value: sessionValue,
                    symbol: sessionSymbol,
                    color: sessionColor
                )
            }

            Section("当前位置") {
                LabeledContent("地点", value: activeTarget?.name ?? "无")
                LabeledContent("坐标", value: coordinatesValue)

                if let activeTarget, !activeTarget.subtitle.isEmpty {
                    LabeledContent("区域", value: activeTarget.subtitle)
                }
            }

            Section {
                Button {
                    Task { await runConnectionCheck() }
                } label: {
                    HStack {
                        Label("运行连接检查", systemImage: "stethoscope")
                        Spacer()
                        if diagnostics.state == .running {
                            ProgressView()
                        }
                    }
                }
                .disabled(diagnostics.state == .running)

                if let resultMessage {
                    Label(resultMessage, systemImage: resultSymbol)
                        .font(.subheadline)
                        .foregroundStyle(resultColor)
                }

                if let lastChecked = diagnostics.lastChecked {
                    LabeledContent(
                        "上次检查",
                        value: lastChecked.formatted(date: .omitted, time: .shortened)
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            } header: {
                Text("连接检查")
            } footer: {
                Text("此检查会验证已保存的配对记录，以及通过 LocalDevVPN 是否能发现已配对的 iPhone。它不会启动、更改或停止位置控制。")
            }

            Section {
                ShareLink(
                    item: diagnosticsText,
                    subject: Text("漫游控制诊断")
                ) {
                    Label("分享诊断信息", systemImage: "square.and.arrow.up")
                }
            } footer: {
                Text("使用 iOS 分享面板选择发送或保存报告的位置。报告绝不包含配对密钥或 PIN 码。")
            }

            Section("帮助") {
                Button {
                    isShowingDeviceSetup = true
                } label: {
                    Label("配对与连接", systemImage: "iphone.and.arrow.forward")
                }
                .foregroundStyle(.primary)

                Link(destination: appModel.localDevVPNInstallURL) {
                    Label("在 App Store 中打开 LocalDevVPN", systemImage: "arrow.up.right.square")
                }
            }
        }
        .navigationTitle("连接健康度")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            diagnostics.cancel()
        }
        .sheet(isPresented: $isShowingDeviceSetup) {
            PairingSetupView()
                .environment(appModel)
        }
    }

    private var activeTarget: LocationTarget? {
        if case .active(let target) = appModel.deviceSession.phase {
            return target
        }
        return nil
    }

    private var coordinatesValue: String {
        guard let activeTarget else { return "无" }
        return String(format: "%.5f, %.5f", activeTarget.latitude, activeTarget.longitude)
    }

    private var pairingValue: String {
        switch appModel.pairingStatus {
        case .checking: "检查中"
        case .importing: "导入中"
        case .notPaired: "未配对"
        case .paired: "就绪"
        case .failed: "有问题"
        }
    }

    private var pairingSymbol: String {
        switch appModel.pairingStatus {
        case .checking, .importing: "arrow.triangle.2.circlepath"
        case .notPaired: "exclamationmark.circle"
        case .paired: "checkmark.circle.fill"
        case .failed: "xmark.circle.fill"
        }
    }

    private var pairingColor: Color {
        switch appModel.pairingStatus {
        case .checking, .importing: .blue
        case .notPaired: .orange
        case .paired: .green
        case .failed: .red
        }
    }

    private var localDevVPNValue: String {
        switch diagnostics.state {
        case .notRun:
            if case .active = appModel.deviceSession.phase { return "已连接" }
            return "未检查"
        case .running: return "检查中"
        case .passed: return "可访问"
        case .failed: return "无法访问"
        }
    }

    private var localDevVPNSymbol: String {
        switch diagnostics.state {
        case .notRun:
            if case .active = appModel.deviceSession.phase { return "checkmark.circle.fill" }
            return "questionmark.circle"
        case .running: return "arrow.triangle.2.circlepath"
        case .passed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }

    private var localDevVPNColor: Color {
        switch diagnostics.state {
        case .notRun:
            if case .active = appModel.deviceSession.phase { return .green }
            return .secondary
        case .running: return .blue
        case .passed: return .green
        case .failed: return .red
        }
    }

    private var sessionValue: String {
        switch appModel.deviceSession.phase {
        case .idle: "未活动"
        case .openingLocalDevVPN: "正在打开 LocalDevVPN"
        case .discovering: "正在查找此 iPhone"
        case .connecting: "正在连接"
        case .active: "活动中"
        case .stopping: "正在停止"
        case .failed: "失败"
        }
    }

    private var sessionSymbol: String {
        switch appModel.deviceSession.phase {
        case .idle: "pause.circle"
        case .openingLocalDevVPN, .discovering, .connecting: "arrow.triangle.2.circlepath"
        case .active: "location.circle.fill"
        case .stopping: "stop.circle"
        case .failed: "exclamationmark.triangle.fill"
        }
    }

    private var sessionColor: Color {
        switch appModel.deviceSession.phase {
        case .idle: .secondary
        case .openingLocalDevVPN, .discovering, .connecting, .stopping: .blue
        case .active: .green
        case .failed: .red
        }
    }

    private var resultMessage: String? {
        switch diagnostics.state {
        case .notRun, .running: nil
        case .passed(let message), .failed(let message): message
        }
    }

    private var resultSymbol: String {
        switch diagnostics.state {
        case .passed: "checkmark.circle.fill"
        case .failed: "exclamationmark.triangle.fill"
        case .notRun, .running: "circle"
        }
    }

    private var resultColor: Color {
        switch diagnostics.state {
        case .passed: .green
        case .failed: .red
        case .notRun, .running: .secondary
        }
    }

    private func healthRow(
        title: String,
        value: String,
        symbol: String,
        color: Color
    ) -> some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: symbol)
                        .foregroundStyle(color)
                        .frame(width: 22)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                        Text(value)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                HStack(spacing: 12) {
                    Image(systemName: symbol)
                        .foregroundStyle(color)
                        .frame(width: 22)
                    Text(title)
                    Spacer()
                    Text(value)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(value)")
    }

    @MainActor
    private func runConnectionCheck() async {
        do {
            let pairingRecord = try await appModel.pairingService.pairingRecordData()
            diagnostics.run(
                pairingRecord: pairingRecord,
                sessionPhase: appModel.deviceSession.phase
            )
        } catch {
            diagnostics.run(pairingRecord: nil, sessionPhase: appModel.deviceSession.phase)
        }
    }

    private var diagnosticsText: String {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "未知"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "未知"
        let checked = diagnostics.lastChecked?.formatted(date: .numeric, time: .standard) ?? "未运行"

        return """
        漫游控制诊断报告
        生成时间：\(Date().formatted(date: .numeric, time: .standard))
        应用：\(appVersion)（\(build)）
        iOS：\(UIDevice.current.systemVersion)
        配对：\(pairingValue)
        LocalDevVPN：\(localDevVPNValue)
        会话：\(sessionValue)
        活动地点：\(activeTarget?.name ?? "无")
        坐标：\(coordinatesValue)
        上次连接检查：\(checked)
        连接检查结果：\(diagnosticResultText)
        外观：\(appModel.appearance.title)
        地图样式：\(appModel.mapDisplayStyle.title)
        """
    }

    private var diagnosticResultText: String {
        switch diagnostics.state {
        case .notRun: "未运行"
        case .running: "运行中"
        case .passed(let message): "通过 — \(message)"
        case .failed(let message): "失败 — \(message)"
        }
    }
}

#Preview {
    NavigationStack {
        ConnectionHealthView()
            .environment(AppModel())
    }
}

import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isShowingDeviceSetup = false
    @State private var isReplayingOnboarding = false
    @State private var isConfirmingReset = false
    @State private var resetError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("外观") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("主题")
                            .font(.subheadline.weight(.medium))

                        themePicker
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("地图样式")
                            .font(.subheadline.weight(.medium))

                        mapStylePicker
                    }
                    .padding(.vertical, 4)
                }

                Section("设备") {
                    NavigationLink {
                        ConnectionHealthView()
                            .environment(appModel)
                    } label: {
                        Label("连接健康度", systemImage: "stethoscope")
                    }

                    Button {
                        isShowingDeviceSetup = true
                    } label: {
                        Label {
                            pairingConnectionLabel
                        } icon: {
                            Image(systemName: "iphone.and.arrow.forward")
                        }
                    }
                    .foregroundStyle(.primary)
                }

                Section {
                    Toggle(
                        "分享匿名使用统计",
                        isOn: anonymousUsageStatisticsBinding
                    )

                    NavigationLink {
                        UsageStatisticsPrivacyView()
                    } label: {
                        Label("分享内容", systemImage: "hand.raised.fill")
                    }
                } header: {
                    Text("隐私")
                } footer: {
                    Text("可选功能，默认关闭。用于估算参与安装的活动量，绝不包含位置、搜索和配对数据。")
                }

                Section("关于") {
                    NavigationLink {
                        AboutRoamControlView()
                    } label: {
                        Label("关于漫游控制", systemImage: "info.circle")
                    }

                    LabeledContent("版本", value: versionText)
                    LabeledContent("构建号", value: buildNumberText)
                    LabeledContent("构建时间", value: buildDateText)

                    Button {
                        isReplayingOnboarding = true
                    } label: {
                        Label("重新查看介绍", systemImage: "sparkles")
                    }
                    .foregroundStyle(.primary)
                }

                Section {
                    Button("重置漫游控制", role: .destructive) {
                        isConfirmingReset = true
                    }
                } footer: {
                    Text("这会清除配对记录和本地应用设置，然后重新显示引导，不会移除或更改 LocalDevVPN。")
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .preferredColorScheme(preferredColorScheme)
        .sheet(isPresented: $isShowingDeviceSetup) {
            PairingSetupView()
                .environment(appModel)
        }
        .fullScreenCover(isPresented: $isReplayingOnboarding) {
            OnboardingView(isReplay: true)
                .environment(appModel)
        }
        .confirmationDialog(
            "重置漫游控制？",
            isPresented: $isConfirmingReset,
            titleVisibility: .visible
        ) {
            Button("重置应用", role: .destructive) {
                Task { await resetApp() }
            }
        } message: {
            Text("你的配对记录和本地选择将被移除，并返回欢迎界面。")
        }
        .alert("无法完成重置", isPresented: isShowingResetError) {
            Button("好", role: .cancel) {
                resetError = nil
            }
        } message: {
            Text(resetError ?? "请重试。")
        }
    }

    private var connectionLabel: String {
        switch appModel.connectionState {
        case .notConfigured: "未配对"
        case .ready: "就绪"
        case .connecting: "正在连接"
        case .active: "活动中"
        case .failed: "有问题"
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch appModel.appearance {
        case .automatic: nil
        case .light: .light
        case .dark: .dark
        }
    }

    private var appearanceBinding: Binding<AppAppearance> {
        Binding(
            get: { appModel.appearance },
            set: appModel.setAppearance
        )
    }

    @ViewBuilder
    private var themePicker: some View {
        if dynamicTypeSize.isAccessibilitySize {
            Picker("主题", selection: appearanceBinding) {
                ForEach(AppAppearance.allCases) { appearance in
                    Label(appearance.title, systemImage: appearance.systemImage)
                        .tag(appearance)
                }
            }
            .pickerStyle(.menu)
        } else {
            Picker("主题", selection: appearanceBinding) {
                ForEach(AppAppearance.allCases) { appearance in
                    Label(appearance.title, systemImage: appearance.systemImage)
                        .tag(appearance)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    @ViewBuilder
    private var mapStylePicker: some View {
        if dynamicTypeSize.isAccessibilitySize {
            Picker("地图样式", selection: mapStyleBinding) {
                ForEach(MapDisplayStyle.allCases) { style in
                    Text(style.title).tag(style)
                }
            }
            .pickerStyle(.menu)
        } else {
            Picker("地图样式", selection: mapStyleBinding) {
                ForEach(MapDisplayStyle.allCases) { style in
                    Text(style.title).tag(style)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    @ViewBuilder
    private var pairingConnectionLabel: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 3) {
                Text("配对与连接")
                Text(connectionLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack {
                Text("配对与连接")
                Spacer()
                Text(connectionLabel)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var mapStyleBinding: Binding<MapDisplayStyle> {
        Binding(
            get: { appModel.mapDisplayStyle },
            set: appModel.setMapDisplayStyle
        )
    }

    private var anonymousUsageStatisticsBinding: Binding<Bool> {
        Binding(
            get: { appModel.sharesAnonymousUsageStatistics },
            set: appModel.setSharesAnonymousUsageStatistics
        )
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return version ?? "1.0"
    }

    private var buildNumberText: String {
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        return build ?? "未知"
    }

    private var buildDateText: String {
        if
            let timestamp = Bundle.main.object(
                forInfoDictionaryKey: "RoamControlBuildTimestamp"
            ) as? String,
            let buildDate = ISO8601DateFormatter().date(from: timestamp)
        {
            return buildDate.formatted(date: .abbreviated, time: .shortened)
        }

        guard
            let executableURL = Bundle.main.executableURL,
            let values = try? executableURL.resourceValues(forKeys: [.contentModificationDateKey]),
            let buildDate = values.contentModificationDate
        else { return "未知" }

        return buildDate.formatted(date: .abbreviated, time: .shortened)
    }

    private var isShowingResetError: Binding<Bool> {
        Binding(
            get: { resetError != nil },
            set: { if !$0 { resetError = nil } }
        )
    }

    @MainActor
    private func resetApp() async {
        do {
            try await appModel.resetApp()
            dismiss()
        } catch {
            resetError = error.localizedDescription
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppModel())
}

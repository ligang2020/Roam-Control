import SwiftUI
import UniformTypeIdentifiers

struct PairingSetupView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isImporting = false
    @State private var isConfirmingRemoval = false

    private let localDevVPNURL = URL(string: "https://apps.apple.com/app/localdevvpn/id6755608044")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    statusCard
                    requirementsCard
                    privacyCard
                }
                .padding(16)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("设备设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: allowedPairingTypes,
            allowsMultipleSelection: false
        ) { result in
            guard case .success(let urls) = result, let url = urls.first else { return }
            Task { await appModel.importPairingRecord(from: url) }
        }
        .confirmationDialog(
            "移除此配对记录？",
            isPresented: $isConfirmingRemoval,
            titleVisibility: .visible
        ) {
            Button("移除配对", role: .destructive) {
                Task { await appModel.removePairingRecord() }
            }
        } message: {
            Text("漫游控制需要新的 RPPairing 文件才能再次连接。")
        }
    }

    private var statusCard: some View {
        setupCard {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: statusSymbol)
                    .font(.title2)
                    .foregroundStyle(statusColor)
                    .frame(width: 32)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    Text(statusTitle)
                        .font(.headline)
                    Text(statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(statusTitle). \(statusMessage)")

            if case .paired(let summary) = appModel.pairingStatus {
                Divider()

                pairingDetail(title: "指纹", value: summary.fingerprint, monospaced: true)

                pairingDetail(
                    title: "添加时间",
                    value: summary.importedAt.formatted(date: .abbreviated, time: .shortened)
                )

                Button("替换配对文件") {
                    isImporting = true
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)

                Button("移除配对", role: .destructive) {
                    isConfirmingRemoval = true
                }
                .frame(maxWidth: .infinity)
            } else {
                pairingProgress

                if appModel.onDevicePairing.isAvailableOnThisDevice {
                    if appModel.onDevicePairing.isRunning {
                        Button("取消配对", role: .cancel) {
                            appModel.cancelOnDevicePairing()
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                    } else {
                        Button {
                            appModel.startOnDevicePairing()
                        } label: {
                            Label("配对此 iPhone", systemImage: "iphone.and.arrow.forward")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(isBusy)
                    }
                } else {
                    Label("设备端配对需要使用实体 iPhone。", systemImage: "iphone")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Button {
                    isImporting = true
                } label: {
                    Label("导入现有文件", systemImage: "doc.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isBusy)
            }
        }
    }

    @ViewBuilder
    private var pairingProgress: some View {
        switch appModel.onDevicePairing.phase {
        case .idle, .success, .failed:
            EmptyView()

        case .preparing:
            Divider()
            Label {
                Text("正在准备安全配对会话…")
            } icon: {
                ProgressView()
            }
            .font(.subheadline)

        case .waitingForSettings:
            Divider()
            VStack(alignment: .leading, spacing: 10) {
                Text("在“设置”中完成")
                    .font(.subheadline.weight(.semibold))
                instructionRow("打开“设置”›“隐私与安全性”›“开发者模式”。")
                instructionRow("点击“与漫游控制配对”。")
                instructionRow("iOS 要求输入时，请使用此处显示的代码。")
            }

        case .showingPIN(let pin):
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Text("在“设置”中输入此代码")
                    .font(.subheadline.weight(.semibold))
                Text(pin.map(String.init).joined(separator: " "))
                    .font(.largeTitle.weight(.semibold))
                    .fontDesign(.rounded)
                    .monospacedDigit()
                    .foregroundStyle(.blue)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .accessibilityLabel("配对代码 \(pin)")
                Text("代码由此 iPhone 生成，并会在本次配对尝试结束后失效。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        case .storing:
            Divider()
            Label {
                Text("正在将配对记录安全存入钥匙串…")
            } icon: {
                ProgressView()
            }
            .font(.subheadline)

        case .cancelling:
            Divider()
            Label {
                Text("正在停止配对…")
            } icon: {
                ProgressView()
            }
            .font(.subheadline)
        }
    }

    private var requirementsCard: some View {
        setupCard {
            Text("连接前准备")
                .font(.headline)

            requirementRow(number: "1", text: "在此配对此 iPhone，或导入现有的 RPPairing 文件。")
            requirementRow(number: "2", text: "安装并开启 LocalDevVPN。")
            requirementRow(number: "3", text: "保持 iPhone 的开发者模式开启。")

            Link(destination: localDevVPNURL) {
                Label("查看 LocalDevVPN", systemImage: "arrow.up.right.square")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Text("iOS 27 提供了设备端配对功能。模拟器可以测试界面，但 Apple 仅在实体 iPhone 上提供真实握手流程。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var privacyCard: some View {
        setupCard {
            Label("已安全存储", systemImage: "lock.shield")
                .font(.headline)
                .foregroundStyle(.green)

            Text("配对记录会在此 iPhone 上生成或检查，然后仅存储在本机钥匙串中。漫游控制不会上传它。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func setupCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14, content: content)
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func requirementRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(.blue, in: Circle())

            Text(text)
                .font(.subheadline)
                .padding(.top, 2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("第 \(number) 步：\(text)")
    }

    private func instructionRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.blue)
                .padding(.top, 3)
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }

    private func pairingDetail(
        title: String,
        value: String,
        monospaced: Bool = false
    ) -> some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .foregroundStyle(.secondary)
                    Text(value)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(monospaced ? .caption.monospaced() : .caption)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                LabeledContent(title, value: value)
                    .font(monospaced ? .caption.monospaced() : .caption)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(value)")
    }

    private var allowedPairingTypes: [UTType] {
        var types: [UTType] = [.propertyList]
        if let mobileDevicePairing = UTType(filenameExtension: "mobiledevicepairing") {
            types.append(mobileDevicePairing)
        }
        return types
    }

    private var isBusy: Bool {
        appModel.pairingStatus == .checking
            || appModel.pairingStatus == .importing
            || appModel.onDevicePairing.isRunning
    }

    private var statusSymbol: String {
        switch appModel.onDevicePairing.phase {
        case .preparing, .waitingForSettings, .showingPIN, .storing, .cancelling:
            return "iphone.radiowaves.left.and.right"
        case .failed:
            return "exclamationmark.triangle.fill"
        case .idle, .success:
            break
        }

        switch appModel.pairingStatus {
        case .checking, .importing: return "arrow.triangle.2.circlepath"
        case .notPaired: return "iphone.badge.exclamationmark"
        case .paired: return "checkmark.shield.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }

    private var statusColor: Color {
        switch appModel.onDevicePairing.phase {
        case .preparing, .waitingForSettings, .showingPIN, .storing, .cancelling:
            return .blue
        case .failed:
            return .red
        case .idle, .success:
            break
        }

        switch appModel.pairingStatus {
        case .checking, .importing: return .blue
        case .notPaired: return .orange
        case .paired: return .green
        case .failed: return .red
        }
    }

    private var statusTitle: String {
        switch appModel.onDevicePairing.phase {
        case .preparing: return "正在准备配对"
        case .waitingForSettings: return "可在“设置”中继续"
        case .showingPIN: return "配对代码已准备好"
        case .storing: return "正在完成配对"
        case .cancelling: return "正在停止配对"
        case .failed: return "配对出现问题"
        case .idle, .success: break
        }

        switch appModel.pairingStatus {
        case .checking: return "正在检查此 iPhone"
        case .importing: return "正在检查配对文件"
        case .notPaired: return "需要配对"
        case .paired: return "配对文件已就绪"
        case .failed: return "配对出现问题"
        }
    }

    private var statusMessage: String {
        switch appModel.onDevicePairing.phase {
        case .preparing:
            return "正在此 iPhone 上启动私密会话。"
        case .waitingForSettings:
            return "漫游控制已显示在 iOS 配对界面中。"
        case .showingPIN:
            return "请在“设置”中输入六位代码进行确认。"
        case .storing:
            return "握手成功，正在安全保存密钥。"
        case .cancelling:
            return "正在关闭本地会话和广播。"
        case .failed(let message):
            return message
        case .idle, .success:
            break
        }

        switch appModel.pairingStatus {
        case .checking:
            return "正在查找安全存储的配对记录。"
        case .importing:
            return "正在验证记录及其密钥。"
        case .notPaired:
            return appModel.onDevicePairing.isAvailableOnThisDevice
                ? "在此 iPhone 上安全创建配对，或导入现有文件。"
                : "连接实体 iPhone 以创建配对，或导入现有文件。"
        case .paired:
            return "LocalDevVPN 会话层连接后，漫游控制可以使用此记录。"
        case .failed(let message):
            return message
        }
    }
}

#Preview {
    PairingSetupView()
        .environment(AppModel())
}

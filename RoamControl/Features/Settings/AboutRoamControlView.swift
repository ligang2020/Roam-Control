import SwiftUI

struct AboutRoamControlView: View {
    var body: some View {
        List {
            appSummary
            quickStart

            Section("选择位置") {
                guideRow(
                    "搜索",
                    symbol: "magnifyingglass",
                    text: "按名称查找地点，或输入纬度和经度。选择结果后会清除搜索内容，方便进行下一次搜索。"
                )
                guideRow(
                    "点击地图",
                    symbol: "hand.tap",
                    text: "在地图任意位置放置精确标记。点击卡片上的关闭按钮即可清除该标记。"
                )
                guideRow(
                    "收藏",
                    symbol: "heart",
                    text: "保存所选地点，方便以后快速使用。你可以在已保存地点页面重命名或移除收藏。"
                )
                guideRow(
                    "收藏与历史记录",
                    symbol: "list.bullet.rectangle",
                    text: "打开已保存的收藏和最近使用的位置。向左滑动项目即可移除。"
                )
                guideRow(
                    "继续上次位置",
                    symbol: "arrow.clockwise",
                    text: "快速再次选择最近的位置。如果不再需要此建议，请点击关闭按钮。"
                )
            }

            Section("地图控制") {
                guideRow(
                    "当前位置",
                    symbol: "location.fill",
                    text: "回到此 iPhone 的真实位置，并让地图恢复正北朝上。"
                )
                guideRow(
                    "指南针",
                    symbol: "safari",
                    text: "地图旋转后显示。它会显示地图方向，点击即可再次朝向正北。"
                )
                guideRow(
                    "连接状态",
                    symbol: "circle.fill",
                    text: "显示漫游控制是否就绪、连接中或活动中。点击可查看配对和连接详情。"
                )
                guideRow(
                    "设置",
                    symbol: "gearshape.fill",
                    text: "更改外观和地图样式、检查连接、管理配对并查看应用信息。"
                )
            }

            Section("位置控制") {
                guideRow(
                    "开始位置控制",
                    symbol: "location.fill",
                    text: "开始将所选地点报告为此 iPhone 的位置。必须先连接 LocalDevVPN。"
                )
                guideRow(
                    "更新位置",
                    symbol: "arrow.triangle.2.circlepath",
                    text: "将活动位置会话移动到新选择的地点，无需重新开始整个连接流程。"
                )
                guideRow(
                    "停止位置控制",
                    symbol: "location.slash.fill",
                    text: "结束活动会话并恢复此 iPhone 的真实位置。"
                )
                guideRow(
                    "移动数据提示",
                    symbol: "antenna.radiowaves.left.and.right",
                    text: "使用移动数据时，请在提示后暂时关闭。建立本地连接后漫游控制会自动继续，并提示你何时可以重新开启移动数据。"
                )
                guideRow(
                    "中断会话恢复",
                    symbol: "arrow.trianglehead.2.clockwise.rotate.90",
                    text: "如果漫游控制未收到正常结束信号，下次启动时可以选择继续、短暂重连以恢复真实位置，或确认真实位置已经恢复。"
                )
            }

            Section("步行路线") {
                guideRow(
                    "预览步行路线",
                    symbol: "figure.walk",
                    text: "在开始任何操作前，请 Apple 地图规划从当前位置到所选目的地的步行路线。"
                )
                guideRow(
                    "步行速度",
                    symbol: "speedometer",
                    text: "选择模拟位置沿路线移动的速度。"
                )
                guideRow(
                    "开始步行",
                    symbol: "figure.walk.motion",
                    text: "开始让报告的位置沿预览路线移动。步行过程中可以使用其他应用。"
                )
                guideRow(
                    "暂停或继续",
                    symbol: "pause.fill",
                    text: "保持路线上的当前位置，然后从暂停处准确继续。"
                )
                guideRow(
                    "沿路线返回",
                    symbol: "arrow.uturn.backward",
                    text: "到达后反向行走，沿原路线返回。"
                )
                guideRow(
                    "新位置",
                    symbol: "mappin.and.ellipse",
                    text: "保持活动会话并返回地图，以便选择其他目的地。"
                )
                guideRow(
                    "停止并恢复",
                    symbol: "stop.fill",
                    text: "停止步行、清除路线并恢复真实位置。确认步骤有助于避免误操作。"
                )
            }

            Section("设置与支持") {
                guideRow(
                    "配对与连接",
                    symbol: "iphone.and.arrow.forward",
                    text: "配对此 iPhone 一次，以便漫游控制通过 LocalDevVPN 识别它。"
                )
                guideRow(
                    "连接健康度",
                    symbol: "stethoscope",
                    text: "检查配对和本地连接，不会改变位置。你还可以分享易读的诊断报告。"
                )
                guideRow(
                    "重新查看介绍",
                    symbol: "sparkles",
                    text: "重新查看引导，不会删除配对、收藏、历史记录或偏好设置。"
                )
                guideRow(
                    "重置漫游控制",
                    symbol: "arrow.counterclockwise",
                    text: "删除配对记录和所有已保存的应用选择，然后返回引导。不会更改 LocalDevVPN 本身。"
                )
            }
        }
        .navigationTitle("关于漫游控制")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var appSummary: some View {
        Section {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 74, height: 74)

                    Image(systemName: "location.north.circle.fill")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(.white)
                        .accessibilityHidden(true)
                }

                VStack(spacing: 5) {
                    Text("漫游控制")
                        .font(.title2.bold())

                    Text("在一张简洁的地图上选择、测试并移动此 iPhone 报告的位置。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .accessibilityElement(children: .combine)
        }
    }

    private var quickStart: some View {
        Section {
            stepRow(1, "配对此 iPhone 一次。")
            stepRow(2, "连接 LocalDevVPN。")
            stepRow(3, "搜索、选择或标记位置。")
            stepRow(4, "开始固定位置控制，或预览步行路线。")
        } header: {
            Text("工作原理")
        } footer: {
            Text("漫游控制用于在你自己的设备上进行基于位置的应用开发和测试。")
        }
    }

    private func stepRow(_ number: Int, _ text: String) -> some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(.blue, in: Circle())

            Text(text)
                .font(.subheadline)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("第 \(number) 步：\(text)")
    }

    private func guideRow(_ title: String, symbol: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(.blue)
                .frame(width: 26, height: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text(text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title). \(text)")
    }
}

#Preview {
    NavigationStack {
        AboutRoamControlView()
    }
}

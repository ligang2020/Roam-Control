import SwiftUI

struct UsageStatisticsPrivacyView: View {
    var body: some View {
        List {
            Section {
                Label {
                    Text("开启分享后，漫游控制只会发送少量固定的匿名活动统计。")
                } icon: {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(.green)
                }
            }

            Section("会分享") {
                privacyRow("经过哈希处理的随机安装标识符", symbol: "number.circle")
                privacyRow("大致事件时间", symbol: "clock")
                privacyRow("应用打开或回到前台", symbol: "app.badge.checkmark")
                privacyRow("应用版本和构建号", symbol: "number")
                privacyRow("已完成介绍", symbol: "sparkles")
                privacyRow("已完成配对", symbol: "iphone.and.arrow.forward")
                privacyRow("已开始固定位置或步行会话", symbol: "figure.walk")
                privacyRow("活动位置已更新", symbol: "location.fill")
            }

            Section("绝不会分享") {
                privacyRow("坐标或地点名称", symbol: "mappin.slash")
                privacyRow("搜索、收藏、历史记录或路线", symbol: "magnifyingglass")
                privacyRow("配对记录或 PIN 码", symbol: "key.slash")
                privacyRow("Apple ID、设备名称或个人信息", symbol: "person.crop.circle.badge.xmark")
                privacyRow("诊断报告", symbol: "doc.text.magnifyingglass")
            }

            Section("存储与控制") {
                Text("此安装会生成一个随机标识符，在发送前进行不可逆哈希处理。它仅用于估算参与安装的活动量。")
                    .foregroundStyle(.secondary)

                Text("关闭分享会立即停止新的上报，并从漫游控制中移除该标识符，但无法撤回 TelemetryDeck 已接收的匿名事件。")
                    .foregroundStyle(.secondary)

                Text("TelemetryDeck 表示不会存储 IP 地址。匿名事件可能会保留约 7–10 年，但不保证具体删除日期。")
                    .foregroundStyle(.secondary)

                Text("漫游控制使用精简的自有发送器，而不是分析 SDK，因此不会自动添加额外的设备元数据。")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("匿名统计")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func privacyRow(_ title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol)
    }
}

#Preview {
    NavigationStack {
        UsageStatisticsPrivacyView()
    }
}

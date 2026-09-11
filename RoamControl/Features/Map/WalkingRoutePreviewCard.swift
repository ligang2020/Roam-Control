import MapKit
import SwiftUI

struct WalkingRoutePreviewCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let route: MKRoute
    let destination: LocationTarget
    let simulation: WalkingSimulationController
    let isPaired: Bool
    let onStart: () -> Void
    let onTogglePause: () -> Void
    let onWalkBack: () -> Void
    let onChooseNewLocation: () -> Void
    let onStop: () -> Void
    let onDone: () -> Void

    @State private var isConfirmingStop = false

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView(.vertical, showsIndicators: false) {
                    cardContent
                }
                .frame(maxHeight: 460)
            } else {
                cardContent
            }
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 18, y: 8)
        .confirmationDialog(
            "停止步行并恢复真实位置？",
            isPresented: $isConfirmingStop,
            titleVisibility: .visible
        ) {
            Button("停止并恢复", role: .destructive, action: onStop)
            Button("继续步行", role: .cancel) {}
        } message: {
            Text("路线进度将被重置。")
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: phaseSymbol)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(phaseColour)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 3) {
                    Text(phaseTitle)
                        .font(.headline)

                    Text(phaseSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? 4 : 2)
                }

                Spacer(minLength: 0)

                if canClose {
                    Button(action: onDone) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("关闭步行路线")
                }
            }

            if showsProgress {
                ProgressView(value: simulation.progress)
                    .tint(simulation.phase == .arrived ? .green : .blue)
            }

            routeMetrics

            if canChoosePace {
                pacePicker
            }

            controls
            footer
        }
    }

    @ViewBuilder
    private var pacePicker: some View {
        if dynamicTypeSize.isAccessibilitySize {
            Picker("步行速度", selection: paceBinding) {
                ForEach(WalkingPace.allCases) { pace in
                    Text(pace.title).tag(pace)
                }
            }
            .pickerStyle(.menu)
        } else {
            Picker("步行速度", selection: paceBinding) {
                ForEach(WalkingPace.allCases) { pace in
                    Text(pace.title).tag(pace)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    @ViewBuilder
    private var routeMetrics: some View {
        let distance = RouteMetric(
            title: showsProgress ? "剩余" : "距离",
            value: distanceText,
            symbol: "point.topleft.down.to.point.bottomright.curvepath"
        )
        let duration = RouteMetric(
            title: simulation.phase == .arrived ? "状态" : "步行中",
            value: durationText,
            symbol: simulation.phase == .arrived ? "checkmark.circle" : "clock"
        )
        let arrival = RouteMetric(
            title: "到达",
            value: arrivalText,
            symbol: "flag.checkered"
        )

        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: 8) {
                distance
                duration
                arrival
            }
        } else {
            HStack(spacing: 10) {
                distance
                duration
                arrival
            }
        }
    }

    @ViewBuilder
    private var controls: some View {
        switch simulation.phase {
        case .idle:
            Button(action: onStart) {
                Label("开始步行", systemImage: "figure.walk.motion")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!isPaired)

        case .preparing:
            HStack(spacing: 10) {
                ProgressView()
                Text("正在启动步行会话…")
                    .font(.subheadline.weight(.medium))
            }
            .frame(maxWidth: .infinity)

        case .walking, .paused:
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(spacing: 10) {
                        pauseButton
                        stopWalkingButton(showTitle: true)
                    }
                } else {
                    HStack(spacing: 10) {
                        pauseButton
                        stopWalkingButton(showTitle: false)
                    }
                }
            }

        case .arrived:
            Button(action: onWalkBack) {
                Label("沿路线返回", systemImage: "arrow.uturn.backward")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(spacing: 10) {
                        newLocationButton
                        stopAtArrivalButton(showTitle: true)
                    }
                } else {
                    HStack(spacing: 10) {
                        newLocationButton
                        stopAtArrivalButton(showTitle: false)
                    }
                }
            }

        case .stopping:
            HStack(spacing: 10) {
                ProgressView()
                Text("正在恢复真实位置…")
                    .font(.subheadline.weight(.medium))
            }
            .frame(maxWidth: .infinity)

        case .failed:
            Button(action: onStart) {
                Label("重试", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!isPaired)
        }
    }

    private var pauseButton: some View {
                Button(action: onTogglePause) {
                    Label(
                        simulation.phase == .paused ? "继续" : "暂停",
                        systemImage: simulation.phase == .paused ? "play.fill" : "pause.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
    }

    @ViewBuilder
    private func stopWalkingButton(showTitle: Bool) -> some View {
                Button(role: .destructive) {
                    isConfirmingStop = true
                } label: {
            if showTitle {
                Label("停止并恢复", systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
            } else {
                Image(systemName: "stop.fill")
                    .frame(width: 28)
            }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .accessibilityLabel("停止步行并恢复真实位置")
    }

    private var newLocationButton: some View {
        Button(action: onChooseNewLocation) {
            Label("新位置", systemImage: "mappin.and.ellipse")
                    .frame(maxWidth: .infinity)
            }
        .buttonStyle(.bordered)
            .controlSize(.large)
    }

    @ViewBuilder
    private func stopAtArrivalButton(showTitle: Bool) -> some View {
                Button(role: .destructive) {
                    isConfirmingStop = true
                } label: {
            if showTitle {
                Label("停止并恢复", systemImage: "location.slash.fill")
                    .frame(maxWidth: .infinity)
            } else {
                Image(systemName: "location.slash.fill")
                    .frame(width: 28)
            }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .accessibilityLabel("停止并恢复真实位置")
    }

    @ViewBuilder
    private var footer: some View {
        switch simulation.phase {
        case .idle:
            Text(isPaired
                 ? "你的位置将以所选速度沿此路线移动。"
                 : "请先配对此 iPhone，再开始步行会话。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .fixedSize(horizontal: false, vertical: true)

        case .preparing:
            Text("如果出现移动数据提示，请按提示操作。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .fixedSize(horizontal: false, vertical: true)

        case .walking:
            Text("请保持漫游控制运行。步行继续时可以使用其他应用。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .fixedSize(horizontal: false, vertical: true)

        case .paused:
            Text("模拟位置会保持在此处，直到你继续操作。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .fixedSize(horizontal: false, vertical: true)

        case .arrived:
            Text("目的地会一直保持活动状态，直到你停止并恢复真实位置。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .fixedSize(horizontal: false, vertical: true)

        case .stopping:
            EmptyView()

        case .failed(let message):
            Text(message)
                .font(.caption)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var canClose: Bool {
        switch simulation.phase {
        case .idle, .failed:
            true
        case .preparing, .walking, .paused, .arrived, .stopping:
            false
        }
    }

    private var canChoosePace: Bool {
        switch simulation.phase {
        case .idle, .failed:
            true
        case .preparing, .walking, .paused, .arrived, .stopping:
            false
        }
    }

    private var showsProgress: Bool {
        switch simulation.phase {
        case .walking, .paused, .arrived:
            true
        case .idle, .preparing, .stopping, .failed:
            false
        }
    }

    private var phaseTitle: String {
        switch simulation.phase {
        case .idle: "步行路线"
        case .preparing: "准备步行"
        case .walking: "步行中"
        case .paused: "步行已暂停"
        case .arrived: "已到达"
        case .stopping: "正在结束步行"
        case .failed: "步行不可用"
        }
    }

    private var phaseSubtitle: String {
        switch simulation.phase {
        case .idle, .preparing, .failed:
            "当前位置到 \(destination.name)"
        case .walking, .paused:
            "正在前往 \(destination.name) · \(Int((simulation.progress * 100).rounded()))%"
        case .arrived:
            "位置控制于 \(destination.name) 已启动"
        case .stopping:
            "正在恢复此 iPhone 的真实位置"
        }
    }

    private var phaseSymbol: String {
        switch simulation.phase {
        case .idle, .preparing, .walking: "figure.walk"
        case .paused: "pause.circle.fill"
        case .arrived: "checkmark.circle.fill"
        case .stopping: "location.slash.fill"
        case .failed: "exclamationmark.triangle.fill"
        }
    }

    private var phaseColour: Color {
        switch simulation.phase {
        case .arrived: .green
        case .failed: .red
        case .idle, .preparing, .walking, .paused, .stopping: .blue
        }
    }

    private var paceBinding: Binding<WalkingPace> {
        Binding(
            get: { simulation.pace },
            set: { simulation.pace = $0 }
        )
    }

    private var distanceText: String {
        let distance = showsProgress ? simulation.remainingDistance : route.distance
        if Locale.current.region?.identifier == "GB" {
            return formatUKDistance(distance)
        }

        let formatter = MeasurementFormatter()
        formatter.locale = .current
        formatter.unitOptions = .naturalScale
        formatter.unitStyle = .short
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter.string(from: Measurement(value: distance, unit: UnitLength.meters))
    }

    private func formatUKDistance(_ distance: CLLocationDistance) -> String {
        let metresPerMile = 1_609.344
        guard distance >= metresPerMile else {
            let yards = max(0, distance / 0.9144)
            return "\(Int(yards.rounded())) 码"
        }

        let miles = distance / metresPerMile
        return miles.formatted(
            .number.precision(.fractionLength(miles < 10 ? 1 : 0))
        ) + " 英里"
    }

    private var durationText: String {
        guard simulation.phase != .arrived else { return "完成" }
        let duration = simulation.totalDistance > 0
            ? simulation.remainingDuration
            : route.expectedTravelTime
        return formatDuration(duration)
    }

    private var arrivalText: String {
        guard simulation.phase != .arrived else { return "现在" }
        let duration = simulation.totalDistance > 0
            ? simulation.remainingDuration
            : route.expectedTravelTime
        return Date.now
            .addingTimeInterval(duration)
            .formatted(date: .omitted, time: .shortened)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = max(1, Int((duration / 60).rounded()))
        guard minutes >= 60 else { return "\(minutes) 分钟" }

        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return remainingMinutes == 0
            ? "\(hours) 小时"
            : "\(hours) 小时 \(remainingMinutes) 分钟"
    }
}

private struct RouteMetric: View {
    let title: String
    let value: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: symbol)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(value)")
    }
}

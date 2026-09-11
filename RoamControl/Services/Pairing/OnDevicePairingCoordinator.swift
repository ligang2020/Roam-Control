import BackgroundTasks
import Foundation
import Observation
import RoamPairingFFI

struct PairedDeviceDetails: Equatable, Sendable {
    let name: String
    let model: String
    let udid: String
}

enum OnDevicePairingPhase: Equatable {
    case idle
    case preparing
    case waitingForSettings
    case showingPIN(String)
    case storing
    case cancelling
    case success(PairedDeviceDetails)
    case failed(String)
}

@MainActor
@Observable
final class OnDevicePairingCoordinator {
    typealias RecordStore = @MainActor (Data, Data?) async throws -> PairingRecordSummary

    static let shared = OnDevicePairingCoordinator()

    private static var taskIdentifierPrefix: String {
        BackgroundTaskIdentifier.prefix(for: "pairing")
    }

    private(set) var phase: OnDevicePairingPhase = .idle

    private let publisher = PairingBonjourPublisher()
    private var activeSession: OpaquePointer?
    private var activeRunIdentifier: UUID?
    private var submittedTaskIdentifier: String?
    private var backgroundTask: BGContinuedProcessingTask?
    private var recordStore: RecordStore?
    private var cancellationRequested = false
    private var pendingFailureMessage: String?
    private var backgroundTaskFinished = true
    private var workerIsRunning = false

    var isRunning: Bool {
        workerIsRunning || phase == .preparing
    }

    var isAvailableOnThisDevice: Bool {
#if targetEnvironment(simulator)
        false
#else
        true
#endif
    }

    private init() {
        publisher.onPublished = { [weak self] in
            self?.advertisementDidPublish()
        }
        publisher.onFailure = { [weak self] in
            self?.advertisementDidFail()
        }
    }

    func start(storeRecord: @escaping RecordStore) {
        guard isAvailableOnThisDevice else {
            phase = .failed("设备端配对需要使用实体 iPhone。")
            return
        }
        guard !isRunning else { return }

        cancellationRequested = false
        pendingFailureMessage = nil
        recordStore = storeRecord
        phase = .preparing

        let identifier = "\(Self.taskIdentifierPrefix).\(UUID().uuidString)"
        let wasRegistered = BGTaskScheduler.shared.register(
            forTaskWithIdentifier: identifier,
            using: .main
        ) { task in
            guard let task = task as? BGContinuedProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }

            MainActor.assumeIsolated {
                Self.shared.beginPairing(with: task)
            }
        }

        guard wasRegistered else {
            recordStore = nil
            phase = .failed(
                "iOS 无法注册安全配对任务。请关闭漫游控制，重新打开后再试。"
            )
            return
        }

        submittedTaskIdentifier = identifier

        let request = BGContinuedProcessingTaskRequest(
            identifier: identifier,
            title: "漫游控制",
            subtitle: "正在准备安全配对…"
        )
        request.strategy = .fail

        Task {
            do {
                try await BGTaskScheduler.shared.submit(request)
            } catch {
                submittedTaskIdentifier = nil
                recordStore = nil
                phase = .failed(
                    "iOS 无法在后台保持配对活动。请保持漫游控制打开后重试。"
                )
            }
        }
    }

    func cancel() {
        guard isRunning else {
            phase = .idle
            return
        }

        cancellationRequested = true
        phase = .cancelling
        publisher.stop()

        if let activeSession {
            rc_remote_pairing_session_cancel(activeSession)
        }
        if let submittedTaskIdentifier {
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: submittedTaskIdentifier)
        }
    }

    func reset() {
        cancel()
        if !isRunning {
            phase = .idle
        }
    }

    private func beginPairing(with task: BGContinuedProcessingTask) {
        guard phase == .preparing, !workerIsRunning else {
            task.setTaskCompleted(success: false)
            return
        }

        backgroundTask = task
        backgroundTaskFinished = false
        task.progress.totalUnitCount = 100
        task.progress.completedUnitCount = 5
        task.expirationHandler = { [weak self] in
            Task { @MainActor in
                self?.pairingTaskExpired()
            }
        }

        runNativePairing()
    }

    private func runNativePairing() {
        guard let session = rc_remote_pairing_session_create() else {
            fail("漫游控制无法启动配对引擎。")
            return
        }

        let runIdentifier = UUID()
        activeRunIdentifier = runIdentifier
        activeSession = session
        workerIsRunning = true

        let sessionBits = UInt(bitPattern: session)
        let contextBits = UInt(bitPattern: Unmanaged.passRetained(self).toOpaque())

        DispatchQueue.global(qos: .userInitiated).async {
            guard
                let session = OpaquePointer(bitPattern: sessionBits),
                let context = UnsafeMutableRawPointer(bitPattern: contextBits)
            else { return }

            var result = RCRemotePairingResult()
            let returnCode = "Roam Control".withCString { hostName in
                "Mac17,7".withCString { hostModel in
                    rc_remote_pairing_session_run(
                        session,
                        hostName,
                        hostModel,
                        remotePairingReadyCallback,
                        remotePairingPINCallback,
                        context,
                        &result
                    )
                }
            }

            let outcome = NativePairingOutcome(result: result, returnCode: returnCode)
            rc_remote_pairing_result_destroy(&result)
            rc_remote_pairing_session_destroy(session)

            DispatchQueue.main.async {
                let coordinator = Unmanaged<OnDevicePairingCoordinator>
                    .fromOpaque(context)
                    .takeRetainedValue()
                coordinator.nativePairingFinished(outcome, runIdentifier: runIdentifier)
            }
        }
    }

    fileprivate func publish(_ advertisement: PairingAdvertisement) {
        guard workerIsRunning, !cancellationRequested else { return }
        publisher.publish(advertisement)
    }

    fileprivate func presentPIN(_ pin: String) {
        guard workerIsRunning, !cancellationRequested else { return }
        phase = .showingPIN(pin)
        backgroundTask?.progress.completedUnitCount = 55
        backgroundTask?.updateTitle(
            "漫游控制配对代码",
            subtitle: "在“设置”中输入 \(pin)"
        )
    }

    private func advertisementDidPublish() {
        guard workerIsRunning, !cancellationRequested else { return }
        phase = .waitingForSettings
        backgroundTask?.progress.completedUnitCount = 25
        backgroundTask?.updateTitle(
            "漫游控制",
            subtitle: "在“设置”中选择“与漫游控制配对”"
        )
    }

    private func advertisementDidFail() {
        guard workerIsRunning, !cancellationRequested else { return }
        fail(
            "需要本地网络权限。请在“设置”›“App”›“漫游控制”中启用，然后重试。"
        )
    }

    private func nativePairingFinished(
        _ outcome: NativePairingOutcome,
        runIdentifier: UUID
    ) {
        guard activeRunIdentifier == runIdentifier else { return }

        activeRunIdentifier = nil
        activeSession = nil
        workerIsRunning = false
        publisher.stop()

        if let pendingFailureMessage {
            self.pendingFailureMessage = nil
            recordStore = nil
            phase = .failed(pendingFailureMessage)
            finishBackgroundTask(success: false)
            return
        }

        if cancellationRequested {
            cancellationRequested = false
            recordStore = nil
            phase = .idle
            finishBackgroundTask(success: false)
            return
        }

        switch outcome {
        case .success(let record, let hostAltIRK, let device):
            phase = .storing
            backgroundTask?.progress.completedUnitCount = 80

            guard let recordStore else {
                fail("漫游控制无法安全存储新的配对记录。")
                return
            }

            Task {
                do {
                    _ = try await recordStore(record, hostAltIRK)
                    self.recordStore = nil
                    self.phase = .success(device)
                    self.backgroundTask?.progress.completedUnitCount = 100
                    self.backgroundTask?.updateTitle(
                        "漫游控制",
                        subtitle: "配对完成"
                    )
                    self.finishBackgroundTask(success: true)
                } catch {
                    self.fail(error.localizedDescription)
                }
            }

        case .failure(let message):
            fail(message)
        }
    }

    private func pairingTaskExpired() {
        cancellationRequested = false
        pendingFailureMessage = "配对耗时过长。请返回漫游控制后重试。"
        if let activeSession {
            rc_remote_pairing_session_cancel(activeSession)
        }
        publisher.stop()
        phase = .failed(pendingFailureMessage ?? "配对耗时过长，请重试。")
        finishBackgroundTask(success: false)
    }

    private func fail(_ message: String) {
        if workerIsRunning, let activeSession {
            pendingFailureMessage = message
            rc_remote_pairing_session_cancel(activeSession)
        }
        publisher.stop()
        recordStore = nil
        phase = .failed(message)
        finishBackgroundTask(success: false)
    }

    private func finishBackgroundTask(success: Bool) {
        guard !backgroundTaskFinished else { return }
        backgroundTaskFinished = true
        backgroundTask?.setTaskCompleted(success: success)
        backgroundTask = nil
        submittedTaskIdentifier = nil
    }
}

fileprivate struct PairingAdvertisement: Sendable {
    let serviceIdentifier: String
    let port: Int32
    let textRecords: [String: Data]
}

private enum NativePairingOutcome: Sendable {
    case success(
        record: Data,
        hostAltIRK: Data?,
        device: PairedDeviceDetails
    )
    case failure(String)

    init(result: RCRemotePairingResult, returnCode: Int32) {
        guard returnCode == 0 else {
            let message = Self.string(from: result.error_message)
            self = .failure(message.isEmpty ? "iPhone 无法完成配对。" : message)
            return
        }

        guard
            let recordPointer = result.pairing_record,
            result.pairing_record_length > 0
        else {
            self = .failure("配对引擎返回了空记录。")
            return
        }

        let record = Data(bytes: recordPointer, count: result.pairing_record_length)
        let hostAltIRK: Data?
        if let pointer = result.host_alt_irk, result.host_alt_irk_length > 0 {
            hostAltIRK = Data(bytes: pointer, count: result.host_alt_irk_length)
        } else {
            hostAltIRK = nil
        }

        self = .success(
            record: record,
            hostAltIRK: hostAltIRK,
            device: PairedDeviceDetails(
                name: Self.string(from: result.device_name),
                model: Self.string(from: result.device_model),
                udid: Self.string(from: result.device_udid)
            )
        )
    }

    private static func string(from pointer: UnsafeMutablePointer<CChar>?) -> String {
        guard let pointer else { return "" }
        return String(cString: pointer)
    }
}

@MainActor
private final class PairingBonjourPublisher: NSObject, NetServiceDelegate {
    var onPublished: (() -> Void)?
    var onFailure: (() -> Void)?

    private var service: NetService?

    func publish(_ advertisement: PairingAdvertisement) {
        stop()

        let service = NetService(
            domain: "",
            type: "_remotepairing-pairable-host._tcp.",
            name: advertisement.serviceIdentifier,
            port: advertisement.port
        )
        service.includesPeerToPeer = true
        service.delegate = self
        service.setTXTRecord(NetService.data(fromTXTRecord: advertisement.textRecords))
        service.schedule(in: .main, forMode: .common)
        service.publish()
        self.service = service
    }

    func stop() {
        service?.stop()
        service?.remove(from: .main, forMode: .common)
        service?.delegate = nil
        service = nil
    }

    nonisolated func netServiceDidPublish(_ sender: NetService) {
        MainActor.assumeIsolated {
            onPublished?()
        }
    }

    nonisolated func netService(_ sender: NetService, didNotPublish errorDict: [String: NSNumber]) {
        MainActor.assumeIsolated {
            onFailure?()
        }
    }
}

private let remotePairingReadyCallback: RCRemotePairingReadyCallback = {
    context,
    serviceIdentifier,
    port,
    keys,
    values,
    count in
    guard
        let context,
        let serviceIdentifier,
        let keys,
        let values
    else { return }

    var textRecords: [String: Data] = [:]
    for index in 0..<Int(count) {
        guard let key = keys[index], let value = values[index] else { continue }
        textRecords[String(cString: key)] = Data(String(cString: value).utf8)
    }

    let advertisement = PairingAdvertisement(
        serviceIdentifier: String(cString: serviceIdentifier),
        port: Int32(port),
        textRecords: textRecords
    )
    let contextBits = UInt(bitPattern: context)

    DispatchQueue.main.async {
        guard let context = UnsafeMutableRawPointer(bitPattern: contextBits) else { return }
        let coordinator = Unmanaged<OnDevicePairingCoordinator>
            .fromOpaque(context)
            .takeUnretainedValue()
        coordinator.publish(advertisement)
    }
}

private let remotePairingPINCallback: RCRemotePairingPINCallback = { context, pin in
    guard let context, let pin else { return }

    let value = String(cString: pin)
    let contextBits = UInt(bitPattern: context)
    DispatchQueue.main.async {
        guard let context = UnsafeMutableRawPointer(bitPattern: contextBits) else { return }
        let coordinator = Unmanaged<OnDevicePairingCoordinator>
            .fromOpaque(context)
            .takeUnretainedValue()
        coordinator.presentPIN(value)
    }
}

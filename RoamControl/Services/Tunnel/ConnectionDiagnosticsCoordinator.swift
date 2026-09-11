import Foundation
import Observation
import RoamPairingFFI

enum ConnectionCheckState: Equatable {
    case notRun
    case running
    case passed(String)
    case failed(String)
}

@MainActor
@Observable
final class ConnectionDiagnosticsCoordinator: NSObject {
    private let browser = NetServiceBrowser()
    private var pairingRecord: Data?
    private var discoveredServices: [NetService] = []
    private var timeoutTask: Task<Void, Never>?
    private var sawNonMatchingService = false

    private(set) var state: ConnectionCheckState = .notRun
    private(set) var lastChecked: Date?

    override init() {
        super.init()
        browser.delegate = self
        browser.includesPeerToPeer = true
    }

    func run(pairingRecord: Data?, sessionPhase: DeviceSessionPhase) {
        cancel(resetState: false)

        guard let pairingRecord else {
            finish(.failed("此 iPhone 尚未配对。请打开“配对与连接”并先完成配对。"))
            return
        }

        switch sessionPhase {
        case .active:
            finish(.passed("安全位置会话正在运行并正常响应。"))
            return
        case .openingLocalDevVPN, .discovering, .connecting, .stopping:
            finish(.failed("漫游控制已在更改连接。请等待完成后再运行检查。"))
            return
        case .idle, .failed:
            break
        }

#if targetEnvironment(simulator)
        finish(.failed("只有实体 iPhone 才能检查 LocalDevVPN 的可访问性。"))
#else
        self.pairingRecord = pairingRecord
        sawNonMatchingService = false
        state = .running
        browser.delegate = self
        browser.searchForServices(ofType: "_remotepairing._tcp.", inDomain: "local.")

        timeoutTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(10))
            guard let self, self.state == .running else { return }

            if self.sawNonMatchingService {
                self.finish(.failed(
                    "可以发现 LocalDevVPN，但其设备公告与已配对 iPhone 不匹配。请关闭再打开 LocalDevVPN，然后重试。"
                ))
            } else {
                self.finish(.failed(
                    "无法通过 LocalDevVPN 访问此 iPhone。请检查隧道是否已连接。使用移动数据时，请短暂关闭数据后再运行检查。"
                ))
            }
        }
#endif
    }

    func cancel() {
        cancel(resetState: true)
    }

    private func cancel(resetState: Bool) {
        timeoutTask?.cancel()
        timeoutTask = nil
        browser.stop()

        for service in discoveredServices {
            service.stopMonitoring()
            service.stop()
            service.remove(from: .main, forMode: .common)
            service.delegate = nil
        }

        discoveredServices = []
        pairingRecord = nil
        sawNonMatchingService = false

        if resetState, state == .running {
            state = .notRun
        }
    }

    private func resolve(_ service: NetService) {
        guard state == .running else { return }
        service.delegate = self
        service.includesPeerToPeer = true
        service.schedule(in: .main, forMode: .common)
        service.resolve(withTimeout: 7)
        discoveredServices.append(service)
    }

    private func inspect(_ service: NetService) {
        guard state == .running, service.port > 0 else { return }
        service.startMonitoring()

        guard
            let pairingRecord,
            let txtData = service.txtRecordData()
        else { return }

        let values = NetService.dictionary(fromTXTRecord: txtData)
        guard
            let identifierData = values["identifier"],
            let authTagData = values["authTag"]
        else { return }

        let identifier = String(decoding: identifierData, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let authTag = String(decoding: authTagData, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !identifier.isEmpty, !authTag.isEmpty else { return }

        let matchesPairedDevice = pairingRecord.withUnsafeBytes { recordBytes in
            guard let recordBaseAddress = recordBytes.bindMemory(to: UInt8.self).baseAddress else {
                return false
            }

            return identifier.withCString { serviceIdentifier in
                authTag.withCString { serviceAuthTag in
                    rc_pairing_record_matches_service(
                        recordBaseAddress,
                        pairingRecord.count,
                        serviceIdentifier,
                        serviceAuthTag
                    ) == 1
                }
            }
        }

        if matchesPairedDevice {
            finish(.passed("配对记录有效，并且可以通过 LocalDevVPN 访问此 iPhone。"))
        } else {
            sawNonMatchingService = true
        }
    }

    private func finish(_ newState: ConnectionCheckState) {
        cancel(resetState: false)
        state = newState
        lastChecked = Date()
    }
}

extension ConnectionDiagnosticsCoordinator: NetServiceBrowserDelegate, NetServiceDelegate {
    nonisolated func netServiceBrowser(
        _ browser: NetServiceBrowser,
        didFind service: NetService,
        moreComing: Bool
    ) {
        MainActor.assumeIsolated {
            resolve(service)
        }
    }

    nonisolated func netServiceBrowser(
        _ browser: NetServiceBrowser,
        didNotSearch errorDict: [String: NSNumber]
    ) {
        MainActor.assumeIsolated {
            finish(.failed("本地网络权限不可用。请在 iPhone“设置”中允许访问，然后重试。"))
        }
    }

    nonisolated func netServiceDidResolveAddress(_ sender: NetService) {
        MainActor.assumeIsolated {
            inspect(sender)
        }
    }

    nonisolated func netService(_ sender: NetService, didUpdateTXTRecord data: Data) {
        MainActor.assumeIsolated {
            inspect(sender)
        }
    }
}

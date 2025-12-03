import Foundation
import Combine

enum ControllerRole: String, Codable, CaseIterable, Identifiable {
    case roof = "roof"
    case sidewall = "sidewall"
    case sensors = "sensors"
    case cameras = "cameras"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .roof: return "Roof Control"
        case .sidewall: return "Side-wall Control"
        case .sensors: return "Environment Sensors"
        case .cameras: return "Cameras"
        }
    }
    
    var description: String {
        switch self {
        case .roof: return "Controls observatory roof open/close"
        case .sidewall: return "Controls side-wall panels (placeholder)"
        case .sensors: return "Temperature, humidity sensors"
        case .cameras: return "All-sky cameras for weather monitoring"
        }
    }
}

struct ControllerConfig: Identifiable, Codable {
    var id: UUID
    var name: String
    var baseURL: String
    var authToken: String?
    var roles: [ControllerRole]
    
    static func `default`() -> ControllerConfig {
        ControllerConfig(
            id: UUID(),
            name: "Observatory Controller",
            baseURL: "http://172.18.1.109:8080",
            authToken: nil,
            roles: ControllerRole.allCases
        )
    }
}

@MainActor
final class ControllerState: ObservableObject, Identifiable {
    let id: UUID
    @Published var name: String
    @Published var baseURL: String {
        didSet { apiClient?.baseURL = baseURL }
    }
    @Published var authToken: String? {
        didSet { apiClient?.authToken = authToken }
    }
    @Published var roles: Set<ControllerRole>
    
    @Published var roof = RoofModel()
    @Published var sensors = SensorsModel()
    @Published var safety = SafetyModel()
    @Published var logs: [LogEntry] = []
    
    var logHandler: ((LogEntry) -> Void)?
    
    private(set) var apiClient: APIClient?
    
    init(config: ControllerConfig) {
        self.id = config.id
        self.name = config.name
        self.baseURL = config.baseURL
        self.authToken = config.authToken
        self.roles = Set(config.roles)
        self.apiClient = APIClient(baseURL: config.baseURL, authToken: config.authToken)
    }
    
    var config: ControllerConfig {
        ControllerConfig(
            id: id,
            name: name,
            baseURL: baseURL,
            authToken: authToken,
            roles: Array(roles)
        )
    }
    
    func fetchStatus() {
        Task {
            await performFetchStatus()
        }
    }
    
    private func performFetchStatus() async {
        guard let apiClient else { return }
        do {
            let status = try await apiClient.fetchStatus()
            updateFromStatus(status)
        } catch {
            addLog(level: .error, module: "api", message: "Failed to fetch status: \(error.localizedDescription)")
        }
    }
    
    func openRoof() {
        guard roles.contains(.roof) else { return }
        guard let apiClient else { return }
        Task {
            do {
                _ = try await apiClient.openRoof()
                addLog(level: .info, module: "roof", message: "Roof open command sent")
                await refreshAfter(delay: 1.0)
            } catch {
                addLog(level: .error, module: "roof", message: "Failed to open roof: \(error.localizedDescription)")
            }
        }
    }
    
    func closeRoof() {
        guard roles.contains(.roof) else { return }
        guard let apiClient else { return }
        Task {
            do {
                _ = try await apiClient.closeRoof()
                addLog(level: .info, module: "roof", message: "Roof close command sent")
                await refreshAfter(delay: 1.0)
            } catch {
                addLog(level: .error, module: "roof", message: "Failed to close roof: \(error.localizedDescription)")
            }
        }
    }
    
    func stopRoof() {
        guard roles.contains(.roof) else { return }
        guard let apiClient else { return }
        Task {
            do {
                try await apiClient.stopRoof()
                addLog(level: .info, module: "roof", message: "Roof stop command sent")
                await refreshAfter(delay: 0.5)
            } catch {
                addLog(level: .error, module: "roof", message: "Failed to stop roof: \(error.localizedDescription)")
            }
        }
    }
    
    func lockMagLock() {
        guard roles.contains(.roof) else { return }
        guard let apiClient else { return }
        Task {
            do {
                try await apiClient.lockMagLock()
                addLog(level: .info, module: "roof", message: "MagLock lock command sent")
                await refreshAfter(delay: 0.5)
            } catch {
                addLog(level: .error, module: "roof", message: "Failed to lock MagLock: \(error.localizedDescription)")
            }
        }
    }
    
    func unlockMagLock() {
        guard roles.contains(.roof) else { return }
        guard let apiClient else { return }
        Task {
            do {
                try await apiClient.unlockMagLock()
                addLog(level: .info, module: "roof", message: "MagLock unlock command sent")
                await refreshAfter(delay: 0.5)
            } catch {
                addLog(level: .error, module: "roof", message: "Failed to unlock MagLock: \(error.localizedDescription)")
            }
        }
    }
    
    private func refreshAfter(delay: TimeInterval) async {
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        await performFetchStatus()
    }
    
    private func updateFromStatus(_ status: StatusResponse) {
        // Only update fields that this controller provides
        if let roofStatus = status.roof {
            roof.state = parseRoofState(roofStatus.state)
            roof.openLimit = roofStatus.openLimit
            roof.closeLimit = roofStatus.closeLimit
            roof.currentA = roofStatus.currentA
            roof.magLockEngaged = roofStatus.magLockEngaged
            roof.fault = roofStatus.fault
        }
        
        if let sensorsStatus = status.sensors {
            sensors.temperature = sensorsStatus.temperature
            sensors.humidity = sensorsStatus.humidity
            sensors.weatherCam.connected = sensorsStatus.weatherCam.connected
            sensors.weatherCam.streaming = sensorsStatus.weatherCam.streaming
            sensors.weatherCam.fault = sensorsStatus.weatherCam.fault
            sensors.meteorCam.connected = sensorsStatus.meteorCam.connected
            sensors.meteorCam.streaming = sensorsStatus.meteorCam.streaming
            sensors.meteorCam.fault = sensorsStatus.meteorCam.fault
        }
        
        if let safetyStatus = status.safety {
            safety.rain = safetyStatus.rain
            safety.windHigh = safetyStatus.windHigh
            safety.doorOpen = safetyStatus.doorOpen
            safety.powerOk = safetyStatus.powerOk
            safety.safeToOpenRoof = safetyStatus.safeToOpenRoof
        }
        
        if let alerts = status.alerts {
            for alert in alerts {
                let level = LogEntry.Level(rawValue: alert.level) ?? .info
                addLog(level: level, module: "system", message: alert.message)
            }
        }
    }
    
    private func parseRoofState(_ state: String) -> RoofModel.State {
        switch state.lowercased() {
        case "open": return .open
        case "closed": return .closed
        case "moving": return .moving
        case "fault": return .fault
        default: return .closed
        }
    }
    
    func addLog(level: LogEntry.Level, module: String, message: String) {
        var entry = LogEntry(ts: Date(), module: module, level: level, message: message, extra: nil)
        entry.controllerName = name
        entry.controllerID = id
        logs.insert(entry, at: 0)
        if logs.count > 500 {
            logs = Array(logs.prefix(500))
        }
        logHandler?(entry)
    }
}



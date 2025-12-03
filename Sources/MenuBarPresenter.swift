import SwiftUI

enum MenuBarPresenter {
    static func iconName(for appState: AppState) -> String {
        let roof = appState.roofController?.roof
        let sensors = appState.sensorsController?.sensors
        switch true {
        case roof?.state == .fault || sensors?.weatherCam.fault != nil || sensors?.meteorCam.fault != nil:
            return "exclamationmark.octagon.fill"
        case roof?.state == .moving || sensors?.weatherCam.streaming == true || sensors?.meteorCam.streaming == true:
            return "arrow.triangle.2.circlepath"
        default:
            return "sparkle"
        }
    }

    struct MenuContent: View {
        @EnvironmentObject var appState: AppState
        var body: some View {
            VStack(alignment: .leading) {
                Text("Observatory").font(.headline)
                Divider()
                Group {
                    if let roof = appState.roofController {
                        Label("\(roof.name): \(roofSummary(for: roof))", systemImage: "house")
                    } else {
                        Label("Roof controller missing", systemImage: "house")
                    }
                    if let sensors = appState.sensorsController {
                        if let temp = sensors.sensors.temperature {
                            Label("Temp: \(temp, specifier: "%.1f")°C", systemImage: "thermometer")
                        }
                        if let hum = sensors.sensors.humidity {
                            Label("Humidity: \(hum, specifier: "%.0f")%", systemImage: "humidity")
                        }
                        Label("Weather Cam: \(sensors.sensors.weatherCam.connected ? "On" : "Off")", systemImage: "camera.fill")
                        Label("Meteor Cam: \(sensors.sensors.meteorCam.connected ? "On" : "Off")", systemImage: "sparkles")
                    } else {
                        Label("Sensors controller missing", systemImage: "sensor.tag.radiowaves.forward")
                    }
                }
                .font(.caption)
                Divider()
                if let roof = appState.roofController {
                    Button("Open Roof") {
                        roof.openRoof()
                    }
                    .disabled(!roof.safety.safeToOpenRoof || roof.roof.state == .open)
                    Button("Stop Roof") {
                        roof.stopRoof()
                    }
                    Button("Close Roof") {
                        roof.closeRoof()
                    }
                    .disabled(roof.roof.state == .closed)
                } else {
                    Text("Add a roof controller to send commands.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Divider()
                Button(role: .destructive) {
                    // E-STOP confirm
                } label: {
                    Label("E‑STOP", systemImage: "stop.circle.fill")
                }
                Divider()
                Button("Open App") { NSApp.activate(ignoringOtherApps: true) }
                Button("Quit") { NSApp.terminate(nil) }
            }
            .padding(8)
            .frame(width: 280)
        }
        
        func roofSummary(for controller: ControllerState) -> String {
            switch controller.roof.state {
            case .open: return "Open"
            case .closed: return "Closed"
            case .moving: return "Moving"
            case .fault: return "Fault"
            }
        }
    }
}



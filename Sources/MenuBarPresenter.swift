import SwiftUI

enum MenuBarPresenter {
    static func iconName(for appState: AppState) -> String {
        let cameras = appState.camerasController
        let sensors = cameras?.sensors
        switch true {
        case sensors?.weatherCam.fault != nil || sensors?.meteorCam.fault != nil:
            return "exclamationmark.octagon.fill"
        case sensors?.weatherCam.streaming == true || sensors?.meteorCam.streaming == true:
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
                    if let cameras = appState.camerasController {
                        if let temp = cameras.sensors.temperature {
                            Label("Temp: \(temp, specifier: "%.1f")°C", systemImage: "thermometer")
                        }
                        if let hum = cameras.sensors.humidity {
                            Label("Humidity: \(hum, specifier: "%.0f")%", systemImage: "humidity")
                        }
                        Label("Weather Cam: \(cameras.sensors.weatherCam.connected ? "On" : "Off")", systemImage: "camera.fill")
                        Label("Meteor Cam: \(cameras.sensors.meteorCam.connected ? "On" : "Off")", systemImage: "sparkles")
                    } else {
                        Label("Camera controller missing", systemImage: "camera")
                    }
                }
                .font(.caption)
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
    }
}





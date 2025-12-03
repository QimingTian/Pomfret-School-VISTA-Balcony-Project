import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SensorsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let controller = appState.sensorsController {
                    EnvironmentSection(controller: controller)
                    CombinedCameraSection(controller: controller)
                } else {
                    MissingSensorsControllerCard()
                }
            }
            .padding()
        }
    }
}

private struct EnvironmentSection: View {
    @ObservedObject var controller: ControllerState
    
    var hasEnvironmentSensors: Bool {
        controller.sensors.temperature != nil || controller.sensors.humidity != nil
    }
    
    var body: some View {
        SensorsPanel(title: "Environment Sensors", icon: "thermometer") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    StatusBadge(
                        text: hasEnvironmentSensors ? "Connected" : "Not Connected",
                        status: hasEnvironmentSensors ? .ok : .error
                    )
                }
                
                if hasEnvironmentSensors {
                    HStack(spacing: 24) {
                        if let temp = controller.sensors.temperature {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Temperature").font(.caption).foregroundColor(.secondary)
                                Text("\(temp, specifier: "%.1f")°C").font(.title2).foregroundColor(.blue)
                            }
                        }
                        if let hum = controller.sensors.humidity {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Humidity").font(.caption).foregroundColor(.secondary)
                                Text("\(hum, specifier: "%.0f")%").font(.title2).foregroundColor(.blue)
                            }
                        }
                    }
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .cornerRadius(8)
                        .overlay {
                            VStack(spacing: 8) {
                                if let temp = controller.sensors.temperature {
                                    Text("\(temp, specifier: "%.1f")°C").font(.largeTitle).foregroundColor(.blue)
                                }
                                if let hum = controller.sensors.humidity {
                                    Text("\(hum, specifier: "%.0f")% Humidity").font(.title3).foregroundColor(.secondary)
                                }
                            }
                        }
                } else {
                    Text("No environment sensors connected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
            }
        }
    }
}

private struct CombinedCameraSection: View {
    @ObservedObject var controller: ControllerState
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        cameraCard(
            title: "Weather & Meteor Monitor Camera",
            primaryCamera: controller.sensors.weatherCam,
            secondaryCamera: controller.sensors.meteorCam,
            controller: controller,
            appState: appState
        )
    }
}

@ViewBuilder
private func cameraCard(title: String, primaryCamera: SensorsModel.Camera, secondaryCamera: SensorsModel.Camera, controller: ControllerState, appState: AppState) -> some View {
    SensorsPanel(title: title, icon: "camera.fill") {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                StatusBadge(text: primaryCamera.connected ? "Connected" : "Disconnected", status: primaryCamera.connected ? .ok : .error)
                if primaryCamera.streaming || secondaryCamera.streaming {
                    StatusBadge(text: "Streaming", status: .caution)
                }
            }
            if let lastSnap = primaryCamera.lastSnapshot ?? secondaryCamera.lastSnapshot {
                Text("Last snapshot: \(lastSnap, style: .relative)").font(.caption).foregroundColor(.secondary)
            }
            HStack {
                Button("Start Stream") {
                    startStream(controller: controller, appState: appState)
                }
                .disabled(!primaryCamera.connected || primaryCamera.streaming)
                
                Button("Stop Stream") {
                    stopStream(controller: controller, appState: appState)
                }
                .disabled(!primaryCamera.streaming)
                
                Button("Snapshot") {
                    captureSnapshot(controller: controller, appState: appState)
                }
                .disabled(!primaryCamera.connected)
            }
            if primaryCamera.streaming {
                ZStack {
                    MJPEGStreamView(url: "\(controller.baseURL)/camera/stream")
                        .frame(height: 500)
                    
                    // LIVE 指示器
                    VStack {
                        HStack {
                            Spacer()
                            HStack {
                                Circle().fill(Color.red).frame(width: 8, height: 8)
                                Text("LIVE")
                                    .font(.caption)
                                    .bold()
                            }
                            .padding(6)
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                            .padding(8)
                        }
                        Spacer()
                    }
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .cornerRadius(8)
                    .overlay {
                        if !primaryCamera.connected {
                            Text("Camera not connected").foregroundColor(.secondary)
                        } else {
                            Text("Click 'Start Stream' to view live feed").foregroundColor(.secondary)
                        }
                    }
            }
        }
    }
}

private func startStream(controller: ControllerState, appState: AppState) {
    Task {
        do {
            guard let apiClient = controller.apiClient else { return }
            try await apiClient.startCameraStream()
            appState.addLog(level: .info, module: "camera", message: "Started camera stream", controller: controller)
            // Refresh status to update UI
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5s
            controller.fetchStatus()
        } catch {
            appState.addLog(level: .error, module: "camera", message: "Failed to start stream: \(error.localizedDescription)", controller: controller)
        }
    }
}

private func stopStream(controller: ControllerState, appState: AppState) {
    Task {
        do {
            guard let apiClient = controller.apiClient else { return }
            try await apiClient.stopCameraStream()
            appState.addLog(level: .info, module: "camera", message: "Stopped camera stream", controller: controller)
            // Refresh status to update UI
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5s
            controller.fetchStatus()
        } catch {
            appState.addLog(level: .error, module: "camera", message: "Failed to stop stream: \(error.localizedDescription)", controller: controller)
        }
    }
}

private func captureSnapshot(controller: ControllerState, appState: AppState) {
    Task {
        do {
            guard let apiClient = controller.apiClient else { return }
            let imageData = try await apiClient.captureSnapshot()
            appState.addLog(level: .info, module: "camera", message: "Captured snapshot (\(imageData.count) bytes)", controller: controller)
            // TODO: Display or save the image
        } catch {
            appState.addLog(level: .error, module: "camera", message: "Failed to capture snapshot: \(error.localizedDescription)", controller: controller)
        }
    }
}

private struct MissingSensorsControllerCard: View {
    var body: some View {
        SensorsPanel(title: "Sensors", icon: "questionmark.circle") {
            VStack(alignment: .leading, spacing: 8) {
                Text("No sensors controller configured")
                    .font(.headline)
                Text("Add a sensors-capable controller in Settings to view data.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private struct SensorsPanel<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
            content()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}



import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(appState.controllers) { controller in
                    ControllerSettingsCard(
                        controller: controller,
                        isConnected: appState.connectedControllers.contains(controller.id),
                        canRemove: appState.controllers.count > 1,
                        onConnect: { 
                            connectController(controller)
                        },
                        onDisconnect: {
                            disconnectController(controller)
                        },
                        onRemove: { 
                            disconnectController(controller)
                            appState.removeController(controller)
                        },
                        onChange: {
                            appState.persistControllers()
                            appState.refreshActiveControllers()
                        }
                    )
                }
                Button {
                    appState.addController(name: "Controller \(appState.controllers.count + 1)", baseURL: "http://localhost:8080", roles: [.cameras])
                } label: {
                    Label("Add Controller", systemImage: "plus.circle")
                }
            }
            .padding()
        }
    }
    
    private func connectController(_ controller: ControllerState) {
        appState.addLog(level: .info, module: "settings", message: "Connecting to \(controller.name)...", controller: controller)
        
        // Mark as connected in global state - persists across view changes
        appState.connectedControllers.insert(controller.id)
        
        // Fetch initial status
        controller.fetchStatus()
        appState.addLog(level: .info, module: "settings", message: "Connected to \(controller.name)", controller: controller)
    }
    
    private func disconnectController(_ controller: ControllerState) {
        appState.connectedControllers.remove(controller.id)
        appState.addLog(level: .info, module: "settings", message: "Disconnected from \(controller.name)", controller: controller)
    }
}

private struct ControllerSettingsCard: View {
    @ObservedObject var controller: ControllerState
    let isConnected: Bool
    let canRemove: Bool
    let onConnect: () -> Void
    let onDisconnect: () -> Void
    let onRemove: () -> Void
    let onChange: () -> Void
    
    var body: some View {
        SettingsPanel(title: controller.name, icon: "network") {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Controller Name", text: $controller.name)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: controller.name) { _ in onChange() }
                
                TextField("Base URL", text: $controller.baseURL)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .onChange(of: controller.baseURL) { _ in onChange() }
                
                SecureField("Auth Token (optional)", text: Binding(
                    get: { controller.authToken ?? "" },
                    set: { controller.authToken = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(.roundedBorder)
                .onChange(of: controller.authToken) { _ in onChange() }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Controller Roles").font(.subheadline).foregroundColor(.secondary)
                    ForEach(ControllerRole.allCases) { role in
                        VStack(alignment: .leading, spacing: 2) {
                            Toggle(role.displayName, isOn: Binding(
                                get: { controller.roles.contains(role) },
                                set: { newValue in
                                    if newValue {
                                        controller.roles.insert(role)
                                    }
                                    onChange()
                                }
                            ))
                            Text(role.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 20)
                        }
                    }
                }
                
                HStack(spacing: 8) {
                    if isConnected {
                        Button(action: onDisconnect) {
                            Label("Disconnect", systemImage: "link.slash")
                        }
                    } else {
                        Button(action: onConnect) {
                            Label("Connect", systemImage: "link")
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Circle().fill(isConnected ? Color.green : Color.gray).frame(width: 8, height: 8)
                        Text(isConnected ? "Connected (auto-refresh every 5s)" : "Disconnected")
                            .font(.caption)
                            .foregroundColor(isConnected ? .green : .gray)
                    }
                }
                
                if canRemove {
                    Button(role: .destructive, action: onRemove) {
                        Label("Remove Controller", systemImage: "trash")
                    }
                }
            }
        }
    }
}

private struct SettingsPanel<Content: View>: View {
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
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(NSColor.controlBackgroundColor)))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}


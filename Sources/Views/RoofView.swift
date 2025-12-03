import SwiftUI

struct RoofView: View {
    @EnvironmentObject var appState: AppState
    @State private var showOpenConfirm = false
    @State private var showCloseConfirm = false
    @State private var pendingController: ControllerState?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let controller = appState.roofController {
                controlButtons(for: controller)
                RoofProgressBar(estimate: controller.roof.travelEstimate, moving: controller.roof.state == .moving)
                    .frame(height: 16)
                statusRow(for: controller)
                magLockButtons(for: controller)
                if let fault = controller.roof.fault {
                    faultBanner(text: fault)
                }
            } else {
                MissingRoofControllerCard()
            }
            Spacer()
        }
        .padding()
        .confirmationDialog(
            "Confirm Open Roof?",
            isPresented: $showOpenConfirm,
            presenting: pendingController
        ) { controller in
            Button("Open Roof", role: .destructive) {
                controller.openRoof()
            }
            Button("Cancel", role: .cancel) {}
        } message: { controller in
            ConfirmSummaryView(roofClosed: controller.roof.state == .closed, safety: controller.safety)
        }
        .confirmationDialog(
            "Confirm Close Roof?",
            isPresented: $showCloseConfirm,
            presenting: pendingController
        ) { controller in
            Button("Close Roof", role: .destructive) {
                controller.closeRoof()
            }
            Button("Cancel", role: .cancel) {}
        } message: { controller in
            ConfirmSummaryView(roofClosed: controller.roof.state == .closed, safety: controller.safety)
        }
    }
    
    @ViewBuilder
    private func controlButtons(for controller: ControllerState) -> some View {
        HStack(spacing: 12) {
            Button("Open") {
                pendingController = controller
                showOpenConfirm = true
            }
            .disabled(!controller.safety.safeToOpenRoof || controller.roof.state == .open || controller.roof.state == .moving)
            
            Button("Stop") {
                controller.stopRoof()
            }
            
            Button("Close") {
                pendingController = controller
                showCloseConfirm = true
            }
            .disabled(controller.roof.state == .closed || controller.roof.state == .moving)
        }
    }
    
    @ViewBuilder
    private func statusRow(for controller: ControllerState) -> some View {
        HStack {
            StatusBadge(text: stateText(for: controller), status: statusLevel(for: controller))
            Divider().frame(height: 16)
            Label("Open Limit: \(controller.roof.openLimit ? "Yes" : "No")", systemImage: controller.roof.openLimit ? "checkmark.circle" : "xmark.circle")
            Label("Close Limit: \(controller.roof.closeLimit ? "Yes" : "No")", systemImage: controller.roof.closeLimit ? "checkmark.circle" : "xmark.circle")
            Label("MagLock: \(controller.roof.magLockEngaged ? "Locked" : "Unlocked")", systemImage: controller.roof.magLockEngaged ? "lock.fill" : "lock.open")
                .foregroundColor(controller.roof.magLockEngaged ? .green : .orange)
            if let current = controller.roof.currentA {
                Label(String(format: "Current: %.2f A", current), systemImage: "bolt")
            }
        }
    }
    
    @ViewBuilder
    private func magLockButtons(for controller: ControllerState) -> some View {
        HStack(spacing: 12) {
            Button("Lock MagLock") {
                controller.lockMagLock()
            }
            .disabled(controller.roof.magLockEngaged)
            Button("Unlock MagLock") {
                controller.unlockMagLock()
            }
            .disabled(!controller.roof.magLockEngaged)
        }
    }
    
    @ViewBuilder
    private func faultBanner(text: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.octagon.fill").foregroundColor(.red)
            Text(text).foregroundColor(.red)
        }
        .padding(8)
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func stateText(for controller: ControllerState) -> String {
        switch controller.roof.state {
        case .open: return "Open"
        case .closed: return "Closed"
        case .moving: return "Moving"
        case .fault: return "Fault"
        }
    }
    
    private func statusLevel(for controller: ControllerState) -> StatusLevel {
        switch controller.roof.state {
        case .open, .closed: return .ok
        case .moving: return .caution
        case .fault: return .error
        }
    }
}

private struct MissingRoofControllerCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No roof controller configured")
                .font(.headline)
            Text("Add a roof-capable controller in Settings to send commands.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
    }
}

struct RoofProgressBar: View {
    let estimate: RoofModel.TravelEstimate
    let moving: Bool
    var body: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(Color.secondary.opacity(0.2))
            GeometryReader { geo in
                let width = geo.size.width * max(0, min(1, estimate.percent))
                Capsule()
                    .fill(gradient)
                    .frame(width: width)
                    .animation(.easeInOut(duration: 0.2), value: estimate.percent)
            }
        }
        .overlay(alignment: .center) {
            let t = estimate.remainingSec
            let mm = Int(t) / 60
            let ss = Int(t) % 60
            Text("\(Int(estimate.percent * 100))%  •  \(String(format: "%02d:%02d", mm, ss))")
                .font(.caption.monospacedDigit())
                .foregroundColor(.primary)
        }
        .accessibilityLabel("Roof travel estimate")
    }
    var gradient: LinearGradient {
        switch estimate.confidence {
        case .high:
            return .init(colors: [.green, .green.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
        case .medium:
            return .init(colors: [.yellow, .yellow.opacity(0.6)], startPoint: .leading, endPoint: .trailing)
        case .low:
            return .init(colors: [.orange, .orange.opacity(0.6)], startPoint: .leading, endPoint: .trailing)
        }
    }
}



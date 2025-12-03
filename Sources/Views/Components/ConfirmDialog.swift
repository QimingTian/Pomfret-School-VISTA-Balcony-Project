import SwiftUI

struct ConfirmSummaryView: View {
	let roofClosed: Bool
	let safety: SafetyModel
	var body: some View {
		VStack(alignment: .leading, spacing: 6) {
			Label("Roof closed: \(roofClosed ? "Yes" : "No")", systemImage: roofClosed ? "checkmark.circle" : "xmark.circle")
			Label("Rain: \(safety.rain ? "Yes" : "No")", systemImage: safety.rain ? "cloud.rain" : "cloud")
			Label("Wind high: \(safety.windHigh ? "Yes" : "No")", systemImage: safety.windHigh ? "wind" : "wind")
			Label("Door open: \(safety.doorOpen ? "Yes" : "No")", systemImage: safety.doorOpen ? "door.left.hand.open" : "door.left.hand.closed")
			Label("Power OK: \(safety.powerOk ? "Yes" : "No")", systemImage: safety.powerOk ? "bolt.fill" : "bolt.slash.fill")
		}
		.font(.callout)
	}
}


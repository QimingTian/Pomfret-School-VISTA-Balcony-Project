import SwiftUI

enum StatusLevel { case ok, caution, error }

struct StatusBadge: View {
	let text: String
	let status: StatusLevel
	var body: some View {
		HStack(spacing: 6) {
			Circle().fill(color).frame(width: 8, height: 8)
			Text(text).font(.caption).foregroundColor(color)
		}
		.padding(.horizontal, 8)
		.padding(.vertical, 4)
		.background(color.opacity(0.12))
		.cornerRadius(8)
	}
	var color: Color {
		switch status {
		case .ok: return .green
		case .caution: return .orange
		case .error: return .red
		}
	}
}


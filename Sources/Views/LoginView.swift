import SwiftUI
import AppKit

struct LoginView: View {
	@Binding var isAuthenticated: Bool
	@State private var password: String = ""
	@State private var showError: Bool = false
	
	private let correctPassword = "VISTAobs"
	
	var body: some View {
		VStack(spacing: 24) {
			Image(systemName: "lock.shield.fill")
				.font(.system(size: 64))
				.foregroundColor(.blue)
			
			Text("Pomfret Astro")
				.font(.largeTitle)
				.fontWeight(.bold)
			
			Text("Enter password to continue")
				.font(.subheadline)
				.foregroundColor(.secondary)
			
		SecureField("Password", text: $password)
			.textFieldStyle(.roundedBorder)
			.frame(width: 250)
			.onSubmit {
				checkPassword()
			}
			
			if showError {
				Text("Incorrect password")
					.font(.caption)
					.foregroundColor(.red)
			}
			
			Button("Login") {
				checkPassword()
			}
			.buttonStyle(.borderedProminent)
			.disabled(password.isEmpty)
		}
		.padding(40)
		.frame(width: 400, height: 500)
		.onAppear {
			// Make window key to receive input
			DispatchQueue.main.async {
				if let window = NSApplication.shared.windows.first {
					window.makeKeyAndOrderFront(nil)
				}
			}
		}
	}
	
	private func checkPassword() {
		if password == correctPassword {
			isAuthenticated = true
			password = ""
			showError = false
		} else {
			showError = true
			password = ""
		}
	}
}



import SwiftUI

struct ContentView: View {
	@EnvironmentObject var appState: AppState

	var body: some View {
		NavigationSplitView {
			List(selection: $appState.selection) {
				NavigationLink(value: AppSection.roof) {
					Label("Roof", systemImage: "house")
				}
				NavigationLink(value: AppSection.sensors) {
					Label("Sensors", systemImage: "sensor.tag.radiowaves.forward")
				}
				NavigationLink(value: AppSection.weather) {
					Label("Weather", systemImage: "cloud.sun")
				}
				NavigationLink(value: AppSection.logs) {
					Label("Logs", systemImage: "list.bullet.rectangle")
				}
				NavigationLink(value: AppSection.settings) {
					Label("Settings", systemImage: "gearshape")
				}
			}
			.listStyle(.sidebar)
		} detail: {
			switch appState.selection {
			case .roof: RoofView()
			case .sensors: SensorsView()
			case .weather: WeatherView()
			case .logs: LogsView()
			case .settings: SettingsView()
			}
		}
	}
}

enum AppSection: Hashable {
	case roof, sensors, weather, logs, settings
}


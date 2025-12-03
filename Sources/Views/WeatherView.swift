import SwiftUI

struct WeatherView: View {
    @EnvironmentObject private var appState: AppState
    
    private var weather: WeatherModel { appState.weather }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                metricsGrid
                if let time = weather.observationTime {
                    Text("Last updated \(time.formatted(date: .omitted, time: .standard))")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Weather – Pomfret, CT")
                .font(.largeTitle.bold())
            Text("Powered by Open‑Meteo")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var metricsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16, alignment: .top), count: 3), spacing: 16) {
            WeatherCard(title: "Temperature", value: value(weather.temperatureC, suffix: "°C"), icon: "thermometer")
            WeatherCard(title: "Apparent Temperature", value: value(weather.apparentTemperatureC, suffix: "°C"), icon: "thermometer.medium")
            WeatherCard(title: "Humidity", value: value(weather.humidityPercent, suffix: "%"), icon: "humidity")
            WeatherCard(title: "Cloud Cover", value: value(weather.cloudCoverPercent, suffix: "%"), icon: "cloud.fill")
            WeatherCard(title: "Wind Speed", value: value(weather.windSpeed, suffix: " km/h"), icon: "wind")
            WeatherCard(title: "Wind Gust", value: value(weather.windGust, suffix: " km/h"), icon: "tornado")
            WeatherCard(title: "Precipitation", value: value(weather.precipitationMm, suffix: " mm"), icon: "cloud.rain.fill")
        }
    }
    
    private func value(_ number: Double?, suffix: String) -> String {
        guard let number else { return "—" }
        if suffix.contains("%") {
            return String(format: "%.0f%@", number, suffix)
        } else if suffix.contains("km") || suffix.contains("mm") {
            return String(format: "%.0f%@", number, suffix)
        } else {
            return String(format: "%.1f%@", number, suffix)
        }
    }
}

private struct WeatherCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
            Text(value)
                .font(.title2.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}


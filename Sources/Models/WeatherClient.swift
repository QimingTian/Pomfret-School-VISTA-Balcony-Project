import Foundation

struct WeatherModel {
    var temperatureC: Double?
    var apparentTemperatureC: Double?
    var humidityPercent: Double?
    var precipitationMm: Double?
    var cloudCoverPercent: Double?
    var windSpeed: Double?
    var windGust: Double?
    var observationTime: Date?
}

final class WeatherClient {
    private struct WeatherResponse: Decodable {
        struct Current: Decodable {
            let time: String
            let temperature2M: Double?
            let apparentTemperature: Double?
            let relativeHumidity2M: Double?
            let precipitation: Double?
            let cloudCover: Double?
            let windSpeed10M: Double?
            let windGusts10M: Double?
            
            enum CodingKeys: String, CodingKey {
                case time
                case temperature2M = "temperature_2m"
                case apparentTemperature = "apparent_temperature"
                case relativeHumidity2M = "relative_humidity_2m"
                case precipitation
                case cloudCover = "cloud_cover"
                case windSpeed10M = "wind_speed_10m"
                case windGusts10M = "wind_gusts_10m"
            }
        }
        
        let current: Current?
    }
    
    private let latitude = 41.9159
    private let longitude = -71.9626
    
    func fetchCurrentWeather() async throws -> WeatherModel {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            .init(name: "latitude", value: "\(latitude)"),
            .init(name: "longitude", value: "\(longitude)"),
            .init(name: "current", value: "temperature_2m,apparent_temperature,relative_humidity_2m,precipitation,cloud_cover,wind_speed_10m,wind_gusts_10m"),
            .init(name: "timezone", value: "auto")
        ]
        
        let request = URLRequest(url: components.url!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw WeatherError.invalidResponse(sample: body)
        }
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WeatherResponse.self, from: data)
        guard let current = decoded.current else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw WeatherError.missingFields(sample: body)
        }
        
        return WeatherModel(
            temperatureC: current.temperature2M,
            apparentTemperatureC: current.apparentTemperature,
            humidityPercent: current.relativeHumidity2M,
            precipitationMm: current.precipitation,
            cloudCoverPercent: current.cloudCover,
            windSpeed: current.windSpeed10M,
            windGust: current.windGusts10M,
            observationTime: ISO8601DateFormatter().date(from: current.time)
        )
    }
    
    enum WeatherError: LocalizedError {
        case invalidResponse(sample: String)
        case missingFields(sample: String)
        
        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Failed to fetch weather data"
            case .missingFields:
                return "Weather response missing required fields"
            }
        }
        
        var samplePayload: String? {
            switch self {
            case .invalidResponse(let sample), .missingFields(let sample):
                return sample
            }
        }
    }
}



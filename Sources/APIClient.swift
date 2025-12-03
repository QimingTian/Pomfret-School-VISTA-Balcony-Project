import Foundation
import Combine

class APIClient {
    var baseURL: String
    var authToken: String?
    
    init(baseURL: String, authToken: String? = nil) {
        self.baseURL = baseURL
        self.authToken = authToken
    }
    
    // MARK: - Status
    
    func fetchStatus() async throws -> StatusResponse {
        var urlString = baseURL.trimmingCharacters(in: .whitespaces)
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            urlString = "http://" + urlString
        }
        if urlString.hasSuffix("/") {
            urlString = String(urlString.dropLast())
        }
        urlString += "/status"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(StatusResponse.self, from: data)
    }
    
    // MARK: - Roof Control
    
    func openRoof() async throws -> OperationResponse {
        return try await post("/roof/open")
    }
    
    func closeRoof() async throws -> OperationResponse {
        return try await post("/roof/close")
    }
    
    func stopRoof() async throws {
        try await postEmpty("/roof/stop")
    }
    
    func lockMagLock() async throws {
        try await postEmpty("/roof/lock")
    }
    
    func unlockMagLock() async throws {
        try await postEmpty("/roof/unlock")
    }
    
    // MARK: - Camera Control
    
    func startCameraStream() async throws {
        try await postEmpty("/camera/stream/start")
    }
    
    func stopCameraStream() async throws {
        try await postEmpty("/camera/stream/stop")
    }
    
    func captureSnapshot() async throws -> Data {
        var urlString = baseURL.trimmingCharacters(in: .whitespaces)
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            urlString = "http://" + urlString
        }
        if urlString.hasSuffix("/") {
            urlString = String(urlString.dropLast())
        }
        urlString += "/camera/snapshot"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        return data
    }
    
    // MARK: - Helper Methods
    
    private func post(_ path: String) async throws -> OperationResponse {
        return try await post(path, responseType: OperationResponse.self)
    }
    
    private func postEmpty(_ path: String) async throws {
        _ = try await post(path, responseType: EmptyResponse.self)
    }
    
    private func post<T: Decodable>(_ path: String, responseType: T.Type) async throws -> T {
        var urlString = baseURL.trimmingCharacters(in: .whitespaces)
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            urlString = "http://" + urlString
        }
        if urlString.hasSuffix("/") {
            urlString = String(urlString.dropLast())
        }
        urlString += path
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        if data.isEmpty || String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }
}

// MARK: - Response Models

struct StatusResponse: Codable {
    let roof: RoofStateResponse?
    let sensors: SensorsStateResponse?
    let safety: SafetyStateResponse?
    let alerts: [AlertResponse]?
}

struct RoofStateResponse: Codable {
    let state: String
    let openLimit: Bool
    let closeLimit: Bool
    let currentA: Double?
    let magLockEngaged: Bool
    let fault: String?
}

struct SensorsStateResponse: Codable {
    let temperature: Double?
    let humidity: Double?
    let weatherCam: CameraStateResponse
    let meteorCam: CameraStateResponse
}

struct CameraStateResponse: Codable {
    let connected: Bool
    let streaming: Bool
    let lastSnapshot: String?
    let fault: String?
}

struct SafetyStateResponse: Codable {
    let rain: Bool
    let windHigh: Bool
    let doorOpen: Bool
    let powerOk: Bool
    let safeToOpenRoof: Bool
}

struct AlertResponse: Codable {
    let level: String
    let message: String
    let ts: String
}

struct OperationResponse: Codable {
    let opId: String?
}

struct EmptyResponse: Codable { }

// MARK: - Errors

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}



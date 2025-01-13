import Foundation
import OSLog

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum NetworkError: Error {
    case invalidURL
    case unauthorized
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case networkError(Error)
}

@MainActor
class NetworkClient {
    private let logger = Logger.network
    private let urlSession: URLSession
    private let instance: String
    private var oauthToken: OauthToken?
    private let decoder: JSONDecoder = JSONDecoder()
    
    init(instance: String, oauthToken: OauthToken? = nil) {
        self.instance = instance
        self.oauthToken = oauthToken
        self.urlSession = URLSession.shared
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    private func makeURL(endpoint: NetworkEndpoint) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = instance
        
        // Handle path construction
        var path = endpoint.path
        if !path.hasPrefix("/oauth") && !path.hasPrefix("/api") {
            path = "/api" + path
        }
        components.path = path
        components.queryItems = endpoint.queryItems
        
        guard let url = components.url else {
            logger.error("Failed to construct URL for endpoint: \(endpoint.path)")
            throw NetworkError.invalidURL
        }
        
        return url
    }
    
    private func makeRequest(for endpoint: NetworkEndpoint) throws -> URLRequest {
        let url = try makeURL(endpoint: endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        // Handle request body and content type
        if let body = endpoint.body {
            request.setValue(endpoint.bodyContentType?.headerValue, forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }
        
        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if let token = oauthToken?.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    func setOauthToken(_ token: OauthToken?) {
        self.oauthToken = token
    }
    
    func fetch<T: Decodable>(_ endpoint: NetworkEndpoint, type: T.Type) async throws -> T {
        let request = try makeRequest(for: endpoint)
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Invalid response type")
                throw NetworkError.invalidResponse
            }
            
            if httpResponse.statusCode == 401 {
                logger.error("Unauthorized request")
                throw NetworkError.unauthorized
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                logger.error("HTTP error: \(httpResponse.statusCode)")
                throw NetworkError.httpError(httpResponse.statusCode)
            }
            
            logger.debug("Attempting to decode response data")
            do {
                let result = try decoder.decode(type, from: data)
                return result
            } catch {
                if let rawResponse = String(data: data, encoding: .utf8) {
                    logger.error("Raw response: \(rawResponse)")
                }
                logger.error("Decoding error: \(error.localizedDescription)")
                throw NetworkError.decodingError(error)
            }
        } catch let error as NetworkError {
            throw error
        } catch {
            logger.error("Network error: \(error.localizedDescription)")
            throw NetworkError.networkError(error)
        }
    }
    
    func send(_ endpoint: NetworkEndpoint) async throws {
        let request = try makeRequest(for: endpoint)
        logger.debug("Sending request to: \(endpoint.path)")
        
        let (_, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid response type")
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                logger.error("Unauthorized request")
                throw NetworkError.unauthorized
            }
            logger.error("HTTP error: \(httpResponse.statusCode)")
            throw NetworkError.httpError(httpResponse.statusCode)
        }
    }
} 

//
//  APIClient.swift
//  PostCardIt
//
//  Network layer for communicating with the backend API
//

import Foundation
import Combine

// MARK: - API Configuration
struct APIConfig {
    static var baseURL: String {
        return AppConfig.API.baseURL
    }
    
    // API endpoints
    enum Endpoint {
        case users
        case userById(String)
        case userSearch(String)
        case postcards
        case postcardsSent
        case postcardsReceived
        case friends
        case friendRequests
        
        var path: String {
            switch self {
            case .users:
                return "/users"
            case .userById(let userId):
                return "/users/\(userId)"
            case .userSearch(let query):
                return "/users/search?q=\(query)"
            case .postcards:
                return "/postcards"
            case .postcardsSent:
                return "/postcards/sent"
            case .postcardsReceived:
                return "/postcards/received"
            case .friends:
                return "/friends"
            case .friendRequests:
                return "/friends/requests"
            }
        }
        
        var url: URL {
            guard let url = URL(string: APIConfig.baseURL + path) else {
                fatalError("Invalid URL: \(APIConfig.baseURL + path)")
            }
            return url
        }
    }
}

// MARK: - API Error Types
enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(String)
    case serverError(Int, String)
    case networkError(String)
    case unauthorized
    case forbidden
    case notFound
    case badRequest(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .unauthorized:
            return "Unauthorized access"
        case .forbidden:
            return "Access forbidden"
        case .notFound:
            return "Resource not found"
        case .badRequest(let message):
            return "Bad request: \(message)"
        }
    }
}

// MARK: - API Response Models
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let error: APIErrorResponse?
    let pagination: Pagination?
}

struct APIErrorResponse: Codable {
    let code: String?
    let message: String
    let statusCode: Int?
}

struct Pagination: Codable {
    let hasMore: Bool
    let nextOffset: String?
    let total: Int?
}

// MARK: - HTTP Client
class APIClient: ObservableObject {
    static let shared = APIClient()
    
    private let session: URLSession
    private var authToken: String?
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    // Set the authorization token
    func setAuthToken(_ token: String?) {
        self.authToken = token
    }
    
    // MARK: - Generic HTTP Methods
    func get<T: Codable>(_ endpoint: APIConfig.Endpoint, responseType: T.Type) async throws -> T {
        let request = try createRequest(endpoint: endpoint, method: "GET")
        return try await performRequest(request: request, responseType: responseType)
    }
    
    func post<T: Codable, U: Codable>(_ endpoint: APIConfig.Endpoint, body: T, responseType: U.Type) async throws -> U {
        var request = try createRequest(endpoint: endpoint, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw APIError.decodingError("Failed to encode request body: \(error.localizedDescription)")
        }
        
        return try await performRequest(request: request, responseType: responseType)
    }
    
    func put<T: Codable, U: Codable>(_ endpoint: APIConfig.Endpoint, body: T, responseType: U.Type) async throws -> U {
        var request = try createRequest(endpoint: endpoint, method: "PUT")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw APIError.decodingError("Failed to encode request body: \(error.localizedDescription)")
        }
        
        return try await performRequest(request: request, responseType: responseType)
    }
    
    func delete(_ endpoint: APIConfig.Endpoint) async throws {
        let request = try createRequest(endpoint: endpoint, method: "DELETE")
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("Invalid response type")
        }
        
        if httpResponse.statusCode >= 400 {
            throw APIError.serverError(httpResponse.statusCode, "Delete failed")
        }
    }
    
    // MARK: - Helper Methods
    private func createRequest(endpoint: APIConfig.Endpoint, method: String) throws -> URLRequest {
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add authorization header if token is available
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    private func performRequest<T: Codable>(request: URLRequest, responseType: T.Type) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError("Invalid response type")
            }
            
            // Handle HTTP status codes
            switch httpResponse.statusCode {
            case 200...299:
                break // Success
            case 401:
                throw APIError.unauthorized
            case 403:
                throw APIError.forbidden
            case 404:
                throw APIError.notFound
            case 400...499:
                let errorMessage = try? parseErrorMessage(from: data)
                throw APIError.badRequest(errorMessage ?? "Client error")
            case 500...599:
                let errorMessage = try? parseErrorMessage(from: data)
                throw APIError.serverError(httpResponse.statusCode, errorMessage ?? "Server error")
            default:
                throw APIError.serverError(httpResponse.statusCode, "Unknown error")
            }
            
            // Decode the response
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(responseType, from: data)
            } catch {
                throw APIError.decodingError(error.localizedDescription)
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error.localizedDescription)
        }
    }
    
    private func parseErrorMessage(from data: Data) throws -> String {
        let errorResponse = try JSONDecoder().decode(APIErrorResponse.self, from: data)
        return errorResponse.message
    }
}

// MARK: - Postcard API Models
struct PostcardRequest: Codable {
    let recipientId: String
    let imageUrl: String?
    let message: String
    let location: PostcardLocation?
}

struct PostcardLocation: Codable {
    let latitude: Double?
    let longitude: Double?
    let address: String?
    let city: String?
    let country: String?
}

struct PostcardResponse: Codable {
    let postcards: [PostcardAPIModel]
    let count: Int
    let lastKey: String?
}

struct PostcardAPIModel: Codable {
    let postcardId: String
    let senderId: String
    let recipientId: String
    let imageUrl: String?
    let message: String
    let location: PostcardLocation?
    let sentAt: String
    let status: String
    let createdAt: String
    let updatedAt: String
    
    // Convert to app's Postcard model
    func toPostcard() -> Postcard {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        return Postcard(
            id: postcardId,
            senderId: senderId,
            senderName: "Unknown", // Will be resolved separately
            recipientId: recipientId,
            recipientName: "Unknown", // Will be resolved separately
            message: message,
            country: location?.country ?? "Unknown",
            imageKey: imageUrl,
            createdAt: dateFormatter.date(from: createdAt) ?? Date(),
            isSent: status == "sent"
        )
    }
}

// MARK: - User API Models
struct UserRequest: Codable {
    let username: String?
    let email: String?
    let fullName: String?
    let bio: String?
    let profilePictureUrl: String?
}

struct UserResponse: Codable {
    let userId: String
    let username: String
    let email: String?
    let fullName: String?
    let bio: String?
    let profilePictureUrl: String?
    let isActive: Bool
    let createdAt: String
    let updatedAt: String?
    let postcardsCount: Int
    let friendsCount: Int
}

struct UserSearchResponse: Codable {
    let users: [UserResponse]
    let count: Int
    let searchTerm: String
    let searchType: String
}

// MARK: - Friend API Models
struct FriendRequestAPI: Codable {
    let addresseeId: String
}

struct FriendshipResponse: Codable {
    let friendshipId: String
    let requesterId: String
    let addresseeId: String
    let status: String // PENDING, ACCEPTED, REJECTED, BLOCKED
    let requestedAt: String
    let respondedAt: String?
    let createdAt: String
    let updatedAt: String
}
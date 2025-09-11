//
//  PostcardService.swift
//  PostCardIt
//
//  Created by Taiyue Liu on 5/19/25.
//

import SwiftUI
import AWSCore
import AWSS3

class PostcardService: ObservableObject {
    @Published var sentPostcards: [Postcard] = []
    @Published var receivedPostcards: [Postcard] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    // API client for backend communication
    private let apiClient = APIClient.shared
    
    // S3 configuration for image uploads
    private let bucketName = AppConfig.AWS.s3BucketName
    private let region: AWSRegionType = .USWest2
    
    // Fetch postcards for the user
    func fetchUserPostcards(userId: String) {
        Task {
            await fetchPostcards()
        }
    }
    
    @MainActor
    private func fetchPostcards() async {
        isLoading = true
        errorMessage = ""
        
        do {
            // Fetch sent and received postcards concurrently
            async let sentResponse: PostcardResponse = apiClient.get(.postcardsSent, responseType: PostcardResponse.self)
            async let receivedResponse: PostcardResponse = apiClient.get(.postcardsReceived, responseType: PostcardResponse.self)
            
            let (sent, received) = try await (sentResponse, receivedResponse)
            
            // Convert API models to app models and resolve user names
            self.sentPostcards = await resolveUserNames(for: sent.postcards.map { $0.toPostcard() })
            self.receivedPostcards = await resolveUserNames(for: received.postcards.map { $0.toPostcard() })
            
            self.isLoading = false
            
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            print("Error fetching postcards: \(error)")
        }
    }
    
    // Helper method to resolve user names for postcards
    private func resolveUserNames(for postcards: [Postcard]) async -> [Postcard] {
        var updatedPostcards = postcards
        
        for i in 0..<updatedPostcards.count {
            let postcard = updatedPostcards[i]
            
            // Resolve sender name
            if let senderUser = await fetchUserById(postcard.senderId) {
                updatedPostcards[i].senderName = senderUser.fullName ?? senderUser.username
            }
            
            // Resolve recipient name
            if let recipientId = postcard.recipientId,
               let recipientUser = await fetchUserById(recipientId) {
                updatedPostcards[i].recipientName = recipientUser.fullName ?? recipientUser.username
            }
        }
        
        return updatedPostcards
    }
    
    // Fetch user by ID for resolving names
    private func fetchUserById(_ userId: String) async -> UserResponse? {
        do {
            return try await apiClient.get(.userById(userId), responseType: UserResponse.self)
        } catch {
            print("Error fetching user \(userId): \(error)")
            return nil
        }
    }
    
    // Send a new postcard
    func sendPostcard(postcard: Postcard, image: UIImage?, completion: @escaping (Bool, String?) -> Void) {
        Task {
            await sendPostcardAsync(postcard: postcard, image: image, completion: completion)
        }
    }
    
    @MainActor
    private func sendPostcardAsync(postcard: Postcard, image: UIImage?, completion: @escaping (Bool, String?) -> Void) async {
        isLoading = true
        errorMessage = ""
        
        do {
            var imageUrl: String?
            
            // If we have an image, upload it to S3 first
            if let image = image {
                imageUrl = try await uploadImageAsync(image: image, postcardId: postcard.id)
            }
            
            // Create postcard request
            let postcardRequest = PostcardRequest(
                recipientId: postcard.recipientId ?? "",
                imageUrl: imageUrl,
                message: postcard.message,
                location: PostcardLocation(
                    latitude: nil,
                    longitude: nil,
                    address: nil,
                    city: nil,
                    country: postcard.country.isEmpty ? nil : postcard.country
                )
            )
            
            // Send postcard via API
            let response = try await apiClient.post(.postcards, body: postcardRequest, responseType: PostcardAPIModel.self)
            
            // Add to sent postcards locally
            let newPostcard = response.toPostcard()
            self.sentPostcards.insert(newPostcard, at: 0)
            
            self.isLoading = false
            completion(true, nil)
            
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            completion(false, error.localizedDescription)
        }
    }
    
    // Private async helper method to upload an image to S3
    private func uploadImageAsync(image: UIImage, postcardId: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw APIError.badRequest("Failed to process image")
        }
        
        // Create a unique key for the image
        let imageKey = "postcards/\(postcardId)/original.jpg"
        
        // Create temporary file URL
        let tempUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(postcardId)
        
        do {
            // Write image data to temporary file
            try imageData.write(to: tempUrl)
            
            // Configure S3 transfer manager
            let transferManager = AWSS3TransferManager.default()
            
            // Create upload request
            let uploadRequest = AWSS3TransferManagerUploadRequest()
            uploadRequest?.bucket = bucketName
            uploadRequest?.key = imageKey
            uploadRequest?.body = tempUrl
            uploadRequest?.contentType = "image/jpeg"
            uploadRequest?.acl = .publicRead
            
            // Perform upload
            return try await withCheckedThrowingContinuation { continuation in
                transferManager.upload(uploadRequest!).continueWith { task in
                    // Clean up temporary file
                    try? FileManager.default.removeItem(at: tempUrl)
                    
                    if let error = task.error {
                        continuation.resume(throwing: APIError.networkError("Upload failed: \(error.localizedDescription)"))
                        return nil
                    }
                    
                    continuation.resume(returning: imageKey)
                    return nil
                }
            }
        } catch {
            // Clean up temporary file in case of error
            try? FileManager.default.removeItem(at: tempUrl)
            throw error
        }
    }
    
    // Get the URL for an image stored in S3
    func getImageURL(imageKey: String) -> URL? {
        // Construct the URL based on your S3 bucket and region
        return URL(string: "https://\(bucketName).s3.\(region.rawValue).amazonaws.com/\(imageKey)")
    }
    
    // Delete a postcard
    func deletePostcard(postcardId: String, completion: @escaping (Bool, String?) -> Void) {
        Task {
            await deletePostcardAsync(postcardId: postcardId, completion: completion)
        }
    }
    
    @MainActor
    private func deletePostcardAsync(postcardId: String, completion: @escaping (Bool, String?) -> Void) async {
        isLoading = true
        errorMessage = ""
        
        do {
            // Create endpoint for specific postcard
            let endpoint = APIConfig.Endpoint.postcards
            let deleteUrl = endpoint.url.appendingPathComponent(postcardId)
            
            // Create a custom endpoint for deletion
            var request = URLRequest(url: deleteUrl)
            request.httpMethod = "DELETE"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            // We'll need to create a way to access the auth token through APIClient
            // For now, this is a placeholder - the auth token should be managed by the auth service
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError("Invalid response")
            }
            
            if httpResponse.statusCode >= 400 {
                throw APIError.serverError(httpResponse.statusCode, "Failed to delete postcard")
            }
            
            // Remove from local arrays
            self.sentPostcards.removeAll { $0.id == postcardId }
            self.receivedPostcards.removeAll { $0.id == postcardId }
            
            self.isLoading = false
            completion(true, nil)
            
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            completion(false, error.localizedDescription)
        }
    }
    
    // Set auth token for API calls
    func setAuthToken(_ token: String?) {
        apiClient.setAuthToken(token)
    }
}

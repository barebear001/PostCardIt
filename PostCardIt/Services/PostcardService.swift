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
    
    // S3 configuration
    private let bucketName = "YOUR_S3_BUCKET_NAME"
    private let region: AWSRegionType = .USEast1 // Change to your region
    
    // AWS DynamoDB or API Gateway endpoint for postcard data
    private let apiEndpoint = "YOUR_API_ENDPOINT"
    
    // Fetch postcards for the user
    func fetchUserPostcards(userId: String) {
        isLoading = true
        
        // This is a placeholder for your actual API calls
        // In a real implementation, you would call your AWS API Gateway or Lambda function
        // to fetch postcards from DynamoDB or other data source
        
        // Simulate API call with a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // Placeholder data for sent postcards
            self.sentPostcards = [
                Postcard(
                    senderId: userId,
                    senderName: "You",
                    recipientName: "John",
                    message: "Hello from Paris! Having a wonderful time here.",
                    country: "France",
                    createdAt: Date().addingTimeInterval(-86400 * 7), // 7 days ago
                    isSent: true
                ),
                Postcard(
                    senderId: userId,
                    senderName: "You",
                    recipientName: "Sarah",
                    message: "Greetings from Tokyo! The cherry blossoms are beautiful.",
                    country: "Japan",
                    createdAt: Date().addingTimeInterval(-86400 * 14), // 14 days ago
                    isSent: true
                )
            ]
            
            // Placeholder data for received postcards
            self.receivedPostcards = [
                Postcard(
                    senderId: "user123",
                    senderName: "Alice",
                    recipientId: userId,
                    recipientName: "You",
                    message: "Hello from New York! The city is amazing.",
                    country: "United States",
                    createdAt: Date().addingTimeInterval(-86400 * 3), // 3 days ago
                    isSent: true
                ),
                Postcard(
                    senderId: "user456",
                    senderName: "Bob",
                    recipientId: userId,
                    recipientName: "You",
                    message: "Greetings from Rome! The Colosseum is magnificent.",
                    country: "Italy",
                    createdAt: Date().addingTimeInterval(-86400 * 10), // 10 days ago
                    isSent: true
                )
            ]
            
            self.isLoading = false
        }
    }
    
    // Send a new postcard
    func sendPostcard(postcard: Postcard, image: UIImage?, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        
        // If we have an image, upload it to S3 first
        if let image = image {
            uploadImage(image: image, postcardId: postcard.id) { [weak self] success, imageKey in
                guard let self = self else { return }
                
                if !success {
                    self.isLoading = false
                    completion(false, "Failed to upload image")
                    return
                }
                
                // Now create the postcard with the image key
                var updatedPostcard = postcard
                updatedPostcard.imageKey = imageKey
                
                self.createPostcardRecord(postcard: updatedPostcard) { success, error in
                    self.isLoading = false
                    completion(success, error)
                }
            }
        } else {
            // No image, just create the postcard record
            createPostcardRecord(postcard: postcard) { [weak self] success, error in
                self?.isLoading = false
                completion(success, error)
            }
        }
    }
    
    // Private helper method to create a postcard record in the database
    private func createPostcardRecord(postcard: Postcard, completion: @escaping (Bool, String?) -> Void) {
        // This is a placeholder for your actual API calls
        // In a real implementation, you would call your AWS API Gateway or Lambda function
        // to save the postcard data to DynamoDB or other data source
        
        // Simulate API call with a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // For demo purposes, we'll just simulate success
            completion(true, nil)
        }
    }
    
    // Private helper method to upload an image to S3
    private func uploadImage(image: UIImage, postcardId: String, completion: @escaping (Bool, String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(false, "Failed to process image")
            return
        }
        
        // Create a unique key for the image
        let imageKey = "postcards/\(postcardId)/original.jpg"
        
        // Configure S3 transfer manager
        let transferManager = AWSS3TransferManager.default()
        
        // Create upload request
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest?.bucket = bucketName
        uploadRequest?.key = imageKey
        uploadRequest?.body = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(postcardId)
        uploadRequest?.contentType = "image/jpeg"
        uploadRequest?.acl = .publicRead
        
        // Write image data to temporary file
        do {
            try imageData.write(to: uploadRequest?.body ?? URL(fileURLWithPath: ""))
        } catch {
            completion(false, "Failed to prepare image for upload: \(error.localizedDescription)")
            return
        }
        
        // Perform upload
        transferManager.upload(uploadRequest!).continueWith { task in
            if let error = task.error {
                completion(false, "Upload failed: \(error.localizedDescription)")
                return nil
            }
            
            completion(true, imageKey)
            return nil
        }
    }
    
    // Get the URL for an image stored in S3
    func getImageURL(imageKey: String) -> URL? {
        // Construct the URL based on your S3 bucket and region
        return URL(string: "https://\(bucketName).s3.\(region.rawValue).amazonaws.com/\(imageKey)")
    }
    
    // Delete a postcard
    func deletePostcard(postcardId: String, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        
        // This is a placeholder for your actual API calls
        // In a real implementation, you would call your AWS API Gateway or Lambda function
        // to delete the postcard from DynamoDB and optionally the image from S3
        
        // Simulate API call with a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isLoading = false
            completion(true, nil)
        }
    }
}

//
//  UserService.swift
//  PostCardIt
//
//  Service for managing user profiles and friend relationships
//

import Foundation
import SwiftUI

class UserService: ObservableObject {
    @Published var currentUser: UserProfile?
    @Published var friends: [UserProfile] = []
    @Published var friendRequests: [FriendRequest] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let apiClient = APIClient.shared
    
    // MARK: - User Profile Management
    
    // Create user profile after successful registration
    func createUserProfile(username: String, email: String, fullName: String, bio: String = "", completion: @escaping (Bool) -> Void) {
        Task {
            await createUserProfileAsync(username: username, email: email, fullName: fullName, bio: bio, completion: completion)
        }
    }
    
    @MainActor
    private func createUserProfileAsync(username: String, email: String, fullName: String, bio: String, completion: @escaping (Bool) -> Void) async {
        isLoading = true
        errorMessage = ""
        
        do {
            let userRequest = UserRequest(
                username: username,
                email: email,
                fullName: fullName,
                bio: bio,
                profilePictureUrl: nil
            )
            
            let response = try await apiClient.post(.users, body: userRequest, responseType: UserResponse.self)
            
            self.currentUser = UserProfile(from: response)
            self.isLoading = false
            completion(true)
            
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            completion(false)
        }
    }
    
    // Fetch current user profile
    func fetchCurrentUserProfile(completion: @escaping (Bool) -> Void) {
        Task {
            await fetchCurrentUserProfileAsync(completion: completion)
        }
    }
    
    @MainActor
    private func fetchCurrentUserProfileAsync(completion: @escaping (Bool) -> Void) async {
        isLoading = true
        errorMessage = ""
        
        do {
            let response = try await apiClient.get(.users, responseType: UserResponse.self)
            self.currentUser = UserProfile(from: response)
            self.isLoading = false
            completion(true)
            
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            completion(false)
        }
    }
    
    // Update user profile
    func updateUserProfile(_ profile: UserProfile, completion: @escaping (Bool) -> Void) {
        Task {
            await updateUserProfileAsync(profile, completion: completion)
        }
    }
    
    @MainActor
    private func updateUserProfileAsync(_ profile: UserProfile, completion: @escaping (Bool) -> Void) async {
        isLoading = true
        errorMessage = ""
        
        do {
            let userRequest = UserRequest(
                username: profile.username,
                email: nil, // Email typically can't be updated
                fullName: profile.fullName,
                bio: profile.bio,
                profilePictureUrl: profile.profilePictureUrl
            )
            
            let response = try await apiClient.put(.users, body: userRequest, responseType: UserResponse.self)
            self.currentUser = UserProfile(from: response)
            self.isLoading = false
            completion(true)
            
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            completion(false)
        }
    }
    
    // Search users
    func searchUsers(query: String, completion: @escaping ([UserProfile]) -> Void) {
        Task {
            await searchUsersAsync(query: query, completion: completion)
        }
    }
    
    @MainActor
    private func searchUsersAsync(query: String, completion: @escaping ([UserProfile]) -> Void) async {
        isLoading = true
        errorMessage = ""
        
        do {
            let response = try await apiClient.get(.userSearch(query), responseType: UserSearchResponse.self)
            let userProfiles = response.users.map { UserProfile(from: $0) }
            self.isLoading = false
            completion(userProfiles)
            
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            completion([])
        }
    }
    
    // MARK: - Friend Management
    
    // Fetch friends list
    func fetchFriends(completion: @escaping (Bool) -> Void) {
        Task {
            await fetchFriendsAsync(completion: completion)
        }
    }
    
    @MainActor
    private func fetchFriendsAsync(completion: @escaping (Bool) -> Void) async {
        isLoading = true
        errorMessage = ""
        
        do {
            // This would need to be implemented in the backend - returning accepted friendships
            // For now, we'll simulate an empty friends list
            self.friends = []
            self.isLoading = false
            completion(true)
            
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            completion(false)
        }
    }
    
    // Send friend request
    func sendFriendRequest(to userId: String, completion: @escaping (Bool) -> Void) {
        Task {
            await sendFriendRequestAsync(to: userId, completion: completion)
        }
    }
    
    @MainActor
    private func sendFriendRequestAsync(to userId: String, completion: @escaping (Bool) -> Void) async {
        isLoading = true
        errorMessage = ""
        
        do {
            let friendRequest = FriendRequestAPI(addresseeId: userId)
            let _ = try await apiClient.post(.friends, body: friendRequest, responseType: FriendshipResponse.self)
            self.isLoading = false
            completion(true)
            
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            completion(false)
        }
    }
    
    // Set auth token for API calls
    func setAuthToken(_ token: String?) {
        apiClient.setAuthToken(token)
    }
}

// MARK: - Data Models

struct UserProfile: Identifiable, Codable {
    let id: String
    let username: String
    let email: String?
    let fullName: String?
    let bio: String?
    let profilePictureUrl: String?
    let isActive: Bool
    let createdAt: Date
    let postcardsCount: Int
    let friendsCount: Int
    
    init(from response: UserResponse) {
        self.id = response.userId
        self.username = response.username
        self.email = response.email
        self.fullName = response.fullName
        self.bio = response.bio
        self.profilePictureUrl = response.profilePictureUrl
        self.isActive = response.isActive
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        self.createdAt = dateFormatter.date(from: response.createdAt) ?? Date()
        
        self.postcardsCount = response.postcardsCount
        self.friendsCount = response.friendsCount
    }
    
    init(id: String, username: String, email: String?, fullName: String?, bio: String?, profilePictureUrl: String?, isActive: Bool = true, createdAt: Date = Date(), postcardsCount: Int = 0, friendsCount: Int = 0) {
        self.id = id
        self.username = username
        self.email = email
        self.fullName = fullName
        self.bio = bio
        self.profilePictureUrl = profilePictureUrl
        self.isActive = isActive
        self.createdAt = createdAt
        self.postcardsCount = postcardsCount
        self.friendsCount = friendsCount
    }
}

struct FriendRequest: Codable {
    let addresseeId: String
}

// Extension to update PostcardModel to work with the new structure
extension Postcard {
    // Helper to update postcard with user profile data
    mutating func updateWithUserProfile(sender: UserProfile?, recipient: UserProfile?) {
        if let sender = sender {
            self.senderName = sender.fullName ?? sender.username
        }
        if let recipient = recipient {
            self.recipientName = recipient.fullName ?? recipient.username
        }
    }
}
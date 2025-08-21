//
//  PostcardPreviewDetailView.swift
//  PostCardIt
//
//  Created by Taiyue Liu on 5/19/25.
//

import SwiftUI


// Updated PostcardPreviewDetailView.swift
struct PostcardPreviewDetailView: View {
    let country: String
    let message: String
    let image: UIImage?
    let senderName: String
    let recipientName: String
    
    var postcardService: PostcardService
    var authService: CognitoAuthService
    
    @State private var isSending = false
    @State private var isSent = false
    @State private var errorMessage = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                // Postcard preview
                VStack {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 200)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("To: \(recipientName) in \(country)")
                            .font(.headline)
                        
                        Text(message)
                            .font(.body)
                            .padding(.vertical, 5)
                        
                        HStack {
                            Spacer()
                            Text("From: \(senderName)")
                                .font(.subheadline)
                                .italic()
                        }
                    }
                    .padding()
                }
                .background(Color.white)
                .cornerRadius(15)
                .shadow(radius: 5)
                .padding()
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
                
                Spacer()
                
                // Send button
                Button(action: {
                    sendPostcard()
                }) {
                    if postcardService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else if isSent {
                        Label("Sent!", systemImage: "checkmark")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                    } else {
                        Text("Send Postcard")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .disabled(postcardService.isLoading || isSent)
                .padding()
            }
            .navigationTitle("Postcard Preview")
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    func sendPostcard() {
        guard let userId = authService.user?.username else {
            errorMessage = "User not logged in"
            return
        }
        
        // Create a new postcard object
        let postcard = Postcard(
            senderId: userId,
            senderName: senderName,
            recipientName: recipientName,
            message: message,
            country: country
        )
        
        // Send the postcard
        postcardService.sendPostcard(postcard: postcard, image: image) { success, error in
            if success {
                isSent = true
                
                // Dismiss after showing success
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    presentationMode.wrappedValue.dismiss()
                }
            } else {
                errorMessage = error ?? "Failed to send postcard"
            }
        }
    }
}


#Preview {
    PostcardPreviewDetailView(
        country: "Japan",
        message: "Greetings from Tokyo! The cherry blossoms are absolutely stunning this time of year. The city is vibrant and full of life. Can't wait to share more stories when I get back!",
        image: UIImage(systemName: "photo"),
        senderName: "Alex Johnson",
        recipientName: "Sarah Davis",
        postcardService: PostcardService(),
        authService: CognitoAuthService()
    )
}

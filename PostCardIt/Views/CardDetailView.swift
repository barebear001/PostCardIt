//
//  CardDetailsView.swift
//  PostCardIt
//
//  Created by Taiyue Liu on 5/19/25.
//

import SwiftUI

// CardDetailView.swift
struct CardDetailView: View {
    let postcard: Postcard
    let isReceived: Bool
    let postcardService: PostcardService
    
    @State private var imageURL: URL?
    @State private var showingDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var showingDeleteError = false
    @State private var showingFullImage = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Card image
                if let imageURL = imageURL {
                    Button(action: {
                        showingFullImage = true
                    }) {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(height: 200)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 200)
                                    .clipped()
                            case .failure:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 200)
                                    .overlay(
                                        Image(systemName: "exclamationmark.triangle")
                                            .font(.largeTitle)
                                            .foregroundColor(.gray)
                                    )
                            @unknown default:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 200)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
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
                    // Card details
                    HStack {
                        Text(isReceived ? "From:" : "To:")
                            .fontWeight(.bold)
                        Text(isReceived ? postcard.senderName : postcard.recipientName)
                    }
                    
                    HStack {
                        Text("Location:")
                            .fontWeight(.bold)
                        Text(postcard.country)
                    }
                    
                    HStack {
                        Text("Date:")
                            .fontWeight(.bold)
                        Text(formattedDate(postcard.createdAt))
                    }
                    
                    Divider()
                    
                    Text("Message:")
                        .fontWeight(.bold)
                    
                    Text(postcard.message)
                        .padding(.bottom)
                    
                    if isReceived {
                        NavigationLink(destination: CreateReplyView(originalPostcard: postcard)) {
                            Label("Reply", systemImage: "arrowshape.turn.up.left")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    } else {
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            Label("Delete", systemImage: "trash")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                        .disabled(isDeleting)
                    }
                }
                .padding()
            }
            .padding(.bottom)
        }
        .navigationTitle(isReceived ? "Received Card" : "Sent Card")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showingDeleteConfirmation) {
            Alert(
                title: Text("Delete Postcard"),
                message: Text("Are you sure you want to delete this postcard? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    deletePostcard()
                },
                secondaryButton: .cancel()
            )
        }
        .alert("Error", isPresented: $showingDeleteError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(postcardService.errorMessage)
        }
        .sheet(isPresented: $showingFullImage) {
            if let imageURL = imageURL {
                FullImageView(imageURL: imageURL)
            }
        }
        .onAppear {
            // Load image if there's an image key
            if let imageKey = postcard.imageKey {
                self.imageURL = postcardService.getImageURL(imageKey: imageKey)
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func deletePostcard() {
        isDeleting = true
        
        postcardService.deletePostcard(postcardId: postcard.id) { success, error in
            isDeleting = false
            
            if success {
                // Go back to previous screen
                presentationMode.wrappedValue.dismiss()
            } else {
                postcardService.errorMessage = error ?? "Failed to delete postcard"
                showingDeleteError = true
            }
        }
    }
}

//#Preview {
//    CardDetailView()
//}

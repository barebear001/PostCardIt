//
//  CardReview.swift
//  PostCardIt
//
//  Created by Taiyue Liu on 5/19/25.
//

import SwiftUI

// CardPreviewView.swift
struct CardPreviewView: View {
    let postcard: Postcard
    let isReceived: Bool
    @State private var imageURL: URL?
    @State private var showingImage = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.2))
                .aspectRatio(1.4, contentMode: .fit)
                .shadow(radius: 2)
            
            VStack {
                if let imageURL = imageURL, showingImage {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(height: 60)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 60)
                                .clipped()
                                .cornerRadius(5)
                        case .failure:
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(height: 60)
                    .padding(.top, 5)
                }
                
                VStack(spacing: 4) {
                    Text(isReceived ? "From: \(postcard.senderName)" : "To: \(postcard.recipientName)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(postcard.country)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    Text(formattedDate(postcard.createdAt))
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                .padding(.vertical, 8)
            }
            .padding(.horizontal, 5)
        }
        .onAppear {
            if let imageKey = postcard.imageKey {
                let service = PostcardService()
                self.imageURL = service.getImageURL(imageKey: imageKey)
                
                // Give a small delay to improve the grid loading appearance
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        self.showingImage = true
                    }
                }
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

//#Preview {
//    CardPreviewView(isReceived: true, postcard: Postcard(
//        
//}

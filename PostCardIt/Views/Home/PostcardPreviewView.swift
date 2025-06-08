//
//  PostcardPreviewView.swift
//  PostCardIt
//
//  Created by Taiyue Liu on 5/28/25.
//

import SwiftUI

struct PostcardData: Identifiable {
    let id: Int
    let title: String
    let imageName: String? // Optional if you have actual images
    let aspectRatio: CGFloat // Width/Height ratio
    
    // Sample data with different aspect ratios
    static let sampleData: [PostcardData] = [
        PostcardData(id: 1, title: "Postcard 1", imageName: nil, aspectRatio: 1.4), // Standard postcard
        PostcardData(id: 2, title: "Postcard 2", imageName: nil, aspectRatio: 0.7), // Vertical/portrait
        PostcardData(id: 3, title: "Postcard 3", imageName: nil, aspectRatio: 1.6), // Wide landscape
        PostcardData(id: 4, title: "Postcard 4", imageName: nil, aspectRatio: 1.0), // Square
        PostcardData(id: 5, title: "Postcard 5", imageName: nil, aspectRatio: 1.2), // Slightly wide
        PostcardData(id: 6, title: "Postcard 6", imageName: nil, aspectRatio: 0.8), // Slightly tall
    ]
}

// Updated PostcardPreviewView
struct PostcardPreviewView: View {
    let postcard: PostcardData
    
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.gray.opacity(0.2))
            .aspectRatio(postcard.aspectRatio, contentMode: .fit)
            .overlay(
                VStack {
                    if let imageName = postcard.imageName {
                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipped()
                    } else {
                        Text(postcard.title)
                            .foregroundColor(.gray)
                            .font(.caption)
                        
                        Text("Ratio: \(String(format: "%.1f", postcard.aspectRatio))")
                            .foregroundColor(.gray)
                            .font(.caption2)
                    }
                }
            )
    }
}




#Preview {
    let samplePostcard = PostcardData(id: 1, title: "Sample", imageName: nil, aspectRatio: 1.4)
    return PostcardPreviewView(postcard: samplePostcard)
}

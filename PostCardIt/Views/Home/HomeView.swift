//
//  HomeView.swift
//  PostCardIt
//
//  Created by Taiyue Liu on 5/3/25.
//
import SwiftUI
import MapKit

// HomeView.swift
struct HomeView: View {
    let columns = [GridItem(.adaptive(minimum: 120, maximum: 200), spacing: 16)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: -50) {
                // World Map with illustrations
//            MapPreviewView()
//                .frame(height: 400)
//                .frame(maxWidth: .infinity) // Ensures full width
//                .clipped() // Clips any overflow
//                .ignoresSafeArea(edges: [.horizontal, .top]) // Extends to screen edges and top
            Map()
                .frame(height: 400)
                .frame(maxWidth: .infinity)
                .clipped()
                .ignoresSafeArea(edges: [.horizontal, .top])

            ScrollView {
                MasonryGrid(items: PostcardData.sampleData, columns: 2, spacing: 16) { postcard in
                    PostcardPreviewView(postcard: postcard)
                }
                .padding(.horizontal) // Only the grid has horizontal padding
                .padding(.vertical) // Only bottom padding for the grid
            }
        }
    }
}


#Preview {
    HomeView()
}

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

struct MasonryGrid<Content: View, T: Identifiable>: View {
    let items: [T]
    let columns: Int
    let spacing: CGFloat
    let content: (T) -> Content
    
    init(items: [T], columns: Int = 2, spacing: CGFloat = 16, @ViewBuilder content: @escaping (T) -> Content) {
        self.items = items
        self.columns = columns
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            let columnWidth = (geometry.size.width - CGFloat(columns - 1) * spacing) / CGFloat(columns)
            
            HStack(alignment: .top, spacing: spacing) {
                ForEach(0..<columns, id: \.self) { columnIndex in
                    LazyVStack(spacing: spacing) {
                        ForEach(itemsForColumn(columnIndex)) { item in
                            content(item)
                                .frame(width: columnWidth)
                        }
                    }
                }
            }
        }
    }
    
    private func itemsForColumn(_ columnIndex: Int) -> [T] {
        return items.enumerated().compactMap { index, item in
            index % columns == columnIndex ? item : nil
        }
    }
}

#Preview {
    HomeView()
}

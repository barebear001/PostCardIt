//
//  MapPreviewView.swift
//  PostCardIt
//
//  Created by Taiyue Liu on 5/2/25.
//
import SwiftUI

struct MapPreviewView: View {
    @State private var offset: CGSize = .zero
    @State private var startOffset: CGSize = .zero
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            // Make the map larger than the view to allow scrolling in all directions
            let imageWidth = geometry.size.width * 3
            let imageHeight = geometry.size.height * 2
            
            ZStack {
                // Interactive scrollable map in all directions
                Image("world_map")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: imageWidth, height: imageHeight)
                    .offset(x: offset.width, y: offset.height)
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.1)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !isDragging {
                                    isDragging = true
                                    startOffset = offset
                                }
                                
                                // Calculate new offset
                                let dragX = value.translation.width
                                let dragY = value.translation.height
                                
                                // Apply the translation directly, we'll check bounds separately
                                let rawOffsetX = startOffset.width + dragX
                                let rawOffsetY = startOffset.height + dragY
                                
                                // During dragging, allow significant overscroll on all sides
                                let horizontalOverscroll = geometry.size.width * 0.3
                                let verticalOverscroll = geometry.size.height * 0.3 // Increased vertical overscroll
                                
                                // Horizontal bounds during dragging - very permissive
                                let maxOffsetX = horizontalOverscroll
                                let minOffsetX = -(imageWidth - geometry.size.width) - horizontalOverscroll
                                let boundedX = min(maxOffsetX, max(minOffsetX, rawOffsetX))
                                
                                // Vertical bounds during dragging - make more permissive
                                let maxOffsetY = verticalOverscroll
                                let minOffsetY = -(imageHeight - geometry.size.height) - verticalOverscroll
                                let boundedY = min(maxOffsetY, max(minOffsetY, rawOffsetY))
                                
                                // Print debug info
                                print("Drag Y: \(dragY), Raw Y: \(rawOffsetY), Bounded Y: \(boundedY)")
                                print("Min Y: \(minOffsetY), Max Y: \(maxOffsetY)")
                                
                                offset = CGSize(width: boundedX, height: boundedY)
                            }
                            .onEnded { _ in
                                isDragging = false
                                
                                // When drag ends, use spring animation to snap back to actual bounds if needed
                                withAnimation(.spring()) {
                                    // Horizontal bounds - stricter but still allowing all content to be visible
                                    let maxOffsetX = 0.0  // Left edge
                                    let minOffsetX = min(0, -(imageWidth - geometry.size.width))  // Right edge
                                    let boundedX = min(maxOffsetX, max(minOffsetX, offset.width))
                                    
                                    // Vertical bounds - stricter but still allowing all content to be visible
                                    let maxOffsetY = 0.0  // Top edge
                                    let minOffsetY = min(0, -(imageHeight - geometry.size.height))  // Bottom edge
                                    let boundedY = min(maxOffsetY, max(minOffsetY, offset.height))
                                    
                                    offset = CGSize(width: boundedX, height: boundedY)
                                }
                            }
                    )
                
                // Reset button in the corner
                VStack {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.spring()) {
                                // Center the map by default
                                offset = CGSize(
                                    width: -(imageWidth - geometry.size.width) / 2,
                                    height: -(imageHeight - geometry.size.height) / 2
                                )
                                startOffset = offset
                            }
                        }) {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                                .padding(8)
                                .background(Circle().fill(Color.black.opacity(0.3)))
                        }
                        .padding(12)
                    }
                    
                    Spacer()
                }
            }
            .clipped()
            .onAppear {
                // Initialize the offset to center the map
                offset = CGSize(
                    width: -(imageWidth - geometry.size.width) / 2,
                    height: -(imageHeight - geometry.size.height) / 2
                )
                startOffset = offset
            }
        }
    }
}

#Preview {
    MapPreviewView()
}

//
//  MapPreviewView.swift
//  PostCardIt
//
//  Created by Taiyue Liu on 5/2/25.
//
import SwiftUI

// MapPreviewView.swift
struct MapPreviewView: View {
    @State private var offset: CGSize = .zero
    @State private var startOffset: CGSize = .zero
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            // Make the map larger than the view to allow scrolling in all directions
            let imageWidth = geometry.size.width * 2
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
                                
                                // Calculate new offset with bounds
                                let dragX = value.translation.width
                                let dragY = value.translation.height
                                
                                // Horizontal bounds
                                let maxOffsetX = imageWidth * 0.25  // Allow some overscroll
                                let minOffsetX = -imageWidth + geometry.size.width + imageWidth * 0.25
                                let newOffsetX = min(maxOffsetX, max(minOffsetX, startOffset.width + dragX))
                                
                                // Vertical bounds
                                let maxOffsetY = imageHeight * 0.25  // Allow some overscroll
                                let minOffsetY = -imageHeight + geometry.size.height + imageHeight * 0.25
                                let newOffsetY = min(maxOffsetY, max(minOffsetY, startOffset.height + dragY))
                                
                                offset = CGSize(width: newOffsetX, height: newOffsetY)
                            }
                            .onEnded { _ in
                                isDragging = false
                                
                                // Add animation to smoothly stop at bounds if needed
                                withAnimation(.spring()) {
                                    // Horizontal bounds with resistance
                                    let maxOffsetX = 0.0
                                    let minOffsetX = -imageWidth + geometry.size.width
                                    let boundedX = min(maxOffsetX, max(minOffsetX, offset.width))
                                    
                                    // Vertical bounds with resistance
                                    let maxOffsetY = 0.0
                                    let minOffsetY = -imageHeight + geometry.size.height
                                    let boundedY = min(maxOffsetY, max(minOffsetY, offset.height))
                                    
                                    offset = CGSize(width: boundedX, height: boundedY)
                                }
                            }
                    )
                
                // Add visual indicators for scrolling - horizontal
//                Group {
//                    // Left indicator
//                    if offset.width < -10 {
//                        Image(systemName: "chevron.left")
//                            .foregroundColor(.white)
//                            .shadow(radius: 2)
//                            .padding(8)
//                            .background(Circle().fill(Color.black.opacity(0.3)))
//                            .position(x: 30, y: geometry.size.height / 2)
//                    }
//                    
//                    // Right indicator
//                    if offset.width > -imageWidth + geometry.size.width + 10 {
//                        Image(systemName: "chevron.right")
//                            .foregroundColor(.white)
//                            .shadow(radius: 2)
//                            .padding(8)
//                            .background(Circle().fill(Color.black.opacity(0.3)))
//                            .position(x: geometry.size.width - 30, y: geometry.size.height / 2)
//                    }
//                }
//                
//                // Add visual indicators for scrolling - vertical
//                Group {
//                    // Up indicator
//                    if offset.height < -10 {
//                        Image(systemName: "chevron.up")
//                            .foregroundColor(.white)
//                            .shadow(radius: 2)
//                            .padding(8)
//                            .background(Circle().fill(Color.black.opacity(0.3)))
//                            .position(x: geometry.size.width / 2, y: 30)
//                    }
//                    
//                    // Down indicator
//                    if offset.height > -imageHeight + geometry.size.height + 10 {
//                        Image(systemName: "chevron.down")
//                            .foregroundColor(.white)
//                            .shadow(radius: 2)
//                            .padding(8)
//                            .background(Circle().fill(Color.black.opacity(0.3)))
//                            .position(x: geometry.size.width / 2, y: geometry.size.height - 30)
//                    }
//                }
                
                // Reset button in the corner
//                VStack {
//                    HStack {
//                        Spacer()
//                        
//                        Button(action: {
//                            withAnimation(.spring()) {
//                                offset = .zero
//                                startOffset = .zero
//                            }
//                        }) {
//                            Image(systemName: "arrow.counterclockwise.circle.fill")
//                                .font(.title3)
//                                .foregroundColor(.white)
//                                .shadow(radius: 2)
//                                .padding(8)
//                                .background(Circle().fill(Color.black.opacity(0.3)))
//                        }
//                        .padding(12)
//                    }
//                    
//                    Spacer()
//                }
            }
            .clipped()
        }
    }
}


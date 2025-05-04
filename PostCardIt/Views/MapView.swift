//
//  MapView.swift
//  PostCardIt
//
//  Created by Taiyue Liu on 5/3/25.
//
import SwiftUI

struct MapView: View {
    // State variables to track position and scale
    @State private var offset = CGSize.zero
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack {
                    // Full-screen map image with gestures
                    Image("world_map")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .offset(offset)
                        .scaleEffect(scale)
                        .gesture(
                            // Drag gesture for panning
                            DragGesture()
                                .onChanged { value in
                                    self.offset = CGSize(
                                        width: value.translation.width + self.offset.width,
                                        height: value.translation.height + self.offset.height
                                    )
                                }
                                .onEnded { value in
                                    // Keep the current offset when the drag ends
                                    self.offset = CGSize(
                                        width: value.translation.width + self.offset.width,
                                        height: value.translation.height + self.offset.height
                                    )
                                }
                        )
                        .ignoresSafeArea()
                    }
                }
            }
            .navigationTitle("World Map")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}

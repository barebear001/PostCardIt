//
//  MapPreviewView.swift
//  PostCardIt
//
//  Created by Taiyue Liu on 5/2/25.
//
import SwiftUI

// SplashScreen.swift
struct SplashScreen: View {
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack {
                 Image("splash_image")
                    .resizable()
                    .scaledToFit()
                    .aspectRatio(contentMode: .fit)
            }
        }
    }
}

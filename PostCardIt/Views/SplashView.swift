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
         Image("splash_image")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    SplashScreen()
}

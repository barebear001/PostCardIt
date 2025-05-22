//
//  LegalView.swift
//  PostCardIt
//
//  Created by Taiyue Liu on 5/2/25.
//
import SwiftUI

// LegalView.swift
struct LegalView: View {
    let title: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Last updated: May 1, 2025")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam auctor, nisl eget ultricies aliquam, nunc nisl aliquet nunc, quis aliquam nisl nunc vel nisl. Nullam auctor, nisl eget ultricies aliquam, nunc nisl aliquet nunc, quis aliquam nisl nunc vel nisl.")
                    .padding(.horizontal)
                
                Text("Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.")
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(title)
    }
}

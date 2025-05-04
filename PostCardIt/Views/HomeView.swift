//
//  HomeView.swift
//  PostCardIt
//
//  Created by Taiyue Liu on 5/3/25.
//
import SwiftUI

// HomeView.swift
struct HomeView: View {
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // World Map with illustrations
                    MapPreviewView()
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .padding(.horizontal)
                    
                    // Recent Postcards section
                    Text("Recent Postcards")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(0..<6, id: \.self) { index in
                            PostcardPreviewView(index: index)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("PostCardIt")
        }
    }
}

// Preview providers for SwiftUI previews in Xcode
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

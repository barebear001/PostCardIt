//
//  MainTableView.swift
//  PostCardIt
//
//  Created by Taiyue Liu on 5/2/25.
//
import SwiftUI

// MainTabView.swift
struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image("home_button")
                        .padding()
                    Text("Home")
                }
                .tag(0)
            
            MapView()
                .tabItem {
                    Image("map_button")
                        .padding()
                    Text("Map")
                }
                .tag(1)
            
            CreatePostcardView()
                .tabItem {
                    Image("create_button")
                        .resizable()
                        .scaledToFit()
                        .padding()
                    Text("Create")
                }
                .tag(2)
            
            MyCardsView()
                .tabItem {
                    Image("my_card_button")
                        .padding()
                    Text("Cards")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Image("me_button")
                        .padding()
                    Text("Me")
                }
                .tag(4)
        }
        .accentColor(.blue)
    }
}

//struct MainTabView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainTabView()
//    }
//}


struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        let mockAuthService = CognitoAuthService()

        MainTabView()
            .environmentObject(mockAuthService)
    }
}

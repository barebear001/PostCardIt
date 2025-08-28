import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showingCreateView = false
    @EnvironmentObject var authService: CognitoAuthService
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(0)
                
                MapView()
                    .tag(1)
                
                Color.clear
                    .tag(2)
                    .onAppear {
                        showingCreateView = true
                    }
                
                MyCardsView()
                    .tag(3)
                
                ProfileView()
                    .tag(4)
            }
            
            if selectedTab == 0 || selectedTab == 1 || selectedTab == 3 || selectedTab == 4 {
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .sheet(isPresented: $showingCreateView) {
            CreatePostcardView(selectedTab: $selectedTab)
        }
        .onChange(of: selectedTab) { newValue in
            if newValue == 2 {
                showingCreateView = true
                // Reset to previous tab after triggering the sheet
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    selectedTab = 0
                }
            }
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    let tabItems = [
        TabItem(icon: "home_button", title: "Home"),
        TabItem(icon: "map_button", title: "Map"),
        TabItem(icon: "create_button", title: "Create"),
        TabItem(icon: "my_card_button", title: "My Cards"),
        TabItem(icon: "me_button", title: "Me")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabItems.count, id: \.self) { index in
                let item = tabItems[index]
                
                Button(action: {
                    selectedTab = index
                }) {
                    VStack(spacing: index == 2 ? -10 : 4) {
                        ZStack {
                            if index == 2 {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(red: 1.0, green: 0.905, blue: 0.384))
                                    .frame(width: 68, height: 43)
                                    .rotationEffect(.degrees(-15))
                                    .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: -2)
                                    .position(x: 35, y: 5)
                                
                                Image(item.icon)
                                    .resizable()
//                                    .scaledToFit()
                                    .frame(width: 15, height: 36)
                                    .rotationEffect(.degrees(11.58))
                                    .position(x: 35, y: 5)
                            } else {
                                // Use selected state images when tabs are selected
                                if index == 0 && selectedTab != 0 {
                                    // Home tab unselected
                                    Image("home_unselected")
                                        .resizable()
                                        .frame(width: 26, height: 21)
                                } else if index == 1 && selectedTab == 1 {
                                    // Map tab selected
                                    Image("map_selected")
                                        .resizable()
                                        .frame(width: 26, height: 21)
                                } else if index == 3 && selectedTab == 3 {
                                    // My Cards selected
                                    Image("my_cards_selected")
                                        .resizable()
                                        .frame(width: 27, height: 21)
                                } else if index == 4 && selectedTab == 4 {
                                    // Me tab selected
                                    Image("me_selected")
                                        .resizable()
                                        .frame(width: 26, height: 21)
                                } else {
                                    Image(item.icon)
                                        .resizable()
//                                        .scaledToFit()
                                        .frame(width: index == 3 ? 27 : 26, height: index == 3 ? 21 : 21)
                                }
                            }
                        }
                        .frame(height: index == 2 ? 50 : 36)
                        
                        HStack {
                            Text(item.title)
                                .font(.custom("Kalam-Regular", size: 10))
                                .foregroundColor(.black)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 2)
                .foregroundColor(.black),
            alignment: .bottom
        )
    }
}

struct TabItem {
    let icon: String
    let title: String
}

#Preview {
    let mockAuthService = CognitoAuthService()

    MainTabView()
        .environmentObject(mockAuthService)
}

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var authService: CognitoAuthService
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(0)
                
                MapView()
                    .tag(1)
                
                CreatePostcardView()
                    .tag(2)
                
                MyCardsView()
                    .tag(3)
                
                ProfileView()
                    .tag(4)
            }
            
            if selectedTab == 0 || selectedTab == 1 || selectedTab == 3 {
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    let tabItems = [
        TabItem(icon: "home_button", title: "Home"),
        TabItem(icon: "map_button", title: "Map"),
        TabItem(icon: "create_button", title: "Create"),
        TabItem(icon: "my_card_button", title: "Cards"),
        TabItem(icon: "me_button", title: "Me")
    ]
    
    var body: some View {
        HStack {
            ForEach(0..<tabItems.count, id: \.self) { index in
                let item = tabItems[index]
                
                Button(action: {
                    selectedTab = index
                }) {
                    VStack(spacing: 4) {
                        ZStack {
                            // Yellow highlight box for selected tab
                        
                            if index == 2 {
                                if selectedTab == index {
                                    Rectangle()
                                        .fill(Color.yellow)
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(8)
                                }
                            
                                Image(item.icon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                            }
                            else {
                                if selectedTab == index {
                                    Rectangle()
                                        .fill(Color.yellow)
                                        .frame(width: 45, height: 45)
                                        .cornerRadius(8)
                                }
                                
                                Image(item.icon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 25, height: 25)
                            }
                        }
                        
                        Text(item.title)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(selectedTab == index ? .blue : .gray)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: -5)
        .padding(.horizontal)
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

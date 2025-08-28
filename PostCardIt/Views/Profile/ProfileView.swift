// ProfileView.swift
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: CognitoAuthService
    @State private var userAttributes: [String: String] = [:]
    @State private var isLoading = false
    @State private var selectedTab = 0 // 0 for Stamps, 1 for Friends
    @State private var showingAddFriends = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with profile info
                    VStack(spacing: 16) {
                        // Profile Image
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(width: 81, height: 81)
                        } else {
                            ProfileAvatarView()
                        }
                        
                        // Username
                        Text(userAttributes["name"] ?? "oiiaioiiiai")
                            .font(.custom("Kalam-Regular", size: 15))
                            .foregroundColor(.black)
                        
                        // Location
                        Text("Los Angeles, United States")
                            .font(.custom("Kalam-Regular", size: 12))
                            .foregroundColor(.black)
                        
                        // Add Friends Button
                        HStack {
                            Button(action: {
                                showingAddFriends = true
                            }) {
                                HStack {
                                    Spacer()
                                    Text("Add Friends")
                                        .font(.custom("Kalam-Regular", size: 14))
                                        .foregroundColor(.black)
                                    Spacer()
                                }
                                .frame(height: 36)
                                .background(Color(red: 1.0, green: 0.91, blue: 0.38)) // #FFE762
                                .cornerRadius(18)
                                .shadow(color: .black.opacity(0.25), radius: 2, x: 2, y: 2)
                            }
                            
                            Spacer()
                                .frame(width: 15) // Add spacing between buttons
                            
                            Button(action: {
                                // Settings action
                            }) {
                                Image(systemName: "gearshape.fill")
                                    .foregroundColor(.black)
                                    .frame(width: 36, height: 36)
                                    .background(Color(red: 1.0, green: 0.91, blue: 0.38))
                                    .cornerRadius(18)
                                    .shadow(color: .black.opacity(0.25), radius: 2, x: 2, y: 2)
                            }
                        }
                        .padding(.horizontal, 52)
                        
                        // Stats Row
                        HStack(spacing: 0) {
                            StatView(title: "Received", value: "12")
                            StatView(title: "Sent", value: "16")
                            StatView(title: "Country", value: "5")
                            StatView(title: "City", value: "17")
                        }
                        .padding(.top, 20)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 24)
                    
                    // Grey separator line
                    Rectangle()
                        .fill(Color(red: 0.85, green: 0.85, blue: 0.85))
                        .frame(height: 1)
                        .padding(.top, 20)
                    
                    // Tab Section
                    VStack(spacing: 0) {
                        // Tab Bar
                        HStack(spacing: 0) {
                            Button(action: { selectedTab = 0 }) {
                                VStack(spacing: 8) {
                                    Text("Stamps")
                                        .font(.custom("Kalam-Regular", size: 15))
                                        .foregroundColor(.black)
                                    
                                    Rectangle()
                                        .fill(selectedTab == 0 ? Color(red: 1.0, green: 0.91, blue: 0.38) : Color.clear)
                                        .frame(height: 3)
                                        .cornerRadius(1.5)
                                }
                                .frame(width: 74, height: 42)
                            }
                            .padding(.leading, 43)
                            
                            Button(action: { selectedTab = 1 }) {
                                VStack(spacing: 8) {
                                    Text("Friends")
                                        .font(.custom("Kalam-Regular", size: 15))
                                        .foregroundColor(.black)
                                    
                                    Rectangle()
                                        .fill(selectedTab == 1 ? Color(red: 1.0, green: 0.91, blue: 0.38) : Color.clear)
                                        .frame(height: 3)
                                        .cornerRadius(1.5)
                                }
                                .frame(width: 84, height: 42)
                            }
                            .padding(.leading, 24)
                            
                            Spacer()
                        }
                        
                        // Divider
                        Rectangle()
                            .fill(Color(red: 0.85, green: 0.85, blue: 0.85))
                            .frame(height: 1)
                            .padding(.horizontal, 6)
                        
                        // Tab Content
                        if selectedTab == 0 {
                            StampsView()
                        } else {
                            FriendsView()
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(10, corners: [.topLeft, .topRight])
                    .padding(.top, 20)
                }
            }
            .background(Color.white)
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddFriends) {
                AddFriendsView()
                    .environmentObject(authService)
            }
            .onAppear {
                loadUserAttributes()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func loadUserAttributes() {
        isLoading = true
        
        authService.getUserAttributes { attributes in
            self.userAttributes = attributes
            self.isLoading = false
        }
    }
}

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.custom("Kalam-Regular", size: 12))
                .foregroundColor(.black)
            
            Text(value)
                .font(.custom("Kalam-Regular", size: 24))
                .foregroundColor(.black)
        }
        .frame(width: 50, height: 50)
    }
}

struct StampsView: View {
    let stamps = [
        ("hand.point.right.fill", Color.yellow),
        ("flame.fill", Color.red),
        ("leaf.fill", Color.green),
        ("star.fill", Color.blue),
        ("heart.fill", Color.orange)
    ]
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 20) {
            ForEach(0..<stamps.count, id: \.self) { index in
                Image(systemName: stamps[index].0)
                    .font(.system(size: 24))
                    .foregroundColor(stamps[index].1)
                    .frame(width: 50, height: 50)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 100)
    }
}

struct FriendsView: View {
    var body: some View {
        VStack {
            Text("Friends list will go here")
                .font(.custom("Kalam-Regular", size: 16))
                .foregroundColor(.gray)
                .padding(.top, 50)
            
            Spacer()
        }
        .padding(.bottom, 100)
    }
}

struct AddFriendsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Add Friends functionality will go here")
                    .font(.custom("Kalam-Regular", size: 16))
                    .foregroundColor(.gray)
                    .padding(.top, 50)
                
                Spacer()
            }
            .navigationTitle("Add Friends")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct ProfileAvatarView: View {
    var body: some View {
        ZStack {
            // Background gradient similar to the Figma design
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 0.8, blue: 0.6), // Light peach
                    Color(red: 1.0, green: 0.6, blue: 0.7)  // Light pink
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: 81, height: 81)
            .clipShape(Circle())
            
            // Default avatar character or icon
            Text("👤")
                .font(.system(size: 40))
        }
        .overlay(Circle().stroke(Color.white, lineWidth: 2))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

#Preview {
    ProfileView()
        .environmentObject(CognitoAuthService())
}

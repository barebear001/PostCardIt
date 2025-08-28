import SwiftUI

struct ReceipientSelectionView: View {
    @State private var searchText = ""
    @State private var selectedFriend: Friend?
    @Environment(\.dismiss) private var dismiss
    
    let friends = Friend.sampleFriends
    
    var filteredFriends: [Friend] {
        if searchText.isEmpty {
            return friends
        } else {
            return friends.filter { friend in
                friend.name.localizedCaseInsensitiveContains(searchText) ||
                friend.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with back button and decorative elements
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                        .frame(width: 42, height: 41)
                }
                
                Spacer()
                
                // Decorative postcard elements
                Image("create_top_right_4")
                    .resizable()
                    .frame(width: 100, height: 57)
            }
            .padding(.horizontal)
            .frame(height: 102)
            .background(Color.white)
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                TextField("Search contact", text: $searchText)
                    .font(.custom("Kalam", size: 11))
                    .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black, lineWidth: 1)
            )
            .padding(.horizontal, 19)
            .padding(.top, 4)
            
            // Friends list
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredFriends) { friend in
                        FriendListItemView(
                            friend: friend,
                            isSelected: selectedFriend?.id == friend.id
                        ) {
                            selectedFriend = friend
                        }
                    }
                }
                .padding(.horizontal, 19)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            
            Spacer()
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .overlay(
            // Done Button (Bottom Right)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    NavigationLink(destination: SendCompleteView()) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 21)
                                .fill(Color.yellow)
                                .frame(width: 138, height: 42)
                            
                            Text("Done")
                                .font(.custom("Kalam-Regular", size: 20))
                                .foregroundColor(.black)
                        }
                    }
                    .disabled(selectedFriend == nil)
                    .opacity(selectedFriend == nil ? 0.6 : 1.0)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        )
    }
}

struct FriendListItemView: View {
    let friend: Friend
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Profile image
                ZStack {
                    if let imageName = friend.profileImageName {
                        // For now, use a placeholder with different colors for variety
                        Circle()
                            .fill(profileColor(for: friend.id))
                            .frame(width: 61, height: 61)
                            .overlay(
                                Text(String(friend.name.prefix(2)))
                                    .font(.custom("Kalam", size: 16))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            )
                    } else {
                        Circle()
                            .fill(Color(.systemGray4))
                            .frame(width: 61, height: 61)
                            .overlay(
                                Text(String(friend.name.prefix(2)))
                                    .font(.custom("Kalam", size: 16))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            )
                    }
                }
                
                // Friend name
                Text(friend.name)
                    .font(.custom("Kalam", size: 16))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Selection circle
                Circle()
                    .stroke(Color.black, lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.black : Color.clear)
                            .frame(width: 16, height: 16)
                    )
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Helper function to generate different colors for profile images
    private func profileColor(for id: UUID) -> Color {
        let colors: [Color] = [
            .blue, .purple, .pink, .red, .orange, 
            .yellow, .green, .cyan, .indigo, .mint
        ]
        let index = abs(id.hashValue) % colors.count
        return colors[index].opacity(0.8)
    }
}

#Preview {
    NavigationView {
        ReceipientSelectionView()
    }
}
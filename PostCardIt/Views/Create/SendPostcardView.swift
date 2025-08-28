import SwiftUI

struct Friend: Identifiable, Codable {
    let id = UUID()
    let name: String
    let email: String
    let profileImageName: String?
    let isOnline: Bool
    
    static let sampleFriends = [
        Friend(name: "Name Name", email: "email@example.com", profileImageName: "friend1", isOnline: true),
        Friend(name: "Name Name", email: "email@example.com", profileImageName: "friend2", isOnline: false),
        Friend(name: "Name Name", email: "email@example.com", profileImageName: "friend3", isOnline: true),
        Friend(name: "Name Name", email: "email@example.com", profileImageName: "friend4", isOnline: false),
        Friend(name: "Name Name", email: "email@example.com", profileImageName: "friend5", isOnline: true),
        Friend(name: "Name Name", email: "email@example.com", profileImageName: "friend6", isOnline: false),
        Friend(name: "Name Name", email: "email@example.com", profileImageName: "friend7", isOnline: true),
        Friend(name: "Name Name", email: "email@example.com", profileImageName: "friend8", isOnline: false),
        Friend(name: "Name Name", email: "email@example.com", profileImageName: "friend9", isOnline: true)
    ]
}

struct SendPostcardView: View {
    @State private var searchText = ""
    @State private var selectedFriend: Friend?
    @State private var emailAddress = ""
    @State private var phoneNumber = ""
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
                
                // Friends grid
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 20) {
                        ForEach(filteredFriends) { friend in
                            FriendGridItemView(
                                friend: friend,
                                isSelected: selectedFriend?.id == friend.id
                            ) {
                                selectedFriend = friend
                                emailAddress = ""
                                phoneNumber = ""
                            }
                        }
                    }
                    .padding(.horizontal, 54)
                    .padding(.top, 22)
                    .padding(.bottom, 20)
                }
                .frame(maxHeight: 313)
                
                // Email to section
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "envelope")
                            .font(.system(size: 17))
                            .foregroundColor(.black)
                        
                        Text("Email to")
                            .font(.custom("Kalam", size: 16))
                            .foregroundColor(.black)
                    }
                    .padding(.leading, 19)
                    
                    TextField("@ enter an email address here", text: $emailAddress)
                        .font(.custom("Kalam", size: 11))
                        .foregroundColor(Color.black.opacity(0.35))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black, lineWidth: 1)
                        )
                        .padding(.horizontal, 19)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .onChange(of: emailAddress) { _ in
                            if !emailAddress.isEmpty {
                                selectedFriend = nil
                                phoneNumber = ""
                            }
                        }
                }
                .padding(.top, 20)
                
                // Message to section
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "message")
                            .font(.system(size: 17))
                            .foregroundColor(.black)
                        
                        Text("Message to")
                            .font(.custom("Kalam", size: 16))
                            .foregroundColor(.black)
                    }
                    .padding(.leading, 19)
                    
                    HStack {
                        Text("+1")
                            .font(.custom("Kalam", size: 16))
                            .foregroundColor(.black)
                            .padding(.leading, 16)
                        
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 1, height: 22)
                            .padding(.leading, 8)
                        
                        TextField("enter a phone number here", text: $phoneNumber)
                            .font(.custom("Kalam", size: 11))
                            .foregroundColor(Color.black.opacity(0.35))
                            .padding(.leading, 8)
                            .keyboardType(.phonePad)
                            .onChange(of: phoneNumber) { _ in
                                if !phoneNumber.isEmpty {
                                    selectedFriend = nil
                                    emailAddress = ""
                                }
                            }
                    }
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black, lineWidth: 1)
                    )
                    .padding(.horizontal, 19)
                }
                .padding(.top, 20)
                
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
                        .disabled(!canSend)
                        .opacity(canSend ? 1.0 : 0.6)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            )
    }
    
    private var canSend: Bool {
        return selectedFriend != nil || 
               (!emailAddress.isEmpty && isValidEmail(emailAddress)) ||
               !phoneNumber.isEmpty
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}

struct FriendGridItemView: View {
    let friend: Friend
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Profile image
                ZStack {
                    if let imageName = friend.profileImageName {
                        // For now, use a placeholder with initials since we don't have the actual images
                        Circle()
                            .fill(Color.blue.opacity(0.7))
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
                    .font(.custom("Kalam", size: 11))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.vertical, 4)
            .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SendPostcardView()
}

import SwiftUI

struct Friend: Identifiable, Codable {
    let id = UUID()
    let name: String
    let email: String
    let profileImageName: String?
    let isOnline: Bool
    
    static let sampleFriends = [
        Friend(name: "Alice Johnson", email: "alice@example.com", profileImageName: nil, isOnline: true),
        Friend(name: "Bob Smith", email: "bob@example.com", profileImageName: nil, isOnline: false),
        Friend(name: "Carol Davis", email: "carol@example.com", profileImageName: nil, isOnline: true),
        Friend(name: "David Wilson", email: "david@example.com", profileImageName: nil, isOnline: false),
        Friend(name: "Emma Brown", email: "emma@example.com", profileImageName: nil, isOnline: true),
        Friend(name: "Frank Miller", email: "frank@example.com", profileImageName: nil, isOnline: false)
    ]
}

struct SendPostcardView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @State private var selectedFriend: Friend?
    @State private var sendViaEmail = false
    @State private var emailAddress = ""
    
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
        NavigationView {
            VStack(spacing: 0) {
                // Header with back button
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Text("Send Postcard")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    // Placeholder for symmetry
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.clear)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                
                Divider()
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search friends...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 16)
                
                // Friends list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredFriends) { friend in
                            FriendRowView(
                                friend: friend,
                                isSelected: selectedFriend?.id == friend.id
                            ) {
                                selectedFriend = friend
                                sendViaEmail = false
                                emailAddress = ""
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                }
                
                Divider()
                
                // Email option section
                VStack(spacing: 16) {
                    HStack {
                        Text("Or send via email")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    
                    VStack(spacing: 12) {
                        Toggle("Send via email", isOn: $sendViaEmail)
                            .toggleStyle(SwitchToggleStyle())
                            .onChange(of: sendViaEmail) { value in
                                if value {
                                    selectedFriend = nil
                                }
                            }
                        
                        if sendViaEmail {
                            TextField("Enter email address", text: $emailAddress)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.vertical, 16)
                
                Spacer()
                
                // Send button
                HStack {
                    Spacer()
                    
                    NavigationLink(destination: SendCompleteView()) {
                        Text("Send")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(canSend ? Color.blue : Color.gray)
                            .cornerRadius(25)
                    }
                    .disabled(!canSend)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationBarHidden(true)
            .toolbar(.hidden, for: .tabBar)
        }
    }
    
    private var canSend: Bool {
        if sendViaEmail {
            return !emailAddress.isEmpty && isValidEmail(emailAddress)
        } else {
            return selectedFriend != nil
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
}

struct FriendRowView: View {
    let friend: Friend
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Profile image placeholder
                ZStack {
                    Circle()
                        .fill(Color(.systemGray4))
                        .frame(width: 50, height: 50)
                    
                    if let imageName = friend.profileImageName {
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } else {
                        Text(String(friend.name.prefix(1)))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    
                    // Online status indicator
                    if friend.isOnline {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 14, height: 14)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .offset(x: 18, y: -18)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(friend.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(friend.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(12)
    }
}

#Preview {
    SendPostcardView()
}
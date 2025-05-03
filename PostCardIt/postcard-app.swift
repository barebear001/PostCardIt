// PostCardItApp.swift
import SwiftUI

@main
struct PostCardItApp: App {
    @State private var isShowingSplash = true
    
    var body: some Scene {
        WindowGroup {
            if isShowingSplash {
                SplashScreen()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                isShowingSplash = false
                            }
                        }
                    }
            } else {
                MainTabView()
            }
        }
    }
}

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

// PostcardPreviewView.swift
struct PostcardPreviewView: View {
    let index: Int
    
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.gray.opacity(0.2))
            .aspectRatio(1.4, contentMode: .fit)
            .overlay(
                Text("Postcard \(index + 1)")
                    .foregroundColor(.gray)
            )
    }
}

// MapView.swift
struct MapView: View {
    var body: some View {
        NavigationView {
            ZStack {
                // Full-screen map image
                Image("detailed_map")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                
//                 Map labels and icons for regions
                VStack {
                    Text("NORTH AMERICA")
                        .font(.caption)
                        .position(x: UIScreen.main.bounds.width * 0.3, y: UIScreen.main.bounds.height * 0.25)
                    
                    Text("SOUTH AMERICA")
                        .font(.caption)
                        .position(x: UIScreen.main.bounds.width * 0.3, y: UIScreen.main.bounds.height * 0.5)
                    
                    Text("PACIFIC OCEAN")
                        .font(.caption)
                        .position(x: UIScreen.main.bounds.width * 0.15, y: UIScreen.main.bounds.height * 0.4)
                    
                    Text("ATLANTIC OCEAN")
                        .font(.caption)
                        .position(x: UIScreen.main.bounds.width * 0.7, y: UIScreen.main.bounds.height * 0.4)
                }
            }
            .navigationTitle("World Map")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// ImagePicker.swift
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// PostcardPreviewDetailView.swift
struct PostcardPreviewDetailView: View {
    let country: String
    let message: String
    let image: UIImage?
    @State private var isSending = false
    @State private var isSent = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                // Postcard preview
                VStack {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 200)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("To: \(country)")
                            .font(.headline)
                        
                        Text(message)
                            .font(.body)
                            .padding(.vertical, 5)
                        
                        HStack {
                            Spacer()
                            Text("From: You")
                                .font(.subheadline)
                                .italic()
                        }
                    }
                    .padding()
                }
                .background(Color.white)
                .cornerRadius(15)
                .shadow(radius: 5)
                .padding()
                
                Spacer()
                
                // Send button
                Button(action: {
                    sendPostcard()
                }) {
                    if isSending {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else if isSent {
                        Label("Sent!", systemImage: "checkmark")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                    } else {
                        Text("Send Postcard")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .disabled(isSending || isSent)
                .padding()
            }
            .navigationTitle("Postcard Preview")
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    func sendPostcard() {
        isSending = true
        
        // Simulate network request
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSending = false
            isSent = true
            
            // Dismiss after showing success
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

// MyCardsView.swift
struct MyCardsView: View {
    @State private var selectedTab = 0
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationView {
            VStack {
                // Tab selector
                Picker("View", selection: $selectedTab) {
                    Text("Received").tag(0)
                    Text("Sent").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Cards grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(0..<8, id: \.self) { index in
                            NavigationLink(destination: CardDetailView(isReceived: selectedTab == 0, index: index)) {
                                CardPreviewView(isReceived: selectedTab == 0, index: index)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(selectedTab == 0 ? "Received Cards" : "Sent Cards")
        }
    }
}

// CardPreviewView.swift
struct CardPreviewView: View {
    let isReceived: Bool
    let index: Int
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.2))
                .aspectRatio(1.4, contentMode: .fit)
                .overlay(
                    VStack {
                        Text(isReceived ? "From: John" : "To: Sarah")
                            .font(.caption)
                        Text(isReceived ? "France" : "Japan")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                )
        }
    }
}

// CardDetailView.swift
struct CardDetailView: View {
    let isReceived: Bool
    let index: Int
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Card image
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1.6, contentMode: .fit)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
                
                VStack(alignment: .leading, spacing: 10) {
                    // Card details
                    HStack {
                        Text(isReceived ? "From:" : "To:")
                            .fontWeight(.bold)
                        Text(isReceived ? "John Doe" : "Sarah Smith")
                    }
                    
                    HStack {
                        Text("Location:")
                            .fontWeight(.bold)
                        Text(isReceived ? "Paris, France" : "Tokyo, Japan")
                    }
                    
                    HStack {
                        Text("Date:")
                            .fontWeight(.bold)
                        Text("May 1, 2025")
                    }
                    
                    Divider()
                    
                    Text("Message:")
                        .fontWeight(.bold)
                    
                    Text("Hello from \(isReceived ? "Paris" : "Tokyo")! Having a wonderful time here. The weather is perfect and the sights are amazing. Wish you were here!")
                        .padding(.bottom)
                    
                    if isReceived {
                        Button(action: {
                            // Reply functionality
                        }) {
                            Label("Reply", systemImage: "arrowshape.turn.up.left")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
            .padding(.bottom)
        }
        .navigationTitle(isReceived ? "Received Card" : "Sent Card")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// ProfileView.swift
struct ProfileView: View {
    @State private var username = "YourUsername"
    @State private var email = "your.email@example.com"
    @State private var notifications = true
    @State private var darkMode = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile")) {
                    HStack {
                        Spacer()
                        VStack {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.blue)
                            
                            Text(username)
                                .font(.headline)
                                .padding(.top, 5)
                            
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(.vertical)
                    
                    Button("Edit Profile") {
                        // Edit profile functionality
                    }
                }
                
                Section(header: Text("Settings")) {
                    Toggle("Push Notifications", isOn: $notifications)
                    Toggle("Dark Mode", isOn: $darkMode)
                    
                    NavigationLink(destination: PrivacySettingsView()) {
                        Text("Privacy Settings")
                    }
                    
                    NavigationLink(destination: HelpSupportView()) {
                        Text("Help & Support")
                    }
                }
                
                Section {
                    Button("Log Out") {
                        // Log out functionality
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Profile")
        }
    }
}

// PrivacySettingsView.swift
struct PrivacySettingsView: View {
    @State private var locationAccess = true
    @State private var photoAccess = true
    @State private var publicProfile = false
    
    var body: some View {
        Form {
            Section(header: Text("App Permissions")) {
                Toggle("Location Access", isOn: $locationAccess)
                Toggle("Photo Library Access", isOn: $photoAccess)
            }
            
            Section(header: Text("Profile Privacy")) {
                Toggle("Public Profile", isOn: $publicProfile)
                
                if publicProfile {
                    Text("Your postcards will be visible to other users")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("Privacy Settings")
    }
}

// HelpSupportView.swift
struct HelpSupportView: View {
    var body: some View {
        List {
            Section(header: Text("Frequently Asked Questions")) {
                NavigationLink("How to create a postcard", destination: FAQDetailView(title: "How to create a postcard"))
                NavigationLink("Sharing postcards", destination: FAQDetailView(title: "Sharing postcards"))
                NavigationLink("Account issues", destination: FAQDetailView(title: "Account issues"))
            }
            
            Section(header: Text("Contact Us")) {
                Button(action: {
                    // Email support
                }) {
                    Label("Email Support", systemImage: "envelope")
                }
                
                Button(action: {
                    // Call support
                }) {
                    Label("Call Support", systemImage: "phone")
                }
            }
            
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.gray)
                }
                
                NavigationLink("Terms of Service", destination: LegalView(title: "Terms of Service"))
                NavigationLink("Privacy Policy", destination: LegalView(title: "Privacy Policy"))
            }
        }
        .navigationTitle("Help & Support")
    }
}

// FAQDetailView.swift
struct FAQDetailView: View {
    let title: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam auctor, nisl eget ultricies aliquam, nunc nisl aliquet nunc, quis aliquam nisl nunc vel nisl. Nullam auctor, nisl eget ultricies aliquam, nunc nisl aliquet nunc, quis aliquam nisl nunc vel nisl.")
                    .padding()
                
                Text("Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.")
                    .padding(.horizontal)
            }
        }
        .navigationTitle(title)
    }
}

// Preview providers for SwiftUI previews in Xcode
struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}

struct MyCardsView_Previews: PreviewProvider {
    static var previews: some View {
        MyCardsView()
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}

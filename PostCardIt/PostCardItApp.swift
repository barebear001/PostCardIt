// PostCardItApp.swift
import SwiftUI
import AWSCore

@main
struct PostCardItApp: App {
    @StateObject private var authService = CognitoAuthService()
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
                if authService.isAuthenticated {
                    MainTabView()
                        .environmentObject(authService)
                } else {
                    LoginView()
                        .environmentObject(authService)
                }
            }
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

//struct ProfileView_Previews: PreviewProvider {
//    static var previews: some View {
//        ProfileView()
//    }
//}

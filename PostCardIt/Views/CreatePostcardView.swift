// CreatePostcardView.swift
import SwiftUI

struct CreatePostcardView: View {
    @EnvironmentObject var authService: CognitoAuthService
    @StateObject private var postcardService = PostcardService()
    
    @State private var selectedCountry = "United States"
    @State private var message = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isShowingPreview = false
    @State private var recipientName = ""
    @State private var userAttributes: [String: String] = [:]
    @State private var isLoadingUserInfo = false
    
    let countries = ["United States", "Canada", "Mexico", "Brazil", "France", "Japan", "Australia", "United Kingdom", "Germany", "Italy", "Spain", "China", "India", "Russia"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Recipient")) {
                    TextField("Recipient Name", text: $recipientName)
                    
                    Picker("Country", selection: $selectedCountry) {
                        ForEach(countries, id: \.self) {
                            Text($0)
                        }
                    }
                }
                
                Section(header: Text("Message")) {
                    TextEditor(text: $message)
                        .frame(height: 150)
                }
                
                Section(header: Text("Photo")) {
                    Button(action: {
                        showImagePicker = true
                    }) {
                        HStack {
                            Text("Choose Photo")
                            Spacer()
                            if let selectedImage = selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(5)
                            } else {
                                Image(systemName: "photo")
                            }
                        }
                    }
                }
                
                if postcardService.isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Spacer()
                        }
                    }
                } else if !postcardService.errorMessage.isEmpty {
                    Section {
                        Text(postcardService.errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button("Preview Postcard") {
                        isShowingPreview = true
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(message.isEmpty || recipientName.isEmpty || postcardService.isLoading)
                }
            }
            .navigationTitle("Create Postcard")
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .sheet(isPresented: $isShowingPreview) {
                PostcardPreviewDetailView(
                    country: selectedCountry,
                    message: message,
                    image: selectedImage,
                    senderName: userAttributes["name"] ?? "You",
                    recipientName: recipientName,
                    postcardService: postcardService,
                    authService: authService
                )
            }
            .onAppear {
                loadUserInfo()
            }
        }
    }
    
    private func loadUserInfo() {
        isLoadingUserInfo = true
        
        authService.getUserAttributes { attributes in
            self.userAttributes = attributes
            self.isLoadingUserInfo = false
        }
    }
}

// Updated PostcardPreviewDetailView.swift
struct PostcardPreviewDetailView: View {
    let country: String
    let message: String
    let image: UIImage?
    let senderName: String
    let recipientName: String
    
    var postcardService: PostcardService
    var authService: CognitoAuthService
    
    @State private var isSending = false
    @State private var isSent = false
    @State private var errorMessage = ""
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
                        Text("To: \(recipientName) in \(country)")
                            .font(.headline)
                        
                        Text(message)
                            .font(.body)
                            .padding(.vertical, 5)
                        
                        HStack {
                            Spacer()
                            Text("From: \(senderName)")
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
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
                
                Spacer()
                
                // Send button
                Button(action: {
                    sendPostcard()
                }) {
                    if postcardService.isLoading {
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
                .disabled(postcardService.isLoading || isSent)
                .padding()
            }
            .navigationTitle("Postcard Preview")
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    func sendPostcard() {
        guard let userId = authService.user?.username else {
            errorMessage = "User not logged in"
            return
        }
        
        // Create a new postcard object
        let postcard = Postcard(
            senderId: userId,
            senderName: senderName,
            recipientName: recipientName,
            message: message,
            country: country
        )
        
        // Send the postcard
        postcardService.sendPostcard(postcard: postcard, image: image) { success, error in
            if success {
                isSent = true
                
                // Dismiss after showing success
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    presentationMode.wrappedValue.dismiss()
                }
            } else {
                errorMessage = error ?? "Failed to send postcard"
            }
        }
    }
}

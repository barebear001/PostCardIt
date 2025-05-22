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

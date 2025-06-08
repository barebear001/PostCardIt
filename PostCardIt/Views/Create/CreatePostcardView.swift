// CreatePostcardView.swift
import SwiftUI
import Photos

struct CreatePostcardView: View {
    @EnvironmentObject var authService: CognitoAuthService
    @StateObject private var postcardService = PostcardService()
    
    @State private var selectedCountry = "United States"
    @State private var message = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var isShowingPreview = false
    @State private var recipientName = ""
    @State private var userAttributes: [String: String] = [:]
    @State private var isLoadingUserInfo = false
    @State private var photoAssets: [PHAsset] = []
    @State private var albumImages: [UIImage] = []
    
    let countries = ["United States", "Canada", "Mexico", "Brazil", "France", "Japan", "Australia", "United Kingdom", "Germany", "Italy", "Spain", "China", "India", "Russia"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Selected Photo Preview at Top
                    VStack {
                        Text("Selected Photo")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(12)
                                .shadow(radius: 4)
                                .padding(.horizontal)
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 200)
                                .cornerRadius(12)
                                .overlay(
                                    VStack {
                                        Image(systemName: "photo")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray)
                                        Text("No photo selected")
                                            .foregroundColor(.gray)
                                    }
                                )
                                .padding(.horizontal)
                        }
                    }
                    
                    // Form Section
                    VStack(spacing: 16) {
                        // Recipient Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recipient")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            TextField("Recipient Name", text: $recipientName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Picker("Country", selection: $selectedCountry) {
                                ForEach(countries, id: \.self) {
                                    Text($0)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        .padding(.horizontal)
                        
                        // Message Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Message")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            TextEditor(text: $message)
                                .frame(height: 100)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal)
                        
                        // Error/Loading States
                        if postcardService.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Spacer()
                            }
                        } else if !postcardService.errorMessage.isEmpty {
                            Text(postcardService.errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal)
                        }
                        
                        // Preview Button
                        Button("Preview Postcard") {
                            isShowingPreview = true
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .disabled(message.isEmpty || recipientName.isEmpty || postcardService.isLoading)
                        .padding(.horizontal)
                    }
                    
                    // Photo Album Section at Bottom
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose Photo")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                // Camera Button (First Item)
                                Button(action: {
                                    showCamera = true
                                }) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.blue.opacity(0.1))
                                            .frame(width: 80, height: 80)
                                        
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(.blue)
                                    }
                                }
                                
                                // Album Photos
                                ForEach(Array(albumImages.enumerated()), id: \.offset) { index, image in
                                    Button(action: {
                                        selectedImage = image
                                    }) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipped()
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(
                                                        selectedImage == image ? Color.blue : Color.clear,
                                                        lineWidth: 3
                                                    )
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Create Postcard")
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker(selectedImage: $selectedImage)
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
                requestPhotoLibraryPermission()
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
    
    private func requestPhotoLibraryPermission() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                if status == .authorized || status == .limited {
                    loadPhotoAssets()
                }
            }
        }
    }
    
    private func loadPhotoAssets() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 50 // Limit to recent 50 photos for performance
        
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var newAssets: [PHAsset] = []
        
        assets.enumerateObjects { asset, _, _ in
            newAssets.append(asset)
        }
        
        self.photoAssets = newAssets
        loadImagesFromAssets()
    }
    
    private func loadImagesFromAssets() {
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.isNetworkAccessAllowed = true
        
        var images: [UIImage] = []
        let group = DispatchGroup()
        
        for asset in photoAssets {
            group.enter()
            imageManager.requestImage(
                for: asset,
                targetSize: CGSize(width: 200, height: 200),
                contentMode: .aspectFill,
                options: requestOptions
            ) { image, _ in
                if let image = image {
                    images.append(image)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.albumImages = images
        }
    }
}

// MARK: - CameraPicker
struct CameraPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        
        init(_ parent: CameraPicker) {
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

#Preview {
    let mockAuthService = CognitoAuthService()

    CreatePostcardView()
        .environmentObject(mockAuthService)
}

// CreatePostcardView.swift
import SwiftUI
import Photos

struct CreatePostcardView: View {
    @EnvironmentObject var authService: CognitoAuthService
    @StateObject private var postcardService = PostcardService()
    @Binding var selectedTab: Int
    @Environment(\.dismiss) private var dismiss
    
    @State private var path = NavigationPath()
    @State private var selectedImage: UIImage?
    @State private var showCamera = false
    @State private var photoAssets: [PHAsset] = []
    @State private var albumImages: [UIImage] = []
    
    // Sample images to show from design
    let sampleImages = ["sample_image1", "sample_image2", "sample_image3"]
    let columns = Array(repeating: GridItem(.fixed(91), spacing: 2), count: 4)
    
    var body: some View {
        NavigationStack(path: $path) {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Header with close button and decorative elements
                    HStack {
                        Button(action: {
                            print("Close button tapped, dismissing view")
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.black)
                                .frame(width: 36, height: 42)
                        }
                        
                        Spacer()
                        
                        // Decorative elements from Figma
                        Image("create_top_right_1")
                            .resizable()
                            .frame(width: 100, height: 57)
                    }
                    .padding(.horizontal)
                    //                .padding(.top, 5)
                    .frame(height: 80)
                    .background(Color.white)
                    
                    // Main postcard image
                    ZStack {
                        RoundedRectangle(cornerRadius: 0)
                            .fill(Color(red: 0.992, green: 0.988, blue: 0.982))
                            .shadow(color: Color.black.opacity(0.25), radius: 3, x: 1, y: 2)
                        
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 360, height: 263)
                                .clipped()
                            //                            .cornerRadius(0)
                        } else {
                            Image("main_postcard_image")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 360, height: 263)
                                .clipped()
                                .cornerRadius(0)
                        }
                    }
                    .frame(width: 344, height: 263)
                    .padding(.horizontal, 25)
                    .padding(.top, 20)
                    
                    Spacer(minLength: 20)
                    
                    // Recents section
                    VStack(spacing: 0) {
                        HStack {
                            Text("Recents >")
                                .font(.custom("Kalam", size: 16))
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .padding(.horizontal, 19)
                        .padding(.bottom, 10)
                        
                        // Separator line
                        Rectangle()
                            .fill(Color(red: 0.85, green: 0.85, blue: 0.85))
                            .frame(height: 1)
                        
                        // Photo grid
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 2) {
                                // Camera button
                                Button(action: { showCamera = true }) {
                                    ZStack {
                                        Rectangle()
                                            .fill(Color.white)
                                            .frame(width: 91, height: 91)
                                            .border(Color.black, width: 1)
                                        
                                        Image("camera")
                                            .resizable()
                                            .frame(width: 58, height: 57)
                                    }
                                }
                                
                                // Sample images from design
                                ForEach(Array(sampleImages.enumerated()), id: \.offset) { index, imageName in
                                    Button(action: {
                                        // Load the sample image
                                        if let uiImage = UIImage(named: imageName) {
                                            selectedImage = uiImage
                                        }
                                    }) {
                                        Image(imageName)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 91, height: 91)
                                            .clipped()
                                    }
                                }
                                
                                // Album photos from user's library
                                ForEach(Array(albumImages.enumerated()), id: \.offset) { index, image in
                                    Button(action: { selectedImage = image }) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 91, height: 91)
                                            .clipped()
                                            .overlay(
                                                Rectangle()
                                                    .stroke(
                                                        selectedImage == image ? Color.blue : Color.clear,
                                                        lineWidth: 2
                                                    )
                                            )
                                    }
                                }
                                
                                // Empty placeholder cells
                                ForEach(0..<8, id: \.self) { _ in
                                    Rectangle()
                                        .fill(Color(red: 0.914, green: 0.914, blue: 0.914))
                                        .frame(width: 91, height: 91)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                        }
                        //                    .padding(.bottom)
                        .frame(height: 300)
                    }
                    .background(Color.white)
                    
                    // Bottom section with Next button
                    VStack {
                        HStack {
                            Spacer()
                            NavigationLink(destination: PostcardWritingView()) {
                                HStack {
                                    Text("Next")
                                        .font(.custom("Kalam", size: 20))
                                        .foregroundColor(.black)
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.black)
                                }
                                .padding()
                                .frame(width: 138, height: 42)
                                .background(Color.yellow)
                                .cornerRadius(21)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 5)
                        
                        // Home indicator
                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(Color.black)
                            .frame(width: 138.5, height: 5)
                            .padding(.top, 10)
                    }
                    .frame(height: 91)
                    .background(Color.white)
                }
            }
            .background(Color.white)
            .sheet(isPresented: $showCamera) {
                CameraPicker(selectedImage: $selectedImage)
            }
            .onAppear {
                requestPhotoLibraryPermission()
            }
            .toolbar(.hidden, for: .tabBar)
            .toolbar(.hidden, for: .navigationBar)
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

// Break into separate views
struct CameraButtonView: View {
    @Binding var showCamera: Bool
    
    var body: some View {
        Button(action: {
            showCamera = true
        }) {
            ZStack {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                    .border(Color.black)
                
                Image("camera")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }
        }
    }
}

struct PhotoCellView: View {
    let image: UIImage
    @Binding var selectedImage: UIImage?
    
    var body: some View {
        Button(action: {
            selectedImage = image
        }) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipped()
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

    CreatePostcardView(selectedTab: .constant(2))
        .environmentObject(mockAuthService)
}

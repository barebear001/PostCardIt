// MyCardsView.swift
import SwiftUI

struct MyCardsView: View {
    @EnvironmentObject var authService: CognitoAuthService
    @StateObject private var postcardService = PostcardService()
    @State private var showingError = false
    @State private var refreshing = false
    
    // Optional injected service for preview/testing
    var injectedPostcardService: PostcardService?
    
    // Computed property to get the active service
    private var activePostcardService: PostcardService {
        return injectedPostcardService ?? postcardService
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with title
            VStack {
                Text("My Collection")
                    .font(.custom("Kalam-Regular", size: 16))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 20)
            }
            .frame(height: 102)
            .background(Color.white)
            
            // Main content
            if activePostcardService.isLoading && !refreshing {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                Spacer()
            } else if activePostcardService.receivedPostcards.isEmpty && activePostcardService.sentPostcards.isEmpty {
                Spacer()
                VStack(spacing: 20) {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No postcards yet")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    NavigationLink(destination: CreatePostcardView(selectedTab: .constant(2))) {
                        Text("Create a Postcard")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                Spacer()
            } else {
                // Masonry grid with all postcards
                ScrollView {
                    MasonryGrid(items: allPostcards, columns: 2, spacing: 16) { postcard in
                        NavigationLink(
                            destination: CardDetailView(
                                postcard: postcard,
                                isReceived: activePostcardService.receivedPostcards.contains(where: { $0.id == postcard.id }),
                                postcardService: activePostcardService
                            )
                        ) {
                            PostcardFrontImageView(postcard: postcard)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 0)
                    .padding(.bottom, 120)
                }
                .refreshable {
                    loadPostcards()
                }
            }
        }
        .background(Color.white)
        .alert(isPresented: $showingError) {
            Alert(
                title: Text("Error"),
                message: Text(activePostcardService.errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            loadPostcards()
        }
    }
    
    // Combine received and sent postcards
    private var allPostcards: [Postcard] {
        var combined = activePostcardService.receivedPostcards
        combined.append(contentsOf: activePostcardService.sentPostcards)
        return combined.sorted { $0.createdAt > $1.createdAt }
    }
    
    private func loadPostcards() {
        // Only load if using the real service, not injected one
        guard injectedPostcardService == nil else { return }
        
        guard let userId = authService.user?.username else {
            activePostcardService.errorMessage = "User not logged in"
            showingError = true
            return
        }
        
        activePostcardService.fetchUserPostcards(userId: userId)
    }
}

// Postcard front image view that displays only the scenic image
struct PostcardFrontImageView: View {
    let postcard: Postcard
    @State private var imageURL: URL?
    
    var body: some View {
        if let imageKey = postcard.imageKey {
            // For preview with local assets
            if imageKey.starts(with: "preview_postcard") {
                Image(imageKey)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .background(Color(red: 0.992, green: 0.988, blue: 0.982)) // Off-white background
                    .clipped()
                    .shadow(color: Color.black.opacity(0.25), radius: 3, x: 1, y: 2) // Figma shadow
            } else {
                // For production with remote URLs
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(1.4, contentMode: .fit)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.8)
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .background(Color(red: 0.992, green: 0.988, blue: 0.982))
                            .clipped()
                            .shadow(color: Color.black.opacity(0.25), radius: 3, x: 1, y: 2)
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(1.4, contentMode: .fit)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                                    .font(.title)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .onAppear {
                    let service = PostcardService()
                    self.imageURL = service.getImageURL(imageKey: imageKey)
                }
            }
        }
    }
}

// Full-screen image view
struct FullImageView: View {
    let imageURL: URL
    @Environment(\.presentationMode) var presentationMode
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    self.scale = value
                                }
                                .onEnded { _ in
                                    withAnimation {
                                        self.scale = 1.0
                                    }
                                }
                        )
                case .failure:
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        
                        Text("Failed to load image")
                            .foregroundColor(.white)
                    }
                @unknown default:
                    EmptyView()
                }
            }
            
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                
                Spacer()
            }
        }
    }
}

// Create reply view for responding to a received postcard
struct CreateReplyView: View {
    let originalPostcard: Postcard
    @EnvironmentObject var authService: CognitoAuthService
    @StateObject private var postcardService = PostcardService()
    
    @State private var message = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isShowingPreview = false
    @State private var userAttributes: [String: String] = [:]
    @State private var isLoadingUserInfo = false
    
    var body: some View {
        Form {
            Section(header: Text("Replying to \(originalPostcard.senderName)")) {
                Text("Country: \(originalPostcard.country)")
                    .foregroundColor(.gray)
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
                Button("Preview Reply") {
                    isShowingPreview = true
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .disabled(message.isEmpty || postcardService.isLoading)
            }
        }
        .navigationTitle("Reply to Postcard")
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .sheet(isPresented: $isShowingPreview) {
            PostcardPreviewDetailView(
                country: originalPostcard.country,
                message: message,
                image: selectedImage,
                senderName: userAttributes["name"] ?? "You",
                recipientName: originalPostcard.senderName,
                postcardService: postcardService,
                authService: authService
            )
        }
        .onAppear {
            loadUserInfo()
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

// RefreshableScrollView - Pull to refresh component
struct RefreshableScrollView<Content: View>: View {
    @State private var previousScrollOffset: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var frozen: Bool = false
    @State private var rotation: Angle = .degrees(0)
    
    var threshold: CGFloat = 80
    let content: Content
    let onRefresh: (@escaping () -> Void) -> Void
    
    init(onRefresh: @escaping (@escaping () -> Void) -> Void, @ViewBuilder content: () -> Content) {
        self.onRefresh = onRefresh
        self.content = content()
    }
    
    var body: some View {
        VStack {
            ScrollView {
                ZStack(alignment: .top) {
                    MovingView()
                    
                    VStack {
                        self.content
                            .alignmentGuide(.top, computeValue: { _ in
                                (self.scrollOffset > 0) ? -self.scrollOffset : 0
                            })
                    }
                    
                    SymbolView(height: self.scrollOffset, threshold: self.threshold, frozen: self.frozen, rotation: self.rotation)
                }
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(OffsetPreferenceKey.self) { offset in
                self.scrollOffset = offset
                self.rotation = self.symbolRotation(at: self.scrollOffset)
                
                if !self.frozen && self.scrollOffset > self.threshold {
                    self.frozen = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            self.rotation = .degrees(0)
                        }
                    }
                    
                    self.onRefresh {
                        withAnimation {
                            self.frozen = false
                        }
                    }
                }
                
                // Save last offset
                self.previousScrollOffset = self.scrollOffset
            }
        }
    }
    
    func symbolRotation(at scrollOffset: CGFloat) -> Angle {
        if scrollOffset < self.threshold * 0.5 {
            return .degrees(0)
        } else {
            let h = Double(self.scrollOffset - self.threshold * 0.5)
            let hMax = Double(self.threshold * 0.5)
            return .degrees(180 * min(h / hMax, 1.0))
        }
    }
    
    struct OffsetPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat {
            return 0
        }
        
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }
    
    struct MovingView: View {
        var body: some View {
            GeometryReader { geometry in
                Color.clear.preference(key: OffsetPreferenceKey.self, value: -geometry.frame(in: .named("scroll")).origin.y)
            }
        }
    }
    
    struct SymbolView: View {
        var height: CGFloat
        var threshold: CGFloat
        var frozen: Bool
        var rotation: Angle
        
        var body: some View {
            VStack {
                Spacer().frame(height: 0)
                
                if self.height > 0 {
                    Image(systemName: "arrow.down")
                        .foregroundColor(self.frozen ? .gray : .blue)
                        .rotationEffect(self.rotation)
                        .offset(y: -self.height + (self.frozen ? self.threshold : 0))
                        .animation(self.frozen ? nil : .easeInOut, value: self.height)
                    
                    Spacer().frame(height: self.frozen ? self.threshold : 0)
                }
            }
        }
    }
}

#Preview {
    let mockAuthService = CognitoAuthService()
    
    // Create sample postcards using the downloaded images
    let samplePostcards = [
        Postcard(id: "1", senderId: "user1", senderName: "Alice", recipientName: "You", message: "Having a great time!", country: "Hawaii", imageKey: "preview_postcard_1", createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()),
        Postcard(id: "2", senderId: "user2", senderName: "Bob", recipientName: "You", message: "Beautiful sunset here!", country: "California", imageKey: "preview_postcard_2", createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()),
        Postcard(id: "3", senderId: "user3", senderName: "Charlie", recipientName: "You", message: "City life is amazing!", country: "New York", imageKey: "preview_postcard_3", createdAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()),
        Postcard(id: "4", senderId: "current_user", senderName: "You", recipientName: "Diana", message: "Missing you!", country: "Japan", imageKey: "preview_postcard_4", createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(), isSent: true),
        Postcard(id: "5", senderId: "current_user", senderName: "You", recipientName: "Emma", message: "Wish you were here!", country: "France", imageKey: "preview_postcard_5", createdAt: Calendar.current.date(byAdding: .day, value: -4, to: Date()) ?? Date(), isSent: true),
        Postcard(id: "6", senderId: "user6", senderName: "Frank", recipientName: "You", message: "Greetings from paradise!", country: "Maldives", imageKey: "preview_postcard_6", createdAt: Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date()),
        Postcard(id: "7", senderId: "current_user", senderName: "You", recipientName: "Grace", message: "Amazing architecture here!", country: "Italy", imageKey: "preview_postcard_7", createdAt: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(), isSent: true),
        Postcard(id: "8", senderId: "user8", senderName: "Helen", recipientName: "You", message: "Palm trees and beaches!", country: "Miami", imageKey: "preview_postcard_8", createdAt: Calendar.current.date(byAdding: .day, value: -8, to: Date()) ?? Date())
    ]
    
    // Create mock PostcardService with sample data
    let mockPostcardService = PostcardService()
    mockPostcardService.receivedPostcards = samplePostcards.filter { !$0.isSent }
    mockPostcardService.sentPostcards = samplePostcards.filter { $0.isSent }
    
    // Use the actual MyCardsView with injected mock service
    return MyCardsView(injectedPostcardService: mockPostcardService)
        .environmentObject(mockAuthService)
}

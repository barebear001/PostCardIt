// MyCardsView.swift
import SwiftUI

struct MyCardsView: View {
    @EnvironmentObject var authService: CognitoAuthService
    @StateObject private var postcardService = PostcardService()
    @State private var selectedTab = 0
    @State private var showingError = false
    @State private var refreshing = false
    
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
                
                if postcardService.isLoading && !refreshing {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                } else if (selectedTab == 0 && postcardService.receivedPostcards.isEmpty) ||
                          (selectedTab == 1 && postcardService.sentPostcards.isEmpty) {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: selectedTab == 0 ? "envelope" : "paperplane")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text(selectedTab == 0 ? "No postcards received yet" : "No postcards sent yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        if selectedTab == 1 {
                            NavigationLink(destination: CreatePostcardView(selectedTab: $selectedTab)) {
                                Text("Create a Postcard")
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    Spacer()
                } else {
                    // Cards grid with pull to refresh
                    RefreshableScrollView(onRefresh: { done in
                        refreshing = true
                        loadPostcards()
                        // Simulate network delay for better UX feedback
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            refreshing = false
                            done()
                        }
                    }) {
                        LazyVGrid(columns: columns, spacing: 16) {
                            if selectedTab == 0 {
                                ForEach(postcardService.receivedPostcards) { postcard in
                                    NavigationLink(
                                        destination: CardDetailView(
                                            postcard: postcard,
                                            isReceived: true,
                                            postcardService: postcardService
                                        )
                                    ) {
                                        CardPreviewView(postcard: postcard, isReceived: true)
                                    }
                                }
                            } else {
                                ForEach(postcardService.sentPostcards) { postcard in
                                    NavigationLink(
                                        destination: CardDetailView(
                                            postcard: postcard,
                                            isReceived: false,
                                            postcardService: postcardService
                                        )
                                    ) {
                                        CardPreviewView(postcard: postcard, isReceived: false)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(selectedTab == 0 ? "Received Cards" : "Sent Cards")
            .alert(isPresented: $showingError) {
                Alert(
                    title: Text("Error"),
                    message: Text(postcardService.errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                loadPostcards()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedTab == 1 {
                        NavigationLink(destination: CreatePostcardView(selectedTab: $selectedTab)) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
    }
    
    private func loadPostcards() {
        guard let userId = authService.user?.username else {
            postcardService.errorMessage = "User not logged in"
            showingError = true
            return
        }
        
        postcardService.fetchUserPostcards(userId: userId)
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

    MyCardsView()
        .environmentObject(mockAuthService)
}

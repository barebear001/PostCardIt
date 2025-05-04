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
                            NavigationLink(destination: CreatePostcardView()) {
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
                        NavigationLink(destination: CreatePostcardView()) {
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

// CardPreviewView.swift
struct CardPreviewView: View {
    let postcard: Postcard
    let isReceived: Bool
    @State private var imageURL: URL?
    @State private var showingImage = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.2))
                .aspectRatio(1.4, contentMode: .fit)
                .shadow(radius: 2)
            
            VStack {
                if let imageURL = imageURL, showingImage {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(height: 60)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 60)
                                .clipped()
                                .cornerRadius(5)
                        case .failure:
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(height: 60)
                    .padding(.top, 5)
                }
                
                VStack(spacing: 4) {
                    Text(isReceived ? "From: \(postcard.senderName)" : "To: \(postcard.recipientName)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(postcard.country)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    Text(formattedDate(postcard.createdAt))
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                .padding(.vertical, 8)
            }
            .padding(.horizontal, 5)
        }
        .onAppear {
            if let imageKey = postcard.imageKey {
                let service = PostcardService()
                self.imageURL = service.getImageURL(imageKey: imageKey)
                
                // Give a small delay to improve the grid loading appearance
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        self.showingImage = true
                    }
                }
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// CardDetailView.swift
struct CardDetailView: View {
    let postcard: Postcard
    let isReceived: Bool
    let postcardService: PostcardService
    
    @State private var imageURL: URL?
    @State private var showingDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var showingDeleteError = false
    @State private var showingFullImage = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Card image
                if let imageURL = imageURL {
                    Button(action: {
                        showingFullImage = true
                    }) {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(height: 200)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 200)
                                    .clipped()
                            case .failure:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 200)
                                    .overlay(
                                        Image(systemName: "exclamationmark.triangle")
                                            .font(.largeTitle)
                                            .foregroundColor(.gray)
                                    )
                            @unknown default:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 200)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
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
                    // Card details
                    HStack {
                        Text(isReceived ? "From:" : "To:")
                            .fontWeight(.bold)
                        Text(isReceived ? postcard.senderName : postcard.recipientName)
                    }
                    
                    HStack {
                        Text("Location:")
                            .fontWeight(.bold)
                        Text(postcard.country)
                    }
                    
                    HStack {
                        Text("Date:")
                            .fontWeight(.bold)
                        Text(formattedDate(postcard.createdAt))
                    }
                    
                    Divider()
                    
                    Text("Message:")
                        .fontWeight(.bold)
                    
                    Text(postcard.message)
                        .padding(.bottom)
                    
                    if isReceived {
                        NavigationLink(destination: CreateReplyView(originalPostcard: postcard)) {
                            Label("Reply", systemImage: "arrowshape.turn.up.left")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    } else {
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            Label("Delete", systemImage: "trash")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                        .disabled(isDeleting)
                    }
                }
                .padding()
            }
            .padding(.bottom)
        }
        .navigationTitle(isReceived ? "Received Card" : "Sent Card")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showingDeleteConfirmation) {
            Alert(
                title: Text("Delete Postcard"),
                message: Text("Are you sure you want to delete this postcard? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    deletePostcard()
                },
                secondaryButton: .cancel()
            )
        }
        .alert("Error", isPresented: $showingDeleteError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(postcardService.errorMessage)
        }
        .sheet(isPresented: $showingFullImage) {
            if let imageURL = imageURL {
                FullImageView(imageURL: imageURL)
            }
        }
        .onAppear {
            // Load image if there's an image key
            if let imageKey = postcard.imageKey {
                self.imageURL = postcardService.getImageURL(imageKey: imageKey)
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func deletePostcard() {
        isDeleting = true
        
        postcardService.deletePostcard(postcardId: postcard.id) { success, error in
            isDeleting = false
            
            if success {
                // Go back to previous screen
                presentationMode.wrappedValue.dismiss()
            } else {
                postcardService.errorMessage = error ?? "Failed to delete postcard"
                showingDeleteError = true
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

struct MyCardsView_Previews: PreviewProvider {
    static var previews: some View {
        let mockAuthService = CognitoAuthService()

        MyCardsView()
            .environmentObject(mockAuthService)
    }
}

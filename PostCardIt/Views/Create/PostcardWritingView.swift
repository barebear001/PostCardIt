import SwiftUI

struct PostcardWritingView: View {
    let selectedImage: UIImage?
    @State private var messageText: String = ""
    @State private var selectedFont: PostcardFont = .handwritten
    @State private var showingFontPicker = false
    @State private var selectedStamp: StampModel? = nil
    @Environment(\.dismiss) private var dismiss
    
    // Mock data for timestamp and location
    private let currentDate = Date()
    private let currentLocation = "Diamond Head State Monument, 755Q+V8, Honolulu, HI 96815"
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header with back button and decorative elements
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.black)
                            .frame(width: 42, height: 41)
                    }
                    
                    Spacer()
                    
                    // Decorative elements from Figma
                    Image("create_top_right_2")
                        .resizable()
                        .frame(width: 100, height: 57)
                }
                .padding(.horizontal)
                .frame(height: 102)
                .background(Color.white)
                
                // Main postcard view using PostcardBackView
                PostcardBackView(
                    messageText: messageText,
                    font: selectedFont,
                    timestamp: currentDate,
                    location: currentLocation,
                    selectedStamp: selectedStamp
                )
                .padding(.horizontal, 25)
                .padding(.top, 20)
                
                // Text input area
                ZStack(alignment: .topLeading) {
                    // TextEditor
                    TextEditor(text: $messageText)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .frame(height: 234)
                        .padding(.horizontal, 25)
                        .padding(.top, 34)
                    
                    // Placeholder text
                    if messageText.isEmpty {
                        Text("Add text")
                            .font(.custom("Kalam-Regular", size: 14))
                            .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.85))
                            .padding(.leading, 25)
                            .padding(.top, 42)
                            .allowsHitTesting(false)
                    }
                }
                
                Spacer()
                
                // Bottom section with buttons
                VStack {
                    HStack {
                        // Font button
                        Button(action: {
                            showingFontPicker = true
                        }) {
                            VStack(spacing: 2) {
                                Text("Aa")
                                    .font(.custom("Kalam-Regular", size: 18))
                                    .foregroundColor(.black)
                                Text("Font")
                                    .font(.custom("Kalam-Regular", size: 10))
                                    .foregroundColor(.black)
                            }
                            .frame(width: 30, height: 18)
                        }
                        .padding(.leading, 36)
                        
                        Spacer()
                        
                        // Add Stamp button
                        NavigationLink(destination: StampSelectionView(
                            messageText: messageText,
                            selectedFont: selectedFont,
                            currentLocation: currentLocation,
                            timestamp: currentDate,
                            selectedImage: selectedImage,
                            selectedStamp: $selectedStamp
                        )) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 21)
                                    .fill(Color.yellow)
                                    .frame(width: 138, height: 42)
                                
                                Text("Add a Stamp")
                                    .font(.custom("Kalam-Regular", size: 20))
                                    .foregroundColor(.black)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 13)
                }
                .frame(height: 91)
                .background(Color.white)
            }
        }
        .background(Color.white)
        .toolbar(.hidden, for: .tabBar)
        .toolbar(.hidden, for: .navigationBar)
        .actionSheet(isPresented: $showingFontPicker) {
            ActionSheet(
                title: Text("Choose Font"),
                buttons: PostcardFont.allCases.map { font in
                    .default(Text(font.displayName)) {
                        selectedFont = font
                    }
                } + [.cancel()]
            )
        }
    }
}

struct PostcardBackView: View {
    let messageText: String
    let font: PostcardFont
    let timestamp: Date
    let location: String
    var selectedStamp: StampModel? = nil
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 0)
                .fill(Color(red: 0.992, green: 0.988, blue: 0.982))
            
            HStack(spacing: 0) {
                // Left Section - Writing lines and text
                ZStack {
                    // Writing lines background
                    VStack(spacing: 0) {
                        ForEach(0..<8, id: \.self) { index in
                            VStack(spacing: 0) {
                                Spacer()
                                Rectangle()
                                    .fill(Color(red: 0.85, green: 0.85, blue: 0.85))
                                    .frame(height: 1)
                            }
                            .frame(height: 24) // Line height to match text
                        }
                        Spacer()
                    }
                    .padding(.leading, 14)
                    .padding(.top, 17)
                    
                    // Text overlay aligned with lines
                    if !messageText.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(messageText)
                                .font(font.swiftUIFont)
                                .foregroundColor(.black)
                                .multilineTextAlignment(.leading)
                                .lineSpacing(4)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.leading, 14)
                        .padding(.top, 17)
                    }
                }
                .frame(width: 200, height: 228)
                
                // Vertical divider
                Rectangle()
                    .fill(Color(red: 0.85, green: 0.85, blue: 0.85))
                    .frame(width: 3)
                    .padding(.vertical, 17)
                
                // Right Section
                VStack(spacing: 0) {
                    // Stamp placeholder area (top right)
                    HStack {
                        Spacer()
                        if let stamp = selectedStamp {
                            Image(stamp.imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 70, height: 70)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                                .frame(width: 70, height: 70)
                        }
                        Spacer()
                    }
                    .padding(.top, 17)
                    
                    Spacer()
                    
                    // Location information (bottom right)
                    HStack {
                        Spacer()
                        VStack(alignment: .center, spacing: 2) {
                            Text("21.259684, -157.811595")
                                .font(.custom("Kalam-Regular", size: 8))
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                            
                            // Split address by commas and display each part on a new line
                            ForEach(location.components(separatedBy: ", "), id: \.self) { addressLine in
                                Text(addressLine)
                                    .font(.custom("Kalam-Regular", size: 8))
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        Spacer()
                    }
                    .padding(.bottom, 17)
                }
                .frame(width: 128)
            }
        }
        .frame(width: 344, height: 263)
        .clipped()
        .shadow(color: Color.black.opacity(0.25), radius: 3, x: 1, y: 2)
    }
}

enum PostcardFont: String, CaseIterable {
    case handwritten = "handwritten"
    case typewriter = "typewriter"
    case elegant = "elegant"
    case casual = "casual"
    
    var displayName: String {
        switch self {
        case .handwritten: return "Handwritten"
        case .typewriter: return "Typewriter"
        case .elegant: return "Elegant"
        case .casual: return "Casual"
        }
    }
    
    var swiftUIFont: Font {
        switch self {
        case .handwritten:
            return .custom("Kalam-Regular", size: 14)
        case .typewriter:
            return .custom("Courier", size: 13)
        case .elegant:
            return .custom("Times New Roman", size: 14)
        case .casual:
            return .system(size: 14, weight: .regular, design: .rounded)
        }
    }
}

// Preview
struct PostcardWritingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PostcardWritingView(selectedImage: UIImage(named: "sample_image1"))
        }
    }
}

struct PostcardBackView_Previews: PreviewProvider {
    static var previews: some View {
        PostcardBackView(
            messageText: "Hello from Hawaii! The weather is beautiful and the beaches are amazing. Having a wonderful time exploring Diamond Head.",
            font: .handwritten,
            timestamp: Date(),
            location: "Diamond Head State Monument, 755Q+V8, Honolulu, HI 96815"
        )
    }
}

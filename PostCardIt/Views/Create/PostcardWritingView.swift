import SwiftUI

struct PostcardWritingView: View {
    @State private var messageText: String = ""
    @State private var selectedFont: PostcardFont = .handwritten
    @State private var showingFontPicker = false
    
    // Mock data for timestamp and location
    private let currentDate = Date()
    private let currentLocation = "San Francisco, CA"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Postcard View
            PostcardBackView(
                messageText: messageText,
                font: selectedFont,
                timestamp: currentDate,
                location: currentLocation
            )
            .padding(.horizontal, 20)
            .padding(.top, 20)
                        
            // Text Input Section
            VStack(spacing: 5) {
                TextEditor(text: $messageText)
                    .background(Color(.systemGray6))
                    .overlay(
                        Group {
                            if messageText.isEmpty {
                                Text("Start writing your postcard message...")
                                    .foregroundColor(.secondary)
                                    .font(.body)
                                    .padding(.leading, 16)
                                    .padding(.top, 20)
                                    .allowsHitTesting(false)
                            }
                        },
                        alignment: .topLeading
                    )
            }
            .padding(.horizontal, 20)
            
            // Bottom Controls
            HStack {
                // Font Selection Button
                Button(action: {
                    showingFontPicker = true
                }) {
                    HStack {
                        Image(systemName: "textformat")
                        Text("Font")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(25)
                }
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
                
                Spacer()
                
                // Next Button (Add Stamp)
                NavigationLink(destination: StampSelectionView(
                    messageText: messageText,
                    selectedFont: selectedFont,
                    currentLocation: currentLocation,
                    timestamp: currentDate
                )) {
                    HStack {
                        Text("Add Stamp")
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(25)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle("Write Postcard")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
        .toolbar(.hidden, for: .tabBar)
    }
}

struct PostcardBackView: View {
    let messageText: String
    let font: PostcardFont
    let timestamp: Date
    let location: String
    var selectedStamp: StampModel? = nil
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(Color.white)
            .frame(height: 200)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color(.systemGray3), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .overlay(
                HStack(spacing: 0) {
                    // Left Section - Message Text
                    VStack(alignment: .leading, spacing: 8) {
                        if messageText.isEmpty {
                            Text("Your message will appear here...")
                                .foregroundColor(.secondary)
                                .italic()
                                .font(.system(size: 14))
                        } else {
                            Text(messageText)
                                .font(font.swiftUIFont)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    
                    // Dividing line
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 1)
                        .padding(.vertical, 20)
                    
                    // Right Section - Metadata
                    VStack(spacing: 12) {
                        // Timestamp
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Date")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            Text(dateFormatter.string(from: timestamp))
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        
                        // Location
                        VStack(alignment: .leading, spacing: 4) {
                            Text("From")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            Text(location)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        // Stamp Area
                        if let stamp = selectedStamp {
                            Text(stamp.emoji)
                                .font(.system(size: 30))
                                .frame(width: 60, height: 40)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                                .frame(width: 60, height: 40)
                                .overlay(
                                    Text("STAMP")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                )
                        }
                    }
                    .padding(16)
                    .frame(width: 120, alignment: .top)
                }
            )
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
            return .custom("Marker Felt", size: 14)
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
            PostcardWritingView()
        }
    }
}

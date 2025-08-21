import SwiftUI

struct StampSelectionView: View {
    let messageText: String
    let selectedFont: PostcardFont
    let currentLocation: String
    let timestamp: Date
    let selectedImage: UIImage?
    @Binding var selectedStamp: StampModel?
    @Environment(\.dismiss) private var dismiss

    @State private var selectedStampCategory: StampCategory = .featured
    
    private let stampCategories = StampCategory.allCases
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with back button and decorative elements
            HStack {
                Button(action: {
                    // Navigation back handled by NavigationView
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                        .frame(width: 42, height: 41)
                }
                
                Spacer()
                
                // Decorative elements from Figma
                Image("create_top_right_3")
                    .resizable()
                    .frame(width: 100, height: 57)
            }
            .padding(.horizontal)
            .frame(height: 102)
            .background(Color.white)
            
            // Postcard View at the top
            VStack {
                PostcardBackView(
                    messageText: messageText,
                    font: selectedFont,
                    timestamp: timestamp,
                    location: currentLocation,
                    selectedStamp: selectedStamp
                )
                .frame(width: 344, height: 263)
                .padding(.horizontal, 25)
                .padding(.top, 20)
            }
            .background(Color.white)
            .padding(.bottom, 20)
            
            // Category Tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(stampCategories, id: \.self) { category in
                        Button(action: {
                            selectedStampCategory = category
                        }) {
                            Text(category.displayName)
                                .font(.custom("Kalam-Regular", size: 14))
                                .foregroundColor(selectedStampCategory == category ? .black : .black.opacity(0.5))
                                .padding(.horizontal, 8)
                        }
                    }
                }
                .padding(.horizontal, 21)
                .padding(.vertical, 12)
            }
            .background(Color.white)
            
            // Stamps Grid
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 5), spacing: 16) {
                    ForEach(getStampsForCategory(selectedStampCategory)) { stamp in
                        StampItemView(
                            stamp: stamp,
                            isSelected: selectedStamp?.id == stamp.id
                        ) {
                            selectedStamp = stamp
                        }
                    }
                }
                .padding(.horizontal, 21)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
            .background(Color.white)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .overlay(
            // Preview Button (Bottom Right)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    NavigationLink(destination: CreatePostcardPreviewView(
                        messageText: messageText,
                        selectedFont: selectedFont,
                        selectedStamp: selectedStamp,
                        currentLocation: currentLocation,
                        timestamp: timestamp,
                        selectedImage: selectedImage
                    )) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 21)
                                .fill(Color.yellow)
                                .frame(width: 138, height: 42)
                            
                            Text("Preview")
                                .font(.custom("Kalam-Regular", size: 20))
                                .foregroundColor(.black)
                        }
                    }
                    .disabled(selectedStamp == nil)
                    .opacity(selectedStamp == nil ? 0.6 : 1.0)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        )
    }
    
    private func getStampsForCategory(_ category: StampCategory) -> [StampModel] {
        let sampleStamps = [
            // Featured stamps (10 total as shown in Figma design)
            StampModel(id: "1", name: "Smiley", imageName: "stamp_smiley", category: .featured),
            StampModel(id: "2", name: "Heart", imageName: "stamp_heart", category: .featured),
            StampModel(id: "3", name: "Duck", imageName: "stamp_duck", category: .featured),
            StampModel(id: "4", name: "Lightning", imageName: "stamp_lightning", category: .featured),
            StampModel(id: "5", name: "Sun", imageName: "stamp_sun", category: .featured),
            StampModel(id: "6", name: "Watermelon", imageName: "stamp_watermelon", category: .featured),
            StampModel(id: "7", name: "Flower", imageName: "stamp_flower", category: .featured),
            StampModel(id: "8", name: "Chill", imageName: "stamp_chill", category: .featured),
            StampModel(id: "9", name: "Love", imageName: "stamp_love", category: .featured),
            StampModel(id: "10", name: "Rainbow", imageName: "stamp_rainbow", category: .featured),
            
            // Food stamps
            StampModel(id: "11", name: "Watermelon", imageName: "stamp_watermelon", category: .food),
            
            // Nature stamps
            StampModel(id: "12", name: "Flower", imageName: "stamp_flower", category: .nature),
            StampModel(id: "13", name: "Leaves", imageName: "stamp_leaves", category: .nature),
            
            // Fun stamps
            StampModel(id: "14", name: "Chill", imageName: "stamp_chill", category: .fun),
            StampModel(id: "15", name: "Love", imageName: "stamp_love", category: .fun),
            StampModel(id: "16", name: "Rainbow", imageName: "stamp_rainbow", category: .fun),
            
            // Animal stamps
            StampModel(id: "17", name: "Sheep", imageName: "stamp_sheep", category: .animals),
            StampModel(id: "18", name: "Fox", imageName: "stamp_fox", category: .animals),
            StampModel(id: "19", name: "Bear", imageName: "stamp_bear", category: .animals),
            StampModel(id: "20", name: "Deer", imageName: "stamp_deer", category: .animals),
            StampModel(id: "21", name: "Tiger", imageName: "stamp_tiger", category: .animals),
            StampModel(id: "22", name: "Panda", imageName: "stamp_panda", category: .animals),
            StampModel(id: "23", name: "Monkey", imageName: "stamp_monkey", category: .animals),
            StampModel(id: "24", name: "Bird", imageName: "stamp_bird", category: .animals),
            StampModel(id: "25", name: "Lion", imageName: "stamp_lion", category: .animals),
        ]
        
        if category == .featured {
            return sampleStamps.filter { $0.category == .featured }
        }
        
        return sampleStamps.filter { $0.category == category }
    }
}

struct StampItemView: View {
    let stamp: StampModel
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(stamp.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 59, height: 59)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

enum StampCategory: String, CaseIterable {
    case featured = "featured"
    case travel = "travel"
    case nature = "nature"
    case holidays = "holidays"
    case food = "food"
    case animals = "animals"
    case fun = "fun"
    
    var displayName: String {
        switch self {
        case .featured: return "Featured"
        case .travel: return "Travel"
        case .nature: return "Nature"
        case .holidays: return "Holidays"
        case .food: return "Food"
        case .animals: return "Animals"
        case .fun: return "Fun"
        }
    }
}

struct StampModel: Identifiable {
    let id: String
    let name: String
    let imageName: String
    let category: StampCategory
}

// Preview
struct StampSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StampSelectionView(
                messageText: "Hello from my travels! Having an amazing time exploring new places.",
                selectedFont: .handwritten,
                currentLocation: "San Francisco, CA",
                timestamp: Date(),
                selectedImage: UIImage(named: "sample_image1"),
                selectedStamp: .constant(nil)
            )
        }
    }
}


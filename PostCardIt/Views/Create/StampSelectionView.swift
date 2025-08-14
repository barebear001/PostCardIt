import SwiftUI

struct StampSelectionView: View {
    let messageText: String
    let selectedFont: PostcardFont
    let currentLocation: String
    let timestamp: Date
    
    @State private var selectedStampCategory: StampCategory = .featured
    @State private var selectedStamp: StampModel? = nil
    
    // Sample data - you would load this from your data source
    private let stampCategories = StampCategory.allCases
    
    var body: some View {
        VStack(spacing: 0) {
            // Postcard View at the top
            VStack {
                PostcardBackView(
                    messageText: messageText,
                    font: selectedFont,
                    timestamp: timestamp,
                    location: currentLocation,
                    selectedStamp: selectedStamp
                )
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color(.systemGray6))
            .padding(.bottom, 10)
            
            // Stamp Categories and Grid
            VStack(spacing: 0) {
                // Category Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(stampCategories, id: \.self) { category in
                            Button(action: {
                                selectedStampCategory = category
                            }) {
                                VStack(spacing: 4) {
                                    Text(category.displayName)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(selectedStampCategory == category ? .blue : .secondary)
                                    
                                    Rectangle()
                                        .fill(selectedStampCategory == category ? Color.blue : Color.clear)
                                        .frame(height: 2)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .background(Color(.systemBackground))
                
                Divider()
                
                // Stamps Grid
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                        ForEach(getStampsForCategory(selectedStampCategory)) { stamp in
                            StampItemView(
                                stamp: stamp,
                                isSelected: selectedStamp?.id == stamp.id
                            ) {
                                selectedStamp = stamp
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 100) // Space for bottom button
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle("Add Stamp")
        .navigationBarTitleDisplayMode(.inline)
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
                        timestamp: timestamp
                    )) {
                        HStack {
                            Text("Preview")
                            Image(systemName: "eye")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.purple)
                        .cornerRadius(25)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
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
        // Sample stamp data - replace with your actual data
        let sampleStamps = [
            StampModel(id: "1", name: "Golden Gate", emoji: "🌉", category: .travel),
            StampModel(id: "2", name: "Mountain Peak", emoji: "🏔️", category: .nature),
            StampModel(id: "3", name: "Christmas Tree", emoji: "🎄", category: .holidays),
            StampModel(id: "4", name: "Pizza Slice", emoji: "🍕", category: .food),
            StampModel(id: "5", name: "Cute Cat", emoji: "🐱", category: .animals),
            StampModel(id: "6", name: "Party Hat", emoji: "🎉", category: .fun),
            StampModel(id: "7", name: "Beach Sunset", emoji: "🌅", category: .travel),
            StampModel(id: "8", name: "Forest", emoji: "🌲", category: .nature),
            StampModel(id: "9", name: "Gift Box", emoji: "🎁", category: .holidays),
            StampModel(id: "10", name: "Burger", emoji: "🍔", category: .food),
            StampModel(id: "11", name: "Dog", emoji: "🐕", category: .animals),
            StampModel(id: "12", name: "Rainbow", emoji: "🌈", category: .fun),
        ]
        
        if category == .featured {
            return Array(sampleStamps.prefix(6))
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
            VStack(spacing: 8) {
                Text(stamp.emoji)
                    .font(.system(size: 40))
                    .frame(width: 80, height: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
                
                Text(stamp.name)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
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
    let emoji: String
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
                timestamp: Date()
            )
        }
    }
}


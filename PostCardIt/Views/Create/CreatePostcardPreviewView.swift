import SwiftUI

// Preview view that receives data from previous views
struct CreatePostcardPreviewView: View {
    let messageText: String
    let selectedFont: PostcardFont
    let selectedStamp: StampModel?
    let currentLocation: String
    let timestamp: Date
    let selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: -40) {
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
                Image("create_top_right_3")
                    .resizable()
                    .frame(width: 100, height: 57)
            }
            .padding(.horizontal)
            .frame(height: 102)
            .background(Color.white)
            
            ScrollView {
                VStack(spacing: 25) { // Reduced overlap spacing for stacked effect
                    // Back of Postcard (rotated left)
                    HStack {
                        Spacer()
                        PostcardBackView(
                            messageText: messageText,
                            font: selectedFont,
                            timestamp: timestamp,
                            location: currentLocation,
                            selectedStamp: selectedStamp
                        )
                        .scaleEffect(0.95)
                        .rotationEffect(.degrees(-15))
                        .padding(.top, 30)
                        .padding(.bottom, -30)
                        .zIndex(1) // Make sure back is above front
                        Spacer()
                    }
                    .padding(.leading, 50)
                    .padding(.trailing, 10)
                    
                    // Front of Postcard (rotated right)
                    HStack {
                        PostcardFrontView(selectedImage: selectedImage)
                            .rotationEffect(.degrees(15))
                            .padding(.bottom, 50)
                        Spacer()
                    }
                    .scaleEffect(0.95)
                    .padding(.leading, 0)
                    .padding(.trailing, 80)
                    .zIndex(2) // Make sure front is below back
                
                    // Next Button (Send Postcard)
                    HStack {
                        Spacer()
                        NavigationLink(destination: SendPostcardView()) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 21)
                                    .fill(Color.yellow)
                                    .frame(width: 138, height: 42)
                                
                                Text("Next")
                                    .font(.custom("Kalam-Regular", size: 20))
                                    .foregroundColor(.black)
                            }
                        }
                    }
                    .padding(.trailing, 50)
                    .padding(.top, -25)
                    .padding(.bottom, 100) // Extra bottom padding to avoid tab bar
            }
            .padding(.vertical, 20)
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct PostcardFrontView: View {
    let selectedImage: UIImage?
    
    var body: some View {
        ZStack {
            // Background with selected image or fallback
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.blue)
            
            // Use selected image, then try landscape image, then fallback to gradient
            if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else if let landscapeImage = UIImage(named: "landscape_hawaii") {
                Image(uiImage: landscapeImage)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else {
                // Fallback landscape-style gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue,
                        Color.blue.opacity(0.8),
                        Color.green.opacity(0.6)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .frame(width: 344, height: 263)
        .clipped()
        .shadow(color: Color.black.opacity(0.25), radius: 3, x: 1, y: 2)
    }
}


struct CreatePostcardPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CreatePostcardPreviewView(
                messageText: "Hello from my travels! Having an amazing time exploring new places and meeting wonderful people.",
                selectedFont: .handwritten,
                selectedStamp: StampModel(id: "1", name: "Smiley", imageName: "stamp_smiley", category: .featured),
                currentLocation: "San Francisco, CA",
                timestamp: Date(),
                selectedImage: UIImage(named: "sample_image1")
            )
        }
    }
}

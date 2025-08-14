import SwiftUI

// Preview view that receives data from previous views
struct CreatePostcardPreviewView: View {
    let messageText: String
    let selectedFont: PostcardFont
    let selectedStamp: StampModel?
    let currentLocation: String
    let timestamp: Date

    var body: some View {
        ScrollView {
            VStack(spacing: 50) { // Negative spacing for overlap
                // Back of Postcard (rotated 20 degrees)
                PostcardBackView(
                    messageText: messageText,
                    font: selectedFont,
                    timestamp: timestamp,
                    location: currentLocation,
                    selectedStamp: selectedStamp
                )
                .rotationEffect(.degrees(-20))
                .padding(.horizontal, 20)
                .padding(.top, 50)
                .zIndex(1) // Make sure back is above front
                
                // Front of Postcard (rotated -20 degrees)
                PostcardFrontView()
                    .rotationEffect(.degrees(20))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 50)
                    .zIndex(2) // Make sure front is below back
                
//                Spacer()
                HStack {
                    Spacer()
                    // Next Button (Send Postcard)
                    NavigationLink(destination: SendPostcardView()) {
                        HStack {
                            Text("Send")
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(25)
                    }
                }
                .padding(.bottom, 100) // Extra bottom padding to avoid tab bar
            }
            .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemGray6), Color(.systemBackground)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
//        .edgesIgnoringSafeArea(.bottom)
//        .navigationTitle("Preview")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
//        .toolbar {
//            ToolbarItem(placement: .navigationBarTrailing) {
//                Button("Share") {
//                    // Handle sharing functionality
//                }
//                .foregroundColor(.blue)
//            }
//        }
    }
}

struct PostcardFrontView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.8),
                        Color.purple.opacity(0.6),
                        Color.pink.opacity(0.4)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 200)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 6)
            .overlay(
                // Front content
                VStack(spacing: 16) {
                    // Scenic illustration placeholder
                    ZStack {
                        Circle()
                            .fill(Color.yellow.opacity(0.8))
                            .frame(width: 40, height: 40)
                            .offset(x: -30, y: -20)
                        
                        Rectangle()
                            .fill(Color.green.opacity(0.6))
                            .frame(height: 30)
                            .cornerRadius(15)
                            .offset(y: 10)
                        
                        Text("🏔️")
                            .font(.system(size: 30))
                            .offset(x: 20, y: -10)
                        
                        Text("🌲")
                            .font(.system(size: 20))
                            .offset(x: -40, y: 5)
                        
                        Text("🌲")
                            .font(.system(size: 24))
                            .offset(x: 35, y: 8)
                    }
                    .frame(height: 80)
                    
                    // Location text
                    Text("Greetings from")
                        .font(.system(size: 14, weight: .light, design: .serif))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text("SAN FRANCISCO")
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .tracking(2)
                    
                    Text("CALIFORNIA")
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundColor(.white.opacity(0.9))
                        .tracking(1)
                }
                .padding(20)
            )
    }
}


struct CreatePostcardPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CreatePostcardPreviewView(
                messageText: "Hello from my travels! Having an amazing time exploring new places and meeting wonderful people.",
                selectedFont: .handwritten,
                selectedStamp: StampModel(id: "1", name: "Golden Gate", emoji: "🌉", category: .travel),
                currentLocation: "San Francisco, CA",
                timestamp: Date()
            )
        }
    }
}

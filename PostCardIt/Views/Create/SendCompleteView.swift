import SwiftUI

struct SendCompleteView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showAnimation = false
    
    var body: some View {
        ZStack {
            // Background
            Color.white
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Paper airplane icon with animation
                Image("paper_airplane")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 111, height: 92)
                    .scaleEffect(showAnimation ? 1.0 : 0.5)
                    .opacity(showAnimation ? 1.0 : 0.0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: showAnimation)
                
                Spacer()
                    .frame(height: 30)
                
                // "Card sent!" text with handwritten style
                Text("Card sent!")
                    .font(.custom("Kalam-Regular", size: 20))
                    .foregroundColor(.black)
                    .opacity(showAnimation ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.8).delay(0.3), value: showAnimation)
                
                Spacer()
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showAnimation = true
            }
            
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // Auto-navigate back after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                // Find the root presentation controller and dismiss
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootViewController = window.rootViewController {
                    
                    // Find the top most presented view controller
                    var topController = rootViewController
                    while let presented = topController.presentedViewController {
                        topController = presented
                    }
                    
                    // Dismiss the sheet
                    topController.dismiss(animated: true)
                }
            }
        }
    }
}


#Preview {
    SendCompleteView()
}
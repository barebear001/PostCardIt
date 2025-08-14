import SwiftUI

struct SendCompleteView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Success icon with animation
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .scaleEffect(showConfetti ? 1.0 : 0.8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showConfetti)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                        .scaleEffect(showConfetti ? 1.0 : 0.5)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: showConfetti)
                }
                
                VStack(spacing: 16) {
                    Text("Postcard Sent!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .opacity(showConfetti ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.8).delay(0.4), value: showConfetti)
                    
                    Text("Your postcard has been sent successfully.\nYour friend will receive it soon!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .opacity(showConfetti ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.8).delay(0.6), value: showConfetti)
                }
                
                Spacer()
                
                // Action button
                NavigationLink(destination: MainTabView().navigationBarBackButtonHidden(true)) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                .opacity(showConfetti ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.8).delay(0.8), value: showConfetti)
                
                Spacer()
            }
            
            // Confetti effect
            if showConfetti {
                ConfettiView()
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showConfetti = true
            }
            
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
}

struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<50, id: \.self) { index in
                ConfettiPiece()
                    .offset(
                        x: animate ? CGFloat.random(in: -200...200) : 0,
                        y: animate ? CGFloat.random(in: -400...400) : -50
                    )
                    .rotationEffect(.degrees(animate ? Double.random(in: 0...360) : 0))
                    .scaleEffect(animate ? CGFloat.random(in: 0.5...1.5) : 1)
                    .animation(
                        .easeInOut(duration: Double.random(in: 2...4))
                        .delay(Double.random(in: 0...1)),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}

struct ConfettiPiece: View {
    let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
    @State private var color = Color.red
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 8, height: 8)
            .cornerRadius(2)
            .onAppear {
                color = colors.randomElement() ?? .red
            }
    }
}

#Preview {
    SendCompleteView()
}
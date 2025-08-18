//
//  LoginView.swift
//  PostCardIt
//
//  Created by Taiyue Liu on 5/3/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: CognitoAuthService
    @State private var email = ""
    @State private var password = ""
    @State private var showingRegistration = false
    @State private var showingPasswordReset = false
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Main content
                ScrollView {
                    VStack(spacing: 30) {
                        // Decorative elements and title
                        ZStack {
                            // Background decorative elements
                            LoginDecorations1()
                            
                            VStack(spacing: 20) {
                                // App title with icon
                                HStack(spacing: 2) {
                                    Image("login_postii_icon")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 26, height: 18)
                                        .rotationEffect(.degrees(-35))
                                    
                                    Text("Postii")
                                        .font(.custom("Kalam-Regular", size: 24))
                                        .foregroundColor(.black)
                                    
                                }
                                .padding(.top, 20)
                                
                                // Login heading
                                Text("Log in")
                                    .font(.custom("Kalam", size: 32))
                                    .foregroundColor(.black)
                                    .shadow(color: Color.black.opacity(0.3), radius: 3, x: 2, y: 4)
                                    .padding(.top, 70)
                            }
                        }
                        .frame(height: 200)
                        
                        // Login form
                        VStack(spacing: 15) {
                            // Email field
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.black.opacity(0.35), lineWidth: 1)
                                    .frame(height: 40)
                                
                                HStack {
                                    if email.isEmpty {
                                        Text("example@gmail.com")
                                            .font(.custom("Kalam", size: 14))
                                            .foregroundColor(Color.black.opacity(0.35))
                                            .padding(.leading, 15)
                                    }
                                    Spacer()
                                }
                                
                                TextField("", text: $email)
                                    .font(.custom("Kalam", size: 14))
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .keyboardType(.emailAddress)
                                    .padding(.horizontal, 15)
                            }
                            
                            // Password field with Send codes button
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.black.opacity(0.35), lineWidth: 1)
                                    .frame(height: 40)
                                
                                HStack {
                                    HStack {
                                        if password.isEmpty {
                                            Text("enter codes")
                                                .font(.custom("Kalam", size: 14))
                                                .foregroundColor(Color.black.opacity(0.35))
                                        }
                                        Spacer()
                                    }
                                    .padding(.leading, 15)
                                    
                                    // Send codes button
                                    Button(action: {
                                        // Send verification codes
                                    }) {
                                        Text("Send codes")
                                            .font(.custom("Kalam-Light", size: 12))
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color(red: 1.0, green: 0.9, blue: 0.38))
                                            .cornerRadius(18)
                                            .shadow(color: Color.black.opacity(0.25), radius: 1, x: 1, y: 1)
                                    }
                                    .padding(.trailing, 8)
                                }
                                
                                SecureField("", text: $password)
                                    .font(.custom("Kalam", size: 14))
                                    .padding(.horizontal, 15)
                                    .padding(.trailing, 100)
                            }
                            
                            if !authService.errorMessage.isEmpty {
                                Text(authService.errorMessage)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .padding(.top, 5)
                            }
                            
                            // Continue button
                            Button(action: {
                                authService.signIn(username: email, password: password) { success in
                                    // Handle success in environment object
                                }
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color(red: 1.0, green: 0.9, blue: 0.38).opacity(0.5))
                                        .frame(height: 40)
                                        .shadow(color: Color.black.opacity(0.25), radius: 2, x: 2, y: 2)
                                    
                                    if authService.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .foregroundColor(Color.black.opacity(0.5))
                                    } else {
                                        Text("Continue")
                                            .font(.custom("Kalam-Light", size: 14))
                                            .foregroundColor(Color.black.opacity(0.5))
                                    }
                                }
                            }
                            .disabled(email.isEmpty || password.isEmpty || authService.isLoading)
                            .padding(.horizontal, 33)
                        }
                        .padding(.horizontal, 33)
                        
                        // Or divider
                        Text("or")
                            .font(.custom("Kalam", size: 20))
                            .foregroundColor(.black)
                            .padding(.vertical, 10)
                        
                        // Social login buttons
                        VStack(spacing: 16) {
                            // Facebook
                            SocialLoginButton(
                                title: "Continue with Facebook",
                                backgroundColor: Color(red: 0.098, green: 0.467, blue: 0.949),
                                textColor: .white,
                                iconName: "facebook_logo"
                            ) {
                                // Facebook login
                            }
                            
                            // Google
                            SocialLoginButton(
                                title: "Continue with Google",
                                backgroundColor: .white,
                                textColor: .black,
                                iconName: "google_logo"
                            ) {
                                // Google login
                            }
                            
                            // Apple
                            SocialLoginButton(
                                title: "Continue with Apple",
                                backgroundColor: .black,
                                textColor: .white,
                                iconName: "apple_logo"
                            ) {
                                // Apple login
                            }
                            
                            LoginDecorations2()
                        }
                        .padding(.horizontal, 33)
                        
                        Spacer(minLength: 50)
                    }
                }
                
                // Home indicator
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 138.5, height: 5)
                    .cornerRadius(2.5)
                    .padding(.bottom, 9)
            }
        }
        .sheet(isPresented: $showingRegistration) {
            RegistrationView()
                .environmentObject(authService)
        }
        .sheet(isPresented: $showingPasswordReset) {
            ForgotPasswordView()
                .environmentObject(authService)
        }
    }
}


struct LoginDecorations1: View {
    var body: some View {
        GeometryReader { geometry in
            VStack {
                // Top right decorative elements (sloth) - at position (297, 104) from Figma
                HStack {
                    
                    Image("login_decoration_2")
                        .resizable()
                        .frame(width: 72, height: 79)
                        .position(x: 36, y: 104)
                    
                    Spacer()
                    // Top left bird - at position (0, 115) from Figma
                    Image("login_decoration_1")
                        .resizable()
                        .frame(width: 96, height: 90)
                        .position(x: 150, y: 104)
                }
                
                HStack {
                    
                    // Palm tree near title - at position (71, 186) from Figma
                    Image("login_decoration_3")
                        .resizable()
                        .frame(width: 52, height: 60)
                        .position(x: 97, y: 80)
                    Spacer()
                    
                    // Small decoration near title - at position (307, 225) from Figma
                    Image("login_decoration_6")
                        .resizable()
                        .frame(width: 29, height: 21)
                        .position(x: 140, y: 104)
                }
            }
        }
    }
}

struct LoginDecorations2: View {
    var body: some View {
        GeometryReader { geometry in
                HStack {
                    Image("login_decoration_4")
                        .resizable()
                        .frame(width: 130, height: 66)
                        .position(x: 60, y: 50)
    
                    Spacer()
                    // Bottom right decoration (decoration 5) - at position (213, 741) from Figma
                    Image("login_decoration_5")
                        .resizable()
                        .frame(width: 143, height: 36)
                        .position(x: 70, y: 50)
            }
        }
    }
}

struct SocialLoginButton: View {
    let title: String
    let backgroundColor: Color
    let textColor: Color
    let iconName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let uiImage = UIImage(named: iconName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                } else {
                    // Fallback to system icons if asset loading fails
                    Image(systemName: iconName == "facebook_logo" ? "f.circle.fill" : 
                          iconName == "google_logo" ? "g.circle" : "apple.logo")
                        .font(.system(size: 18))
                        .foregroundColor(textColor)
                        .frame(width: 24, height: 24)
                }
                
                Text(title)
                    .font(.custom("Kalam", size: 14))
                    .foregroundColor(textColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .frame(height: 40)
            .background(backgroundColor)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 0)
        }
    }
}

#Preview {
    let mockAuthService = CognitoAuthService()

    LoginView()
        .environmentObject(mockAuthService)
}


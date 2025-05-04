//
//  LoginView.swift
//  PostCardIt
//
//  Created by Taiyue Liu on 5/3/25.
//

// LoginView.swift
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: CognitoAuthService
    @State private var username = ""
    @State private var password = ""
    @State private var showingRegistration = false
    @State private var showingPasswordReset = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo
                VStack {
                    Image(systemName: "envelope.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                    
                    Text("PostCardIt")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .padding(.bottom, 50)
                
                // Login form
                VStack(spacing: 15) {
                    TextField("Username", text: $username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    
                    if !authService.errorMessage.isEmpty {
                        Text(authService.errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 5)
                    }
                    
                    Button(action: {
                        authService.signIn(username: username, password: password) { _ in
                            // Handle success in environment object
                        }
                    }) {
                        if authService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        } else {
                            Text("Log In")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    .disabled(username.isEmpty || password.isEmpty || authService.isLoading)
                    
                    Button("Forgot password?") {
                        showingPasswordReset = true
                    }
                    .padding(.top, 10)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Create account button
                Button("Don't have an account? Sign Up") {
                    showingRegistration = true
                }
                .foregroundColor(.blue)
                .padding(.bottom, 20)
            }
            .padding()
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
}

//struct LoginView_Previews: PreviewProvider {
    

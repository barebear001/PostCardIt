// ForgotPasswordView.swift
import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var authService: CognitoAuthService
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    @State private var showingResetConfirmation = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reset Password")) {
                    Text("Enter your email address and we'll send a reset code to you.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.vertical, 5)
                    
                    TextField("Email", text: $email)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.emailAddress)
                    
                    if !authService.errorMessage.isEmpty {
                        Text(authService.errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button(action: {
                        authService.forgotPassword(email: email) { success in
                            if success {
                                showingResetConfirmation = true
                            }
                        }
                    }) {
                        if authService.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Spacer()
                            }
                        } else {
                            HStack {
                                Spacer()
                                Text("Send Reset Code")
                                Spacer()
                            }
                        }
                    }
                    .disabled(email.isEmpty || authService.isLoading)
                }
            }
            .navigationTitle("Reset Password")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showingResetConfirmation) {
                ResetPasswordConfirmationView(email: email)
                    .environmentObject(authService)
            }
        }
    }
}

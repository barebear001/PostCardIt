// ResetPasswordConfirmationView.swift
import SwiftUI

struct ResetPasswordConfirmationView: View {
    @EnvironmentObject var authService: CognitoAuthService
    @Environment(\.presentationMode) var presentationMode
    @State private var verificationCode = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    let username: String
    
    var passwordsMatch: Bool {
        return newPassword == confirmPassword
    }
    
    var formIsValid: Bool {
        return !verificationCode.isEmpty && !newPassword.isEmpty &&
               passwordsMatch && newPassword.count >= 8
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reset Password")) {
                    Text("Enter the verification code sent to your email and your new password.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.vertical, 5)
                    
                    TextField("Verification Code", text: $verificationCode)
                        .keyboardType(.numberPad)
                    
                    SecureField("New Password (min 8 characters)", text: $newPassword)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                    
                    if !passwordsMatch && !confirmPassword.isEmpty {
                        Text("Passwords do not match")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    if !authService.errorMessage.isEmpty {
                        Text(authService.errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button(action: {
                        authService.confirmForgotPassword(
                            username: username,
                            newPassword: newPassword,
                            confirmationCode: verificationCode
                        ) { success in
                            if success {
                                // Dismiss this view
                                presentationMode.wrappedValue.dismiss()
                                
                                // Also dismiss the forgot password view
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    presentationMode.wrappedValue.dismiss()
                                }
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
                                Text("Reset Password")
                                Spacer()
                            }
                        }
                    }
                    .disabled(!formIsValid || authService.isLoading)
                }
            }
            .navigationTitle("Reset Password")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

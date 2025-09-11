// ConfirmationView.swift
import SwiftUI

struct ConfirmationView: View {
    @EnvironmentObject var authService: CognitoAuthService
    @Environment(\.presentationMode) var presentationMode
    @State private var confirmationCode = ""
    let email: String
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Verification")) {
                    Text("We sent a verification code to your email. Please enter it below to confirm your account.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.vertical, 5)
                    
                    TextField("Verification Code", text: $confirmationCode)
                        .keyboardType(.numberPad)
                    
                    if !authService.errorMessage.isEmpty {
                        Text(authService.errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button(action: {
                        authService.confirmSignUp(
                            email: email,
                            confirmationCode: confirmationCode
                        ) { success in
                            if success {
                                presentationMode.wrappedValue.dismiss()
                                // Also dismiss the registration view
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
                                Text("Verify Account")
                                Spacer()
                            }
                        }
                    }
                    .disabled(confirmationCode.isEmpty || authService.isLoading)
                }
                
                Section {
                    Button(action: {
                        authService.resendConfirmationCode(email: email) { _ in
                            // Code sent, no additional action needed
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
                                Text("Resend Code")
                                Spacer()
                            }
                        }
                    }
                    .disabled(authService.isLoading)
                }
            }
            .navigationTitle("Confirm Account")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// ForgotPasswordView.swift
import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var authService: CognitoAuthService
    @Environment(\.presentationMode) var presentationMode
    @State private var username = ""
    @State private var showingResetConfirmation = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reset Password")) {
                    Text("Enter your username and we'll send a code to your registered email address.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.vertical, 5)
                    
                    TextField("Username", text: $username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if !authService.errorMessage.isEmpty {
                        Text(authService.errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button(action: {
                        authService.forgotPassword(username: username) { success in
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
                    .disabled(username.isEmpty || authService.isLoading)
                }
            }
            .navigationTitle("Reset Password")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showingResetConfirmation) {
                ResetPasswordConfirmationView(username: username)
                    .environmentObject(authService)
            }
        }
    }
}

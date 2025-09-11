// RegistrationView.swift
import SwiftUI

struct RegistrationView: View {
    @EnvironmentObject var authService: CognitoAuthService
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var phoneNumber = ""
    @State private var showingConfirmation = false
    
    var passwordsMatch: Bool {
        return password == confirmPassword
    }
    
    var formIsValid: Bool {
        return !email.isEmpty && !password.isEmpty &&
               passwordsMatch && password.count >= 8
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account Information")) {
                    TextField("Email", text: $email)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.emailAddress)
                    
                    TextField("Phone Number (optional)", text: $phoneNumber)
                        .keyboardType(.phonePad)
                    
                    TextField("Password (min 8 characters)", text: $password)
                    
                    TextField("Confirm Password", text: $confirmPassword)
                    
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
                        let phoneNumberToUse = phoneNumber.isEmpty ? nil : phoneNumber
                        
                        authService.signUp(
                            email: email,
                            password: password,
                            phoneNumber: phoneNumberToUse
                        ) { success in
                            if success {
                                showingConfirmation = true
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
                                Text("Create Account")
                                Spacer()
                            }
                        }
                    }
                    .disabled(!formIsValid || authService.isLoading)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Sign Up")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showingConfirmation) {
                ConfirmationView(email: email)
                    .environmentObject(authService)
            }
        }
    }
}

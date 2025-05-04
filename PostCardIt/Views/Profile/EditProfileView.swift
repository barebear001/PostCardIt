//
//  Untitled.swift
//  PostCardIt
//
//  Created by Taiyue Liu on 5/3/25.
//

// EditProfileView.swift
import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var authService: CognitoAuthService
    @Environment(\.presentationMode) var presentationMode
    @State private var name: String
    @State private var phoneNumber: String
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var isSuccess = false
    
    init(userAttributes: [String: String]) {
        _name = State(initialValue: userAttributes["name"] ?? "")
        _phoneNumber = State(initialValue: userAttributes["phone_number"] ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Information")) {
                    TextField("Name", text: $name)
                    
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                    
                    if !authService.errorMessage.isEmpty {
                        Text(authService.errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button("Save Changes") {
                        saveProfileChanges()
                    }
                    .disabled(authService.isLoading)
                }
                
                if authService.isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if isSuccess {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }
        }
    }
    
    private func saveProfileChanges() {
        // Validate inputs if needed
        if name.isEmpty {
            alertTitle = "Error"
            alertMessage = "Name cannot be empty"
            showingAlert = true
            return
        }
        
        // Prepare attributes to update
        var attributes = [String: String]()
        attributes["name"] = name
        
        // Format phone number if needed
        if !phoneNumber.isEmpty {
            // Add phone number in the required format for Cognito (e.g., +1XXXXXXXXXX)
            let formattedPhone = formatPhoneNumber(phoneNumber)
            attributes["phone_number"] = formattedPhone
        }
        
        // Update user attributes
        authService.updateUserAttributes(attributes: attributes) { success in
            if success {
                alertTitle = "Success"
                alertMessage = "Profile updated successfully"
                isSuccess = true
            } else {
                alertTitle = "Error"
                alertMessage = "Failed to update profile: \(authService.errorMessage)"
                isSuccess = false
            }
            showingAlert = true
        }
    }
    
    private func formatPhoneNumber(_ phone: String) -> String {
        // Remove any non-numeric characters
        let numbers = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // If the number doesn't start with +, add +1 (or the appropriate country code)
        if !phone.starts(with: "+") {
            return "+1\(numbers)"  // Using +1 for US as default
        }
        
        return phone
    }
}

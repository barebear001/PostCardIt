// ProfileView.swift
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: CognitoAuthService
    @State private var userAttributes: [String: String] = [:]
    @State private var notifications = true
    @State private var darkMode = false
    @State private var showingEditProfile = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile")) {
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Spacer()
                        }
                    } else {
                        HStack {
                            Spacer()
                            VStack {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.blue)
                                
                                Text(userAttributes["name"] ?? userAttributes["email"] ?? "User")
                                    .font(.headline)
                                    .padding(.top, 5)
                                
                                Text(userAttributes["email"] ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(.vertical)
                    }
                    
                    Button("Edit Profile") {
                        showingEditProfile = true
                    }
                    .disabled(isLoading)
                }
                
                Section(header: Text("Settings")) {
                    Toggle("Push Notifications", isOn: $notifications)
                    Toggle("Dark Mode", isOn: $darkMode)
                    
                    NavigationLink(destination: PrivacySettingsView()) {
                        Text("Privacy Settings")
                    }
                    
                    NavigationLink(destination: HelpSupportView()) {
                        Text("Help & Support")
                    }
                }
                
                Section {
                    Button("Log Out") {
                        authService.signOut()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(userAttributes: userAttributes)
                    .environmentObject(authService)
                    .onDisappear {
                        // Reload user attributes when editing is done
                        loadUserAttributes()
                    }
            }
            .onAppear {
                loadUserAttributes()
            }
        }
    }
    
    private func loadUserAttributes() {
        isLoading = true
        
        authService.getUserAttributes { attributes in
            self.userAttributes = attributes
            self.isLoading = false
        }
    }
}

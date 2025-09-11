// CognitoAuthService.swift
import Foundation
import AWSCore
import AWSCognitoIdentityProvider

class CognitoAuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var user: AWSCognitoIdentityUser?
    @Published var errorMessage = ""
    @Published var isLoading = false
    
    private let userPool: AWSCognitoIdentityUserPool
    
    // Replace these values with your own Cognito configuration
    private let cognitoIdentityUserPoolId = "us-west-2_fqvjbiBDV"
    private let cognitoIdentityUserPoolAppClientId = "7lj9rpfda574ngkcdv1km6e2hi"
    private let cognitoRegion = AWSRegionType.USWest2
    private let cognitoRegionString = "us-west-2"
    
    init() {
        // Configure Cognito User Pool
        let serviceConfiguration = AWSServiceConfiguration(region: cognitoRegion, credentialsProvider: nil)
        
        let userPoolConfiguration = AWSCognitoIdentityUserPoolConfiguration(
            clientId: cognitoIdentityUserPoolAppClientId,
            clientSecret: nil,
            poolId: cognitoIdentityUserPoolId
        )
        
        AWSCognitoIdentityUserPool.register(
            with: serviceConfiguration,
            userPoolConfiguration: userPoolConfiguration,
            forKey: "UserPool"
        )
        
        // Handle potential nil return value from forKey
        guard let userPoolInstance = AWSCognitoIdentityUserPool(forKey: "UserPool") else {
            fatalError("Failed to initialize Cognito User Pool")
        }
        userPool = userPoolInstance
        
        // Check if user is already signed in
        if let user = userPool.currentUser() {
            self.user = user
            getSession { success in
                self.isAuthenticated = success
            }
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = ""
        
        user = userPool.getUser(email)
        
        user?.getSession(email, password: password, validationData: nil).continueWith { [weak self] task -> Any? in
            guard let self = self else { return AWSTask<AnyObject>.init() }
            self.isLoading = false
            
            if let error = task.error as NSError? {
                self.errorMessage = error.userInfo["message"] as? String ?? error.localizedDescription
                completion(false)
                return AWSTask<AnyObject>.init()
            }
            
            // Set the ID token in API client for backend calls
            if let idToken = task.result?.idToken?.tokenString {
                APIClient.shared.setAuthToken(idToken)
            }
            
            self.isAuthenticated = true
            completion(true)
            return AWSTask<AnyObject>.init()
        }
    }
    
    func signUp(email: String, password: String, phoneNumber: String?, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = ""
        
        var attributes = [AWSCognitoIdentityUserAttributeType]()
        
        let emailAttribute = AWSCognitoIdentityUserAttributeType()
        emailAttribute?.name = "email"
        emailAttribute?.value = email
        attributes.append(emailAttribute!)
        
        if let phoneNumber = phoneNumber {
            let phoneAttribute = AWSCognitoIdentityUserAttributeType()
            phoneAttribute?.name = "phone_number"
            phoneAttribute?.value = phoneNumber
            attributes.append(phoneAttribute!)
        }
        
        userPool.signUp(email, password: password, userAttributes: attributes, validationData: nil).continueWith { [weak self] task -> Any? in
            guard let self = self else { return AWSTask<AnyObject>.init() }
            self.isLoading = false
            
            if let error = task.error as NSError? {
                self.errorMessage = error.userInfo["message"] as? String ?? error.localizedDescription
                completion(false)
                return AWSTask<AnyObject>.init()
            }
            
            // User successfully signed up but needs to confirm their account
            completion(true)
            return AWSTask<AnyObject>.init()
        }
    }
    
    func confirmSignUp(email: String, confirmationCode: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = ""
        
        let user = userPool.getUser(email)
        
        user.confirmSignUp(confirmationCode).continueWith { [weak self] task -> Any? in
            guard let self = self else { return AWSTask<AnyObject>.init() }
            self.isLoading = false
            
            if let error = task.error as NSError? {
                self.errorMessage = error.userInfo["message"] as? String ?? error.localizedDescription
                completion(false)
                return AWSTask<AnyObject>.init()
            }
            
            completion(true)
            return AWSTask<AnyObject>.init()
        }
    }
    
    func resendConfirmationCode(email: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = ""
        
        let user = userPool.getUser(email)
        
        user.resendConfirmationCode().continueWith { [weak self] task -> Any? in
            guard let self = self else { return AWSTask<AnyObject>.init() }
            self.isLoading = false
            
            if let error = task.error as NSError? {
                self.errorMessage = error.userInfo["message"] as? String ?? error.localizedDescription
                completion(false)
                return AWSTask<AnyObject>.init()
            }
            
            completion(true)
            return AWSTask<AnyObject>.init()
        }
    }
    
    func forgotPassword(email: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = ""
        
        let user = userPool.getUser(email)
        
        user.forgotPassword().continueWith { [weak self] task -> Any? in
            guard let self = self else { return AWSTask<AnyObject>.init() }
            self.isLoading = false
            
            if let error = task.error as NSError? {
                self.errorMessage = error.userInfo["message"] as? String ?? error.localizedDescription
                completion(false)
                return AWSTask<AnyObject>.init()
            }
            
            completion(true)
            return AWSTask<AnyObject>.init()
        }
    }
    
    func confirmForgotPassword(email: String, newPassword: String, confirmationCode: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = ""
        
        let user = userPool.getUser(email)
        
        user.confirmForgotPassword(confirmationCode, password: newPassword).continueWith { [weak self] task -> Any? in
            guard let self = self else { return AWSTask<AnyObject>.init() }
            self.isLoading = false
            
            if let error = task.error as NSError? {
                self.errorMessage = error.userInfo["message"] as? String ?? error.localizedDescription
                completion(false)
                return AWSTask<AnyObject>.init()
            }
            
            completion(true)
            return AWSTask<AnyObject>.init()
        }
    }
    
    func signOut() {
        if let user = userPool.currentUser() {
            user.signOut()
        }
        
        // Clear auth token from API client
        APIClient.shared.setAuthToken(nil)
        
        self.user = nil
        self.isAuthenticated = false
    }
    
    private func getSession(completion: @escaping (Bool) -> Void) {
        user?.getSession().continueWith { [weak self] task -> Any? in
            guard let self = self else { return AWSTask<AnyObject>.init() }
            
            if let error = task.error {
                print("Get session error: \(error)")
                completion(false)
                return AWSTask<AnyObject>.init()
            }
            
            if let idToken = task.result?.idToken?.tokenString {
                // Set auth token in API client for backend calls
                APIClient.shared.setAuthToken(idToken)
                completion(true)
            } else {
                completion(false)
            }
            
            return AWSTask<AnyObject>.init()
        }
    }
    
    func getUserAttributes(completion: @escaping ([String: String]) -> Void) {
        user?.getDetails().continueWith { task -> Any? in
            var attributes = [String: String]()
            
            if let error = task.error {
                print("Get user details error: \(error)")
                completion(attributes)
                return AWSTask<AnyObject>.init()
            }
            
            if let userAttributes = task.result?.userAttributes {
                for attribute in userAttributes {
                    if let name = attribute.name, let value = attribute.value {
                        attributes[name] = value
                    }
                }
            }
            
            completion(attributes)
            return AWSTask<AnyObject>.init()
        }
    }
    
    func updateUserAttributes(attributes: [String: String], completion: @escaping (Bool) -> Void) {
        let userAttributes = attributes.map { key, value in
            let attribute = AWSCognitoIdentityUserAttributeType()
            attribute?.name = key
            attribute?.value = value
            return attribute!
        }
        
        user?.update(userAttributes).continueWith { [weak self] task -> Any? in
            if let error = task.error as NSError? {
                self?.errorMessage = error.userInfo["message"] as? String ?? error.localizedDescription
                completion(false)
                return AWSTask<AnyObject>.init()
            }
            
            completion(true)
            return AWSTask<AnyObject>.init()
        }
    }
}

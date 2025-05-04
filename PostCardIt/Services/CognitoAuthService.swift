// CognitoAuthService.swift
import Foundation
import AWSCore
import AWSCognito
import AWSCognitoIdentityProvider

// Custom identity provider class that implements AWSIdentityProviderManager
class CognitoIdentityProvider: NSObject, AWSIdentityProviderManager {
    let poolId: String
    var idToken: String?
    let regionString: String
    
    init(poolId: String, idToken: String? = nil, regionString: String) {
        self.poolId = poolId
        self.idToken = idToken
        self.regionString = regionString
        super.init()
    }
    
    func logins() -> AWSTask<NSDictionary> {
        if let idToken = idToken {
            let key = "cognito-idp.\(regionString).amazonaws.com/\(poolId)"
            let dictionary = [key: idToken]
            return AWSTask(result: dictionary as NSDictionary)
        }
        
        // Return empty dictionary if no token is available (unauthenticated access)
        return AWSTask(result: [:] as NSDictionary)
    }
    
    // Update the ID token when the user signs in
    func updateIdToken(_ token: String?) {
        self.idToken = token
    }
}

class CognitoAuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var user: AWSCognitoIdentityUser?
    @Published var errorMessage = ""
    @Published var isLoading = false
    
    private let userPool: AWSCognitoIdentityUserPool
    private let credentialsProvider: AWSCognitoCredentialsProvider
    private let identityProvider: CognitoIdentityProvider
    
    // Replace these values with your own Cognito configuration
    private let cognitoIdentityUserPoolId = "us-east-1_dVWN0cQoG"
    private let cognitoIdentityUserPoolAppClientId = "3fgbee10voeud8qaqj4tkcsb3a"
    private let cognitoIdentityPoolId = "us-east-1:d110daff-8047-4d58-826c-ab2088eb689a"
    private let cognitoRegion = AWSRegionType.USEast1 // Change to your region
    private let cognitoRegionString = "us-east-1" // String version of your region
    
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
        
        // Create the identity provider
        identityProvider = CognitoIdentityProvider(
            poolId: cognitoIdentityUserPoolId,
            regionString: cognitoRegionString
        )
        
        // Configure Cognito Identity Pool with the identity provider
        credentialsProvider = AWSCognitoCredentialsProvider(
            regionType: cognitoRegion,
            identityPoolId: cognitoIdentityPoolId,
            identityProviderManager: identityProvider
        )
        
        let configuration = AWSServiceConfiguration(
            region: cognitoRegion,
            credentialsProvider: credentialsProvider
        )
        
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        // Check if user is already signed in
        if let user = userPool.currentUser() {
            self.user = user
            getSession { success in
                self.isAuthenticated = success
            }
        }
    }
    
    func signIn(username: String, password: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = ""
        
        user = userPool.getUser(username)
        
        user?.getSession(username, password: password, validationData: nil).continueWith { [weak self] task -> Any? in
            guard let self = self else { return AWSTask<AnyObject>.init() }
            self.isLoading = false
            
            if let error = task.error as NSError? {
                self.errorMessage = error.userInfo["message"] as? String ?? error.localizedDescription
                completion(false)
                return AWSTask<AnyObject>.init()
            }
            
            // Set the ID token in the identity provider
            if let idToken = task.result?.idToken?.tokenString {
                self.identityProvider.updateIdToken(idToken)
                
                // Clear credentials and force a refresh by getting identity ID
                self.credentialsProvider.clearCredentials()
                self.credentialsProvider.getIdentityId().continueWith { task in
                    if let error = task.error {
                        print("Credentials refresh error: \(error)")
                    }
                    return nil
                }
            }
            
            self.isAuthenticated = true
            completion(true)
            return AWSTask<AnyObject>.init()
        }
    }
    
    func signUp(username: String, password: String, email: String, phoneNumber: String?, completion: @escaping (Bool) -> Void) {
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
        
        userPool.signUp(username, password: password, userAttributes: attributes, validationData: nil).continueWith { [weak self] task -> Any? in
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
    
    func confirmSignUp(username: String, confirmationCode: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = ""
        
        let user = userPool.getUser(username)
        
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
    
    func resendConfirmationCode(username: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = ""
        
        let user = userPool.getUser(username)
        
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
    
    func forgotPassword(username: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = ""
        
        let user = userPool.getUser(username)
        
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
    
    func confirmForgotPassword(username: String, newPassword: String, confirmationCode: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = ""
        
        let user = userPool.getUser(username)
        
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
            
            // Clear the identity provider token and credentials
            identityProvider.updateIdToken(nil)
            credentialsProvider.clearKeychain()
            credentialsProvider.clearCredentials()
        }
        
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
                // Update the identity provider with the ID token
                self.identityProvider.updateIdToken(idToken)
                
                // Clear credentials and force a refresh by getting identity ID
                self.credentialsProvider.clearCredentials()
                
                // Use getIdentityId to force a refresh of the credentials
                self.credentialsProvider.getIdentityId().continueWith { task in
                    if let error = task.error {
                        print("Credentials refresh error: \(error)")
                        completion(false)
                    } else {
                        completion(true)
                    }
                    return nil
                }
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

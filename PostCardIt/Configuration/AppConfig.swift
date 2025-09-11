//
//  AppConfig.swift
//  PostCardIt
//
//  Application configuration settings
//

import Foundation

struct AppConfig {
    // MARK: - Environment Configuration
    enum Environment {
        case development
        case staging
        case production
        
        static var current: Environment {
//            #if DEBUG
//            return .development
//            #else
            return .production
//            #endif
        }
    }
    
    // MARK: - API Configuration
    struct API {
        static var baseURL: String {
            switch Environment.current {
            case .development:
                // TODO: Replace with your development API Gateway URL
                return "https://your-dev-api-gateway-url.amazonaws.com/v1"
            case .staging:
                // TODO: Replace with your staging API Gateway URL
                return "https://your-staging-api-gateway-url.amazonaws.com/v1"
            case .production:
                // TODO: Replace with your production API Gateway URL
                return "https://2h6q53sir8.execute-api.us-west-2.amazonaws.com/prod"
            }
        }
        
        static let timeout: TimeInterval = 30.0
    }
    
    // MARK: - AWS Configuration
    struct AWS {
        // Cognito Configuration
        static let cognitoUserPoolId = "us-west-2_fqvjbiBDV"
        static let cognitoClientId = "7lj9rpfda574ngkcdv1km6e2hi"
        static let cognitoIdentityPoolId = "us-east-1:d110daff-8047-4d58-826c-ab2088eb689a"
        static let region = "us-west-2"
        
        // S3 Configuration
        static var s3BucketName: String {
            switch Environment.current {
            case .development:
                return "postcard-it-dev"
            case .staging:
                return "postcard-it-staging"
            case .production:
                return "postii-assets-prod-725214515251"
            }
        }
    }
    
    // MARK: - Feature Flags
    struct Features {
        static let enableOfflineMode = false
        static let enableAnalytics = Environment.current == .production
        static let enableDebugLogging = Environment.current == .development
    }
    
    // MARK: - App Information
    struct App {
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.postcardit.app"
        
        static var userAgent: String {
            return "PostCardIt/\(version) (\(buildNumber)) iOS"
        }
    }
    
    // MARK: - UI Configuration
    struct UI {
        static let animationDuration: Double = 0.3
        static let pageSize = 20 // For pagination
        static let maxImageSizeBytes = 10 * 1024 * 1024 // 10MB
        static let imageCompressionQuality: CGFloat = 0.7
    }
}

// MARK: - Configuration Helper Extensions
extension AppConfig {
    // Helper method to check if we're in development
    static var isDevelopment: Bool {
        return Environment.current == .development
    }
    
    // Helper method to check if we're in production
    static var isProduction: Bool {
        return Environment.current == .production
    }
}

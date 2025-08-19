# PostCardIt - Development Documentation for Claude Code

## Project Overview

PostCardIt is an iOS application that allows users to create and send digital postcards. Built with SwiftUI and integrated with AWS services for authentication and storage.

**Key Features:**
- User authentication via AWS Cognito
- Digital postcard creation with custom images
- Photo library integration
- Tab-based navigation with custom tab bar
- User profile management
- Map integration for location-based features

## Architecture & Tech Stack

- **Platform**: iOS 14.0+
- **UI Framework**: SwiftUI
- **Authentication**: AWS Cognito Identity Provider
- **Storage**: AWS S3 for image storage
- **Dependencies**: CocoaPods (AWS SDK)
- **Testing**: Swift Testing + XCTest UI Testing

## Project Structure

```
PostCardIt/
├── PostCardIt/                     # Main app target
│   ├── PostCardItApp.swift         # App entry point with splash screen and auth flow
│   ├── Model/
│   │   └── PostcardModel.swift     # Core data models
│   ├── Services/
│   │   ├── CognitoAuthService.swift # AWS Cognito authentication service
│   │   └── PostcardService.swift   # Postcard business logic and AWS S3 integration
│   ├── Views/
│   │   ├── Authentication/         # Login, registration, password reset views
│   │   ├── Home/                   # Home screen with postcard previews
│   │   ├── Create/                 # Postcard creation workflow
│   │   ├── Cards/                  # User's postcards management
│   │   ├── Map/                    # Map view for location features
│   │   ├── Profile/                # User profile and settings
│   │   ├── MainTabView.swift       # Custom tab navigation
│   │   └── SplashView.swift        # Launch screen
│   ├── Assets.xcassets/            # App icons and UI images
│   ├── Stamps.xcassets/            # Postcard stamp collections
│   ├── Kalam/                      # Custom font files
│   └── Info.plist                  # App configuration
├── PostCardItTests/                # Unit tests
├── PostCardItUITests/              # UI automation tests
├── Podfile                         # CocoaPods dependency management
└── Pods/                          # AWS SDK dependencies
```

## Key Components

### App Flow
1. **Splash Screen** (2-second delay)
2. **Authentication Check** → Login or Main App
3. **Main Tab Navigation** with custom tab bar

### Services
- **CognitoAuthService**: Handles user registration, login, password reset
- **PostcardService**: Manages postcard creation, image upload to S3

### Views Architecture
- **MVVM Pattern**: ViewModels as ObservableObject services
- **Environment Objects**: Shared auth service across views
- **State Management**: @State, @StateObject, @Binding patterns

## Development Commands

### Setup
```bash
# Install dependencies
pod install

# Open workspace (important: use .xcworkspace not .xcodeproj)
open PostCardIt.xcworkspace

# Build project
xcodebuild -workspace PostCardIt.xcworkspace -scheme PostCardIt build

# Run tests
xcodebuild test -workspace PostCardIt.xcworkspace -scheme PostCardIt -destination 'platform=iOS Simulator,name=iPhone 15'
```

### AWS Configuration
- Configure AWS credentials in `CognitoAuthService.swift`
- Set up Cognito User Pool and Identity Pool
- Configure S3 bucket for image storage

## Code Conventions

### Naming
- Use camelCase for variables/functions
- Use PascalCase for types/classes
- Descriptive names: `selectedImage` not `img`
- Boolean prefixes: `is`, `has`, `should`

### SwiftUI Patterns
- `@StateObject` for view-owned ObservableObjects
- `@EnvironmentObject` for shared services
- Extract complex views into separate components
- Use computed properties for simple view logic

### File Organization
- Group related views in folders
- One main type per file
- Use MARK comments for sections

## Testing Strategy

### Unit Tests (`PostCardItTests/`)
- Framework: Swift Testing (modern approach)
- Test models, services, business logic

### UI Tests (`PostCardItUITests/`)
- Framework: XCTest UI Testing
- Test user flows, navigation, authentication

## Current Implementation Status

### Completed Features
- ✅ User authentication (login, registration, password reset)
- ✅ Custom tab bar navigation
- ✅ Basic UI structure for all main screens
- ✅ AWS Cognito integration
- ✅ Image picker integration
- ✅ Splash screen with app branding

### In Development
- 🚧 Backend API integration (placeholder methods exist)
- 🚧 Postcard creation workflow
- 🚧 Map functionality
- 🚧 Profile management features

### Known Technical Debt
- Remove commented-out code in CreatePostcardView
- Implement proper error states throughout app
- Add comprehensive unit test coverage
- Consider migrating to async/await patterns

## Common Issues & Solutions

### Build Issues
- Always use `.xcworkspace` file, not `.xcodeproj`
- Run `pod install` after pulling changes
- Check AWS SDK compatibility with iOS version

### Development Tips
- Use iOS Simulator iPhone 15 for testing
- Check Info.plist permissions for photo library access
- Monitor memory usage during image operations
- Test authentication flows thoroughly

## Security Considerations

- AWS Cognito handles password security
- Never log sensitive user information
- Use HTTPS for all network requests
- Implement proper session management
- Handle photo library permissions gracefully

## Resources

- [Existing Development Guidelines](./DEVELOPMENT_GUIDELINES.md) - Comprehensive development guide
- [AWS SDK for iOS](https://docs.aws.amazon.com/sdk-for-ios/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Swift Testing Framework](https://developer.apple.com/documentation/testing)

---

**For Claude Code**: This is a SwiftUI iOS app with AWS backend integration. Use the existing patterns and services when making modifications. Always test authentication flows and image handling features when making changes.
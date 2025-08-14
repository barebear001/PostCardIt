# PostCardIt Development Guidelines

## Project Overview

PostCardIt is an iOS application built with SwiftUI that allows users to create and send digital postcards. The app features AWS Cognito authentication, S3 image storage, and a modern iOS interface.

## Architecture

### Technology Stack
- **Platform**: iOS 14.0+
- **Framework**: SwiftUI
- **Authentication**: AWS Cognito Identity Provider
- **Storage**: AWS S3 for images
- **Dependency Management**: CocoaPods
- **Testing**: Swift Testing + XCTest

### Project Structure
```
PostCardIt/
├── PostCardIt/
│   ├── PostCardItApp.swift          # Main app entry point
│   ├── Model/
│   │   └── PostcardModel.swift      # Core data models
│   ├── Services/
│   │   ├── CognitoAuthService.swift # Authentication service
│   │   └── PostcardService.swift    # Postcard business logic
│   ├── Views/
│   │   ├── Authentication/          # Auth-related views
│   │   ├── Home/                    # Home screen components
│   │   ├── Create/                  # Postcard creation flow
│   │   ├── Cards/                   # User's postcards
│   │   ├── Map/                     # Map functionality
│   │   ├── Profile/                 # User profile
│   │   ├── MainTabView.swift        # Tab navigation
│   │   └── SplashView.swift         # Launch screen
│   ├── Assets.xcassets/             # App images and icons
│   ├── Stamps.xcassets/             # Postcard stamp assets
│   └── Info.plist                   # App configuration
├── PostCardItTests/                 # Unit tests
├── PostCardItUITests/              # UI tests
├── Podfile                         # CocoaPods dependencies
└── Pods/                           # AWS SDK dependencies
```

## Code Conventions

### Swift Style Guidelines

1. **Naming Conventions**
   - Use camelCase for variables and functions
   - Use PascalCase for types, classes, and protocols
   - Use descriptive names: `selectedImage` not `img`
   - Prefix boolean variables with `is`, `has`, or `should`

2. **File Organization**
   - Group related views in folders (Authentication/, Home/, etc.)
   - One main type per file
   - Use MARK comments for logical sections
   - Include header comments with creation date

3. **SwiftUI Patterns**
   - Use `@StateObject` for view-owned ObservableObject instances
   - Use `@EnvironmentObject` for shared data between views
   - Prefer computed properties over functions for simple view logic
   - Extract complex views into separate components

### Code Examples
```swift
// Good: Descriptive naming and proper state management
struct CreatePostcardView: View {
    @EnvironmentObject var authService: CognitoAuthService
    @StateObject private var postcardService = PostcardService()
    @State private var selectedImage: UIImage?
    @State private var isShowingPreview = false
    
    var body: some View {
        // View implementation
    }
}

// Good: Extracted component
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    // Implementation
}
```

## Architecture Patterns

### MVVM Implementation
- **Models**: Simple data structures (PostcardModel.swift)
- **ViewModels**: ObservableObject services (CognitoAuthService, PostcardService)
- **Views**: SwiftUI views that observe ViewModels

### Service Layer
- `CognitoAuthService`: Handles all authentication operations
- `PostcardService`: Manages postcard creation, storage, and retrieval
- Services use `@Published` properties for reactive UI updates

### Navigation Pattern
- Tab-based navigation using `MainTabView`
- Modal presentations for creation flows
- NavigationView/NavigationLink for hierarchical navigation

## Dependencies

### CocoaPods Configuration
```ruby
platform :ios, '14.0'

target 'PostCardIt' do
  use_frameworks!
  
  # AWS Core and Authentication
  pod 'AWSCore'
  pod 'AWSCognito'
  pod 'AWSCognitoIdentityProvider'
  
  # AWS S3 for image storage
  pod 'AWSS3'
end
```

### AWS Services Integration
- **Cognito User Pool**: User registration and authentication
- **Cognito Identity Pool**: Federated identity for AWS services
- **S3**: Image storage with public read access for postcards

## Testing Strategy

### Unit Testing
- Framework: Swift Testing (modern approach)
- Location: `PostCardItTests/`
- Focus: Model validation, service logic, business rules

### UI Testing
- Framework: XCTest UI Testing
- Location: `PostCardItUITests/`
- Focus: User flows, navigation, authentication

### Test Structure
```swift
// Unit Test Example
import Testing
@testable import PostCardIt

struct PostCardItTests {
    @Test func example() async throws {
        // Test implementation
    }
}

// UI Test Example
final class PostCardItUITests: XCTestCase {
    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
```

## Development Workflow

### Setting Up Development Environment
1. Clone the repository
2. Run `pod install` to install AWS dependencies
3. Open `PostCardIt.xcworkspace` (not .xcodeproj)
4. Configure AWS credentials in CognitoAuthService.swift
5. Update Info.plist permissions as needed

### Building and Running
- **Minimum iOS Version**: 14.0
- **Target Device**: iPhone/iPad
- **Build Configuration**: Debug for development, Release for distribution

### Code Quality Standards
1. **No warnings**: Code should compile without warnings
2. **SwiftLint compliance**: Follow Swift style guidelines
3. **Documentation**: Public APIs should have documentation comments
4. **Error handling**: Proper error handling with user-friendly messages

## Security Guidelines

### Authentication
- AWS Cognito handles password security and validation
- Store only necessary user attributes locally
- Implement proper session management and logout

### Data Protection
- Never log sensitive user information
- Use HTTPS for all network requests
- Implement proper keychain storage for tokens

### Permissions
- Request photo library access only when needed
- Provide clear usage descriptions in Info.plist
- Handle permission denial gracefully

## Performance Guidelines

### Image Handling
- Compress images before uploading to S3
- Use appropriate image sizes for different contexts
- Implement lazy loading for photo grids

### Memory Management
- Use weak references in closures to prevent retain cycles
- Dispose of resources properly in deinit methods
- Monitor memory usage during photo operations

### Network Optimization
- Implement proper error handling for network failures
- Use background queues for API operations
- Cache frequently accessed data appropriately

## Future Development Considerations

### Scalability
- Consider moving to SwiftUI's new data flow patterns
- Implement proper offline support
- Add comprehensive logging and analytics

### Feature Additions
- Backend API integration (replace placeholder methods)
- Push notifications for received postcards
- Social features and user discovery
- Advanced photo editing capabilities

### Technical Debt
- Remove commented-out code in CreatePostcardView
- Implement proper error states throughout the app
- Add comprehensive unit test coverage
- Consider migrating to async/await patterns

## Common Commands

### Development
```bash
# Install dependencies
pod install

# Update dependencies
pod update

# Build project
xcodebuild -workspace PostCardIt.xcworkspace -scheme PostCardIt build

# Run tests
xcodebuild test -workspace PostCardIt.xcworkspace -scheme PostCardIt -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Git Workflow
- Use feature branches for new development
- Follow conventional commit messages
- Include relevant issue numbers in commits
- Ensure all tests pass before merging

## Resources

- [Apple's SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [AWS SDK for iOS Documentation](https://docs.aws.amazon.com/sdk-for-ios/)
- [Swift Testing Framework](https://developer.apple.com/documentation/testing)
- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

---

Last Updated: August 14, 2025
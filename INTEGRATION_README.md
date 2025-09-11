# PostCardIt Frontend-Backend Integration

This document outlines the completed integration between the iOS frontend and AWS backend infrastructure.

## ✅ Integration Complete

The following components have been integrated:

### 1. API Client Layer (`APIClient.swift`)
- **Purpose**: HTTP networking layer for communicating with the backend API
- **Features**:
  - Generic HTTP methods (GET, POST, PUT, DELETE)
  - Automatic JWT token management
  - Error handling and response parsing
  - Support for async/await patterns

### 2. PostcardService Integration
- **Updated**: `PostCardIt/Services/PostcardService.swift`
- **Features**:
  - Real API calls to backend Lambda functions
  - S3 image upload integration
  - Async/await pattern for better performance
  - User name resolution for postcards
- **Endpoints Used**:
  - `GET /v1/postcards/sent` - Fetch sent postcards
  - `GET /v1/postcards/received` - Fetch received postcards
  - `POST /v1/postcards` - Send new postcard
  - `DELETE /v1/postcards/{id}` - Delete postcard

### 3. User Service (`UserService.swift`)
- **Purpose**: Manage user profiles and friend relationships
- **Features**:
  - User profile CRUD operations
  - User search functionality
  - Friend request management
  - Profile data models
- **Endpoints Used**:
  - `GET /v1/users` - Get current user profile
  - `POST /v1/users` - Create user profile
  - `PUT /v1/users` - Update user profile
  - `GET /v1/users/search` - Search users
  - `POST /v1/friends` - Send friend request

### 4. Authentication Integration
- **Updated**: `PostCardIt/Services/CognitoAuthService.swift`
- **Features**:
  - JWT token management
  - API client token synchronization
  - Automatic token refresh handling

### 5. Configuration Management
- **Created**: `PostCardIt/Configuration/AppConfig.swift`
- **Features**:
  - Environment-based configuration
  - API endpoint management
  - AWS service configuration
  - Feature flags

## 🔧 Configuration Required

Before using the integration, you need to update the following configuration values:

### 1. API Gateway URLs
Update the API Gateway URLs in `AppConfig.swift`:

```swift
// Replace these with your actual deployed API Gateway URLs
case .development:
    return "https://your-dev-api-gateway-url.amazonaws.com/v1"
case .staging:
    return "https://your-staging-api-gateway-url.amazonaws.com/v1"
case .production:
    return "https://your-prod-api-gateway-url.amazonaws.com/v1"
```

### 2. AWS Configuration
The following AWS resources are already configured but verify they match your deployment:
- **Cognito User Pool**: `us-east-1_dVWN0cQoG`
- **Cognito Client ID**: `3fgbee10voeud8qaqj4tkcsb3a`
- **Cognito Identity Pool**: `us-east-1:d110daff-8047-4d58-826c-ab2088eb689a`
- **S3 Bucket**: `postcard-it-beta` (production)

## 🚀 Deployment Steps

### 1. Deploy Backend Infrastructure
```bash
cd postii-infra
npm install
cdk bootstrap  # If not already done
cdk deploy --all
```

### 2. Update Frontend Configuration
After deployment, update `AppConfig.swift` with your API Gateway URLs from the CDK outputs.

### 3. Test Integration
The app will now communicate with your backend APIs:
- User registration/login via Cognito
- Postcard operations via Lambda functions
- Image uploads to S3
- User profile management

## 📱 Frontend Components Updated

The following components are already integrated and ready to use:

- **LoginView**: Uses CognitoAuthService for authentication
- **MyCardsView**: Displays postcards from backend API
- **CreatePostcardView**: Sends postcards via backend API
- **ProfileView**: Manages user profiles via UserService

## 🔍 Error Handling

The integration includes comprehensive error handling:
- Network errors
- Authentication failures
- Server errors
- Data parsing errors

All errors are displayed to users through the `errorMessage` properties on service classes.

## 🧪 Testing

### Local Testing
1. Ensure your backend is deployed and accessible
2. Update API URLs in `AppConfig.swift`
3. Build and run the iOS app
4. Test user registration, login, and postcard operations

### Production Testing
1. Deploy backend to production environment
2. Update production API URLs
3. Test with production Cognito user pool
4. Verify S3 image uploads work correctly

## 📊 API Documentation

The backend APIs follow the specifications in `PostCardIt-Backend-Design.md`:

### Authentication
- JWT tokens via AWS Cognito
- Automatic token refresh
- Secure API endpoints

### Postcard Operations
- Send postcards with images
- Fetch sent/received postcards
- Real-time user name resolution

### User Management
- Profile creation and updates
- User search functionality
- Friend request system

## 🔄 Data Flow

1. **Authentication**: User signs in via Cognito → JWT token stored → Token sent with all API requests
2. **Postcards**: 
   - Send: Image → S3 upload → Postcard data → DynamoDB via Lambda
   - Fetch: DynamoDB query via Lambda → User name resolution → Display in app
3. **Users**: CRUD operations via Lambda functions → DynamoDB storage

## 🛠 Maintenance

### Adding New Endpoints
1. Add endpoint to `APIConfig.Endpoint` enum
2. Create request/response models as needed
3. Add service methods using `APIClient`
4. Update frontend components

### Configuration Updates
- Environment variables in `AppConfig.swift`
- AWS resource identifiers
- Feature flags for new functionality

## 📝 Notes

- The integration uses modern Swift async/await patterns
- All network operations are performed off the main thread
- Error messages are user-friendly and localized
- The app gracefully handles offline scenarios
- JWT tokens are automatically managed and refreshed

The integration is complete and ready for testing. Update the API URLs in the configuration file and deploy your backend to start using the integrated application.
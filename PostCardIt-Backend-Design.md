# PostCardIt Backend Design Document

## Overview

This document outlines the complete backend architecture for the PostCardIt iOS application, including data schema, storage design, API specifications, and business logic implementation.

## Table of Contents
- [Data Schema](#data-schema)
- [Storage Architecture](#storage-architecture)  
- [API Design](#api-design)
- [Business Logic](#business-logic)
- [Security & Authentication](#security--authentication)
- [Performance Considerations](#performance-considerations)

---

## Data Schema

### Core Entities

#### User Profile
```json
{
  "userId": "uuid",
  "username": "string (unique, 3-30 chars)",
  "email": "string (unique, validated)",
  "profileImageUrl": "string (S3 URL)",
  "firstName": "string",
  "lastName": "string", 
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "isActive": "boolean",
  "lastLoginAt": "timestamp"
}
```

#### Friendship
```json
{
  "friendshipId": "uuid",
  "requesterId": "uuid (FK to User)",
  "addresseeId": "uuid (FK to User)", 
  "status": "enum (PENDING, ACCEPTED, REJECTED, BLOCKED)",
  "requestedAt": "timestamp",
  "respondedAt": "timestamp",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

#### Postcard
```json
{
  "postcardId": "uuid",
  "senderId": "uuid (FK to User)",
  "recipientId": "uuid (FK to User)",
  "text": "string (max 500 chars)",
  "imageUrl": "string (S3 URL)",
  "stampImageUrl": "string (S3 URL)",
  "sentAt": "timestamp",
  "deliveredAt": "timestamp",
  "readAt": "timestamp",
  "location": {
    "latitude": "decimal",
    "longitude": "decimal", 
    "address": "string",
    "city": "string",
    "country": "string"
  },
  "status": "enum (DRAFT, SENT, DELIVERED, READ)",
  "type": "enum (SENT, RECEIVED)",
  "isArchived": "boolean",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

---

## Storage Architecture

### Database: Amazon DynamoDB

#### Users Table
- **Primary Key**: userId (String)
- **GSI1**: email-index (email as PK)
- **GSI2**: username-index (username as PK)
- **Attributes**: All user profile fields

#### Friendships Table 
- **Primary Key**: friendshipId (String)
- **GSI1**: requester-index (requesterId as PK, createdAt as SK)
- **GSI2**: addressee-index (addresseeId as PK, createdAt as SK)
- **GSI3**: status-index (status as PK, createdAt as SK)
- **Attributes**: All friendship fields

#### Postcards Table
- **Primary Key**: postcardId (String) 
- **GSI1**: sender-sent-index 
  - PK: `SENDER#{senderId}` 
  - SK: `SENT#{sentAt}`
- **GSI2**: recipient-received-index
  - PK: `RECIPIENT#{recipientId}`
  - SK: `RECEIVED#{deliveredAt || sentAt}`
- **GSI3**: status-index (status as PK, sentAt as SK)
- **GSI4**: user-timeline-index
  - PK: `USER#{userId}#{type}` (where type is SENT or RECEIVED)
  - SK: `{sentAt || deliveredAt}`
- **Attributes**: All postcard fields

### Query Patterns
```typescript
// Get all postcards sent by user
PK = "SENDER#user123", SK begins_with "SENT#"

// Get all postcards received by user  
PK = "RECIPIENT#user123", SK begins_with "RECEIVED#"

// Get user's complete postcard timeline (sent + received)
PK = "USER#user123#SENT" OR PK = "USER#user123#RECEIVED"

// Get unread received postcards
PK = "RECIPIENT#user123", FilterExpression: status = "DELIVERED"
```

### File Storage: Amazon S3

#### Bucket Structure
```
postcardit-assets/
├── profile-images/
│   └── {userId}/
│       └── profile.jpg
├── postcard-images/
│   └── {postcardId}/
│       ├── original.jpg
│       └── thumbnail.jpg
└── stamps/
    └── {stampId}.png
```

---

## API Design

### Base Configuration
- **Base URL**: `https://api.postcardit.com/v1`
- **Authentication**: Bearer JWT tokens via AWS Cognito
- **Content-Type**: `application/json`
- **Rate Limiting**: 100 requests/minute per user

### Authentication Endpoints
```
POST   /auth/register          # Register new user
POST   /auth/login             # User login
POST   /auth/refresh           # Refresh JWT token
POST   /auth/logout            # Logout user
```

### User Management Endpoints
```
GET    /users/profile          # Get current user profile  
PUT    /users/profile          # Update user profile
POST   /users/profile/image    # Upload profile image
DELETE /users/profile/image    # Delete profile image
GET    /users/search?q={query} # Search users by username/email
```

### Friends Management Endpoints
```
GET    /friends                # Get user's friends list
POST   /friends/request        # Send friend request
PUT    /friends/{friendshipId} # Accept/reject friend request  
DELETE /friends/{friendshipId} # Remove friend/cancel request
GET    /friends/requests       # Get pending friend requests
GET    /friends/requests/sent  # Get sent friend requests
```

### Postcards Endpoints
```
# Main postcard endpoints
GET    /postcards                    # Get all postcards (sent + received)
GET    /postcards/sent              # Get only sent postcards  
GET    /postcards/received          # Get only received postcards
GET    /postcards/received/unread   # Get unread received postcards
POST   /postcards                   # Create/send new postcard
GET    /postcards/{id}              # Get specific postcard
PUT    /postcards/{id}/read         # Mark received postcard as read
PUT    /postcards/{id}/archive      # Archive postcard (sent or received)
DELETE /postcards/{id}              # Delete postcard (only sender can delete)

# Additional endpoints
POST   /postcards/upload            # Upload postcard image
GET    /postcards/stats             # Get user stats (total sent/received)
GET    /stamps                      # Get available stamps
```

### Query Parameters
```
GET /postcards?type=sent&limit=20&offset=0&status=read
GET /postcards?type=received&unreadOnly=true  
GET /postcards?archived=false&fromDate=2024-01-01
```

### Response Format
```typescript
interface APIResponse<T> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
  };
  pagination?: {
    hasMore: boolean;
    nextOffset?: string;
    total?: number;
  };
}

interface PostcardResponse {
  postcards: Postcard[];
  pagination: {
    hasMore: boolean;
    nextOffset?: string; 
  };
  summary: {
    total: number;
    unread?: number; // Only for received postcards
  };
}
```

---

## Business Logic

### Core Handler Structure (Node.js/TypeScript)

#### Base Handler Pattern
```typescript
interface APIResponse<T> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
  };
}

abstract class BaseHandler {
  protected validateAuth(event: APIGatewayProxyEvent): Promise<User>;
  protected handleError(error: Error): APIGatewayProxyResult;
  protected success<T>(data: T): APIGatewayProxyResult;
}
```

### Service Layer

#### FriendshipService
```typescript
class FriendshipService {
  // Send friend request with validation
  async sendFriendRequest(requesterId: string, addresseeId: string): Promise<Friendship> {
    // Validate users exist and aren't already friends
    // Create PENDING friendship record
    // Send push notification to addressee
  }

  // Accept/reject friend request
  async respondToFriendRequest(friendshipId: string, userId: string, action: 'ACCEPT' | 'REJECT'): Promise<Friendship> {
    // Verify user is the addressee
    // Update friendship status
    // Send push notification to requester
  }

  // Get user's friends (accepted friendships only)
  async getFriends(userId: string): Promise<User[]> {
    // Query both requester and addressee indexes
    // Return combined list of friends
  }
}
```

#### PostcardService
```typescript
class PostcardService {
  // Create and send postcard
  async sendPostcard(senderId: string, recipientId: string, data: PostcardData): Promise<Postcard> {
    // Validate friendship exists
    // Upload image to S3 if provided
    // Create postcard record
    // Update both sender and recipient GSIs
    // Send push notification to recipient
    // Return postcard with signed URLs
  }

  // Get sent postcards for user
  async getSentPostcards(userId: string, options: QueryOptions): Promise<PostcardResponse> {
    // Query sender-sent-index
    // Return paginated results
  }

  // Get received postcards for user  
  async getReceivedPostcards(userId: string, unreadOnly = false, options: QueryOptions): Promise<PostcardResponse> {
    // Query recipient-received-index
    // Apply unread filter if requested
    // Return paginated results with unread count
  }

  // Mark postcard as read (only recipient)
  async markAsRead(postcardId: string, userId: string): Promise<void> {
    // Verify user is recipient
    // Update status and readAt timestamp
  }

  // Archive postcard (sender or recipient)
  async archivePostcard(postcardId: string, userId: string): Promise<void> {
    // Verify user is sender or recipient
    // Set isArchived flag
  }
}
```

#### ValidationService
```typescript
class ValidationService {
  // Input sanitization and validation
  validatePostcardText(text: string): boolean;
  validateImageFormat(file: File): boolean;
  validateImageSize(file: File): boolean;
  
  // Rate limiting
  checkRateLimit(userId: string, action: string): Promise<boolean>;
}
```

#### NotificationService
```typescript
class NotificationService {
  // Push notifications
  async sendFriendRequestNotification(userId: string, requesterName: string): Promise<void>;
  async sendPostcardNotification(userId: string, senderName: string): Promise<void>;
  async sendFriendAcceptedNotification(userId: string, friendName: string): Promise<void>;
  
  // Email notifications for important events
  async sendWelcomeEmail(userId: string): Promise<void>;
}
```

### Error Handling

#### Error Codes
```typescript
enum ErrorCodes {
  // Authentication
  UNAUTHORIZED = 'UNAUTHORIZED',
  INVALID_TOKEN = 'INVALID_TOKEN',
  TOKEN_EXPIRED = 'TOKEN_EXPIRED',
  
  // Friendship
  FRIENDSHIP_EXISTS = 'FRIENDSHIP_EXISTS',
  FRIENDSHIP_NOT_FOUND = 'FRIENDSHIP_NOT_FOUND',
  CANNOT_FRIEND_SELF = 'CANNOT_FRIEND_SELF',
  
  // Postcards
  INVALID_RECIPIENT = 'INVALID_RECIPIENT',
  POSTCARD_NOT_FOUND = 'POSTCARD_NOT_FOUND',
  UNAUTHORIZED_ACCESS = 'UNAUTHORIZED_ACCESS',
  
  // Rate limiting
  RATE_LIMIT_EXCEEDED = 'RATE_LIMIT_EXCEEDED',
  
  // Validation
  INVALID_INPUT = 'INVALID_INPUT',
  IMAGE_TOO_LARGE = 'IMAGE_TOO_LARGE',
  INVALID_IMAGE_FORMAT = 'INVALID_IMAGE_FORMAT'
}
```

---

## Security & Authentication

### AWS Cognito Integration
- User registration and login
- JWT token validation
- Password requirements and policies
- Email verification
- Password reset functionality

### API Security
- All endpoints require valid JWT token (except auth endpoints)
- Input validation and sanitization
- SQL injection prevention (N/A with DynamoDB)
- XSS prevention
- Rate limiting per user/IP
- CORS configuration

### Data Privacy
- Profile images stored in private S3 buckets
- Signed URLs for image access with expiration
- User data encryption at rest (DynamoDB encryption)
- HTTPS/TLS for all API communication

---

## Performance Considerations

### Database Optimization
- DynamoDB GSIs for efficient querying
- Composite keys for range queries
- Pagination for large result sets
- Connection pooling for database access

### Caching Strategy
- AWS CloudFront for static assets (images, stamps)
- API Gateway caching for frequently accessed endpoints
- Application-level caching for user sessions

### Image Optimization
- Automatic thumbnail generation for postcards
- Multiple image sizes (@1x, @2x, @3x for iOS)
- WebP format support for smaller file sizes
- Image compression on upload

### Monitoring & Logging
- AWS CloudWatch for API metrics
- Application logs for debugging
- Error tracking and alerting
- Performance monitoring for slow queries

---

## Deployment Architecture

### AWS Services Stack
- **API Gateway**: REST API endpoints and routing
- **Lambda Functions**: Business logic handlers
- **DynamoDB**: Primary database storage
- **S3**: File and image storage
- **Cognito**: User authentication
- **CloudFront**: CDN for image delivery
- **SNS**: Push notifications
- **SES**: Email notifications

### Environment Configuration
- **Development**: Single region, basic monitoring
- **Staging**: Production-like setup for testing
- **Production**: Multi-AZ, comprehensive monitoring, backups

---

## Future Considerations

### Scalability Enhancements
- DynamoDB on-demand billing for variable traffic
- Lambda auto-scaling based on request volume
- CloudFront edge locations for global performance

### Feature Extensions
- Postcard templates and themes
- Group postcards and broadcast sending
- Postcard delivery tracking and notifications
- Social features (postcard likes, comments)
- Analytics dashboard for users

### Data Analytics
- User engagement metrics
- Postcard delivery success rates
- Popular locations and times
- Friend network analysis
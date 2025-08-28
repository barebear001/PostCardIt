# AWS CDK Deployment Guide for Postii

This guide provides step-by-step instructions for deploying the Postii backend infrastructure using AWS CDK (Cloud Development Kit).

## Table of Contents
- [Prerequisites](#prerequisites)
- [Project Setup](#project-setup)
- [CDK Stack Structure](#cdk-stack-structure)
- [Infrastructure Components](#infrastructure-components)
- [Deployment Instructions](#deployment-instructions)
- [Environment Management](#environment-management)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Software
```bash
# Install Node.js (version 18 or later)
node --version

# Install AWS CLI
aws --version

# Install AWS CDK globally
npm install -g aws-cdk

# Verify CDK installation
cdk --version
```

### AWS Configuration
```bash
# Configure AWS credentials
aws configure

# Or use environment variables
export AWS_ACCESS_KEY_ID=your-access-key
export AWS_SECRET_ACCESS_KEY=your-secret-key
export AWS_DEFAULT_REGION=us-east-1
```

---

## Project Setup

### Initialize CDK Project
```bash
# Create new directory for infrastructure
mkdir postii-infrastructure
cd postii-infrastructure

# Initialize CDK project
cdk init app --language typescript

# Install additional dependencies
npm install @aws-cdk/aws-dynamodb @aws-cdk/aws-s3 @aws-cdk/aws-lambda @aws-cdk/aws-apigateway @aws-cdk/aws-cognito @aws-cdk/aws-cloudfront
```

### Project Structure
```
postii-infrastructure/
├── bin/
│   └── postii.ts           # CDK app entry point
├── lib/
│   ├── postii-stack.ts     # Main stack
│   ├── database-stack.ts       # DynamoDB resources
│   ├── storage-stack.ts        # S3 and CloudFront
│   ├── auth-stack.ts          # Cognito authentication
│   └── api-stack.ts           # API Gateway and Lambda
├── lambda/
│   ├── auth/                  # Authentication handlers
│   ├── users/                 # User management handlers
│   ├── friends/               # Friend management handlers
│   └── postcards/             # Postcard handlers
├── cdk.json
├── package.json
└── tsconfig.json
```

---

## CDK Stack Structure

### Main App Entry Point
**bin/postii.ts**
```typescript
#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { PostiiStack } from '../lib/postii-stack';

const app = new cdk.App();

// Development environment
new PostiiStack(app, 'PostiiDev', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
  },
  stage: 'dev'
});

// Production environment
new PostiiStack(app, 'PostiiProd', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
  },
  stage: 'prod'
});
```

### Main Stack
**lib/postii-stack.ts**
```typescript
import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import { DatabaseStack } from './database-stack';
import { StorageStack } from './storage-stack';
import { AuthStack } from './auth-stack';
import { ApiStack } from './api-stack';

export interface PostiiStackProps extends cdk.StackProps {
  stage: string;
}

export class PostiiStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: PostiiStackProps) {
    super(scope, id, props);

    const { stage } = props;

    // Database resources
    const databaseStack = new DatabaseStack(this, 'Database', { stage });

    // Storage resources
    const storageStack = new StorageStack(this, 'Storage', { stage });

    // Authentication resources
    const authStack = new AuthStack(this, 'Auth', { stage });

    // API resources (depends on all other stacks)
    const apiStack = new ApiStack(this, 'Api', {
      stage,
      userPool: authStack.userPool,
      usersTable: databaseStack.usersTable,
      friendshipsTable: databaseStack.friendshipsTable,
      postcardsTable: databaseStack.postcardsTable,
      assetsBucket: storageStack.assetsBucket,
    });

    // Outputs
    new cdk.CfnOutput(this, 'ApiUrl', {
      value: apiStack.api.url,
      description: 'API Gateway URL',
    });

    new cdk.CfnOutput(this, 'UserPoolId', {
      value: authStack.userPool.userPoolId,
      description: 'Cognito User Pool ID',
    });

    new cdk.CfnOutput(this, 'UserPoolClientId', {
      value: authStack.userPoolClient.userPoolClientId,
      description: 'Cognito User Pool Client ID',
    });
  }
}
```

---

## Infrastructure Components

### Database Stack
**lib/database-stack.ts**
```typescript
import * as cdk from 'aws-cdk-lib';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import { Construct } from 'constructs';

export interface DatabaseStackProps {
  stage: string;
}

export class DatabaseStack extends Construct {
  public readonly usersTable: dynamodb.Table;
  public readonly friendshipsTable: dynamodb.Table;
  public readonly postcardsTable: dynamodb.Table;

  constructor(scope: Construct, id: string, props: DatabaseStackProps) {
    super(scope, id);

    const { stage } = props;

    // Users Table
    this.usersTable = new dynamodb.Table(this, 'UsersTable', {
      tableName: `postii-users-${stage}`,
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      encryption: dynamodb.TableEncryption.AWS_MANAGED,
      pointInTimeRecovery: stage === 'prod',
      removalPolicy: stage === 'prod' ? cdk.RemovalPolicy.RETAIN : cdk.RemovalPolicy.DESTROY,
    });

    // Add GSIs for Users table
    this.usersTable.addGlobalSecondaryIndex({
      indexName: 'email-index',
      partitionKey: { name: 'email', type: dynamodb.AttributeType.STRING },
    });

    this.usersTable.addGlobalSecondaryIndex({
      indexName: 'username-index', 
      partitionKey: { name: 'username', type: dynamodb.AttributeType.STRING },
    });

    // Friendships Table
    this.friendshipsTable = new dynamodb.Table(this, 'FriendshipsTable', {
      tableName: `postii-friendships-${stage}`,
      partitionKey: { name: 'friendshipId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      encryption: dynamodb.TableEncryption.AWS_MANAGED,
      pointInTimeRecovery: stage === 'prod',
      removalPolicy: stage === 'prod' ? cdk.RemovalPolicy.RETAIN : cdk.RemovalPolicy.DESTROY,
    });

    // Add GSIs for Friendships table
    this.friendshipsTable.addGlobalSecondaryIndex({
      indexName: 'requester-index',
      partitionKey: { name: 'requesterId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'createdAt', type: dynamodb.AttributeType.STRING },
    });

    this.friendshipsTable.addGlobalSecondaryIndex({
      indexName: 'addressee-index',
      partitionKey: { name: 'addresseeId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'createdAt', type: dynamodb.AttributeType.STRING },
    });

    // Postcards Table
    this.postcardsTable = new dynamodb.Table(this, 'PostcardsTable', {
      tableName: `postii-postcards-${stage}`,
      partitionKey: { name: 'postcardId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      encryption: dynamodb.TableEncryption.AWS_MANAGED,
      pointInTimeRecovery: stage === 'prod',
      removalPolicy: stage === 'prod' ? cdk.RemovalPolicy.RETAIN : cdk.RemovalPolicy.DESTROY,
    });

    // Add GSIs for Postcards table
    this.postcardsTable.addGlobalSecondaryIndex({
      indexName: 'sender-sent-index',
      partitionKey: { name: 'senderPK', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'sentSK', type: dynamodb.AttributeType.STRING },
    });

    this.postcardsTable.addGlobalSecondaryIndex({
      indexName: 'recipient-received-index',
      partitionKey: { name: 'recipientPK', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'receivedSK', type: dynamodb.AttributeType.STRING },
    });
  }
}
```

### Storage Stack
**lib/storage-stack.ts**
```typescript
import * as cdk from 'aws-cdk-lib';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as cloudfront from 'aws-cdk-lib/aws-cloudfront';
import * as origins from 'aws-cdk-lib/aws-cloudfront-origins';
import { Construct } from 'constructs';

export interface StorageStackProps {
  stage: string;
}

export class StorageStack extends Construct {
  public readonly assetsBucket: s3.Bucket;
  public readonly distribution: cloudfront.Distribution;

  constructor(scope: Construct, id: string, props: StorageStackProps) {
    super(scope, id);

    const { stage } = props;

    // S3 Bucket for assets
    this.assetsBucket = new s3.Bucket(this, 'AssetsBucket', {
      bucketName: `postii-assets-${stage}-${cdk.Aws.ACCOUNT_ID}`,
      encryption: s3.BucketEncryption.S3_MANAGED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      versioned: stage === 'prod',
      lifecycleRules: [
        {
          id: 'delete-incomplete-uploads',
          abortIncompleteMultipartUploadAfter: cdk.Duration.days(7),
        },
      ],
      removalPolicy: stage === 'prod' ? cdk.RemovalPolicy.RETAIN : cdk.RemovalPolicy.DESTROY,
    });

    // CloudFront Distribution
    this.distribution = new cloudfront.Distribution(this, 'AssetsDistribution', {
      defaultBehavior: {
        origin: new origins.S3Origin(this.assetsBucket),
        allowedMethods: cloudfront.AllowedMethods.ALLOW_GET_HEAD,
        cachedMethods: cloudfront.CachedMethods.CACHE_GET_HEAD,
        cachePolicy: cloudfront.CachePolicy.CACHING_OPTIMIZED,
        viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
      },
      priceClass: stage === 'prod' ? cloudfront.PriceClass.PRICE_CLASS_ALL : cloudfront.PriceClass.PRICE_CLASS_100,
    });
  }
}
```

### Authentication Stack  
**lib/auth-stack.ts**
```typescript
import * as cdk from 'aws-cdk-lib';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import { Construct } from 'constructs';

export interface AuthStackProps {
  stage: string;
}

export class AuthStack extends Construct {
  public readonly userPool: cognito.UserPool;
  public readonly userPoolClient: cognito.UserPoolClient;

  constructor(scope: Construct, id: string, props: AuthStackProps) {
    super(scope, id);

    const { stage } = props;

    // Cognito User Pool
    this.userPool = new cognito.UserPool(this, 'UserPool', {
      userPoolName: `postii-users-${stage}`,
      signInAliases: { email: true, username: true },
      selfSignUpEnabled: true,
      userVerification: {
        emailSubject: 'Welcome to Postii!',
        emailBody: 'Hello {username}, your verification code is {####}',
        emailStyle: cognito.VerificationEmailStyle.CODE,
      },
      passwordPolicy: {
        minLength: 8,
        requireLowercase: true,
        requireUppercase: true,
        requireDigits: true,
        requireSymbols: false,
      },
      accountRecovery: cognito.AccountRecovery.EMAIL_ONLY,
      removalPolicy: stage === 'prod' ? cdk.RemovalPolicy.RETAIN : cdk.RemovalPolicy.DESTROY,
    });

    // User Pool Client
    this.userPoolClient = new cognito.UserPoolClient(this, 'UserPoolClient', {
      userPool: this.userPool,
      userPoolClientName: `postii-client-${stage}`,
      generateSecret: false, // Mobile apps don't use client secrets
      authFlows: {
        userPassword: true,
        userSrp: true,
      },
      oAuth: {
        flows: {
          authorizationCodeGrant: true,
        },
        scopes: [cognito.OAuthScope.OPENID, cognito.OAuthScope.EMAIL, cognito.OAuthScope.PROFILE],
      },
    });
  }
}
```

### API Stack
**lib/api-stack.ts**
```typescript
import * as cdk from 'aws-cdk-lib';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as s3 from 'aws-cdk-lib/aws-s3';
import { Construct } from 'constructs';

export interface ApiStackProps {
  stage: string;
  userPool: cognito.UserPool;
  usersTable: dynamodb.Table;
  friendshipsTable: dynamodb.Table;
  postcardsTable: dynamodb.Table;
  assetsBucket: s3.Bucket;
}

export class ApiStack extends Construct {
  public readonly api: apigateway.RestApi;

  constructor(scope: Construct, id: string, props: ApiStackProps) {
    super(scope, id);

    const { stage, userPool, usersTable, friendshipsTable, postcardsTable, assetsBucket } = props;

    // Create API Gateway
    this.api = new apigateway.RestApi(this, 'PostiiApi', {
      restApiName: `postii-api-${stage}`,
      description: `Postii API - ${stage}`,
      defaultCorsPreflightOptions: {
        allowOrigins: apigateway.Cors.ALL_ORIGINS,
        allowMethods: apigateway.Cors.ALL_METHODS,
        allowHeaders: ['Content-Type', 'Authorization'],
      },
    });

    // Cognito Authorizer
    const authorizer = new apigateway.CognitoUserPoolsAuthorizer(this, 'ApiAuthorizer', {
      cognitoUserPools: [userPool],
      identitySource: 'method.request.header.Authorization',
    });

    // Lambda execution role
    const lambdaRole = new iam.Role(this, 'LambdaExecutionRole', {
      assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSLambdaBasicExecutionRole'),
      ],
    });

    // Grant permissions to access DynamoDB tables
    usersTable.grantFullAccess(lambdaRole);
    friendshipsTable.grantFullAccess(lambdaRole);
    postcardsTable.grantFullAccess(lambdaRole);
    assetsBucket.grantReadWrite(lambdaRole);

    // Environment variables for all Lambdas
    const commonEnvironment = {
      USERS_TABLE: usersTable.tableName,
      FRIENDSHIPS_TABLE: friendshipsTable.tableName,
      POSTCARDS_TABLE: postcardsTable.tableName,
      ASSETS_BUCKET: assetsBucket.bucketName,
      STAGE: stage,
    };

    // Create Lambda functions
    const authHandler = new lambda.Function(this, 'AuthHandler', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('lambda/auth'),
      role: lambdaRole,
      environment: commonEnvironment,
    });

    const usersHandler = new lambda.Function(this, 'UsersHandler', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('lambda/users'),
      role: lambdaRole,
      environment: commonEnvironment,
    });

    const friendsHandler = new lambda.Function(this, 'FriendsHandler', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('lambda/friends'),
      role: lambdaRole,
      environment: commonEnvironment,
    });

    const postcardsHandler = new lambda.Function(this, 'PostcardsHandler', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('lambda/postcards'),
      role: lambdaRole,
      environment: commonEnvironment,
    });

    // API Routes
    const v1 = this.api.root.addResource('v1');

    // Auth routes (no authorization required)
    const auth = v1.addResource('auth');
    auth.addMethod('POST', new apigateway.LambdaIntegration(authHandler));
    auth.addResource('{proxy+}').addMethod('ANY', new apigateway.LambdaIntegration(authHandler));

    // Protected routes (require authorization)
    const users = v1.addResource('users');
    users.addMethod('ANY', new apigateway.LambdaIntegration(usersHandler), { authorizer });
    users.addResource('{proxy+}').addMethod('ANY', new apigateway.LambdaIntegration(usersHandler), { authorizer });

    const friends = v1.addResource('friends');
    friends.addMethod('ANY', new apigateway.LambdaIntegration(friendsHandler), { authorizer });
    friends.addResource('{proxy+}').addMethod('ANY', new apigateway.LambdaIntegration(friendsHandler), { authorizer });

    const postcards = v1.addResource('postcards');
    postcards.addMethod('ANY', new apigateway.LambdaIntegration(postcardsHandler), { authorizer });
    postcards.addResource('{proxy+}').addMethod('ANY', new apigateway.LambdaIntegration(postcardsHandler), { authorizer });
  }
}
```

---

## Deployment Instructions

### Initial Setup
```bash
# Bootstrap CDK (one-time setup per account/region)
cdk bootstrap

# Install dependencies
npm install

# Build TypeScript
npm run build
```

### Deploy to Development
```bash
# Deploy development stack
cdk deploy PostiiDev

# Deploy specific stack only
cdk deploy PostiiDev/Database
cdk deploy PostiiDev/Storage
cdk deploy PostiiDev/Auth
cdk deploy PostiiDev/Api
```

### Deploy to Production
```bash
# Deploy production stack
cdk deploy PostiiProd --require-approval never

# Deploy with specific parameters
cdk deploy PostiiProd \
  --parameters stage=prod \
  --require-approval never
```

### Useful CDK Commands
```bash
# Show differences between current and deployed stack
cdk diff PostiiDev

# Show CloudFormation template
cdk synth PostiiDev

# Destroy stack (be careful!)
cdk destroy PostiiDev

# List all stacks
cdk list

# View stack outputs
aws cloudformation describe-stacks \
  --stack-name PostiiDev \
  --query 'Stacks[0].Outputs'
```

---

## Environment Management

### Environment Configuration
**cdk.context.json**
```json
{
  "dev": {
    "region": "us-east-1",
    "account": "123456789012",
    "enablePointInTimeRecovery": false,
    "enableS3Versioning": false,
    "cloudFrontPriceClass": "PriceClass_100"
  },
  "prod": {
    "region": "us-east-1", 
    "account": "123456789012",
    "enablePointInTimeRecovery": true,
    "enableS3Versioning": true,
    "cloudFrontPriceClass": "PriceClass_All"
  }
}
```

### Environment Variables
```bash
# Set environment for deployment
export CDK_DEFAULT_ACCOUNT=123456789012
export CDK_DEFAULT_REGION=us-east-1
export STAGE=dev

# Deploy with environment
cdk deploy Postii${STAGE^}
```

### CI/CD Pipeline (GitHub Actions)
**.github/workflows/deploy.yml**
```yaml
name: Deploy Postii Infrastructure

on:
  push:
    branches: [main, develop]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
          
      - name: Deploy to dev
        if: github.ref == 'refs/heads/develop'
        run: |
          npm run build
          cdk deploy PostiiDev --require-approval never
          
      - name: Deploy to prod  
        if: github.ref == 'refs/heads/main'
        run: |
          npm run build
          cdk deploy PostiiProd --require-approval never
```

---

## Troubleshooting

### Common Issues

**CDK Bootstrap Required**
```bash
Error: Need to perform AWS CDK bootstrap
Solution: cdk bootstrap
```

**Permission Denied**
```bash
Error: AccessDenied: User is not authorized
Solution: Check AWS credentials and IAM permissions
```

**Resource Already Exists**
```bash
Error: Resource already exists
Solution: Import existing resource or use different name
```

**Lambda Code Asset Missing**
```bash
Error: Cannot find asset
Solution: Ensure lambda code exists in specified directory
```

### Debug Commands
```bash
# Enable verbose logging
cdk deploy --verbose

# Show CloudFormation events
aws cloudformation describe-stack-events --stack-name PostiiDev

# Check Lambda logs
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/Postii"

# Test API endpoint
curl -X GET https://your-api-id.execute-api.us-east-1.amazonaws.com/prod/v1/health
```

### Stack Cleanup
```bash
# Remove all resources (development only!)
cdk destroy PostiiDev --force

# Remove specific construct
cdk destroy PostiiDev/Database --force
```

---

## Next Steps

1. **Implement Lambda Functions**: Create the actual handler code in the `lambda/` directories
2. **Add Monitoring**: Implement CloudWatch alarms and dashboards
3. **Set up CI/CD**: Configure automated testing and deployment
4. **Add Security**: Implement WAF, VPC, and additional security measures
5. **Performance Testing**: Load test the deployed infrastructure

This CDK setup provides a solid foundation for deploying and managing your Postii backend infrastructure with proper separation of environments and best practices for AWS resource management.
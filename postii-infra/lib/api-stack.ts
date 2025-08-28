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
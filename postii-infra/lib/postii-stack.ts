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

    new cdk.CfnOutput(this, 'AssetsBucket', {
      value: storageStack.assetsBucket.bucketName,
      description: 'S3 Assets Bucket Name',
    });

    new cdk.CfnOutput(this, 'CloudFrontDistributionUrl', {
      value: storageStack.distribution.distributionDomainName,
      description: 'CloudFront Distribution URL',
    });
  }
}
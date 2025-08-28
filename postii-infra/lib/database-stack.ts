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
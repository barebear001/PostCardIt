#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { DatabaseStack } from '../lib/database-stack';
import { StorageStack } from '../lib/storage-stack';
import { AuthStack } from '../lib/auth-stack';
import { ApiStack } from '../lib/api-stack';

const app = new cdk.App();

// Development environment
const devEnv = {
  account: process.env.CDK_DEFAULT_ACCOUNT,
  region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
};

const devDatabaseStack = new DatabaseStack(app, 'PostiiDatabaseDev', {
  env: devEnv,
  stage: 'dev'
});

const devStorageStack = new StorageStack(app, 'PostiiStorageDev', {
  env: devEnv,
  stage: 'dev'
});

const devAuthStack = new AuthStack(app, 'PostiiAuthDev', {
  env: devEnv,
  stage: 'dev'
});

const devApiStack = new ApiStack(app, 'PostiiApiDev', {
  env: devEnv,
  stage: 'dev',
  userPool: devAuthStack.userPool,
  usersTable: devDatabaseStack.usersTable,
  friendshipsTable: devDatabaseStack.friendshipsTable,
  postcardsTable: devDatabaseStack.postcardsTable,
  assetsBucket: devStorageStack.assetsBucket,
});

// Add dependencies for proper deployment order
devApiStack.addDependency(devDatabaseStack);
devApiStack.addDependency(devStorageStack);
devApiStack.addDependency(devAuthStack);

// Production environment
const prodEnv = {
  account: "725214515251",
  region: 'us-west-2',
};

const prodDatabaseStack = new DatabaseStack(app, 'PostiiDatabaseProd', {
  env: prodEnv,
  stage: 'prod'
});

const prodStorageStack = new StorageStack(app, 'PostiiStorageProd', {
  env: prodEnv,
  stage: 'prod'
});

const prodAuthStack = new AuthStack(app, 'PostiiAuthProd', {
  env: prodEnv,
  stage: 'prod'
});

const prodApiStack = new ApiStack(app, 'PostiiApiProd', {
  env: prodEnv,
  stage: 'prod',
  userPool: prodAuthStack.userPool,
  usersTable: prodDatabaseStack.usersTable,
  friendshipsTable: prodDatabaseStack.friendshipsTable,
  postcardsTable: prodDatabaseStack.postcardsTable,
  assetsBucket: prodStorageStack.assetsBucket,
});

// Add dependencies for proper deployment order
prodApiStack.addDependency(prodDatabaseStack);
prodApiStack.addDependency(prodStorageStack);
prodApiStack.addDependency(prodAuthStack);
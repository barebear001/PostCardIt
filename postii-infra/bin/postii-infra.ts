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
    account: "725214515251",
    region: 'us-west-2',
  },
  stage: 'prod'
});
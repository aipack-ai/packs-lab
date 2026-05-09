# Infrastructure as Code (AWS CDK)

This document outlines the infrastructure standards for hosting sites using AWS CDK (Cloud Development Kit). The infrastructure is designed for high availability, security, and low-latency global distribution.

## Overview

The infrastructure uses a combination of S3 for storage, CloudFront as a Content Delivery Network (CDN), Route 53 for DNS, and AWS Certificate Manager (ACM) for SSL/TLS.

Standard placeholders used in this documentation:
- **Account ID**: `__AWS_ACCOUNT_NUMBER__`
- **Domain**: `example.com`
- **Stack/Bucket ID**: `site-example-com`

## Initial Project Setup

To set up the CDK environment, follow these steps. Running `cdk init` will generate the standard boilerplate, including `cdk.json` with recommended context flags.

```sh
# 1. Create the cdk directory
mkdir cdk
cd cdk

# 2. Initialize the CDK application
cdk init app --language typescript
```

### Root .gitignore Recommendations

Add the following to the project's root `.gitignore` to prevent committing generated CDK build artifacts.

```
# -- cdk
cdk/**/*.js
!jest.config.js
!cdk/cloudfront-functions/*.js
cdk/**/*.d.ts
```

After initialization, you will have a directory structure with `bin/`, `lib/`, and a `cdk.json` file. The `cdk.json` file will contain many `@aws-cdk/*` context flags; these are feature flags managed by the CDK CLI and do not need to be manually edited unless specific behavior overrides are required.

## Customization and Implementation

Replace the generated boilerplate files with the following standardized configurations. Ensure all placeholders (like `__WEBSITE_ID__`) are replaced with actual project values.

### 1. Update package.json

Ensure dependencies match the standardized versions.

```json
{
  "name": "cdk",
  "version": "0.1.0",
  "bin": {
    "cdk": "bin/cdk.js"
  },
  "scripts": {
    "build": "tsc",
    "watch": "tsc -w",
    "cdk": "cdk"
  },
  "devDependencies": {
    "@types/node": "22.7.9",
    "aws-cdk": "2.171.0",
    "ts-node": "^10.9.2",
    "typescript": "~5.6.3"
  },
  "dependencies": {
    "aws-cdk-lib": "2.171.0",
    "constructs": "^10.0.0"
  }
}
```

### 2. Update bin/cdk.ts

The entry point for the CDK application.

```typescript
#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import { CdkStack, STACK_ID } from '../lib/cdk-stack';

const app = new cdk.App();
new CdkStack(app, STACK_ID, {});
```

### 3. Create lib/config.ts

Define the project-specific constants in a central location.

```typescript
export const AWS_ACCOUNT_NUMBER = "__AWS_ACCOUNT_NUMBER__";
export const WEBSITE_ID = "__WEBSITE_ID__";
export const DOMAIN_NAME = "__DOMAIN_NAME__";
export const DEPLOY_USER = "__DEPLOY_USER__";
export const CDK_USER = "__CDK_USER__";
```

### 4. Update lib/cdk-stack.ts

The main stack definition containing the logic for S3, CloudFront, and DNS.

```typescript
import * as cdk from 'aws-cdk-lib';
import * as certificatemanager from 'aws-cdk-lib/aws-certificatemanager';
import * as cloudFront from 'aws-cdk-lib/aws-cloudfront';
import * as origins from 'aws-cdk-lib/aws-cloudfront-origins';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as route53Targets from 'aws-cdk-lib/aws-route53-targets';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as s3Deploy from 'aws-cdk-lib/aws-s3-deployment';
import { Construct } from 'constructs';
import { AWS_ACCOUNT_NUMBER, DEPLOY_USER, DOMAIN_NAME, WEBSITE_ID } from './config';

export const STACK_ID = `${WEBSITE_ID}-stack`;

export class CdkStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, {
      ...props, env: {
        account: AWS_ACCOUNT_NUMBER,
        region: 'us-east-1'
      }
    });

    const bucketName = WEBSITE_ID;
    
    // Create or import the bucket
    const siteBucket = s3.Bucket.fromBucketName(this, 'SiteBucket', bucketName);

    // Ensure the /site folder exists
    new s3Deploy.BucketDeployment(this, 'CreateSiteFolder', {
      sources: [s3Deploy.Source.data('site/.keep', '')],
      destinationBucket: siteBucket,
    });

    // Grant access to the deployment user
    const deployUser = iam.User.fromUserArn(this, 'DeployUser', `arn:aws:iam::${AWS_ACCOUNT_NUMBER}:user/${DEPLOY_USER}`);
    siteBucket.grantReadWrite(deployUser);

    const hostedZone = route53.HostedZone.fromLookup(this, 'HostedZone', {
      domainName: DOMAIN_NAME,
    });

    const certificate = new certificatemanager.Certificate(this, 'SiteCertificate', {
      domainName: DOMAIN_NAME,
      validation: certificatemanager.CertificateValidation.fromDns(hostedZone),
    });

    const cfFunction = new cloudFront.Function(this, 'CFFunctionSiteBase', {
      functionName: `${WEBSITE_ID}-uri-rewrite`,
      code: cloudFront.FunctionCode.fromFile({ filePath: 'cloudfront-functions/site_name_cf_function_01.js' }),
    });

    const distribution = new cloudFront.Distribution(this, 'SiteDistribution', {
      defaultBehavior: {
        functionAssociations: [{
          function: cfFunction,
          eventType: cloudFront.FunctionEventType.VIEWER_REQUEST,
        }],
        origin: origins.S3BucketOrigin.withOriginAccessControl(siteBucket, {
          originPath: '/site'
        }),
        viewerProtocolPolicy: cloudFront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
        cachePolicy: cloudFront.CachePolicy.CACHING_DISABLED,
      },
      domainNames: [DOMAIN_NAME],
      certificate,
      defaultRootObject: 'index.html',
      comment: `${WEBSITE_ID} distribution`,
    });

    new route53.ARecord(this, 'SiteAliasRecord', {
      zone: hostedZone,
      target: route53.RecordTarget.fromAlias(new route53Targets.CloudFrontTarget(distribution)),
    });
  }
}
```

### 5. Create cloudfront-functions/site_name_cf_function_01.js

The edge logic for handling clean URLs.

```javascript
function handler(event) {
    var request = event.request;
    var uri = request.uri;

    if (uri.endsWith('/')) {
        request.uri += 'index.html';
    }
    else if (uri.trim().length > 0 && !uri.includes(".")) {
        request.uri = uri + ".html";
    }
    return request;
}
```

## Operational Commands

### CDK Lifecycle

Standard commands for managing the infrastructure stack.

```sh
# Initial setup (one-time per account/region)
cdk bootstrap --profile __CDK_USER__

# Generate CloudFormation template
cdk synth

# Deploy the infrastructure
cdk deploy --profile __CDK_USER__
```

### Manual Deployment (S3 Sync)

While `ssite publish` is the primary tool, manual synchronization can be performed using `ss3` (or AWS CLI) with specific flags to ensure correct content headers.

```sh
# Sync full site to S3 prefix
# --noext-ct "text/html" ensures that extensionless files (clean URLs) are served as HTML
ss3 --profile __DEPLOY_USER__ cp _site/ s3://__WEBSITE_ID__/site -r --over etag --noext-ct "text/html" --region us-east-1
```

## External Integrations

### Substack Custom Domain

If integrating a Substack blog under a subdomain (e.g., `news.example.com`):

- **Subdomain**: `news.__DOMAIN_NAME__`
- **CNAME**: `news` pointing to `target.substack-custom-domains.com`

## Security and IAM

### CloudFront Origin Access Control (OAC) Policy

The following S3 bucket policy allows the CloudFront distribution to securely access content while keeping the bucket private.

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudfront.amazonaws.com"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::__WEBSITE_ID__/*",
            "Condition": {
                "StringEquals": {
                    "AWS:SourceArn": "arn:aws:cloudfront::__AWS_ACCOUNT_ID__:distribution/__CLOUDFRONT_DIST_ID__"
                }
            }
        }
    ]
}
```

## Workflow Summary

1. **Infrastructure**: Deploy the stack using `cdk deploy --profile __CDK_USER__`.
2. **Configuration**: Ensure `ssite.toml` matches the `__WEBSITE_ID__` and AWS profile.
3. **Local Development**: Use `ssite dev` to run the build orchestrator and local server.
4. **Publishing**: Use `ssite publish` for automated deployment, or the `ss3` command for manual syncs.

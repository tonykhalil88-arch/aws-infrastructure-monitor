\# AWS Infrastructure Monitor



A production-grade AWS infrastructure monitoring system built with Terraform, 

Lambda, and GitHub Actions CI/CD. Built as a portfolio project to demonstrate 

real-world cloud engineering skills.



\## Architecture Overview



The system follows an event-driven serverless architecture:



\- \*\*GitHub Actions\*\* triggers on every push to main

\- \*\*Terraform\*\* provisions all infrastructure automatically  

\- \*\*EventBridge\*\* runs the Lambda monitor every hour

\- \*\*Lambda\*\* checks CloudWatch metrics and writes to DynamoDB

\- \*\*SNS\*\* sends email alerts if issues are detected

\- \*\*CloudWatch\*\* watches your AWS bill 24/7



\## What It Does



\- Monitors AWS infrastructure and CloudWatch metrics every hour automatically

\- Stores all monitoring results in DynamoDB with automatic TTL expiry

\- Sends email alerts via SNS if any issues are detected

\- Triggers a billing alarm if AWS costs exceed $10 USD

\- Deploys automatically via GitHub Actions on every push to main



\## Tech Stack



| Technology | Purpose |

|---|---|

| Terraform | Infrastructure as Code — provisions all AWS resources |

| AWS Lambda | Serverless monitoring function (Python 3.12) |

| Amazon DynamoDB | Metrics storage with TTL auto-expiry |

| Amazon SNS | Email alerting system |

| Amazon CloudWatch | Metrics monitoring and billing alarm |

| Amazon EventBridge | Hourly scheduling of Lambda function |

| Amazon S3 | Terraform remote state storage |

| GitHub Actions | CI/CD pipeline — auto deploys on push to main |

| IAM | Least privilege security for all resources |



\## AWS Services Used



`Lambda` `DynamoDB` `SNS` `CloudWatch` `EventBridge` `S3` `IAM` `API Gateway`



\## Architecture Decisions



\### Why Terraform?

All infrastructure is defined as code — reproducible, version controlled, 

and deployable with a single command. No manual clicking in the AWS console.



\### Why S3 Backend?

Terraform state is stored in S3 so both local development and the GitHub 

Actions CI/CD pipeline share the same state. This prevents resource conflicts 

and enables team collaboration.



\### Why DynamoDB PAY\_PER\_REQUEST?

The monitoring function runs hourly — PAY\_PER\_REQUEST means we only pay for 

actual reads and writes, not provisioned capacity sitting idle. Cost optimised 

by design.



\### Why IAM Least Privilege?

The Lambda execution role only has permissions for exactly what it needs:

\- CloudWatch read access

\- DynamoDB write access to the specific metrics table

\- SNS publish access to the specific alerts topic

\- CloudWatch Logs write access



Nothing more. Nothing less.



\## CI/CD Pipeline



Every push to `main` triggers the GitHub Actions pipeline:



1\. Checkout code

2\. Configure AWS credentials from GitHub Secrets

3\. Terraform init with S3 backend

4\. Terraform format check

5\. Terraform validate

6\. Terraform plan

7\. Terraform apply (main branch only)



\## Project Structure

```

aws-infrastructure-monitor/

├── .github/

│   └── workflows/

│       └── deploy.yml        # GitHub Actions CI/CD pipeline

├── lambda/

│   └── monitor.py            # Python monitoring function

├── terraform/

│   ├── main.tf               # All AWS resources

│   ├── variables.tf          # Input variables

│   ├── outputs.tf            # Output values

│   └── terraform.tfvars      # Variable values

└── README.md

```



\## Infrastructure Deployed



\- \*\*SNS Topic\*\* — aws-monitor-alerts-dev

\- \*\*CloudWatch Billing Alarm\*\* — triggers at $10 USD

\- \*\*DynamoDB Table\*\* — aws-monitor-metrics-dev

\- \*\*IAM Role + Policy\*\* — least privilege Lambda execution

\- \*\*Lambda Function\*\* — aws-monitor-monitor-dev (Python 3.12)

\- \*\*EventBridge Rule\*\* — runs every hour

\- \*\*S3 Bucket\*\* — Terraform remote state



\## Author



\*\*Tony Khalil\*\*

\- AWS Certified Cloud Practitioner (March 2026)

\- AWS Solutions Architect Associate (In Progress)

\- GitHub: \[tonykhalil88-arch](https://github.com/tonykhalil88-arch)

\- LinkedIn: \[tony-khalil](https://www.linkedin.com/in/tony-khalil-a6390a3b5)


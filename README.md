# AI Infrastructure Monitor

AI-powered AWS infrastructure monitoring stack built with **CloudFormation**, **AWS Lambda**, and a **local HTML dashboard**.  
Designed to deploy quickly, analyze logs, send alerts via SNS, and optionally expose a public endpoint for live metrics.

---

## Features
- **One-command deploy** using `deploy.sh`
- CloudFormation template for reproducible AWS setup
- Lambda function for log analysis (OpenAI API optional)
- SNS email alerts for issues
- CloudWatch dashboard for metrics
- Local HTML dashboard (`dashboard.html`) for quick viewing
- Optional Lambda Function URL for public API access

---

## Requirements
- AWS CLI v2 installed & configured (`aws configure`)
- AWS account with permissions for:
  - Lambda
  - CloudFormation
  - SNS
  - CloudWatch
- `zip` utility (Linux/macOS) or `Compress-Archive` (Windows)
- (Optional) OpenAI API key for AI-driven analysis

---

## Deployment

1. **Clone the repo**
   ```bash
   git clone https://github.com/<your-username>/ai-infra-monitor.git
   cd ai-infra-monitor
Hapyy coding ;)

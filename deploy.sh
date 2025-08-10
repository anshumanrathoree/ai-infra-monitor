

#!/bin/bash

# AI Infrastructure Monitor - Deployment Script
set -e

echo "íº€ AI Infrastructure Monitor Deployment Script"
echo "=============================================="

# Configuration
STACK_NAME="ai-infra-monitor"
REGION="us-east-1"
PROFILE="default"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity --profile $PROFILE &> /dev/null; then
        print_error "AWS credentials not configured for profile: $PROFILE"
        print_status "Run: aws configure --profile $PROFILE"
        exit 1
    fi
    
    # Check required files
    for file in "cloudformation.yaml" "lambda_function.py" "dashboard.html"; do
        if [ ! -f "$file" ]; then
            print_error "Required file missing: $file"
            exit 1
        fi
    done
    
    print_success "Prerequisites check passed!"
}

# Function to get user inputs
get_user_inputs() {
    print_status "Gathering deployment configuration..."
    
    # Get notification email
    read -p "Enter your email for alerts (default: admin@example.com): " EMAIL
    EMAIL=${EMAIL:-admin@example.com}
    
    # Get OpenAI API key
    read -s -p "Enter your OpenAI API Key (press enter to skip): " OPENAI_KEY
    echo
    
    if [ -z "$OPENAI_KEY" ]; then
        print_warning "No OpenAI API key provided. AI analysis will be limited."
        OPENAI_KEY=""
    fi
    
    # Confirm region
    read -p "AWS Region (default: $REGION): " INPUT_REGION
    REGION=${INPUT_REGION:-$REGION}
    
    print_success "Configuration gathered!"
    echo "  - Email: $EMAIL"
    echo "  - Region: $REGION"
    echo "  - OpenAI Key: $([ -n "$OPENAI_KEY" ] && echo "Provided" || echo "Not provided")"
}

# Function to create deployment package
create_deployment_package() {
    print_status "Creating Lambda deployment package..."
    
    # Create temp directory for packaging
    TEMP_DIR=$(mktemp -d)
    cp lambda_function.py $TEMP_DIR/
    cd $TEMP_DIR
    
    # Create deployment zip
    zip -r ../lambda-deployment.zip .
    cd - > /dev/null
    mv $TEMP_DIR/../lambda-deployment.zip ./
    
    print_success "Lambda deployment package created!"
}

# Function to deploy CloudFormation stack
deploy_stack() {
    print_status "Deploying CloudFormation stack..."
    
    # Deploy the stack
    aws cloudformation deploy \
        --template-file cloudformation.yaml \
        --stack-name $STACK_NAME \
        --parameter-overrides \
            OpenAIAPIKey="$OPENAI_KEY" \
            NotificationEmail="$EMAIL" \
        --capabilities CAPABILITY_NAMED_IAM \
        --region $REGION \
        --profile $PROFILE
    
    if [ $? -eq 0 ]; then
        print_success "CloudFormation stack deployed successfully!"
    else
        print_error "Failed to deploy CloudFormation stack"
        exit 1
    fi
}

# Function to update Lambda function code
update_lambda_code() {
    print_status "Updating Lambda function code..."
    
    # Wait a moment for Lambda to be ready
    sleep 10
    
    aws lambda update-function-code \
        --function-name ai-infra-monitor \
        --zip-file fileb://lambda-deployment.zip \
        --region $REGION \
        --profile $PROFILE
    
    if [ $? -eq 0 ]; then
        print_success "Lambda function code updated!"
    else
        print_warning "Lambda function code update failed - this is normal for first deployment"
    fi
}

# Function to get stack outputs
get_stack_outputs() {
    print_status "Retrieving deployment information..."
    
    print_success "Deployment completed successfully!"
    echo
    echo "í³Š AWS Console Links:"
    echo "   - CloudWatch: https://${REGION}.console.aws.amazon.com/cloudwatch/home?region=${REGION}"
    echo "   - Lambda: https://${REGION}.console.aws.amazon.com/lambda/home?region=${REGION}#/functions/ai-infra-monitor"
    echo "   - SNS: https://${REGION}.console.aws.amazon.com/sns/v3/home?region=${REGION}"
    echo
    echo "í³ Local files:"
    echo "   - Web Dashboard: $(pwd)/dashboard.html"
}

# Function to test the deployment
test_deployment() {
    print_status "Testing deployment..."
    
    # Test Lambda function
    aws lambda invoke \
        --function-name ai-infra-monitor \
        --payload '{}' \
        --region $REGION \
        --profile $PROFILE \
        test-output.json > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        print_success "Lambda function test completed!"
        if [ -f test-output.json ]; then
            echo "Test result:"
            cat test-output.json
            rm test-output.json
        fi
    else
        print_warning "Lambda function test failed - may need a few minutes to initialize"
    fi
}

# Function to cleanup
cleanup() {
    print_status "Cleaning up temporary files..."
    rm -f lambda-deployment.zip
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf $TEMP_DIR
    fi
}

# Main execution
main() {
    echo
    print_status "Starting deployment process..."
    
    check_prerequisites
    get_user_inputs
    create_deployment_package
    deploy_stack
    update_lambda_code
    get_stack_outputs
    test_deployment
    cleanup
    
    print_success "í¾‰ AI Infrastructure Monitor deployed successfully!"
    echo
    echo "Next steps:"
    echo "1. Check your email for SNS subscription confirmation"
    echo "2. Visit CloudWatch to see your dashboard"
    echo "3. Open dashboard.html in your browser"
    echo "4. Monitor Lambda logs for any issues"
    echo
    echo "The system will analyze logs every 15 minutes automatically!"
}

# Handle script interruption
trap cleanup EXIT

# Run main function
main

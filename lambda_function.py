import json
import boto3
import os
from datetime import datetime, timedelta

# Initialize AWS clients
cloudwatch = boto3.client('cloudwatch')
logs_client = boto3.client('logs')
sns = boto3.client('sns')

def lambda_handler(event, context):
    """
    Main Lambda function to analyze infrastructure logs using AI
    """
    try:
        print("Starting log analysis...")
        
        # Get logs from CloudWatch
        log_data = fetch_recent_logs()
        
        if not log_data:
            print("No recent logs to analyze")
            return create_response(200, "No recent logs to analyze")
        
        print(f"Found {len(log_data)} log entries")
        
        # Analyze logs (simplified version for demo)
        analysis_result = analyze_logs_simple(log_data)
        
        # Store metrics in CloudWatch
        store_metrics(analysis_result)
        
        print("Analysis completed successfully")
        
        return create_response(200, {
            "message": "Log analysis completed",
            "logs_analyzed": len(log_data),
            "analysis": analysis_result
        })
        
    except Exception as e:
        print(f"Error in lambda_handler: {str(e)}")
        return create_response(500, f"Error: {str(e)}")

def fetch_recent_logs():
    """
    Fetch recent logs from CloudWatch Logs
    """
    try:
        log_groups = [
            '/aws/lambda/ai-infra-monitor'
        ]
        
        all_logs = []
        end_time = datetime.now()
        start_time = end_time - timedelta(minutes=30)
        
        for log_group in log_groups:
            try:
                response = logs_client.filter_log_events(
                    logGroupName=log_group,
                    startTime=int(start_time.timestamp() * 1000),
                    endTime=int(end_time.timestamp() * 1000),
                    limit=50
                )
                
                for event in response.get('events', []):
                    all_logs.append({
                        'timestamp': event['timestamp'],
                        'message': event['message'],
                        'log_group': log_group
                    })
            except Exception as e:
                print(f"Could not fetch logs from {log_group}: {e}")
                continue
        
        return all_logs[-30:]
        
    except Exception as e:
        print(f"Error fetching logs: {e}")
        return []

def analyze_logs_simple(log_data):
    """
    Simple log analysis (can be enhanced with AI later)
    """
    error_count = 0
    warning_count = 0
    issues = []
    
    for log in log_data:
        message = log['message'].lower()
        if any(word in message for word in ['error', 'exception', 'failed', 'critical']):
            error_count += 1
        elif any(word in message for word in ['warning', 'warn', 'deprecated']):
            warning_count += 1
    
    # Determine severity
    if error_count > 5:
        severity = "high"
        issues.append(f"High error count detected: {error_count} errors")
    elif error_count > 2:
        severity = "medium"  
        issues.append(f"Moderate error count: {error_count} errors")
    elif warning_count > 10:
        severity = "medium"
        issues.append(f"Many warnings detected: {warning_count} warnings")
    else:
        severity = "low"
    
    recommendations = []
    if error_count > 0:
        recommendations.append("Review error logs for root cause analysis")
    if warning_count > 5:
        recommendations.append("Address warning conditions to prevent issues")
    if not recommendations:
        recommendations.append("Continue monitoring - system appears stable")
    
    return {
        "severity": severity,
        "issues_found": issues,
        "recommendations": recommendations,
        "summary": f"Analyzed {len(log_data)} logs: {error_count} errors, {warning_count} warnings"
    }

def store_metrics(analysis):
    """
    Store analysis metrics in CloudWatch
    """
    try:
        severity_map = {'low': 1, 'medium': 2, 'high': 3, 'critical': 4}
        severity_value = severity_map.get(analysis.get('severity', 'low'), 1)
        issues_count = len(analysis.get('issues_found', []))
        
        cloudwatch.put_metric_data(
            Namespace='Infrastructure/AI-Monitor',
            MetricData=[
                {
                    'MetricName': 'SeverityLevel',
                    'Value': severity_value,
                    'Unit': 'None'
                },
                {
                    'MetricName': 'IssuesFound',
                    'Value': issues_count,
                    'Unit': 'Count'
                }
            ]
        )
        
        print(f"Metrics stored: Severity={severity_value}, Issues={issues_count}")
        
    except Exception as e:
        print(f"Failed to store metrics: {e}")

def create_response(status_code, body):
    """
    Create Lambda response
    """
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(body) if isinstance(body, dict) else str(body)
    }

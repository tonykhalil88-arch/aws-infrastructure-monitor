import json
import boto3
import os
from datetime import datetime, timezone
import uuid

dynamodb = boto3.resource('dynamodb')
sns = boto3.client('sns')
cloudwatch = boto3.client('cloudwatch')

TABLE_NAME = os.environ['DYNAMODB_TABLE']
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']

def lambda_handler(event, context):
    print(f"Monitor triggered at {datetime.now(timezone.utc).isoformat()}")
    
    results = []
    
    # Check 1 — Record this execution to DynamoDB
    table = dynamodb.Table(TABLE_NAME)
    metric_id = str(uuid.uuid4())
    timestamp = datetime.now(timezone.utc).isoformat()
    
    item = {
        'MetricId': metric_id,
        'Timestamp': timestamp,
        'EventType': 'MonitorRun',
        'Source': 'aws-infrastructure-monitor',
        'Status': 'OK'
    }
    
    # Check 2 — Get CloudWatch metrics
    try:
        cw = boto3.client('cloudwatch')
        response = cw.list_metrics(
            Namespace='AWS/Lambda',
            MetricName='Invocations'
        )
        metric_count = len(response.get('Metrics', []))
        item['LambdaMetricsCount'] = metric_count
        item['Status'] = 'OK'
        results.append(f"CloudWatch check passed — {metric_count} Lambda metrics found")
        print(f"CloudWatch check passed — {metric_count} metrics found")
    except Exception as e:
        item['Status'] = 'ERROR'
        item['Error'] = str(e)
        results.append(f"CloudWatch check failed: {str(e)}")
        print(f"CloudWatch check failed: {str(e)}")

    # Write to DynamoDB
    try:
        table.put_item(Item=item)
        results.append("Metrics written to DynamoDB successfully")
        print("Metrics written to DynamoDB")
    except Exception as e:
        results.append(f"DynamoDB write failed: {str(e)}")
        print(f"DynamoDB write failed: {str(e)}")

    # Check 3 — Send SNS notification if there are errors
    if item['Status'] == 'ERROR':
        try:
            sns.publish(
                TopicArn=SNS_TOPIC_ARN,
                Subject='AWS Monitor Alert — Error Detected',
                Message=f"Monitor detected an issue at {timestamp}\n\nDetails:\n" + 
                        "\n".join(results)
            )
            print("Alert sent via SNS")
        except Exception as e:
            print(f"SNS publish failed: {str(e)}")

    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Monitor run complete',
            'timestamp': timestamp,
            'results': results,
            'status': item['Status']
        })
    }
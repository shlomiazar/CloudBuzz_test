# future import division
import boto3
import json
 
def SHLOMI(event, context):
    number1 = int(event['queryStringParameters']['Number1'])
    number2 = int(event['queryStringParameters']['Number2'])
    summ = number1 + number2
    
    client = boto3.client('sns')
    snsArn = 'arn:aws:sns:us-east-1:194180725215:testss'
    message = str(summ)
    
    try:
        response = client.publish(
         TopicArn=snsArn,
         Message=message,
         Subject="this is a test message!"
        )
    
        return {
          'statusCode': 200,
          'headers': {'Content-Type': 'application/json'},
          'body': json.dumps(message)  
        }
    except: 
        return {
          'statusCode': 200,
          'headers': {'Content-Type': 'application/json'},
          'body': json.dumps('Something error!')  
        }


def lambda_handler(event, context):
    print ("start")
    return SHLOMI(event, context)

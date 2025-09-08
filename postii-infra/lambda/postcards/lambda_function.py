import json
import logging
import boto3
import uuid
import os
from datetime import datetime, timezone
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource('dynamodb')
s3_client = boto3.client('s3')

def lambda_handler(event, context):
    """
    Postii Postcards handler - handles sending and viewing postcards
    """
    logger.info(f'Postcards handler called: {json.dumps(event)}')
    
    try:
        # Get environment variables
        postcards_table_name = os.environ.get('POSTCARDS_TABLE')
        assets_bucket = os.environ.get('ASSETS_BUCKET')
        
        if not postcards_table_name or not assets_bucket:
            return error_response(500, 'Missing environment variables')
        
        postcards_table = dynamodb.Table(postcards_table_name)
        
        # Parse request
        http_method = event.get('httpMethod')
        path = event.get('path', '').split('/')
        resource_path = event.get('resource', '')
        
        # Extract user ID from Cognito claims
        request_context = event.get('requestContext', {})
        authorizer = request_context.get('authorizer', {})
        claims = authorizer.get('claims', {})
        user_id = claims.get('sub')
        
        if not user_id:
            return error_response(401, 'User not authenticated')
        
        # Route requests
        if http_method == 'POST' and '/postcards' in resource_path:
            return send_postcard(postcards_table, event, user_id, assets_bucket)
        elif http_method == 'GET' and '/postcards/sent' in resource_path:
            return get_sent_postcards(postcards_table, user_id, event)
        elif http_method == 'GET' and '/postcards/received' in resource_path:
            return get_received_postcards(postcards_table, user_id, event)
        elif http_method == 'GET' and '/postcards' in resource_path:
            # Default to received postcards
            return get_received_postcards(postcards_table, user_id, event)
        else:
            return error_response(404, 'Endpoint not found')
            
    except Exception as e:
        logger.error(f'Error in postcards handler: {str(e)}')
        return error_response(500, 'Internal server error')

def send_postcard(table, event, sender_id, assets_bucket):
    """Send a postcard to a recipient"""
    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        
        recipient_id = body.get('recipientId')
        image_url = body.get('imageUrl')  # URL to image in S3
        message = body.get('message', '')
        location = body.get('location', {})  # Optional location data
        
        # Validate required fields
        if not recipient_id or not image_url:
            return error_response(400, 'recipientId and imageUrl are required')
        
        # Generate postcard ID
        postcard_id = str(uuid.uuid4())
        current_time = datetime.now(timezone.utc)
        timestamp = current_time.isoformat()
        
        # Create postcard item
        postcard_item = {
            'postcardId': postcard_id,
            'senderId': sender_id,
            'recipientId': recipient_id,
            'imageUrl': image_url,
            'message': message,
            'location': location,
            'sentAt': timestamp,
            'status': 'sent',
            'createdAt': timestamp,
            'updatedAt': timestamp,
            # GSI attributes for efficient querying
            'senderPK': f'USER#{sender_id}',
            'sentSK': f'SENT#{timestamp}#{postcard_id}',
            'recipientPK': f'USER#{recipient_id}',
            'receivedSK': f'RECEIVED#{timestamp}#{postcard_id}'
        }
        
        # Save to DynamoDB
        table.put_item(Item=postcard_item)
        
        logger.info(f'Postcard {postcard_id} sent from {sender_id} to {recipient_id}')
        
        return success_response({
            'postcardId': postcard_id,
            'status': 'sent',
            'sentAt': timestamp,
            'message': 'Postcard sent successfully'
        })
        
    except json.JSONDecodeError:
        return error_response(400, 'Invalid JSON in request body')
    except Exception as e:
        logger.error(f'Error sending postcard: {str(e)}')
        return error_response(500, 'Failed to send postcard')

def get_sent_postcards(table, user_id, event):
    """Get postcards sent by the user"""
    try:
        # Get query parameters
        query_params = event.get('queryStringParameters') or {}
        limit = int(query_params.get('limit', 20))
        last_evaluated_key = query_params.get('lastKey')
        
        # Query using sender GSI
        query_params = {
            'IndexName': 'sender-sent-index',
            'KeyConditionExpression': 'senderPK = :sender_pk',
            'ExpressionAttributeValues': {
                ':sender_pk': f'USER#{user_id}'
            },
            'ScanIndexForward': False,  # Most recent first
            'Limit': min(limit, 100)  # Cap at 100
        }
        
        if last_evaluated_key:
            try:
                query_params['ExclusiveStartKey'] = json.loads(last_evaluated_key)
            except json.JSONDecodeError:
                return error_response(400, 'Invalid lastKey parameter')
        
        response = table.query(**query_params)
        
        # Format postcards for response
        postcards = []
        for item in response.get('Items', []):
            postcards.append(format_postcard(item))
        
        result = {
            'postcards': postcards,
            'count': len(postcards)
        }
        
        # Include pagination token if there are more results
        if 'LastEvaluatedKey' in response:
            result['lastKey'] = json.dumps(response['LastEvaluatedKey'])
        
        return success_response(result)
        
    except Exception as e:
        logger.error(f'Error getting sent postcards: {str(e)}')
        return error_response(500, 'Failed to retrieve sent postcards')

def get_received_postcards(table, user_id, event):
    """Get postcards received by the user"""
    try:
        # Get query parameters
        query_params = event.get('queryStringParameters') or {}
        limit = int(query_params.get('limit', 20))
        last_evaluated_key = query_params.get('lastKey')
        
        # Query using recipient GSI
        query_params = {
            'IndexName': 'recipient-received-index',
            'KeyConditionExpression': 'recipientPK = :recipient_pk',
            'ExpressionAttributeValues': {
                ':recipient_pk': f'USER#{user_id}'
            },
            'ScanIndexForward': False,  # Most recent first
            'Limit': min(limit, 100)  # Cap at 100
        }
        
        if last_evaluated_key:
            try:
                query_params['ExclusiveStartKey'] = json.loads(last_evaluated_key)
            except json.JSONDecodeError:
                return error_response(400, 'Invalid lastKey parameter')
        
        response = table.query(**query_params)
        
        # Format postcards for response
        postcards = []
        for item in response.get('Items', []):
            postcards.append(format_postcard(item))
        
        result = {
            'postcards': postcards,
            'count': len(postcards)
        }
        
        # Include pagination token if there are more results
        if 'LastEvaluatedKey' in response:
            result['lastKey'] = json.dumps(response['LastEvaluatedKey'])
        
        return success_response(result)
        
    except Exception as e:
        logger.error(f'Error getting received postcards: {str(e)}')
        return error_response(500, 'Failed to retrieve received postcards')

def format_postcard(item):
    """Format postcard item for API response"""
    return {
        'postcardId': item.get('postcardId'),
        'senderId': item.get('senderId'),
        'recipientId': item.get('recipientId'),
        'imageUrl': item.get('imageUrl'),
        'message': item.get('message', ''),
        'location': item.get('location', {}),
        'sentAt': item.get('sentAt'),
        'status': item.get('status'),
        'createdAt': item.get('createdAt'),
        'updatedAt': item.get('updatedAt')
    }

def success_response(data, status_code=200):
    """Return successful API response"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        },
        'body': json.dumps(data)
    }

def error_response(status_code, message):
    """Return error API response"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        },
        'body': json.dumps({
            'error': message,
            'statusCode': status_code
        })
    }
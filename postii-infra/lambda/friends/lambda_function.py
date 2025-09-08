import json
import boto3
import logging
import os
import uuid
from datetime import datetime
from boto3.dynamodb.conditions import Key, Attr

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')

def lambda_handler(event, context):
    """
    Postii Friends Lambda Handler
    
    Handles friend-related operations:
    1. Send friend request
    2. Accept friend request  
    3. Search for friends
    """
    
    try:
        # Get environment variables
        users_table_name = os.environ.get('USERS_TABLE')
        friendships_table_name = os.environ.get('FRIENDSHIPS_TABLE')
        
        if not users_table_name or not friendships_table_name:
            logger.error("Missing required environment variables")
            return create_response(500, {'error': 'Configuration error'})
            
        users_table = dynamodb.Table(users_table_name)
        friendships_table = dynamodb.Table(friendships_table_name)
        
        # Extract route information
        http_method = event.get('httpMethod', '')
        path = event.get('path', '')
        path_parameters = event.get('pathParameters') or {}
        query_parameters = event.get('queryStringParameters') or {}
        
        # Parse request body if present
        body = {}
        if event.get('body'):
            try:
                body = json.loads(event['body'])
            except json.JSONDecodeError:
                return create_response(400, {'error': 'Invalid JSON in request body'})
        
        # Extract user ID from Cognito claims
        claims = event.get('requestContext', {}).get('authorizer', {}).get('claims', {})
        current_user_id = claims.get('sub')
        
        if not current_user_id:
            return create_response(401, {'error': 'Unauthorized - missing user ID'})
            
        logger.info(f'Processing {http_method} request for user {current_user_id}')
        
        # Route to appropriate handler based on path and method
        if 'send-request' in path and http_method == 'POST':
            return handle_send_friend_request(friendships_table, users_table, current_user_id, body)
        elif 'accept-request' in path and http_method == 'POST':
            return handle_accept_friend_request(friendships_table, current_user_id, body)
        elif 'search' in path and http_method == 'GET':
            return handle_search_friends(users_table, current_user_id, query_parameters)
        elif http_method == 'GET':
            return handle_get_friends(friendships_table, current_user_id, query_parameters)
        else:
            return create_response(404, {'error': 'Endpoint not found'})
            
    except Exception as e:
        logger.error(f'Unexpected error: {str(e)}', exc_info=True)
        return create_response(500, {'error': 'Internal server error'})


def handle_send_friend_request(friendships_table, users_table, requester_id, body):
    """Send a friend request to another user"""
    
    try:
        # Validate input
        addressee_username = body.get('username')
        if not addressee_username:
            return create_response(400, {'error': 'Username is required'})
            
        # Find the addressee user by username
        response = users_table.query(
            IndexName='username-index',
            KeyConditionExpression=Key('username').eq(addressee_username)
        )
        
        if not response['Items']:
            return create_response(404, {'error': 'User not found'})
            
        addressee_user = response['Items'][0]
        addressee_id = addressee_user['userId']
        
        # Check if user is trying to send request to themselves
        if requester_id == addressee_id:
            return create_response(400, {'error': 'Cannot send friend request to yourself'})
            
        # Check if friendship already exists
        existing_friendship = check_existing_friendship(friendships_table, requester_id, addressee_id)
        if existing_friendship:
            status = existing_friendship.get('status')
            if status == 'accepted':
                return create_response(409, {'error': 'Already friends'})
            elif status == 'pending':
                return create_response(409, {'error': 'Friend request already sent'})
                
        # Create friend request
        friendship_id = str(uuid.uuid4())
        current_time = datetime.utcnow().isoformat()
        
        friendship_item = {
            'friendshipId': friendship_id,
            'requesterId': requester_id,
            'addresseeId': addressee_id,
            'status': 'pending',
            'createdAt': current_time,
            'updatedAt': current_time
        }
        
        friendships_table.put_item(Item=friendship_item)
        
        logger.info(f'Friend request sent from {requester_id} to {addressee_id}')
        
        return create_response(201, {
            'message': 'Friend request sent successfully',
            'friendshipId': friendship_id,
            'status': 'pending'
        })
        
    except Exception as e:
        logger.error(f'Error sending friend request: {str(e)}')
        return create_response(500, {'error': 'Failed to send friend request'})


def handle_accept_friend_request(friendships_table, current_user_id, body):
    """Accept a friend request"""
    
    try:
        # Validate input
        friendship_id = body.get('friendshipId')
        if not friendship_id:
            return create_response(400, {'error': 'Friendship ID is required'})
            
        # Get the friendship record
        response = friendships_table.get_item(
            Key={'friendshipId': friendship_id}
        )
        
        if 'Item' not in response:
            return create_response(404, {'error': 'Friend request not found'})
            
        friendship = response['Item']
        
        # Verify the current user is the addressee
        if friendship['addresseeId'] != current_user_id:
            return create_response(403, {'error': 'Unauthorized to accept this friend request'})
            
        # Check if already accepted
        if friendship['status'] == 'accepted':
            return create_response(409, {'error': 'Friend request already accepted'})
            
        # Check if the request is still pending
        if friendship['status'] != 'pending':
            return create_response(400, {'error': 'Friend request is no longer pending'})
            
        # Update the friendship status
        current_time = datetime.utcnow().isoformat()
        
        friendships_table.update_item(
            Key={'friendshipId': friendship_id},
            UpdateExpression='SET #status = :status, updatedAt = :updated',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={
                ':status': 'accepted',
                ':updated': current_time
            }
        )
        
        logger.info(f'Friend request {friendship_id} accepted by {current_user_id}')
        
        return create_response(200, {
            'message': 'Friend request accepted successfully',
            'friendshipId': friendship_id,
            'status': 'accepted'
        })
        
    except Exception as e:
        logger.error(f'Error accepting friend request: {str(e)}')
        return create_response(500, {'error': 'Failed to accept friend request'})


def handle_search_friends(users_table, current_user_id, query_parameters):
    """Search for users by username or email"""
    
    try:
        # Get search query
        query = query_parameters.get('q', '').strip()
        if not query:
            return create_response(400, {'error': 'Search query is required'})
            
        if len(query) < 2:
            return create_response(400, {'error': 'Search query must be at least 2 characters'})
            
        # Search by username (using begins_with for partial matches)
        username_results = []
        try:
            response = users_table.scan(
                FilterExpression=Attr('username').contains(query),
                ProjectionExpression='userId, username, email, #name',
                ExpressionAttributeNames={'#name': 'name'}
            )
            username_results = response.get('Items', [])
        except Exception as e:
            logger.error(f'Error searching usernames: {str(e)}')
            
        # Search by email (using begins_with for partial matches)  
        email_results = []
        try:
            response = users_table.scan(
                FilterExpression=Attr('email').contains(query),
                ProjectionExpression='userId, username, email, #name',
                ExpressionAttributeNames={'#name': 'name'}
            )
            email_results = response.get('Items', [])
        except Exception as e:
            logger.error(f'Error searching emails: {str(e)}')
            
        # Combine results and remove duplicates
        all_results = username_results + email_results
        unique_results = {}
        
        for user in all_results:
            user_id = user['userId']
            # Don't include the current user in search results
            if user_id != current_user_id:
                unique_results[user_id] = {
                    'userId': user_id,
                    'username': user.get('username', ''),
                    'email': user.get('email', ''),
                    'name': user.get('name', ''),
                }
        
        results_list = list(unique_results.values())
        
        # Limit results to prevent large responses
        max_results = int(query_parameters.get('limit', 20))
        results_list = results_list[:max_results]
        
        logger.info(f'Search for "{query}" returned {len(results_list)} results')
        
        return create_response(200, {
            'query': query,
            'results': results_list,
            'count': len(results_list)
        })
        
    except Exception as e:
        logger.error(f'Error searching for friends: {str(e)}')
        return create_response(500, {'error': 'Failed to search for friends'})


def handle_get_friends(friendships_table, current_user_id, query_parameters):
    """Get user's friends and friend requests"""
    
    try:
        # Get friends where user is the requester
        sent_requests = friendships_table.query(
            IndexName='requester-index',
            KeyConditionExpression=Key('requesterId').eq(current_user_id)
        ).get('Items', [])
        
        # Get friends where user is the addressee
        received_requests = friendships_table.query(
            IndexName='addressee-index', 
            KeyConditionExpression=Key('addresseeId').eq(current_user_id)
        ).get('Items', [])
        
        # Categorize friendships
        friends = []
        pending_sent = []
        pending_received = []
        
        for friendship in sent_requests:
            if friendship['status'] == 'accepted':
                friends.append({
                    'friendshipId': friendship['friendshipId'],
                    'friendId': friendship['addresseeId'],
                    'status': 'accepted',
                    'createdAt': friendship['createdAt']
                })
            elif friendship['status'] == 'pending':
                pending_sent.append({
                    'friendshipId': friendship['friendshipId'],
                    'userId': friendship['addresseeId'],
                    'status': 'pending',
                    'createdAt': friendship['createdAt']
                })
                
        for friendship in received_requests:
            if friendship['status'] == 'accepted':
                friends.append({
                    'friendshipId': friendship['friendshipId'],
                    'friendId': friendship['requesterId'],
                    'status': 'accepted',
                    'createdAt': friendship['createdAt']
                })
            elif friendship['status'] == 'pending':
                pending_received.append({
                    'friendshipId': friendship['friendshipId'],
                    'userId': friendship['requesterId'],
                    'status': 'pending',
                    'createdAt': friendship['createdAt']
                })
        
        logger.info(f'Retrieved friends for user {current_user_id}: {len(friends)} friends, {len(pending_sent)} sent, {len(pending_received)} received')
        
        return create_response(200, {
            'friends': friends,
            'pendingSent': pending_sent,
            'pendingReceived': pending_received,
            'counts': {
                'friends': len(friends),
                'pendingSent': len(pending_sent),
                'pendingReceived': len(pending_received)
            }
        })
        
    except Exception as e:
        logger.error(f'Error getting friends: {str(e)}')
        return create_response(500, {'error': 'Failed to get friends'})


def check_existing_friendship(friendships_table, user_id_1, user_id_2):
    """Check if friendship exists between two users"""
    
    try:
        # Check if user_id_1 sent request to user_id_2
        response = friendships_table.query(
            IndexName='requester-index',
            KeyConditionExpression=Key('requesterId').eq(user_id_1),
            FilterExpression=Attr('addresseeId').eq(user_id_2)
        )
        
        if response['Items']:
            return response['Items'][0]
            
        # Check if user_id_2 sent request to user_id_1
        response = friendships_table.query(
            IndexName='requester-index',
            KeyConditionExpression=Key('requesterId').eq(user_id_2),
            FilterExpression=Attr('addresseeId').eq(user_id_1)
        )
        
        if response['Items']:
            return response['Items'][0]
            
        return None
        
    except Exception as e:
        logger.error(f'Error checking existing friendship: {str(e)}')
        return None


def create_response(status_code, body):
    """Create a standardized HTTP response"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        },
        'body': json.dumps(body, default=str)
    }
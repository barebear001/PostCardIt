import json
import logging
import boto3
import os
from datetime import datetime, timezone
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource('dynamodb')
s3_client = boto3.client('s3')

def lambda_handler(event, context):
    """
    Postii Users handler - handles user profile management
    """
    logger.info(f'Users handler called: {json.dumps(event)}')
    
    try:
        # Get environment variables
        users_table_name = os.environ.get('USERS_TABLE')
        assets_bucket = os.environ.get('ASSETS_BUCKET')
        
        if not users_table_name:
            return error_response(500, 'Missing environment variables')
        
        users_table = dynamodb.Table(users_table_name)
        
        # Parse request
        http_method = event.get('httpMethod')
        resource_path = event.get('resource', '')
        path_parameters = event.get('pathParameters') or {}
        
        # Extract user ID from Cognito claims
        request_context = event.get('requestContext', {})
        authorizer = request_context.get('authorizer', {})
        claims = authorizer.get('claims', {})
        authenticated_user_id = claims.get('sub')
        
        if not authenticated_user_id:
            return error_response(401, 'User not authenticated')
        
        # Route requests
        if http_method == 'GET' and resource_path == '/v1/users':
            # Get current user's profile
            return get_user_profile(users_table, authenticated_user_id)
        elif http_method == 'GET' and resource_path == '/v1/users/{userId}':
            # Get specific user by ID
            target_user_id = path_parameters.get('userId')
            return get_user_by_id(users_table, target_user_id, authenticated_user_id)
        elif http_method == 'PUT' and resource_path == '/v1/users':
            # Update current user's profile
            return update_user_profile(users_table, event, authenticated_user_id, assets_bucket)
        elif http_method == 'POST' and resource_path == '/v1/users':
            # Create/initialize user profile
            return create_user_profile(users_table, event, authenticated_user_id, assets_bucket)
        elif http_method == 'GET' and resource_path == '/v1/users/search':
            # Search users by username or email
            return search_users(users_table, event, authenticated_user_id)
        else:
            return error_response(404, 'Endpoint not found')
            
    except Exception as e:
        logger.error(f'Error in users handler: {str(e)}')
        return error_response(500, 'Internal server error')

def get_user_profile(table, user_id):
    """Get the authenticated user's profile"""
    try:
        response = table.get_item(Key={'userId': user_id})
        
        if 'Item' not in response:
            return error_response(404, 'User profile not found')
        
        user_profile = format_user_profile(response['Item'], is_self=True)
        return success_response(user_profile)
        
    except Exception as e:
        logger.error(f'Error getting user profile: {str(e)}')
        return error_response(500, 'Failed to retrieve user profile')

def get_user_by_id(table, target_user_id, authenticated_user_id):
    """Get a specific user's profile by ID"""
    try:
        if not target_user_id:
            return error_response(400, 'User ID is required')
        
        response = table.get_item(Key={'userId': target_user_id})
        
        if 'Item' not in response:
            return error_response(404, 'User not found')
        
        # Check if viewing own profile or another user's profile
        is_self = target_user_id == authenticated_user_id
        user_profile = format_user_profile(response['Item'], is_self=is_self)
        
        return success_response(user_profile)
        
    except Exception as e:
        logger.error(f'Error getting user by ID: {str(e)}')
        return error_response(500, 'Failed to retrieve user')

def create_user_profile(table, event, user_id, assets_bucket):
    """Create or initialize a user profile"""
    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        
        username = body.get('username', '').strip()
        email = body.get('email', '').strip()
        full_name = body.get('fullName', '').strip()
        bio = body.get('bio', '').strip()
        profile_picture_url = body.get('profilePictureUrl', '')
        
        # Validate required fields
        if not username or not email:
            return error_response(400, 'username and email are required')
        
        # Check if user already exists
        try:
            existing_user = table.get_item(Key={'userId': user_id})
            if 'Item' in existing_user:
                return error_response(409, 'User profile already exists')
        except Exception:
            pass
        
        # Check if username is already taken
        try:
            username_response = table.query(
                IndexName='username-index',
                KeyConditionExpression='username = :username',
                ExpressionAttributeValues={':username': username}
            )
            if username_response.get('Items'):
                return error_response(409, 'Username already taken')
        except Exception as e:
            logger.error(f'Error checking username: {str(e)}')
            return error_response(500, 'Failed to validate username')
        
        # Check if email is already taken
        try:
            email_response = table.query(
                IndexName='email-index',
                KeyConditionExpression='email = :email',
                ExpressionAttributeValues={':email': email}
            )
            if email_response.get('Items'):
                return error_response(409, 'Email already registered')
        except Exception as e:
            logger.error(f'Error checking email: {str(e)}')
            return error_response(500, 'Failed to validate email')
        
        current_time = datetime.now(timezone.utc).isoformat()
        
        # Create user profile
        user_item = {
            'userId': user_id,
            'username': username,
            'email': email,
            'fullName': full_name,
            'bio': bio,
            'profilePictureUrl': profile_picture_url,
            'isActive': True,
            'createdAt': current_time,
            'updatedAt': current_time,
            'postcardsCount': 0,
            'friendsCount': 0
        }
        
        table.put_item(Item=user_item)
        
        logger.info(f'User profile created for user {user_id}')
        
        return success_response({
            'userId': user_id,
            'username': username,
            'email': email,
            'fullName': full_name,
            'bio': bio,
            'profilePictureUrl': profile_picture_url,
            'createdAt': current_time,
            'message': 'User profile created successfully'
        })
        
    except json.JSONDecodeError:
        return error_response(400, 'Invalid JSON in request body')
    except Exception as e:
        logger.error(f'Error creating user profile: {str(e)}')
        return error_response(500, 'Failed to create user profile')

def update_user_profile(table, event, user_id, assets_bucket):
    """Update the user's profile"""
    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        
        # Get current user profile
        response = table.get_item(Key={'userId': user_id})
        if 'Item' not in response:
            return error_response(404, 'User profile not found')
        
        current_user = response['Item']
        
        # Fields that can be updated
        updatable_fields = {
            'fullName': body.get('fullName'),
            'bio': body.get('bio'),
            'profilePictureUrl': body.get('profilePictureUrl'),
            'username': body.get('username')
        }
        
        # Remove None values
        updatable_fields = {k: v for k, v in updatable_fields.items() if v is not None}
        
        if not updatable_fields:
            return error_response(400, 'No valid fields to update')
        
        # If updating username, check if it's already taken
        if 'username' in updatable_fields and updatable_fields['username'] != current_user.get('username'):
            try:
                username_response = table.query(
                    IndexName='username-index',
                    KeyConditionExpression='username = :username',
                    ExpressionAttributeValues={':username': updatable_fields['username']}
                )
                if username_response.get('Items'):
                    return error_response(409, 'Username already taken')
            except Exception as e:
                logger.error(f'Error checking username: {str(e)}')
                return error_response(500, 'Failed to validate username')
        
        # Build update expression
        update_expression = "SET updatedAt = :updated_at"
        expression_attribute_values = {
            ':updated_at': datetime.now(timezone.utc).isoformat()
        }
        
        for field, value in updatable_fields.items():
            if isinstance(value, str):
                value = value.strip()
            update_expression += f", {field} = :{field}"
            expression_attribute_values[f':{field}'] = value
        
        # Update user profile
        table.update_item(
            Key={'userId': user_id},
            UpdateExpression=update_expression,
            ExpressionAttributeValues=expression_attribute_values
        )
        
        # Get updated user profile
        updated_response = table.get_item(Key={'userId': user_id})
        updated_user = format_user_profile(updated_response['Item'], is_self=True)
        
        logger.info(f'User profile updated for user {user_id}')
        
        return success_response({
            **updated_user,
            'message': 'Profile updated successfully'
        })
        
    except json.JSONDecodeError:
        return error_response(400, 'Invalid JSON in request body')
    except Exception as e:
        logger.error(f'Error updating user profile: {str(e)}')
        return error_response(500, 'Failed to update user profile')

def search_users(table, event, authenticated_user_id):
    """Search users by username or email"""
    try:
        query_params = event.get('queryStringParameters') or {}
        search_term = query_params.get('q', '').strip()
        search_type = query_params.get('type', 'username')  # 'username' or 'email'
        limit = min(int(query_params.get('limit', 10)), 50)  # Cap at 50
        
        if not search_term:
            return error_response(400, 'Search term is required')
        
        if search_type not in ['username', 'email']:
            return error_response(400, 'Search type must be "username" or "email"')
        
        # Search using appropriate GSI
        index_name = f'{search_type}-index'
        
        response = table.query(
            IndexName=index_name,
            KeyConditionExpression=f'{search_type} = :search_term',
            ExpressionAttributeValues={
                ':search_term': search_term
            },
            Limit=limit
        )
        
        # Format results
        users = []
        for item in response.get('Items', []):
            # Don't include the searching user in results
            if item.get('userId') != authenticated_user_id:
                users.append(format_user_profile(item, is_self=False))
        
        return success_response({
            'users': users,
            'count': len(users),
            'searchTerm': search_term,
            'searchType': search_type
        })
        
    except ValueError:
        return error_response(400, 'Invalid limit parameter')
    except Exception as e:
        logger.error(f'Error searching users: {str(e)}')
        return error_response(500, 'Failed to search users')

def format_user_profile(item, is_self=False):
    """Format user profile for API response"""
    base_profile = {
        'userId': item.get('userId'),
        'username': item.get('username'),
        'fullName': item.get('fullName', ''),
        'bio': item.get('bio', ''),
        'profilePictureUrl': item.get('profilePictureUrl', ''),
        'isActive': item.get('isActive', True),
        'createdAt': item.get('createdAt'),
        'postcardsCount': item.get('postcardsCount', 0),
        'friendsCount': item.get('friendsCount', 0)
    }
    
    # Include sensitive information only for the user's own profile
    if is_self:
        base_profile.update({
            'email': item.get('email'),
            'updatedAt': item.get('updatedAt')
        })
    
    return base_profile

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
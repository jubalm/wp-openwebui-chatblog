"""
WordPress REST API Client for OpenWebUI Pipeline
Handles WordPress API operations using stored Application Passwords
"""

import asyncio
import logging
from typing import Optional, Dict, Any, List
from datetime import datetime
import httpx
import base64
from urllib.parse import urljoin

from wordpress_oauth import pipeline as oauth_pipeline


class WordPressAPIClient:
    """WordPress REST API Client with Application Password authentication"""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.timeout = 30
    
    async def get_credentials(self, user_id: str, connection_id: str) -> Optional[Dict[str, Any]]:
        """Get WordPress credentials for a user connection"""
        return await oauth_pipeline.get_wordpress_credentials(user_id, connection_id)
    
    async def make_request(self, method: str, endpoint: str, credentials: Dict[str, Any], data: Optional[Dict] = None) -> Dict[str, Any]:
        """Make authenticated request to WordPress REST API"""
        try:
            site_url = credentials['site_url'].rstrip('/')
            api_url = urljoin(site_url, f'/wp-json/wp/v2/{endpoint.lstrip("/")}')
            
            # Create Basic Auth header with Application Password
            # WordPress expects: username:application_password
            # We'll extract username from the site or use a default approach
            username = await self._get_wordpress_username(credentials)
            auth_string = f"{username}:{credentials['application_password']}"
            auth_bytes = auth_string.encode('ascii')
            auth_header = base64.b64encode(auth_bytes).decode('ascii')
            
            headers = {
                'Authorization': f'Basic {auth_header}',
                'Content-Type': 'application/json',
                'User-Agent': 'OpenWebUI-WordPress-Connector/1.0'
            }
            
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                if method.upper() == 'GET':
                    response = await client.get(api_url, headers=headers, params=data)
                elif method.upper() == 'POST':
                    response = await client.post(api_url, headers=headers, json=data)
                elif method.upper() == 'PUT':
                    response = await client.put(api_url, headers=headers, json=data)
                elif method.upper() == 'DELETE':
                    response = await client.delete(api_url, headers=headers)
                else:
                    raise ValueError(f"Unsupported HTTP method: {method}")
                
                if response.status_code in [200, 201]:
                    return {
                        'success': True,
                        'data': response.json(),
                        'status_code': response.status_code
                    }
                else:
                    error_data = {}
                    try:
                        error_data = response.json()
                    except:
                        error_data = {'message': response.text}
                    
                    return {
                        'success': False,
                        'error': error_data,
                        'status_code': response.status_code,
                        'message': error_data.get('message', f'HTTP {response.status_code}')
                    }
                    
        except Exception as e:
            self.logger.error(f"WordPress API request failed: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'message': f'Request failed: {str(e)}'
            }
    
    async def _get_wordpress_username(self, credentials: Dict[str, Any]) -> str:
        """Get WordPress username for the application password"""
        # Try to get current user info from WordPress
        try:
            site_url = credentials['site_url'].rstrip('/')
            users_url = urljoin(site_url, '/wp-json/wp/v2/users/me')
            
            # For now, we'll use 'admin' as default username
            # In a production setup, this should be configurable or retrieved
            return 'admin'
            
        except Exception as e:
            self.logger.warning(f"Could not determine WordPress username: {str(e)}")
            return 'admin'
    
    async def get_posts(self, user_id: str, connection_id: str, params: Optional[Dict] = None) -> Dict[str, Any]:
        """Get WordPress posts"""
        credentials = await self.get_credentials(user_id, connection_id)
        if not credentials:
            return {'success': False, 'message': 'No credentials found'}
        
        query_params = {
            'per_page': 10,
            'orderby': 'date',
            'order': 'desc',
            'status': 'publish'
        }
        
        if params:
            query_params.update(params)
        
        return await self.make_request('GET', 'posts', credentials, query_params)
    
    async def get_post(self, user_id: str, connection_id: str, post_id: int) -> Dict[str, Any]:
        """Get a specific WordPress post"""
        credentials = await self.get_credentials(user_id, connection_id)
        if not credentials:
            return {'success': False, 'message': 'No credentials found'}
        
        return await self.make_request('GET', f'posts/{post_id}', credentials)
    
    async def create_post(self, user_id: str, connection_id: str, post_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new WordPress post"""
        credentials = await self.get_credentials(user_id, connection_id)
        if not credentials:
            return {'success': False, 'message': 'No credentials found'}
        
        # Sanitize and validate post data
        clean_data = {
            'title': post_data.get('title', ''),
            'content': post_data.get('content', ''),
            'excerpt': post_data.get('excerpt', ''),
            'status': post_data.get('status', 'draft'),
            'slug': post_data.get('slug', ''),
            'categories': post_data.get('categories', []),
            'tags': post_data.get('tags', [])
        }
        
        # Remove empty fields
        clean_data = {k: v for k, v in clean_data.items() if v}
        
        return await self.make_request('POST', 'posts', credentials, clean_data)
    
    async def update_post(self, user_id: str, connection_id: str, post_id: int, post_data: Dict[str, Any]) -> Dict[str, Any]:
        """Update an existing WordPress post"""
        credentials = await self.get_credentials(user_id, connection_id)
        if not credentials:
            return {'success': False, 'message': 'No credentials found'}
        
        # Sanitize and validate post data
        clean_data = {}
        allowed_fields = ['title', 'content', 'excerpt', 'status', 'slug', 'categories', 'tags']
        
        for field in allowed_fields:
            if field in post_data:
                clean_data[field] = post_data[field]
        
        return await self.make_request('PUT', f'posts/{post_id}', credentials, clean_data)
    
    async def delete_post(self, user_id: str, connection_id: str, post_id: int, force: bool = False) -> Dict[str, Any]:
        """Delete a WordPress post"""
        credentials = await self.get_credentials(user_id, connection_id)
        if not credentials:
            return {'success': False, 'message': 'No credentials found'}
        
        params = {'force': force} if force else {}
        return await self.make_request('DELETE', f'posts/{post_id}', credentials, params)
    
    async def get_categories(self, user_id: str, connection_id: str) -> Dict[str, Any]:
        """Get WordPress categories"""
        credentials = await self.get_credentials(user_id, connection_id)
        if not credentials:
            return {'success': False, 'message': 'No credentials found'}
        
        return await self.make_request('GET', 'categories', credentials)
    
    async def get_tags(self, user_id: str, connection_id: str) -> Dict[str, Any]:
        """Get WordPress tags"""
        credentials = await self.get_credentials(user_id, connection_id)
        if not credentials:
            return {'success': False, 'message': 'No credentials found'}
        
        return await self.make_request('GET', 'tags', credentials)
    
    async def get_pages(self, user_id: str, connection_id: str, params: Optional[Dict] = None) -> Dict[str, Any]:
        """Get WordPress pages"""
        credentials = await self.get_credentials(user_id, connection_id)
        if not credentials:
            return {'success': False, 'message': 'No credentials found'}
        
        query_params = {
            'per_page': 10,
            'orderby': 'date',
            'order': 'desc',
            'status': 'publish'
        }
        
        if params:
            query_params.update(params)
        
        return await self.make_request('GET', 'pages', credentials, query_params)
    
    async def create_page(self, user_id: str, connection_id: str, page_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new WordPress page"""
        credentials = await self.get_credentials(user_id, connection_id)
        if not credentials:
            return {'success': False, 'message': 'No credentials found'}
        
        # Sanitize and validate page data
        clean_data = {
            'title': page_data.get('title', ''),
            'content': page_data.get('content', ''),
            'excerpt': page_data.get('excerpt', ''),
            'status': page_data.get('status', 'draft'),
            'slug': page_data.get('slug', ''),
            'parent': page_data.get('parent', 0)
        }
        
        # Remove empty fields
        clean_data = {k: v for k, v in clean_data.items() if v}
        
        return await self.make_request('POST', 'pages', credentials, clean_data)
    
    async def search_content(self, user_id: str, connection_id: str, query: str, content_type: str = 'post') -> Dict[str, Any]:
        """Search WordPress content"""
        credentials = await self.get_credentials(user_id, connection_id)
        if not credentials:
            return {'success': False, 'message': 'No credentials found'}
        
        endpoint = 'posts' if content_type == 'post' else 'pages'
        params = {
            'search': query,
            'per_page': 20,
            'orderby': 'relevance'
        }
        
        return await self.make_request('GET', endpoint, credentials, params)
    
    async def get_site_info(self, user_id: str, connection_id: str) -> Dict[str, Any]:
        """Get WordPress site information"""
        credentials = await self.get_credentials(user_id, connection_id)
        if not credentials:
            return {'success': False, 'message': 'No credentials found'}
        
        # Get site info from the root endpoint
        try:
            site_url = credentials['site_url'].rstrip('/')
            api_url = urljoin(site_url, '/wp-json/')
            
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(api_url)
                
                if response.status_code == 200:
                    data = response.json()
                    return {
                        'success': True,
                        'data': {
                            'name': data.get('name', ''),
                            'description': data.get('description', ''),
                            'url': data.get('url', ''),
                            'home': data.get('home', ''),
                            'gmt_offset': data.get('gmt_offset', 0),
                            'timezone_string': data.get('timezone_string', ''),
                            'namespaces': data.get('namespaces', []),
                            'site_logo': data.get('site_logo', 0),
                            'site_icon': data.get('site_icon', 0)
                        }
                    }
                else:
                    return {
                        'success': False,
                        'message': f'Failed to get site info: HTTP {response.status_code}'
                    }
                    
        except Exception as e:
            self.logger.error(f"Failed to get WordPress site info: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'message': f'Failed to get site info: {str(e)}'
            }
    
    async def test_connection(self, user_id: str, connection_id: str) -> Dict[str, Any]:
        """Test WordPress API connection"""
        credentials = await self.get_credentials(user_id, connection_id)
        if not credentials:
            return {'success': False, 'message': 'No credentials found'}
        
        # Test by getting site info
        result = await self.get_site_info(user_id, connection_id)
        
        if result['success']:
            return {
                'success': True,
                'message': 'WordPress connection test successful',
                'site_info': result['data']
            }
        else:
            return {
                'success': False,
                'message': f'WordPress connection test failed: {result.get("message", "Unknown error")}'
            }


# Initialize WordPress API client
wordpress_client = WordPressAPIClient()
"""
WordPress OAuth2 Pipeline for OpenWebUI
Handles secure WordPress Application Password storage and retrieval
"""

import os
import json
import logging
import asyncio
from typing import Optional, Dict, Any, List
from datetime import datetime, timedelta
from cryptography.fernet import Fernet
import httpx
import sqlite3
from pathlib import Path

from pydantic import BaseModel, Field
from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware


class Pipeline:
    """WordPress OAuth2 Pipeline for OpenWebUI integration"""
    
    def __init__(self):
        self.name = "WordPress OAuth2 Pipeline"
        self.description = "Handles secure WordPress Application Password storage and OAuth2 flow"
        self.version = "1.0.0"
        
        # Initialize encryption key
        self.encryption_key = self._get_encryption_key()
        self.cipher_suite = Fernet(self.encryption_key)
        
        # Initialize database
        self.db_path = Path("/app/data/wordpress_connections.db")
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self._init_database()
        
        # Configure logging
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
        
        # Authentik configuration
        self.authentik_url = os.getenv("AUTHENTIK_URL", "https://auth.example.com")
        self.authentik_client_id = os.getenv("AUTHENTIK_CLIENT_ID")
        self.authentik_client_secret = os.getenv("AUTHENTIK_CLIENT_SECRET")
        
    def _get_encryption_key(self) -> bytes:
        """Get or generate encryption key for storing passwords"""
        key_env = os.getenv("WORDPRESS_ENCRYPTION_KEY")
        if key_env:
            return key_env.encode()
        
        # Generate new key if not provided
        key = Fernet.generate_key()
        self.logger.warning(f"Generated new encryption key. Set WORDPRESS_ENCRYPTION_KEY={key.decode()}")
        return key
    
    def _init_database(self):
        """Initialize SQLite database for storing WordPress connections"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS wordpress_connections (
                    id TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    site_url TEXT NOT NULL,
                    site_name TEXT NOT NULL,
                    encrypted_token TEXT NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    last_used TIMESTAMP,
                    is_active BOOLEAN DEFAULT 1
                )
            """)
            conn.commit()
    
    async def verify_authentik_token(self, token: str) -> Optional[Dict[str, Any]]:
        """Verify token with Authentik and return user info"""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{self.authentik_url}/application/o/userinfo/",
                    headers={"Authorization": f"Bearer {token}"}
                )
                
                if response.status_code == 200:
                    return response.json()
                else:
                    self.logger.error(f"Authentik token verification failed: {response.status_code}")
                    return None
        except Exception as e:
            self.logger.error(f"Error verifying Authentik token: {str(e)}")
            return None
    
    async def register_wordpress_connection(self, user_info: Dict[str, Any], connection_data: Dict[str, Any]) -> Dict[str, Any]:
        """Register a new WordPress connection for the user"""
        try:
            # Encrypt the application password
            encrypted_password = self.cipher_suite.encrypt(
                connection_data["application_password"].encode()
            ).decode()
            
            # Generate connection ID
            connection_id = f"wp_{user_info['sub']}_{hash(connection_data['site_url'])}"
            
            # Store in database
            with sqlite3.connect(self.db_path) as conn:
                conn.execute("""
                    INSERT OR REPLACE INTO wordpress_connections 
                    (id, user_id, site_url, site_name, encrypted_token, created_at, is_active)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                """, (
                    connection_id,
                    user_info["sub"],
                    connection_data["site_url"],
                    connection_data.get("site_name", "WordPress Site"),
                    encrypted_password,
                    datetime.utcnow().isoformat(),
                    True
                ))
                conn.commit()
            
            self.logger.info(f"Registered WordPress connection for user {user_info['sub']}")
            
            return {
                "success": True,
                "connection_id": connection_id,
                "message": "WordPress connection registered successfully"
            }
            
        except Exception as e:
            self.logger.error(f"Error registering WordPress connection: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to register WordPress connection"
            )
    
    async def get_wordpress_connections(self, user_id: str) -> List[Dict[str, Any]]:
        """Get all WordPress connections for a user"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.execute("""
                    SELECT id, site_url, site_name, created_at, last_used, is_active
                    FROM wordpress_connections
                    WHERE user_id = ? AND is_active = 1
                """, (user_id,))
                
                connections = []
                for row in cursor.fetchall():
                    connections.append({
                        "id": row[0],
                        "site_url": row[1],
                        "site_name": row[2],
                        "created_at": row[3],
                        "last_used": row[4],
                        "is_active": bool(row[5])
                    })
                
                return connections
                
        except Exception as e:
            self.logger.error(f"Error getting WordPress connections: {str(e)}")
            return []
    
    async def get_wordpress_credentials(self, user_id: str, connection_id: str) -> Optional[Dict[str, Any]]:
        """Get decrypted WordPress credentials for API calls"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.execute("""
                    SELECT site_url, encrypted_token
                    FROM wordpress_connections
                    WHERE id = ? AND user_id = ? AND is_active = 1
                """, (connection_id, user_id))
                
                row = cursor.fetchone()
                if not row:
                    return None
                
                # Decrypt the password
                decrypted_password = self.cipher_suite.decrypt(
                    row[1].encode()
                ).decode()
                
                # Update last_used timestamp
                conn.execute("""
                    UPDATE wordpress_connections
                    SET last_used = ?
                    WHERE id = ?
                """, (datetime.utcnow().isoformat(), connection_id))
                conn.commit()
                
                return {
                    "site_url": row[0],
                    "application_password": decrypted_password
                }
                
        except Exception as e:
            self.logger.error(f"Error getting WordPress credentials: {str(e)}")
            return None
    
    async def delete_wordpress_connection(self, user_id: str, connection_id: str) -> bool:
        """Delete a WordPress connection"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.execute("""
                    UPDATE wordpress_connections
                    SET is_active = 0
                    WHERE id = ? AND user_id = ?
                """, (connection_id, user_id))
                
                return cursor.rowcount > 0
                
        except Exception as e:
            self.logger.error(f"Error deleting WordPress connection: {str(e)}")
            return False


# Pydantic models for API requests
class WordPressConnectionRequest(BaseModel):
    site_url: str = Field(..., description="WordPress site URL")
    site_name: str = Field("WordPress Site", description="Display name for the site")
    application_password: str = Field(..., description="WordPress Application Password")


class WordPressConnectionResponse(BaseModel):
    success: bool
    connection_id: str
    message: str


class WordPressConnectionsResponse(BaseModel):
    connections: List[Dict[str, Any]]


# Initialize pipeline
pipeline = Pipeline()

# FastAPI app for custom endpoints
app = FastAPI(title="WordPress OAuth2 Pipeline", version="1.0.0")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)

# Security
security = HTTPBearer()


async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Get current user from Authentik token"""
    user_info = await pipeline.verify_authentik_token(credentials.credentials)
    if not user_info:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return user_info


@app.post("/api/wordpress/register-connection", response_model=WordPressConnectionResponse)
async def register_connection(
    connection_request: WordPressConnectionRequest,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """Register a new WordPress connection"""
    return await pipeline.register_wordpress_connection(
        current_user, 
        connection_request.dict()
    )


@app.get("/api/wordpress/connections", response_model=WordPressConnectionsResponse)
async def get_connections(
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """Get all WordPress connections for the current user"""
    connections = await pipeline.get_wordpress_connections(current_user["sub"])
    return WordPressConnectionsResponse(connections=connections)


@app.delete("/api/wordpress/connections/{connection_id}")
async def delete_connection(
    connection_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """Delete a WordPress connection"""
    success = await pipeline.delete_wordpress_connection(current_user["sub"], connection_id)
    if success:
        return {"success": True, "message": "Connection deleted successfully"}
    else:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Connection not found"
        )


@app.get("/api/wordpress/credentials/{connection_id}")
async def get_credentials(
    connection_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """Get WordPress credentials for API calls (internal use only)"""
    credentials = await pipeline.get_wordpress_credentials(current_user["sub"], connection_id)
    if credentials:
        return credentials
    else:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Connection not found"
        )


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "pipeline": pipeline.name, "version": pipeline.version}


# Required OpenWebUI Pipeline methods
async def on_startup():
    """Called when the pipeline starts"""
    global wordpress_client
    # Import here to avoid circular imports
    from wordpress_client import WordPressAPIClient
    wordpress_client = WordPressAPIClient()
    pipeline.logger.info(f"Starting {pipeline.name} v{pipeline.version}")
    return pipeline


async def on_shutdown():
    """Called when the pipeline shuts down"""
    pipeline.logger.info(f"Shutting down {pipeline.name}")


# Import WordPress API client  
# Note: Import moved here to avoid circular import issues
wordpress_client = None

# Add WordPress API endpoints
@app.get("/api/wordpress/posts")
async def get_posts(
    connection_id: str,
    per_page: int = 10,
    page: int = 1,
    status: str = "publish",
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """Get WordPress posts"""
    params = {
        'per_page': per_page,
        'page': page,
        'status': status
    }
    result = await wordpress_client.get_posts(current_user["sub"], connection_id, params)
    if result['success']:
        return result['data']
    else:
        raise HTTPException(status_code=400, detail=result['message'])

@app.post("/api/wordpress/posts")
async def create_post(
    connection_id: str,
    post_data: Dict[str, Any],
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """Create WordPress post"""
    result = await wordpress_client.create_post(current_user["sub"], connection_id, post_data)
    if result['success']:
        return result['data']
    else:
        raise HTTPException(status_code=400, detail=result['message'])

@app.put("/api/wordpress/posts/{post_id}")
async def update_post(
    post_id: int,
    connection_id: str,
    post_data: Dict[str, Any],
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """Update WordPress post"""
    result = await wordpress_client.update_post(current_user["sub"], connection_id, post_id, post_data)
    if result['success']:
        return result['data']
    else:
        raise HTTPException(status_code=400, detail=result['message'])

@app.delete("/api/wordpress/posts/{post_id}")
async def delete_post(
    post_id: int,
    connection_id: str,
    force: bool = False,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """Delete WordPress post"""
    result = await wordpress_client.delete_post(current_user["sub"], connection_id, post_id, force)
    if result['success']:
        return {"message": "Post deleted successfully"}
    else:
        raise HTTPException(status_code=400, detail=result['message'])

@app.get("/api/wordpress/test/{connection_id}")
async def test_wordpress_connection(
    connection_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """Test WordPress connection"""
    result = await wordpress_client.test_connection(current_user["sub"], connection_id)
    if result['success']:
        return result
    else:
        raise HTTPException(status_code=400, detail=result['message'])

# Import content automation
from content_automation import (
    content_automation, 
    CreateWorkflowRequest, 
    WorkflowResponse,
    ContentType,
    WorkflowStatus
)

# Content Automation Endpoints
@app.post("/api/content/workflows", response_model=WorkflowResponse)
async def create_content_workflow(
    workflow_request: CreateWorkflowRequest,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """Create a new content publishing workflow"""
    workflow_data = workflow_request.dict()
    workflow_data["user_id"] = current_user["sub"]
    
    workflow = await content_automation.create_workflow(workflow_data)
    
    # Start the workflow immediately if not scheduled
    if not workflow.scheduled_publish_time:
        await content_automation.start_workflow(workflow.id)
    
    return WorkflowResponse(
        id=workflow.id,
        status=workflow.status,
        title=workflow.title,
        content_type=workflow.content_type,
        wordpress_post_id=workflow.wordpress_post_id,
        created_at=workflow.created_at,
        updated_at=workflow.updated_at,
        completed_at=workflow.completed_at,
        error_message=workflow.error_message,
        retry_count=workflow.retry_count
    )

@app.get("/api/content/workflows", response_model=List[WorkflowResponse])
async def list_content_workflows(
    status: Optional[WorkflowStatus] = None,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """List content workflows for the current user"""
    workflows = await content_automation.list_workflows(current_user["sub"], status)
    
    return [
        WorkflowResponse(
            id=w.id,
            status=w.status,
            title=w.title,
            content_type=w.content_type,
            wordpress_post_id=w.wordpress_post_id,
            created_at=w.created_at,
            updated_at=w.updated_at,
            completed_at=w.completed_at,
            error_message=w.error_message,
            retry_count=w.retry_count
        ) for w in workflows
    ]

@app.get("/api/content/workflows/{workflow_id}", response_model=WorkflowResponse)
async def get_content_workflow(
    workflow_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """Get a specific content workflow"""
    workflow = await content_automation.get_workflow(workflow_id)
    
    if not workflow:
        raise HTTPException(status_code=404, detail="Workflow not found")
    
    if workflow.user_id != current_user["sub"]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    return WorkflowResponse(
        id=workflow.id,
        status=workflow.status,
        title=workflow.title,
        content_type=workflow.content_type,
        wordpress_post_id=workflow.wordpress_post_id,
        created_at=workflow.created_at,
        updated_at=workflow.updated_at,
        completed_at=workflow.completed_at,
        error_message=workflow.error_message,
        retry_count=workflow.retry_count
    )

@app.post("/api/content/workflows/{workflow_id}/cancel")
async def cancel_content_workflow(
    workflow_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """Cancel a content workflow"""
    workflow = await content_automation.get_workflow(workflow_id)
    
    if not workflow:
        raise HTTPException(status_code=404, detail="Workflow not found")
    
    if workflow.user_id != current_user["sub"]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    success = await content_automation.cancel_workflow(workflow_id)
    
    if success:
        return {"success": True, "message": "Workflow cancelled successfully"}
    else:
        raise HTTPException(status_code=400, detail="Cannot cancel workflow in current status")

@app.post("/api/content/workflows/{workflow_id}/retry")
async def retry_content_workflow(
    workflow_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """Retry a failed content workflow"""
    workflow = await content_automation.get_workflow(workflow_id)
    
    if not workflow:
        raise HTTPException(status_code=404, detail="Workflow not found")
    
    if workflow.user_id != current_user["sub"]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    if workflow.status != WorkflowStatus.FAILED:
        raise HTTPException(status_code=400, detail="Only failed workflows can be retried")
    
    # Reset workflow for retry
    workflow.status = WorkflowStatus.PENDING
    workflow.error_message = None
    workflow.retry_count = 0
    workflow.updated_at = datetime.utcnow()
    
    # Start the workflow
    await content_automation.start_workflow(workflow_id)
    
    return {"success": True, "message": "Workflow retry initiated"}

@app.get("/api/content/templates")
async def get_content_templates():
    """Get available content templates and their configurations"""
    return {
        "templates": {
            content_type.value: {
                "name": content_type.value.replace('_', ' ').title(),
                "description": f"Template for {content_type.value.replace('_', ' ')} content",
                "config": content_automation.content_templates[content_type]
            }
            for content_type in ContentType
        }
    }

# Main pipeline entry point
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=9099)
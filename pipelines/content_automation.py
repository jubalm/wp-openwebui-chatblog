"""
Content Publishing Automation Pipeline
Handles automated workflows for OpenWebUI → WordPress content publishing
"""

import asyncio
import logging
import json
import uuid
from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
from enum import Enum
from dataclasses import dataclass, asdict
from pathlib import Path

import httpx
from fastapi import FastAPI, HTTPException, BackgroundTasks
from pydantic import BaseModel, Field

# Workflow status enumeration
class WorkflowStatus(str, Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"

class ContentType(str, Enum):
    BLOG_POST = "blog_post"
    ARTICLE = "article"
    TUTORIAL = "tutorial"
    FAQ = "faq"
    DOCUMENTATION = "documentation"

@dataclass
class ContentWorkflow:
    """Content publishing workflow definition"""
    id: str
    user_id: str
    connection_id: str
    title: str
    content: str
    content_type: ContentType
    status: WorkflowStatus
    wordpress_post_id: Optional[int] = None
    tags: List[str] = None
    categories: List[str] = None
    featured_image_url: Optional[str] = None
    publish_immediately: bool = False
    scheduled_publish_time: Optional[datetime] = None
    seo_title: Optional[str] = None
    seo_description: Optional[str] = None
    created_at: datetime = None
    updated_at: datetime = None
    completed_at: Optional[datetime] = None
    error_message: Optional[str] = None
    retry_count: int = 0
    max_retries: int = 3

    def __post_init__(self):
        if self.created_at is None:
            self.created_at = datetime.utcnow()
        if self.updated_at is None:
            self.updated_at = datetime.utcnow()
        if self.tags is None:
            self.tags = []
        if self.categories is None:
            self.categories = []

class ContentAutomationService:
    """Service for managing automated content publishing workflows"""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.workflows: Dict[str, ContentWorkflow] = {}
        self.active_tasks: Dict[str, asyncio.Task] = {}
        
        # Content processing templates
        self.content_templates = {
            ContentType.BLOG_POST: {
                "wordpress_format": "standard",
                "default_categories": ["Blog"],
                "auto_excerpt": True,
                "auto_tags": True
            },
            ContentType.ARTICLE: {
                "wordpress_format": "standard", 
                "default_categories": ["Articles"],
                "auto_excerpt": True,
                "auto_tags": True
            },
            ContentType.TUTORIAL: {
                "wordpress_format": "standard",
                "default_categories": ["Tutorials", "How-to"],
                "auto_excerpt": True,
                "auto_tags": True,
                "add_table_of_contents": True
            },
            ContentType.FAQ: {
                "wordpress_format": "standard",
                "default_categories": ["FAQ"],
                "auto_excerpt": False,
                "auto_tags": True
            },
            ContentType.DOCUMENTATION: {
                "wordpress_format": "standard",
                "default_categories": ["Documentation"],
                "auto_excerpt": True,
                "auto_tags": True,
                "add_table_of_contents": True
            }
        }
    
    async def create_workflow(self, workflow_data: Dict[str, Any]) -> ContentWorkflow:
        """Create a new content publishing workflow"""
        workflow_id = str(uuid.uuid4())
        
        workflow = ContentWorkflow(
            id=workflow_id,
            user_id=workflow_data["user_id"],
            connection_id=workflow_data["connection_id"],
            title=workflow_data["title"],
            content=workflow_data["content"],
            content_type=ContentType(workflow_data.get("content_type", ContentType.BLOG_POST)),
            status=WorkflowStatus.PENDING,
            tags=workflow_data.get("tags", []),
            categories=workflow_data.get("categories", []),
            featured_image_url=workflow_data.get("featured_image_url"),
            publish_immediately=workflow_data.get("publish_immediately", False),
            scheduled_publish_time=workflow_data.get("scheduled_publish_time"),
            seo_title=workflow_data.get("seo_title"),
            seo_description=workflow_data.get("seo_description")
        )
        
        self.workflows[workflow_id] = workflow
        self.logger.info(f"Created workflow {workflow_id} for user {workflow.user_id}")
        
        return workflow
    
    async def process_workflow(self, workflow_id: str) -> None:
        """Process a content publishing workflow"""
        if workflow_id not in self.workflows:
            raise ValueError(f"Workflow {workflow_id} not found")
        
        workflow = self.workflows[workflow_id]
        workflow.status = WorkflowStatus.PROCESSING
        workflow.updated_at = datetime.utcnow()
        
        try:
            self.logger.info(f"Processing workflow {workflow_id}")
            
            # Step 1: Content preprocessing
            processed_content = await self._preprocess_content(workflow)
            
            # Step 2: WordPress post creation/update
            wordpress_result = await self._publish_to_wordpress(workflow, processed_content)
            
            # Step 3: Post-processing tasks
            await self._post_process_workflow(workflow, wordpress_result)
            
            # Mark as completed
            workflow.status = WorkflowStatus.COMPLETED
            workflow.completed_at = datetime.utcnow()
            workflow.wordpress_post_id = wordpress_result.get("id")
            
            self.logger.info(f"Workflow {workflow_id} completed successfully. WordPress post ID: {workflow.wordpress_post_id}")
            
        except Exception as e:
            workflow.status = WorkflowStatus.FAILED
            workflow.error_message = str(e)
            workflow.retry_count += 1
            
            self.logger.error(f"Workflow {workflow_id} failed: {str(e)}")
            
            # Schedule retry if under max retries
            if workflow.retry_count < workflow.max_retries:
                self.logger.info(f"Scheduling retry {workflow.retry_count}/{workflow.max_retries} for workflow {workflow_id}")
                await self._schedule_retry(workflow)
            
        finally:
            workflow.updated_at = datetime.utcnow()
            # Remove from active tasks
            if workflow_id in self.active_tasks:
                del self.active_tasks[workflow_id]
    
    async def _preprocess_content(self, workflow: ContentWorkflow) -> Dict[str, Any]:
        """Preprocess content based on content type"""
        template = self.content_templates[workflow.content_type]
        
        processed = {
            "title": workflow.title,
            "content": workflow.content,
            "status": "publish" if workflow.publish_immediately else "draft"
        }
        
        # Auto-generate excerpt if enabled
        if template.get("auto_excerpt", False):
            processed["excerpt"] = self._generate_excerpt(workflow.content)
        
        # Auto-generate tags if enabled and not provided
        if template.get("auto_tags", False) and not workflow.tags:
            processed["tags"] = await self._auto_generate_tags(workflow.content)
        else:
            processed["tags"] = workflow.tags
        
        # Apply default categories
        categories = workflow.categories or template.get("default_categories", [])
        processed["categories"] = categories
        
        # Add table of contents if specified
        if template.get("add_table_of_contents", False):
            processed["content"] = self._add_table_of_contents(workflow.content)
        
        # SEO optimization
        if workflow.seo_title:
            processed["seo_title"] = workflow.seo_title
        if workflow.seo_description:
            processed["seo_description"] = workflow.seo_description
        
        # Featured image
        if workflow.featured_image_url:
            processed["featured_media_url"] = workflow.featured_image_url
        
        self.logger.debug(f"Preprocessed content for workflow {workflow.id}")
        return processed
    
    async def _publish_to_wordpress(self, workflow: ContentWorkflow, content: Dict[str, Any]) -> Dict[str, Any]:
        """Publish content to WordPress via our pipeline service"""
        # Import the wordpress client from the main pipeline
        from wordpress_oauth import pipeline as oauth_pipeline
        
        # Get WordPress credentials
        credentials = await oauth_pipeline.get_wordpress_credentials(workflow.user_id, workflow.connection_id)
        if not credentials:
            raise Exception("WordPress credentials not found")
        
        # Import WordPress client
        from wordpress_client import WordPressAPIClient
        client = WordPressAPIClient()
        
        # Create WordPress post
        result = await client.create_post(workflow.user_id, workflow.connection_id, content)
        
        if not result['success']:
            raise Exception(f"WordPress publishing failed: {result['message']}")
        
        return result['data']
    
    async def _post_process_workflow(self, workflow: ContentWorkflow, wordpress_result: Dict[str, Any]) -> None:
        """Perform post-processing tasks after successful publication"""
        # Log successful publication
        self.logger.info(f"Published content to WordPress. Post ID: {wordpress_result.get('id')}, URL: {wordpress_result.get('link')}")
        
        # Here we could add additional tasks like:
        # - Social media posting
        # - Email notifications
        # - Analytics tracking
        # - Backup creation
        # - SEO submission
        
        # For now, just log the completion
        self.logger.debug(f"Post-processing completed for workflow {workflow.id}")
    
    async def _schedule_retry(self, workflow: ContentWorkflow) -> None:
        """Schedule a retry for a failed workflow"""
        # Calculate retry delay (exponential backoff)
        delay_seconds = min(300, 30 * (2 ** (workflow.retry_count - 1)))  # Max 5 minutes
        
        self.logger.info(f"Scheduling retry for workflow {workflow.id} in {delay_seconds} seconds")
        
        # Reset status to pending for retry
        workflow.status = WorkflowStatus.PENDING
        
        # Schedule the retry
        async def retry_task():
            await asyncio.sleep(delay_seconds)
            await self.process_workflow(workflow.id)
        
        task = asyncio.create_task(retry_task())
        self.active_tasks[workflow.id] = task
    
    def _generate_excerpt(self, content: str, max_length: int = 160) -> str:
        """Generate an excerpt from content"""
        # Remove HTML tags and clean up
        import re
        clean_content = re.sub(r'<[^>]+>', '', content)
        clean_content = re.sub(r'\s+', ' ', clean_content).strip()
        
        if len(clean_content) <= max_length:
            return clean_content
        
        # Find the last complete sentence within the limit
        excerpt = clean_content[:max_length]
        last_period = excerpt.rfind('.')
        if last_period > max_length * 0.7:  # If we find a period in the last 30%
            excerpt = excerpt[:last_period + 1]
        else:
            # Otherwise, cut at the last space
            last_space = excerpt.rfind(' ')
            if last_space > 0:
                excerpt = excerpt[:last_space] + '...'
        
        return excerpt
    
    async def _auto_generate_tags(self, content: str, max_tags: int = 8) -> List[str]:
        """Auto-generate tags from content"""
        # This is a simple implementation. In production, you might want to use
        # NLP libraries or AI services for better tag extraction
        
        import re
        from collections import Counter
        
        # Extract words and filter common ones
        words = re.findall(r'\b[a-zA-Z]{3,}\b', content.lower())
        
        # Common words to exclude
        stop_words = {
            'the', 'and', 'for', 'are', 'but', 'not', 'you', 'all', 'can', 'had', 
            'her', 'was', 'one', 'our', 'out', 'day', 'get', 'has', 'him', 'his', 
            'how', 'its', 'may', 'new', 'now', 'old', 'see', 'two', 'who', 'boy', 
            'did', 'she', 'use', 'way', 'will', 'with', 'this', 'that', 'have',
            'from', 'they', 'know', 'want', 'been', 'good', 'much', 'some', 'time',
            'very', 'when', 'come', 'here', 'just', 'like', 'long', 'make', 'many',
            'over', 'such', 'take', 'than', 'them', 'well', 'were'
        }
        
        # Filter out stop words and count frequency
        filtered_words = [word for word in words if word not in stop_words and len(word) > 3]
        word_counts = Counter(filtered_words)
        
        # Get most common words as tags
        tags = [word.capitalize() for word, _ in word_counts.most_common(max_tags)]
        
        return tags
    
    def _add_table_of_contents(self, content: str) -> str:
        """Add a table of contents to content based on headings"""
        import re
        
        # Find all headings (H1-H6)
        headings = re.findall(r'<h([1-6])[^>]*>(.*?)</h[1-6]>', content, re.IGNORECASE)
        
        if len(headings) < 2:  # Only add TOC if there are at least 2 headings
            return content
        
        # Generate table of contents
        toc_html = '<div class="table-of-contents">\n<h3>Table of Contents</h3>\n<ul>\n'
        
        for level, heading_text in headings:
            # Create anchor from heading text
            anchor = re.sub(r'[^a-zA-Z0-9\s]', '', heading_text).replace(' ', '-').lower()
            toc_html += f'<li><a href="#{anchor}">{heading_text}</a></li>\n'
        
        toc_html += '</ul>\n</div>\n\n'
        
        # Add anchors to headings in content
        def add_anchor(match):
            level = match.group(1)
            attrs = match.group(2) if match.group(2) else ''
            heading_text = match.group(3)
            anchor = re.sub(r'[^a-zA-Z0-9\s]', '', heading_text).replace(' ', '-').lower()
            return f'<h{level}{attrs} id="{anchor}">{heading_text}</h{level}>'
        
        content_with_anchors = re.sub(
            r'<h([1-6])([^>]*)>(.*?)</h[1-6]>', 
            add_anchor, 
            content, 
            flags=re.IGNORECASE
        )
        
        # Insert TOC after first paragraph or at the beginning
        first_p = content_with_anchors.find('<p>')
        if first_p != -1:
            first_p_end = content_with_anchors.find('</p>', first_p) + 4
            return content_with_anchors[:first_p_end] + '\n\n' + toc_html + content_with_anchors[first_p_end:]
        else:
            return toc_html + content_with_anchors
    
    async def get_workflow(self, workflow_id: str) -> Optional[ContentWorkflow]:
        """Get workflow by ID"""
        return self.workflows.get(workflow_id)
    
    async def list_workflows(self, user_id: str, status: Optional[WorkflowStatus] = None) -> List[ContentWorkflow]:
        """List workflows for a user, optionally filtered by status"""
        workflows = [w for w in self.workflows.values() if w.user_id == user_id]
        
        if status:
            workflows = [w for w in workflows if w.status == status]
        
        # Sort by creation time, newest first
        workflows.sort(key=lambda w: w.created_at, reverse=True)
        
        return workflows
    
    async def cancel_workflow(self, workflow_id: str) -> bool:
        """Cancel a pending or processing workflow"""
        if workflow_id not in self.workflows:
            return False
        
        workflow = self.workflows[workflow_id]
        
        if workflow.status in [WorkflowStatus.PENDING, WorkflowStatus.PROCESSING]:
            workflow.status = WorkflowStatus.CANCELLED
            workflow.updated_at = datetime.utcnow()
            
            # Cancel active task if exists
            if workflow_id in self.active_tasks:
                self.active_tasks[workflow_id].cancel()
                del self.active_tasks[workflow_id]
            
            self.logger.info(f"Cancelled workflow {workflow_id}")
            return True
        
        return False
    
    async def start_workflow(self, workflow_id: str) -> None:
        """Start processing a workflow"""
        if workflow_id not in self.workflows:
            raise ValueError(f"Workflow {workflow_id} not found")
        
        workflow = self.workflows[workflow_id]
        
        if workflow.status != WorkflowStatus.PENDING:
            raise ValueError(f"Workflow {workflow_id} is not in pending status")
        
        # Check if scheduled publish time has passed
        if workflow.scheduled_publish_time:
            if datetime.utcnow() < workflow.scheduled_publish_time:
                # Schedule for later
                delay = (workflow.scheduled_publish_time - datetime.utcnow()).total_seconds()
                
                async def scheduled_task():
                    await asyncio.sleep(delay)
                    await self.process_workflow(workflow_id)
                
                task = asyncio.create_task(scheduled_task())
                self.active_tasks[workflow_id] = task
                
                self.logger.info(f"Scheduled workflow {workflow_id} for {workflow.scheduled_publish_time}")
                return
        
        # Start immediate processing
        task = asyncio.create_task(self.process_workflow(workflow_id))
        self.active_tasks[workflow_id] = task


# Global service instance
content_automation = ContentAutomationService()

# Pydantic models for API requests/responses
class CreateWorkflowRequest(BaseModel):
    title: str = Field(..., description="Content title")
    content: str = Field(..., description="Content body")
    content_type: ContentType = Field(ContentType.BLOG_POST, description="Type of content")
    connection_id: str = Field(..., description="WordPress connection ID")
    tags: Optional[List[str]] = Field(None, description="Content tags")
    categories: Optional[List[str]] = Field(None, description="Content categories")
    featured_image_url: Optional[str] = Field(None, description="Featured image URL")
    publish_immediately: bool = Field(False, description="Publish immediately")
    scheduled_publish_time: Optional[datetime] = Field(None, description="Scheduled publish time")
    seo_title: Optional[str] = Field(None, description="SEO title")
    seo_description: Optional[str] = Field(None, description="SEO description")

class WorkflowResponse(BaseModel):
    id: str
    status: WorkflowStatus
    title: str
    content_type: ContentType
    wordpress_post_id: Optional[int]
    created_at: datetime
    updated_at: datetime
    completed_at: Optional[datetime]
    error_message: Optional[str]
    retry_count: int
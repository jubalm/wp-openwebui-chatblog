"""
OpenWebUI Integration Pipeline for WordPress Publishing
This pipeline integrates directly with OpenWebUI to provide WordPress publishing capabilities
"""

import asyncio
import logging
from typing import Generator, Iterator, Dict, Any, List, Optional
from datetime import datetime
import httpx
import json

class Pipeline:
    """OpenWebUI Pipeline for WordPress Content Publishing"""
    
    def __init__(self):
        self.name = "WordPress Publisher"
        self.description = "Publish content directly to WordPress with automated formatting and SEO optimization"
        self.version = "1.0.0"
        
        # Configuration
        self.pipeline_service_url = "http://wordpress-oauth-pipeline.admin-apps.svc.cluster.local:9099"
        self.logger = logging.getLogger(__name__)
        
        # Pipeline settings
        self.valves = {
            "WORDPRESS_CONNECTION_ID": {
                "type": "str",
                "default": "",
                "description": "WordPress connection ID (get from /api/wordpress/connections)"
            },
            "AUTO_PUBLISH": {
                "type": "bool", 
                "default": False,
                "description": "Automatically publish to WordPress (vs. save as draft)"
            },
            "CONTENT_TYPE": {
                "type": "str",
                "default": "blog_post",
                "description": "Content type: blog_post, article, tutorial, faq, documentation"
            },
            "AUTO_GENERATE_TAGS": {
                "type": "bool",
                "default": True,
                "description": "Automatically generate tags from content"
            },
            "AUTO_GENERATE_EXCERPT": {
                "type": "bool",
                "default": True,
                "description": "Automatically generate excerpt from content"
            },
            "ADD_TABLE_OF_CONTENTS": {
                "type": "bool",
                "default": False,
                "description": "Add table of contents for long content"
            },
            "DEFAULT_CATEGORIES": {
                "type": "str",
                "default": "Blog",
                "description": "Default categories (comma-separated)"
            }
        }
    
    async def on_startup(self):
        """Called when the pipeline starts"""
        self.logger.info(f"Starting {self.name} v{self.version}")
        return self
    
    async def on_shutdown(self):
        """Called when the pipeline shuts down"""
        self.logger.info(f"Shutting down {self.name}")
    
    def pipe(
        self, 
        user_message: str, 
        model_id: str, 
        messages: List[Dict], 
        body: Dict
    ) -> Generator[str, None, None]:
        """
        Main pipeline processing function
        This intercepts the conversation flow to detect WordPress publishing intent
        """
        
        # Check if user wants to publish to WordPress
        publish_keywords = [
            "publish to wordpress", "post to wordpress", "create wordpress post",
            "wordpress publish", "blog post", "publish this", "post this to blog"
        ]
        
        user_message_lower = user_message.lower()
        should_publish = any(keyword in user_message_lower for keyword in publish_keywords)
        
        if should_publish:
            # Extract content from conversation
            content = self._extract_content_from_messages(messages)
            title = self._extract_title_from_content(content, user_message)
            
            if content and title:
                # Process WordPress publishing
                yield f"🚀 **WordPress Publishing Pipeline Activated**\n\n"
                yield f"**Title:** {title}\n"
                yield f"**Content Type:** {self.valves['CONTENT_TYPE']}\n"
                yield f"**Auto-publish:** {'Yes' if self.valves['AUTO_PUBLISH'] else 'No (Draft)'}\n\n"
                
                # Start publishing workflow
                workflow_result = asyncio.run(self._publish_to_wordpress(
                    title=title,
                    content=content,
                    user_auth_header=body.get("authorization", "")
                ))
                
                if workflow_result["success"]:
                    yield f"✅ **Publishing Workflow Created Successfully!**\n\n"
                    yield f"**Workflow ID:** `{workflow_result['workflow_id']}`\n"
                    yield f"**Status:** {workflow_result['status']}\n"
                    
                    if workflow_result.get('wordpress_post_id'):
                        yield f"**WordPress Post ID:** {workflow_result['wordpress_post_id']}\n"
                    
                    yield f"\n💡 *You can check the publishing status using the workflow ID.*\n"
                else:
                    yield f"❌ **Publishing Failed**\n\n"
                    yield f"**Error:** {workflow_result.get('error', 'Unknown error')}\n"
                    yield f"\n🔧 *Please check your WordPress connection and try again.*\n"
            else:
                yield f"❌ **Could not extract content for publishing**\n\n"
                yield f"Please ensure your message contains content to publish and try again.\n"
                yield f"Use phrases like 'publish this to WordPress' or 'create a blog post' to trigger publishing.\n"
        else:
            # Pass through to normal OpenWebUI processing
            yield f"💬 *Processing your request normally...*\n"
            yield f"*Tip: Use 'publish to WordPress' to activate the publishing pipeline.*\n"
    
    def _extract_content_from_messages(self, messages: List[Dict]) -> str:
        """Extract content from conversation messages"""
        # Get the assistant's last response as primary content
        content_parts = []
        
        for message in reversed(messages):
            if message.get("role") == "assistant":
                content = message.get("content", "")
                if content and len(content.strip()) > 50:  # Substantial content
                    content_parts.append(content)
                    break
        
        # If no assistant content, use user messages
        if not content_parts:
            for message in messages:
                if message.get("role") == "user":
                    content = message.get("content", "")
                    if content and len(content.strip()) > 50:
                        content_parts.append(content)
        
        return "\n\n".join(content_parts)
    
    def _extract_title_from_content(self, content: str, user_message: str) -> str:
        """Extract or generate a title from content"""
        # Check if user specified a title in their message
        title_patterns = [
            r"title[:\s]+([^\n]+)",
            r"called[:\s]+([^\n]+)",
            r"named[:\s]+([^\n]+)",
            r"about[:\s]+([^\n]+)"
        ]
        
        import re
        for pattern in title_patterns:
            match = re.search(pattern, user_message, re.IGNORECASE)
            if match:
                title = match.group(1).strip().strip('"\'')
                if len(title) > 5 and len(title) < 100:
                    return title
        
        # Extract from content headings
        heading_match = re.search(r'^#+\s+(.+)$', content, re.MULTILINE)
        if heading_match:
            title = heading_match.group(1).strip()
            if len(title) > 5 and len(title) < 100:
                return title
        
        # Generate from first sentence
        sentences = re.split(r'[.!?]+', content.strip())
        if sentences:
            first_sentence = sentences[0].strip()
            if len(first_sentence) > 10 and len(first_sentence) < 100:
                # Clean up and use as title
                title = re.sub(r'^(the|a|an)\s+', '', first_sentence, flags=re.IGNORECASE)
                return title.strip()
        
        # Fallback title
        return f"Blog Post - {datetime.now().strftime('%Y-%m-%d')}"
    
    async def _publish_to_wordpress(self, title: str, content: str, user_auth_header: str) -> Dict[str, Any]:
        """Publish content to WordPress via our automation service"""
        try:
            # Prepare workflow data
            workflow_data = {
                "title": title,
                "content": content,
                "content_type": self.valves["CONTENT_TYPE"],
                "connection_id": self.valves["WORDPRESS_CONNECTION_ID"],
                "publish_immediately": self.valves["AUTO_PUBLISH"],
                "categories": [cat.strip() for cat in self.valves["DEFAULT_CATEGORIES"].split(",")],
                "tags": [] if self.valves["AUTO_GENERATE_TAGS"] else None
            }
            
            # Make request to our pipeline service
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.pipeline_service_url}/api/content/workflows",
                    json=workflow_data,
                    headers={"Authorization": user_auth_header},
                    timeout=30.0
                )
                
                if response.status_code == 200:
                    result = response.json()
                    return {
                        "success": True,
                        "workflow_id": result["id"],
                        "status": result["status"],
                        "wordpress_post_id": result.get("wordpress_post_id")
                    }
                else:
                    error_detail = response.json().get("detail", "Unknown error")
                    return {
                        "success": False,
                        "error": f"HTTP {response.status_code}: {error_detail}"
                    }
                    
        except httpx.TimeoutException:
            return {
                "success": False,
                "error": "Request timeout - WordPress publishing service unavailable"
            }
        except Exception as e:
            return {
                "success": False,
                "error": f"Publishing error: {str(e)}"
            }
    
    def _format_content_for_wordpress(self, content: str) -> str:
        """Format content for WordPress publishing"""
        # Convert markdown to HTML if needed
        import re
        
        # Convert markdown headers
        content = re.sub(r'^### (.+)$', r'<h3>\1</h3>', content, flags=re.MULTILINE)
        content = re.sub(r'^## (.+)$', r'<h2>\1</h2>', content, flags=re.MULTILINE)
        content = re.sub(r'^# (.+)$', r'<h1>\1</h1>', content, flags=re.MULTILINE)
        
        # Convert markdown bold and italic
        content = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', content)
        content = re.sub(r'\*(.+?)\*', r'<em>\1</em>', content)
        
        # Convert markdown links
        content = re.sub(r'\[(.+?)\]\((.+?)\)', r'<a href="\2">\1</a>', content)
        
        # Convert line breaks to paragraphs
        paragraphs = content.split('\n\n')
        formatted_paragraphs = []
        
        for para in paragraphs:
            para = para.strip()
            if para and not para.startswith('<'):
                para = f'<p>{para}</p>'
            formatted_paragraphs.append(para)
        
        return '\n\n'.join(formatted_paragraphs)

# Create pipeline instance
pipeline = Pipeline()
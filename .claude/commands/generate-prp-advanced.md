---
title: "Generate Advanced PRP"
description: "AI-enhanced Project Requirements Planning with intelligent context detection"
---

# Generate Advanced Project Requirements Planning (PRP)

This command creates a comprehensive Project Requirements Planning (PRP) document using AI-enhanced questioning based on your project context.

## Usage

```bash
/generate-prp-advanced
```

## What it does

This intelligent tool automatically detects your project context and asks targeted questions relevant to your specific technology stack and project type.

## Features

### Automatic Context Detection
- Technology stack and frameworks
- Existing test infrastructure  
- CI/CD configurations
- Database files and configurations
- Package managers and dependencies

### AI-Enhanced Questioning
- Adapts questions based on detected project type
- Frontend-specific questions for React/Vue/Angular projects
- Backend-specific questions for API/server projects
- Database-related questions when databases are detected
- Security questions for auth/API projects

### Comprehensive Output
- All features from the basic PRP generator
- Context-specific considerations section
- Intelligent follow-up questions
- Technology-aware recommendations
- Enhanced project analysis

## Technology-Specific Questions

The tool asks different questions based on your detected stack:

- **Frontend**: Browser support, responsive design, offline functionality, accessibility
- **Backend**: Authentication, rate limiting, request volume, logging, error handling
- **Database**: Migrations, backup strategy, performance, indexing
- **Testing**: Coverage requirements, integration tests, frameworks, load testing
- **Security**: Encryption, compliance, auditing, password policies

## Example Usage

After running the command, reference the generated file:
```
Based on the advanced PRP file [project_name]_PRP_2025-07-04.md, please implement the core functionality.
```

The generated PRP includes intelligent analysis and context-specific recommendations for your project.
# Generate PRP

**Command**: `generate-prp`
**Description**: AI-enhanced Project Requirements Planning generator that adapts questions based on your project context

## Overview

This intelligent tool creates comprehensive Project Requirements Planning (PRP) documents through an AI-enhanced interview process that automatically detects your project context and asks relevant questions based on your technology stack and project type.

## Features

- **Automatic project context detection** - analyzes your codebase to understand tech stack, frameworks, and infrastructure
- **Intelligent adaptive questioning** - asks relevant questions based on detected project characteristics
- **Technology stack-aware guidance** - provides specific recommendations for React, Node.js, Python, etc.
- **Comprehensive requirement gathering** - covers business, technical, functional, and risk assessment
- **Claude Code optimized output** - generates PRP files specifically formatted for maximum Claude Code effectiveness

## Usage

Run the command:
/generate-prp

## What It Detects

The tool automatically analyzes your project directory to detect:

- **Technology Stack**: Node.js, Python, Ruby, Java, Go
- **Frameworks**: React, Vue, Angular, Express, Next.js, Django, Flask
- **Package Managers**: npm/yarn, pip/poetry, bundler
- **Testing Infrastructure**: Jest, pytest, RSpec, etc.
- **CI/CD**: GitHub Actions, GitLab CI, Travis, Jenkins
- **Database Files**: SQLite, configuration files
- **Project Structure**: Standard conventions and best practices

## Intelligent Questions

Based on your project context, the tool asks targeted questions such as:

### Frontend Projects
- Browser support requirements
- Responsive design needs
- Offline functionality
- Accessibility requirements
- State management preferences

### Backend Projects  
- Authentication/authorization approach
- Rate limiting requirements
- Expected request volume
- Logging and error handling strategies

### Database Projects
- Migration requirements
- Backup and recovery strategies
- Performance optimization needs
- Indexing requirements

### Testing Projects
- Required test coverage percentage
- Integration testing needs
- Performance testing requirements

## Output

Generates a comprehensive PRP markdown file containing:

- **Project overview** with detected context
- **Business and functional requirements**
- **Technical specifications** and constraints
- **Implementation guidance** tailored to your stack
- **Risk assessment** and uncertainty areas
- **Context-specific considerations** based on detected technologies
- **Implementation checklist** for Claude Code

## Integration

- Automatically updates your `CLAUDE.md` file with PRP reference
- Creates structured documentation optimized for Claude Code consumption
- Provides clear guidance for the Research → Plan → Implement workflow

## Example

Run the advanced PRP generator:
/generate-prp

The tool will:
1. Detect that you're using React + Node.js
2. Ask frontend-specific questions about browser support, state management
3. Ask backend-specific questions about authentication, APIs
4. Generate a comprehensive PRP file: `my_feature_PRP_2025-07-04.md`
5. Update CLAUDE.md with the new PRP reference

## Best Practices

1. **Run at project start** - Generate PRP before beginning implementation
2. **Update as needed** - Regenerate when requirements change significantly  
3. **Reference in conversations** - Tell Claude to "Based on the PRP file..."
4. **Keep current** - Update CLAUDE.md references as projects evolve

This tool implements the expert-level "Research → Plan → Implement" workflow that separates professional Claude Code usage from beginner approaches.

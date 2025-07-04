---
allowed-tools: Bash(find:*), Bash(grep:*), Bash(ls:*), Bash(cat:*), WebFetch
description: Generate a comprehensive Product Requirements Document optimized for Claude Code implementation
---

# Generate PRD for Claude Code Implementation

## Phase 1: Project Discovery
First, I'll analyze the current project to understand its context, structure, and existing documentation.

### Analyzing project structure...
!`find . -type f -name "*.md" -o -name "*.json" -o -name "*.yaml" -o -name "*.yml" | grep -E "(README|CLAUDE|package|composer|requirements|Cargo)" | head -20`

### Checking for existing documentation...
!`ls -la | grep -E "README|CLAUDE|docs"`

### Detecting technology stack...
!`find . -maxdepth 2 -name "package.json" -o -name "requirements.txt" -o -name "Gemfile" -o -name "Cargo.toml" -o -name "go.mod" -o -name "composer.json" | head -5`

## Phase 2: Requirements Gathering

Based on the project analysis, I need to gather specific information about your product requirements. Please answer the following questions:

**1. Product Overview**
- What is the product/feature name?
- What problem does it solve? (Be specific about user pain points)
- Who is the target user/persona?
- What is the core value proposition?

**2. Business Context**
- What are the business goals? (metrics, KPIs)
- What is the timeline/deadline?
- Are there any budget or resource constraints?
- What are the success criteria?

**3. Technical Requirements**
- What integrations are needed? (APIs, databases, services)
- Are there performance requirements? (load time, concurrent users)
- What are the security/compliance requirements?
- Any specific technology preferences or constraints?

**4. Scope & Priorities**
- What features are must-have vs nice-to-have?
- What is explicitly OUT of scope?
- Are there any dependencies or blockers?
- What is the MVP vs full release scope?

$ARGUMENTS

## Phase 3: PRD Generation

Based on your responses, I will generate a comprehensive PRD following this AI-optimized structure:

### PRD Structure Template:
```markdown
# Product Requirements Document: [Product Name]

## 1. Executive Summary
- **Product Vision**: [Clear, inspiring vision statement]
- **Problem Statement**: [Specific problem being solved]
- **Solution Overview**: [High-level solution approach]
- **Success Metrics**: [Measurable outcomes]

## 2. Context & Background
- **Market Opportunity**: [Size, growth, trends]
- **User Research**: [Key insights, pain points]
- **Competitive Analysis**: [Differentiation points]
- **Technical Feasibility**: [Validation of approach]

## 3. Product Requirements

### 3.1 Functional Requirements
[Organized as user stories with clear acceptance criteria]

| User Story | Description | Priority | Acceptance Criteria |
|------------|-------------|----------|-------------------|
| As a [user], I want to [action] | [Details] | P0/P1/P2 | - [ ] Criteria 1<br>- [ ] Criteria 2 |

### 3.2 Non-Functional Requirements
- **Performance**: [Specific metrics]
- **Security**: [Requirements and standards]
- **Scalability**: [Expected growth handling]
- **Accessibility**: [Standards to meet]

### 3.3 Technical Architecture
- **System Design**: [High-level architecture]
- **Data Model**: [Key entities and relationships]
- **API Specifications**: [Endpoints and contracts]
- **Third-party Dependencies**: [Services and libraries]

## 4. Implementation Plan

### 4.1 Release Strategy
- **Phase 1 - MVP**: [Core features, timeline]
- **Phase 2 - Enhancement**: [Additional features]
- **Phase 3 - Scale**: [Performance, optimization]

### 4.2 Development Workflow
- **Git Strategy**: [Branching model]
- **Testing Approach**: [Unit, integration, E2E]
- **CI/CD Pipeline**: [Automation requirements]
- **Monitoring**: [Metrics and alerting]

## 5. Claude Code Implementation Guide

### 5.1 Project Setup
\`\`\`bash
# Commands for Claude Code to initialize project
[Specific setup commands]
\`\`\`

### 5.2 Development Guidelines
- **Code Style**: [Standards and linting]
- **Documentation**: [Inline and external]
- **Error Handling**: [Patterns to follow]
- **Testing**: [Coverage requirements]

### 5.3 Claude-Specific Instructions
- **Context Management**: [How to maintain context]
- **Verification Steps**: [Quality checks]
- **Integration Points**: [Where human review needed]

## 6. Risks & Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| [Risk description] | High/Med/Low | High/Med/Low | [Strategy] |

## 7. Success Metrics & Monitoring

### 7.1 Key Performance Indicators
- **Technical Metrics**: [Response time, uptime]
- **Business Metrics**: [Conversion, engagement]
- **User Metrics**: [Satisfaction, adoption]

### 7.2 Monitoring Dashboard
- **Real-time Metrics**: [What to track]
- **Alerts**: [Thresholds and notifications]
- **Reports**: [Frequency and recipients]

## 8. Appendices
- **Glossary**: [Technical terms]
- **References**: [Documentation links]
- **Mockups/Designs**: [Visual references]
```

## Phase 4: Claude Code Optimization

After generating the PRD, I will:

1. **Create a CLAUDE.md file** with project-specific context and best practices
2. **Generate custom slash commands** for common development tasks
3. **Set up verification workflows** to ensure quality implementation
4. **Create test scenarios** that Claude can execute autonomously

## Phase 5: Validation Questions

Before finalizing the PRD, I'll ask:

1. Does this align with your vision and constraints?
2. Are there any missing requirements or considerations?
3. Is the scope appropriate for your timeline?
4. Do you need any sections expanded or clarified?

---

**Usage Tips:**
- Run this command at the project root
- Have any existing documentation ready
- Be as specific as possible in your answers
- Use `/project:prd update` to refine the document
- Save the generated PRD as `PRD.md` in your project root

Would you like me to proceed with generating your PRD? Please provide your initial project description or answer the questions above.

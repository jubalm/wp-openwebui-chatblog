---
title: "Generate PRP"
description: "Create a comprehensive Project Requirements Planning document"
---

# Generate Project Requirements Planning (PRP)

This command creates a comprehensive Project Requirements Planning (PRP) document through an interactive interview process.

## Usage

```bash
/generate-prp
```

## What it does

- Interactive requirement gathering
- Comprehensive technical and business context
- Risk assessment and implementation guidance
- Automatic CLAUDE.md integration
- Structured format optimized for Claude Code

## Features

- **Project Overview**: Name, description, and type classification
- **Technical Context**: Technology stack, affected files, database/API changes
- **Business Requirements**: Problem statement, success criteria, stakeholders
- **Functional Requirements**: Core functionality, user workflows, I/O specs
- **Technical Requirements**: Performance, security, scalability considerations
- **Dependencies**: External and internal dependencies
- **Implementation Guidance**: Development approach, coding standards, testing
- **Risk Assessment**: Potential challenges and uncertainty areas

The generated PRP file can be referenced in your Claude Code conversations to provide comprehensive project context.

## Example Usage

After running the command, reference the generated file:
```
Based on the PRP file [project_name]_PRP_2025-07-04.md, please implement the core functionality.
```
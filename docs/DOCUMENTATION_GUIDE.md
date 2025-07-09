# Documentation Guide

> **Last Updated**: July 8, 2025  
> **Purpose**: Map of all documentation and where to find specific information

## 📚 Documentation Structure

```
wp-openwebui/
├── README.md                           # Project overview and quick start
├── PRP.md                             # Project Requirements Plan (main requirements doc)
├── CLAUDE.md                          # AI context file with references
├── SESSION_CHANGES.md                 # Development session changes log
├── DOCUMENTATION_ALIGNMENT_PLAN.md    # This documentation reorganization plan
└── docs/
    ├── 1.PRODUCT_REQUIREMENTS.md      # Original PoC requirements (historical)
    ├── 3.TECHNICAL_OVERVIEW.md        # Technical architecture details
    ├── 4.DEPLOYMENT_STRATEGY.md       # Deployment approach and strategies
    ├── 5.WORDPRESS_OPENWEBUI_INTEGRATION_README.md  # Integration specifics
    ├── ARCHITECTURE_STATUS.md         # Current architecture overview
    ├── DEVELOPER_QUICKSTART.md        # Essential developer commands
    ├── IMPLEMENTATION_STATUS.md       # What's built vs planned
    ├── INFRASTRUCTURE_STATUS.md       # Current infrastructure details
    ├── MULTI_TENANT_ARCHITECTURE.md   # Multi-tenancy design
    ├── PLAN_WORDPRESS_OPENWEBUI_INTEGRATION_PLAN.md # Integration planning
    ├── TENANT_PROVISIONING_QUICKSTART.md # Tenant setup guide
    └── archive/
        └── PRD.md.archived            # Original Product Requirements Document
```

## 🔍 Where to Find Information

### Project Overview & Status
- **Current Status**: `README.md`, `PRP.md` (Executive Summary)
- **Implementation Progress**: `docs/IMPLEMENTATION_STATUS.md`
- **Known Issues**: `docs/IMPLEMENTATION_STATUS.md#known-issues-and-workarounds`

### Requirements & Planning
- **Current Requirements**: `PRP.md` (Project Requirements Plan)
- **Original PoC Requirements**: `docs/1.PRODUCT_REQUIREMENTS.md`
- **Historical PRD**: `docs/archive/PRD.md.archived`

### Technical Details
- **Architecture Overview**: `docs/ARCHITECTURE_STATUS.md`
- **Technical Deep Dive**: `docs/3.TECHNICAL_OVERVIEW.md`
- **Infrastructure Details**: `docs/INFRASTRUCTURE_STATUS.md`
- **Deployment Strategy**: `docs/4.DEPLOYMENT_STRATEGY.md`

### Developer Resources
- **Quick Commands**: `docs/DEVELOPER_QUICKSTART.md`
- **Essential Commands**: `CLAUDE.md#essential-quick-commands`
- **Troubleshooting**: `docs/DEVELOPER_QUICKSTART.md#troubleshooting`

### Integration & Features
- **WordPress-OpenWebUI Integration**: `docs/5.WORDPRESS_OPENWEBUI_INTEGRATION_README.md`
- **Multi-Tenant Design**: `docs/MULTI_TENANT_ARCHITECTURE.md`
- **Tenant Provisioning**: `docs/TENANT_PROVISIONING_QUICKSTART.md`

### Development History
- **Session Changes**: `SESSION_CHANGES.md`
- **Development Progress**: `CLAUDE.md` (session progress section)

## 📋 Documentation Conventions

### Status Indicators
- ✅ **Complete/Operational**: Feature or component is fully implemented
- 🔄 **In Progress**: Active development or partial implementation
- ❌ **Not Started/Pending**: Planned but not yet implemented
- ⚠️ **Known Issue**: Problem identified with workaround available

### Version Control
- All documentation includes "Last Updated" dates
- Major changes increment document versions
- Historical versions archived in `docs/archive/`

### File Naming
- `UPPERCASE.md`: Primary documentation files
- `lowercase.md`: Supporting or temporary files
- Numbers prefix: Ordered reading sequence

## 🔧 Maintenance Guidelines

### When to Update Documentation

1. **Infrastructure Changes**: Update `INFRASTRUCTURE_STATUS.md`
2. **New Features**: Update `IMPLEMENTATION_STATUS.md` and relevant technical docs
3. **Architecture Changes**: Update `ARCHITECTURE_STATUS.md`
4. **Requirements Changes**: Update `PRP.md`
5. **Known Issues**: Add to `IMPLEMENTATION_STATUS.md`

### Documentation Review Process

1. **Weekly Review**: Check for outdated information
2. **Release Updates**: Update all docs with new version info
3. **Issue Resolution**: Update known issues when fixed
4. **User Feedback**: Incorporate clarifications based on questions

## 🎯 Quick Reference for Common Tasks

### "How do I..."

| Task | Documentation |
|------|---------------|
| Access the cluster | `DEVELOPER_QUICKSTART.md#environment-setup` |
| Test services | `DEVELOPER_QUICKSTART.md#service-health-checks` |
| Deploy changes | `DEVELOPER_QUICKSTART.md#deploy-changes` |
| Check current status | `IMPLEMENTATION_STATUS.md` |
| Understand architecture | `ARCHITECTURE_STATUS.md` |
| View requirements | `PRP.md` |
| Troubleshoot issues | `DEVELOPER_QUICKSTART.md#troubleshooting` |

### Key Configuration Values

| Item | Value | Found In |
|------|-------|----------|
| Cluster ID | `354372a8-cdfc-4c4c-814c-37effe9bf8a2` | Multiple docs |
| LoadBalancer IP | `85.215.220.121` | Multiple docs |
| PostgreSQL Host | `pg-ng6akjkmbb4rn9e5.postgresql.de-txl.ionos.com` | `INFRASTRUCTURE_STATUS.md` |
| MariaDB Host | `ma-d8nn61870q23eimk.mariadb.de-txl.ionos.com` | `INFRASTRUCTURE_STATUS.md` |

## 📝 Contributing to Documentation

### Before Making Changes
1. Check if information exists elsewhere
2. Ensure consistency with other docs
3. Update related documentation
4. Maintain status indicators

### Documentation Standards
- Use clear, concise language
- Include code examples where helpful
- Maintain consistent formatting
- Update "Last Updated" dates
- Cross-reference related docs

### Review Checklist
- [ ] Information is accurate
- [ ] Status indicators are current
- [ ] Links to other docs work
- [ ] Code examples are tested
- [ ] Formatting is consistent

---

*This guide helps navigate the project documentation. For AI assistance, start with [CLAUDE.md](../CLAUDE.md).*
# Microsoft Sentinel MCP Configuration

A comprehensive Model Context Protocol (MCP) configuration for Microsoft Sentinel security operations, incident management, and threat hunting.

## Overview

This project provides an enhanced MCP configuration that enables:
- **Automated incident correlation** across multiple data sources
- **Advanced threat hunting** capabilities with pre-built queries
- **Risk assessment** frameworks with weighted scoring
- **Operational dashboards** for different user roles
- **SLA management** and escalation workflows

## Prerequisites

- Microsoft Sentinel workspace with appropriate permissions
- Azure Active Directory with security monitoring enabled
- MCP client (VS Code with Copilot or compatible client)
- Access to the following Sentinel tables:
  - `SecurityIncident`, `SecurityAlert`
  - `SigninLogs`, `AuditLogs` 
  - `AADUserRiskEvents`, `AADRiskyUsers`
  - `Usage`

## Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd sentinel-mcp-github
   ```

2. **Configure your workspace**
   - Update `workspaceId` in `mcp.json` with your Sentinel workspace ID
   - Update `workspaceName` to match your workspace name

3. **Validate configuration**
   ```bash
   # Using the provided validation script
   python scripts/validate_config.py
   ```

4. **Deploy the configuration**
   - Copy `mcp.json` to your MCP client configuration directory
   - Restart your MCP client

## Project Structure

```
sentinel-mcp-github/
├── mcp.json                    # Main MCP configuration
├── README.md                   # This file
├── schema.json                 # JSON schema for validation
├── queries/                    # Pre-built KQL queries
│   ├── incident-analysis/      # Incident investigation queries
│   ├── threat-hunting/         # Proactive hunting queries
│   ├── risk-assessment/        # Risk scoring queries
│   └── operational/            # Dashboard and metrics queries
├── scripts/                    # Automation and utility scripts
│   ├── validate_config.py      # Configuration validation
│   ├── deploy_config.ps1       # PowerShell deployment script
│   └── query_tester.py         # KQL query testing utility
├── dashboards/                 # Azure Workbook templates
│   ├── executive-dashboard.json
│   ├── analyst-dashboard.json
│   └── operational-dashboard.json
└── environments/               # Environment-specific configs
    ├── dev.json
    ├── staging.json
    └── production.json
```

## Key Features

### Incident Analysis
- **Multi-table correlation**: Links incidents with alerts, sign-ins, and risk events
- **Time-windowed joins**: Contextual data within specified time windows
- **Identity enrichment**: Comprehensive user and device context

### Threat Hunting
- **30-day hunting window** for pattern detection
- **MITRE ATT&CK aligned** focus areas
- **Pre-built hunting queries** for common attack vectors

### Risk Assessment
- **Weighted scoring** for users and alerts
- **Multi-dimensional risk factors**
- **Configurable assessment windows**

### Operational Excellence
- **SLA management** with auto-escalation
- **Role-based dashboards**
- **KPI tracking** (MTTR, MTTD, False Positive Rate)

## Available Queries

### Incident Analysis
- `incident-correlation.kql` - Link incidents with related alerts
- `incident-timeline.kql` - Chronological incident progression
- `affected-entities.kql` - Comprehensive entity impact analysis

### Threat Hunting
- `suspicious-signins.kql` - Anomalous authentication patterns
- `privilege-escalation.kql` - Elevated permission activities
- `lateral-movement.kql` - Cross-system access patterns

### Risk Assessment
- `user-risk-score.kql` - Comprehensive user risk calculation
- `alert-confidence.kql` - Alert reliability assessment
- `threat-landscape.kql` - Current threat environment overview

## Configuration

### Basic Configuration
The main configuration is in `mcp.json`. Key sections:

```json
{
  "workspaceBoundary": {
    "primary": {
      "workspaceId": "your-workspace-id",
      "workspaceName": "your-workspace-name"
    }
  }
}
```

### Advanced Configuration
- **Analysis Profiles**: Customize correlation rules and enrichment fields
- **Operational Metrics**: Adjust SLA thresholds and escalation rules
- **Automation Rules**: Configure auto-assignment and lifecycle management

## Dashboard Deployment

Deploy pre-built Azure Workbook dashboards:

```powershell
# Deploy executive dashboard
./scripts/deploy_config.ps1 -Dashboard executive -Environment production

# Deploy analyst dashboard  
./scripts/deploy_config.ps1 -Dashboard analyst -Environment production
```

## Customization

### Adding New Data Sources
1. Update `dataSources.availableTables` in `mcp.json`
2. Add correlation rules in `analysisProfiles`
3. Create corresponding KQL queries in `queries/`

### Custom Metrics
Modify `operationalMetrics` section to add:
- New incident categories
- Custom severity levels
- Additional KPIs

### Automation Rules
Extend `automationRules` for:
- Custom alert processing logic
- Advanced incident lifecycle management
- Integration with external systems

## Testing

Run the test suite to validate your configuration:

```bash
# Validate configuration
python scripts/validate_config.py

# Test KQL queries
python scripts/query_tester.py --workspace your-workspace-id

# Performance testing
python scripts/performance_test.py
```

## Security Considerations

- **Least Privilege**: Ensure MCP server has minimum required permissions
- **Network Security**: Use secure connections (HTTPS) for all endpoints
- **Credential Management**: Store sensitive information in Azure Key Vault
- **Audit Logging**: Enable comprehensive logging for all MCP activities

## Best Practices

1. **Regular Updates**: Keep correlation rules and queries updated
2. **Performance Monitoring**: Monitor query performance and optimize as needed
3. **False Positive Management**: Regularly review and tune detection rules
4. **Documentation**: Keep custom modifications documented
5. **Backup**: Maintain configuration backups and version history

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

- **Documentation**: Check the `/docs` folder for detailed guides
- **Issues**: Report bugs and feature requests via GitHub Issues
- **Community**: Join our discussions for tips and best practices


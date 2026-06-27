# Cookie-Rule Scripts

This folder contains Bash proof-of-concept scripts for authorized security testing of Microsoft 365 inbox rule abuse scenarios.

## Important

- Use only in environments where you have explicit written permission.
- These scripts can create or modify mailbox rules.
- Running these scripts against systems you do not own or operate is unauthorized.

## Scripts

### `cookie-login-inbox-rule.sh`

Baseline flow:

- Uses ESTS cookie values to request an OAuth authorization code and token.
- Creates a simple inbox forwarding rule via Outlook REST API.
- Lists inbox rules to verify creation.

### `cookie-login-inbox-rule2.sh`

Enhanced variant focused on lower observability:

- Enumerates existing rules and aligns naming/sequence patterns.
- Creates a keyword-scoped forwarding rule.
- Uses jitter and separate user-agent values for different stages.

### `cookie-login-inbox-rule3.sh`

Internal-forwarding variant:

- Derives tenant domain from token identity claims.
- Builds an internal recipient address and creates a forwarding rule.
- Supports dual forwarding pattern used in the script logic.

## Prerequisites

- Linux or macOS shell with `bash`, `curl`, and `python3`.
- Valid lab account context and authorized test scope.
- Network access to Microsoft login and Outlook endpoints.

## Usage

1. Open the target script and set required config values (cookies, forwarding targets, and optional keywords).
2. Make the script executable if needed:

```bash
chmod +x cookie-login-inbox-rule.sh
chmod +x cookie-login-inbox-rule2.sh
chmod +x cookie-login-inbox-rule3.sh
```

3. Run the script from this directory:

```bash
./cookie-login-inbox-rule.sh
./cookie-login-inbox-rule2.sh
./cookie-login-inbox-rule3.sh
```

## Operational Notes

- Scripts may fail if session cookies are expired or invalid.
- API behavior can vary by tenant controls and mail forwarding policies.
- Use dedicated test mailboxes and reset mailbox rules after exercises.

## Recommended Validation

- Confirm new or changed rules from mailbox settings and API output.
- Review audit logs for rule creation and mail flow events.
- Capture detections and map findings to your SOC playbooks.
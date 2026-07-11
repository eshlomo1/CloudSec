# AppConfAbuse

This folder has one script, `UserAppAbuse.py`, and it is basically a single-file Entra app abuse / hardening reproducer.

The idea is simple: sign in as a normal user, create a fresh app registration and service principal, then push a bunch of attacker-relevant settings through Graph to see what the tenant allows and where the consent wall actually kicks in.

## What the script does

In plain English, it:

1. Uses device-code sign-in so you can complete MFA in the browser.
2. Authenticates as a standard user and checks who you really signed in as.
3. Creates a new app registration and service principal.
4. Tries a pretty aggressive config set:
   - multi-tenant hosting
   - attacker-controlled redirect URIs
   - implicit flow settings
   - public client settings
   - group claims / optional claims
   - requested Graph permissions
   - consent-screen URLs
   - app roles and identifier URIs
5. Adds credentials, including a client secret and a federated identity credential.
6. Tries to add users, including Global Administrators, to the enterprise app.
7. Pushes through consent paths and records what actually sticks.
8. Dumps a small artifact file so you can review the result later.

The important takeaway is the same one the script prints at the end: the config often goes through broadly, but the effective grant is still bounded by tenant consent rules.

## Requirements

- macOS, Linux, or Windows with a normal shell and outbound HTTPS access
- Python 3.10+ (the script only uses the standard library, so no pip install is needed)
- A browser you can use for device-code sign-in and MFA
- An Entra ID tenant with app registration creation enabled for the test account
- Microsoft Graph / Entra access for the signed-in user, including whatever directory visibility your test relies on
- A tenant configuration that does not block the device-code flow or basic Graph calls

No extra packages are needed. It uses the Python standard library only.

### Entra settings that matter

The script gets much farther if the tenant allows these things for the test account:

- `Users can register applications` or equivalent app-creation permission
- device-code authentication to Microsoft login
- Graph read/write access for applications, service principals, and consent objects
- enough directory visibility to enumerate the current user and, if allowed, directory roles
- whatever consent policy your lab uses for delegated and admin-consent testing

## Usage

Run it with either a UPN or a tenant value:

```bash
python3 UserAppAbuse.py alice@contoso.onmicrosoft.com
python3 UserAppAbuse.py contoso.onmicrosoft.com alice@contoso.onmicrosoft.com
python3 UserAppAbuse.py organizations
```

You can also pass a tenant GUID if you want.

### Quick notes

- If you pass a full UPN, the script uses the domain part as the tenant.
- If you pass `organizations`, the browser lets you pick the account interactively.
- The script prints a device-code message, so be ready to open the URL and enter the code.
- It is meant for owner-authorized lab or bug-bounty research only.

## Output

When it finishes, you should get:

- console output showing which config writes worked and which ones got blocked
- `run_artifacts.json` with the actor, app, service principal, assigned principals, and granted scopes
- the created app registration and service principal left in place for inspection

If you want to clean up, delete the app registration and service principal manually in Entra.

## Files

- `UserAppAbuse.py` - the main script

## A couple of gotchas

- `allowedToCreateApps=true` matters. If your user cannot create apps, the script stops early.
- Some of the more aggressive writes are expected to fail depending on tenant policy and permissions.
- The script is not trying to prove a Microsoft vuln. It is more of a reproducible boundary test for Entra app hardening and consent behavior.

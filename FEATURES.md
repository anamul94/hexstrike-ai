# HexStrike AI — Feature Implementation Specification
> **Target Version:** v7.0
> **Base Version:** v6.0 (150+ tools, 12+ AI agents)
> **Last Updated:** 2026-04-16

---

## How to Use This File

Each feature is structured as follows:
- **ID** — Unique reference (use in commits and PRs)
- **Category** — Which pillar it belongs to
- **Priority** — 🔴 Critical / 🟠 High / 🟡 Medium / 🟢 Nice-to-have
- **Description** — What it is and what problem it solves
- **Tools / Components** — Specific tools or modules to integrate
- **New MCP Functions** — Functions to add to `hexstrike_server.py` / `hexstrike_mcp.py`
- **New AI Agent** — If a new autonomous agent is required
- **Dependencies** — Other features or tools it depends on
- **Acceptance Criteria** — How to verify it works

---

## TABLE OF CONTENTS

| ID | Feature | Category | Priority |
|---|---|---|---|
| [F-01](#f-01) | C2 Framework Integration | Red Team | 🔴 |
| [F-02](#f-02) | Active Directory Full Attack Chain | Red Team | 🔴 |
| [F-03](#f-03) | Privilege Escalation Automation | Red Team | 🔴 |
| [F-04](#f-04) | AV/EDR Evasion & Payload Obfuscation | Red Team | 🔴 |
| [F-05](#f-05) | Lateral Movement & Pivoting | Red Team | 🔴 |
| [F-06](#f-06) | Persistence Mechanisms | Red Team | 🟠 |
| [F-07](#f-07) | Data Collection & Exfiltration | Red Team | 🟠 |
| [F-08](#f-08) | Mobile Application Security | New Vertical | 🔴 |
| [F-09](#f-09) | Social Engineering Toolkit | Red Team | 🟠 |
| [F-10](#f-10) | Automated Pentest Report Generation | Core Platform | 🔴 |
| [F-11](#f-11) | AI / LLM Security Testing | New Vertical | 🟠 |
| [F-12](#f-12) | Supply Chain & Dependency Security | New Vertical | 🟠 |
| [F-13](#f-13) | Compliance & Hardening Framework | New Vertical | 🟡 |
| [F-14](#f-14) | Scope Enforcement System | Core Platform | 🟠 |
| [F-15](#f-15) | Engagement / Session Management | Core Platform | 🟠 |
| [F-16](#f-16) | Finding De-duplication Engine | Core Platform | 🟡 |
| [F-17](#f-17) | Stealth Mode & Rate Limiting | Core Platform | 🟠 |
| [F-18](#f-18) | Notification & Alert System | Core Platform | 🟡 |
| [F-19](#f-19) | RedTeam Master Orchestrator Agent | Red Team | 🔴 |

---

## RED TEAM FEATURES

---

### F-01
## C2 Framework Integration
**Category:** Red Team — Command & Control
**Priority:** 🔴 Critical

### Description
Currently HexStrike can achieve initial access and run exploits, but has no way to maintain persistent, interactive sessions post-exploitation. A C2 (Command & Control) framework is the backbone of any red team engagement — it manages reverse shells, beacons, and orchestrates all post-exploitation activity.

Without C2 integration, every shell is one-shot and non-persistent. The AI agent cannot issue follow-up commands, pivot, or maintain access across network changes and reboots.

### Tools to Integrate
| Tool | Why |
|---|---|
| **Sliver** | Best open-source C2. Supports mTLS, HTTP/S, DNS beacons. Has a REST API perfectly suited for AI agent automation. Actively maintained (BishopFox). |
| **Mythic** | Highly modular, agent-agnostic C2 with REST API. Supports multiple payload types and operating systems. Best for API-driven integration. |
| **Havoc** | Modern Cobalt Strike alternative with strong EDR evasion built in. Shellcode execution and BOF support. |
| **Metasploit meterpreter** | Already partially present — needs proper C2 session management wrappers (list sessions, interact, background, route). |

### New MCP Functions
```python
c2_start_listener(framework, protocol, host, port, options)
c2_generate_payload(framework, os_target, arch, format, listener_id)
c2_list_sessions()
c2_interact_session(session_id, command)
c2_background_session(session_id)
c2_terminate_session(session_id)
c2_route_through_session(session_id, target_network)
c2_run_module(session_id, module_name, options)
```

### New AI Agent
**`C2OrchestratorAgent`**
- Automatically starts appropriate listener based on target environment
- Delivers payload via initial access vector (from existing agents)
- Confirms beacon check-in
- Passes active session to `PrivEscAgent`, `LateralMovementAgent`, etc.
- Tracks all active sessions in a session registry

### Dependencies
- `F-04` (EvasionAgent — payloads must be AV-clean before delivery)
- Sliver or Mythic installed in Docker image / system

### Acceptance Criteria
- [ ] Can start a C2 listener via MCP function call
- [ ] Can generate payload for target OS (Linux/Windows)
- [ ] Session check-in is confirmed and visible via `c2_list_sessions()`
- [ ] AI agent can issue commands to active session
- [ ] Agent automatically hands session off to PrivEscAgent

---

### F-02
## Active Directory Full Attack Chain
**Category:** Red Team — Windows / Active Directory
**Priority:** 🔴 Critical

### Description
Active Directory is present in virtually every enterprise environment. The current HexStrike AD coverage is limited to `enum4linux`, `enum4linux-ng`, `netexec`, and `evil-winrm` — which only covers the basic enumeration phase.

A full AD red team engagement requires: domain enumeration → attack path mapping → Kerberos attacks → ADCS exploitation → credential dumping → Domain Admin takeover. None of these attack stages exist as integrated workflows.

### Tools to Integrate
| Tool | Attack Stage | Key Function |
|---|---|---|
| **BloodHound + SharpHound** | Recon | Map AD structure, find shortest path to Domain Admin, identify attack paths |
| **LDAPDomainDump** | Recon | Dump all users, groups, GPOs, OUs, trusts from LDAP |
| **Kerbrute** | Initial Access | User enumeration, AS-REP roasting, password spraying via Kerberos |
| **Impacket suite** | Credential Access | `GetUserSPNs` (Kerberoast), `GetNPUsers` (AS-REP Roast), `secretsdump` (DCSync), `wmiexec`, `psexec` |
| **Certipy** | Privilege Escalation | ADCS attack framework — ESC1 through ESC8 certificate template abuse |
| **Rubeus** | Lateral Movement | Pass-the-Ticket, Overpass-the-Hash, S4U2Self, S4U2Proxy |
| **PowerView / PowerSploit** | Recon + PrivEsc | ACL abuse, delegation attacks, GPO exploitation |
| **ADRecon** | Reporting | Comprehensive AD enumeration into structured report |
| **Mimikatz / PyMimikatz** | Credential Dump | LSASS dump, DCSync, Golden/Silver Ticket generation |

### New MCP Functions
```python
bloodhound_collect(target_dc, domain, username, password, collection_method)
bloodhound_analyze(neo4j_url, query_type)     # e.g. "shortest_path_to_da"
ldap_domain_dump(target, domain, username, password)
kerbrute_enum(domain, dc_ip, wordlist, attack_type)  # userenum / spray / asreproast
impacket_kerberoast(domain, dc_ip, username, password)
impacket_asreproast(domain, dc_ip)
impacket_secretsdump(target, domain, username, password, method)  # dcsync / local
certipy_find(target, domain, username, password)
certipy_exploit(target, domain, username, password, template, esc_type)
rubeus_attack(attack_type, options)            # asreproast / kerberoast / ptt / s4u
powerview_query(command, target, credentials)
mimikatz_run(command, target, session_id)
```

### New AI Agent
**`ADRedTeamAgent`**

Autonomous attack chain:
```
Step 1: LDAPDomainDump + BloodHound collect → domain structure map
Step 2: BloodHound query → find shortest path to Domain Admin
Step 3: Kerbrute → enumerate valid users
Step 4: Impacket GetNPUsers → AS-REP roasting (no pre-auth accounts)
Step 5: Impacket GetUserSPNs → Kerberoasting service accounts
Step 6: Hashcat → crack recovered TGS/TGT hashes
Step 7 (if Step 5-6 fail): Certipy → check for ADCS misconfigurations (ESC1-8)
Step 8: secretsdump / mimikatz → dump all hashes from DC (DCSync)
Step 9: Golden Ticket → forge tickets for unrestricted access
Step 10: Hand credentials + sessions to C2OrchestratorAgent
```

### Dependencies
- `F-01` (C2 integration for session management)
- `F-05` (lateral movement to reach DC)
- Impacket, BloodHound, Certipy installed

### Acceptance Criteria
- [ ] BloodHound data collection runs and produces attack path graph
- [ ] Kerberoast attack successfully retrieves crackable hashes
- [ ] Certipy detects at least one ADCS misconfiguration on test lab
- [ ] Full chain from domain user → Domain Admin runs autonomously on test AD lab
- [ ] Results piped into findings with evidence

---

### F-03
## Privilege Escalation Automation
**Category:** Red Team — Post-Exploitation
**Priority:** 🔴 Critical

### Description
After obtaining initial shell access (often as a low-privilege user), the red team must escalate to root (Linux) or SYSTEM/Administrator (Windows) to achieve their objectives. Currently HexStrike has no automated privilege escalation capability — if you get a shell, you're stuck at the access level you landed with.

This feature automates the entire PrivEsc enumeration → identification → exploitation cycle on both Linux and Windows.

### Tools to Integrate

**Linux**
| Tool | Purpose |
|---|---|
| **LinPEAS** | #1 most comprehensive Linux PrivEsc enumeration script. Outputs color-coded findings ranked by severity. |
| **Linux Exploit Suggester 2** | Maps live kernel version to known kernel exploit CVEs |
| **GTFOBins (lookup integration)** | Auto-lookup SUID/sudo binaries against GTFOBins exploit database |
| **Pspy** | Spy on cron jobs and processes without root — find credential leakage in scripts |
| **Unix-PrivEsc-Check** | Lightweight alternative to LinPEAS for stealth scans |

**Windows**
| Tool | Purpose |
|---|---|
| **WinPEAS** | #1 Windows PrivEsc enumeration. Detects misconfigs, stored creds, token privileges |
| **PowerUp** | PowerShell-based: unquoted service paths, weak service permissions, AlwaysInstallElevated |
| **PrintSpoofer** | Token impersonation: Service Account → SYSTEM using Print Spooler |
| **JuicyPotato / GodPotato** | Impersonate privileged tokens (SeImpersonatePrivilege) → SYSTEM |
| **Seatbelt** | C# host-based security checks: installed AV, UAC settings, AppLocker, credentials |
| **Watson** | Detect missing patches for known local PrivEsc CVEs based on patch level |
| **BeRoot** | Cross-platform auto-PrivEsc check |

### New MCP Functions
```python
linpeas_run(session_id, output_format, stealth_mode)
winpeas_run(session_id, output_format, search_fast)
linux_exploit_suggester(kernel_version, session_id)
gtfobins_lookup(binary_name)                    # returns exploitable techniques
pspy_monitor(session_id, duration, filter)
printspoofer_run(session_id)
juicypotato_run(session_id, prog, clsid)
powerup_run(session_id)
seatbelt_run(session_id, checks)
watson_check(session_id)
privesc_auto(session_id, os_type)               # master function - picks best chain
```

### New AI Agent
**`PrivEscAgent`**
```
Step 1: Detect OS, architecture, current privilege level
Step 2: Deploy and run LinPEAS / WinPEAS
Step 3: Parse output → rank escalation vectors by confidence score
Step 4: Attempt highest-confidence vector first
Step 5: If kernel exploit available → run Linux-Exploit-Suggester → compile & run
Step 6: If Windows token → try PrintSpoofer / GodPotato
Step 7: Verify new privilege level (whoami / id)
Step 8: Report result to C2OrchestratorAgent
Step 9: If successful → trigger PersistenceAgent
```

### Dependencies
- `F-01` (active C2 session to run tools in)
- `F-04` (evasion — WinPEAS/PEASS may trigger AV on Windows)

### Acceptance Criteria
- [ ] LinPEAS runs through session and output is parsed by AI
- [ ] Agent correctly identifies and ranks PrivEsc vectors from LinPEAS output
- [ ] Successfully escalates from www-data → root on a test Linux box
- [ ] Successfully escalates from IIS → SYSTEM on a test Windows box using PrintSpoofer
- [ ] Privilege level is verified before handing off to next step

---

### F-04
## AV/EDR Evasion & Payload Obfuscation
**Category:** Red Team — Defense Evasion
**Priority:** 🔴 Critical

### Description
Modern enterprise environments run Endpoint Detection & Response (EDR) tools (CrowdStrike, SentinelOne, Defender, Carbon Black). Without evasion, any payload or tool (msfvenom, nc, mimikatz) will be flagged and killed within seconds.

This feature adds an evasion pipeline that wraps/obfuscates payloads before delivery, patches AMSI in-memory before running PowerShell tools, and blinds ETW (Event Tracing for Windows) to reduce telemetry.

### Tools to Integrate
| Tool | Technique | Use Case |
|---|---|---|
| **Donut** | Shellcode conversion | Converts any PE/DLL/shellcode to position-independent code that runs in-memory without touching disk |
| **Scarecrow** | EDR bypass loader | Creates shellcode loaders with AMSI bypass, ETW patching, and API unhooking built-in |
| **Freeze** | Go loader generator | Generates Go-based shellcode loaders that evade most signature-based AV |
| **Shellter** | PE injection | Injects shellcode into legitimate Windows PE files (putty.exe, notepad.exe) |
| **Invoke-Obfuscation** | PS obfuscation | PowerShell script obfuscation through AST manipulation and encoding |
| **Phantom-Evasion** | AV evasion framework | Interactive tool wrapping Metasploit payloads with multiple evasion layers |
| **AMSI Bypass** | Memory patching | Patches AMSI.dll in memory to disable scanning before PowerShell tool execution |
| **ETW Patching** | Telemetry blind | Patches EtwEventWrite to null — removes EDR telemetry source |
| **ConfuserEx** | .NET obfuscation | Obfuscates .NET assemblies (C#) to evade signature detection |

### New MCP Functions
```python
donut_convert(payload_file, arch, output_format, options)
scarecrow_generate(shellcode_file, domain, loader_type)
freeze_generate(shellcode_file, process_inject, syscall_type)
shellter_inject(pe_file, shellcode, stealth_mode)
invoke_obfuscation(script_content, technique)   # token/string/encoding/launcher
amsi_bypass_generate(technique)                  # patch/reflection/force_error
etw_patch_generate()
confuserex_obfuscate(dotnet_assembly, config)
evasion_pipeline(payload_file, target_av, target_os)  # master function
check_av_edr(session_id)                        # detect what AV/EDR is running
```

### New AI Agent
**`EvasionAgent`**
```
Step 1: Query target for AV/EDR product (from recon or via Seatbelt)
Step 2: Select evasion stack based on detected product
    → CrowdStrike:   Scarecrow + ETW patching + AMSI bypass
    → Defender:      Donut + Shellter or Freeze
    → No AV:         Raw msfvenom payload
Step 3: Wrap payload through selected evasion stack
Step 4: (Optional) Test against local AV before delivery
Step 5: Deliver evasion-ready payload
Step 6: Monitor for detection events
```

### Dependencies
- None (runs before all other post-exploitation features)
- Donut, Scarecrow, Freeze installed in Docker image

### Acceptance Criteria
- [ ] Donut successfully wraps a test PE into shellcode
- [ ] Scarecrow-generated loader executes on Windows Defender-protected host without detection
- [ ] AMSI bypass allows WinPEAS to run without being blocked
- [ ] EvasionAgent correctly identifies CrowdStrike on a test host and selects appropriate stack

---

### F-05
## Lateral Movement & Pivoting
**Category:** Red Team — Lateral Movement
**Priority:** 🔴 Critical

### Description
After gaining access to one host, red teams must move through the internal network to reach high-value targets (DC, finance servers, developer machines). Currently HexStrike has no pivoting or lateral movement capability — all tools run from the attacker machine external to the network.

This feature adds tunneling tools to reach internal-only hosts and lateral movement wrappers to spread through the network using harvested credentials.

### Tools to Integrate
| Tool | Purpose |
|---|---|
| **Chisel** | Fast TCP/UDP tunnel over HTTP. Deploy on compromised host → create SOCKS5 proxy to reach internal network. |
| **Ligolo-ng** | Next-gen pivoting tool. Creates full TUN interface on attacker machine — all attacker tools route through compromised host transparently. |
| **Proxychains** | Route any tool through SOCKS proxy (used with Chisel/Ligolo) |
| **rpivot** | Reverse SOCKS proxy — useful when compromised host can't receive inbound connections |
| **SSH dynamic forwarding** | -D flag for SOCKS5 tunneling through SSH sessions |
| **Impacket wmiexec / psexec** | Remote code execution on Windows hosts using credentials |
| **NetExec (already present)** | Needs lateral movement workflow: credential spray all discovered hosts, auto-run commands |
| **Evil-WinRM (already present)** | WinRM lateral movement — needs session chaining support |

### New MCP Functions
```python
chisel_server_start(port, auth)
chisel_client_deploy(session_id, attacker_host, attacker_port)
ligolo_agent_deploy(session_id)
ligolo_add_route(network_cidr)
proxychains_configure(proxy_type, host, port)
pivot_through(session_id, target_host, tool, command)      # run tool via pivot
impacket_wmiexec(target, domain, username, password, command)
impacket_psexec(target, domain, username, password, command)
lateral_spray(credential_list, host_list, protocol)         # spray creds → all hosts
lateral_spread(session_id, network_range, credentials)      # auto lateral movement
```

### New AI Agent
**`LateralMovementAgent`**
```
Step 1: Get live host list from earlier network scan
Step 2: Get credential list from PrivEscAgent / ADRedTeamAgent
Step 3: Deploy Chisel/Ligolo on current compromised host
Step 4: Route scanner through pivot → scan internal network
Step 5: NetExec credential spray against all reachable hosts
Step 6: For each successful auth → establish shell
Step 7: Register all new sessions with C2OrchestratorAgent
Step 8: Repeat from Step 1 on each new host (recursive spread)
Step 9: Stop when target objectives are reached OR all hosts enumerated
```

### Dependencies
- `F-01` (C2 sessions for deploying pivot tools)
- `F-02` (AD credentials for spraying)
- `F-03` (elevated access to deploy pivot tools)

### Acceptance Criteria
- [ ] Chisel tunnel established through compromised host
- [ ] Internal-only host reachable via proxychains through pivot
- [ ] NetExec successfully sprays credentials against internal hosts via pivot
- [ ] Agent establishes session on second internal host using harvested credentials

---

### F-06
## Persistence Mechanisms
**Category:** Red Team — Persistence
**Priority:** 🟠 High

### Description
A red team operation requires maintaining access for the full engagement duration (often weeks). Without persistence, every reboot loses the foothold. This feature automates deploying the stealthiest persistence method appropriate for the target OS, privilege level, and detected security tools.

### Tools / Techniques to Implement

**Linux Persistence**
| Technique | Stealth | Privilege Required |
|---|---|---|
| Cron job injection | Medium | User |
| SSH authorized_keys injection | High | User |
| Systemd service (user) | Medium | User |
| Systemd service (system) | Low | Root |
| LD_PRELOAD hijack | High | User |
| Bash profile / bashrc | High | User |
| PAM backdoor | Very Low (permanent) | Root |
| Shared library hijack | High | Root |

**Windows Persistence**
| Technique | Stealth | Privilege Required |
|---|---|---|
| Registry Run Key (HKCU) | Medium | User |
| Registry Run Key (HKLM) | Low | Admin |
| Scheduled Task (user) | Medium | User |
| Scheduled Task (SYSTEM) | Low | Admin |
| WMI Event Subscription | High | Admin |
| DLL Hijacking | High | User |
| COM Object Hijacking | Very High | User |
| Service installation | Low | Admin |
| Startup folder | Medium | User |

### New MCP Functions
```python
persist_cron(session_id, payload, schedule)
persist_ssh_key(session_id, public_key)
persist_systemd(session_id, service_name, payload, scope)    # user/system
persist_registry(session_id, key_path, payload)
persist_scheduled_task(session_id, task_name, payload, trigger)
persist_wmi(session_id, filter_name, consumer_name, payload)
persist_startup(session_id, payload, filename)
persist_auto(session_id, os_type, privilege_level, stealth_preference)  # master
verify_persistence(session_id, method)                       # simulate reboot check
remove_persistence(session_id, method)                       # clean-up for debrief
```

### New AI Agent
**`PersistenceAgent`**
- Receives OS type, privilege level, and detected AV/EDR from previous agents
- Selects stealth-appropriate persistence method
- Deploys persistence payload via C2 session
- Verifies survival across simulated logout/reboot
- Logs all persistence mechanisms deployed for debrief/cleanup

### Dependencies
- `F-01` (C2 session), `F-03` (privilege level known), `F-04` (payload must evade AV)

### Acceptance Criteria
- [ ] SSH key persistence survives user-level test
- [ ] WMI subscription persistence survives reboot on Windows test host
- [ ] PersistenceAgent autonomously selects correct method based on OS/privilege
- [ ] Remove function successfully cleans up deployed persistence for debrief

---

### F-07
## Data Collection & Exfiltration
**Category:** Red Team — Collection & Exfiltration
**Priority:** 🟠 High

### Description
After achieving objectives, data must be securely exfiltrated back to the red team. This feature implements stealthy collection of target data (credentials, documents, configs, secrets) and multiple exfiltration channels that bypass DLP (Data Loss Prevention) and egress filtering.

### Tools to Integrate
| Tool | Exfil Channel | Notes |
|---|---|---|
| **DNScat2** | DNS | Exfiltrate data encoded in DNS queries — bypasses most firewalls |
| **Egress-Assess** | Multiple | Test which outbound channels are available (HTTP, FTP, DNS, ICMP) |
| **Loot Aggregator (custom)** | Local | AI-assisted collection: find credentials, API keys, SSH keys, config files, documents |
| **Custom HTTPS chunked exfil** | HTTPS | Send data in small chunks over HTTPS to attacker C2 — blends with normal traffic |
| **Packetwhisper** | DNS/steganography | Slow but very stealthy DNS exfiltration using steganography |

### New MCP Functions
```python
loot_collect(session_id, collect_types)         # creds/keys/docs/configs/all
loot_search_secrets(session_id, paths)           # TruffleHog-style secret scanning on host
egress_check(session_id)                        # test available outbound channels
exfil_dns(session_id, data, dns_server)
exfil_https(session_id, data, receiver_url)
exfil_auto(session_id, data, stealth_level)     # picks best channel
exfil_status(task_id)
```

### New AI Agent
**`ExfiltrationAgent`**
- Runs `egress_check` to discover available exfil channels
- Uses `loot_collect` to gather target materials from compromised hosts
- Ranks and deduplicates collected data by sensitivity
- Selects appropriate exfil channel based on what's available + stealth requirements
- Verifies data received on attacker side

### Dependencies
- `F-01` (C2 session), `F-05` (lateral movement — collect from multiple hosts)

### Acceptance Criteria
- [ ] Agent successfully identifies SSH private keys and `.env` files on test host
- [ ] DNS exfiltration channel successfully sends test payload through DNS
- [ ] Egress check correctly identifies blocked vs. allowed protocols

---

## NEW VERTICAL FEATURES

---

### F-08
## Mobile Application Security
**Category:** New Vertical — Mobile
**Priority:** 🔴 Critical

### Description
Bug bounty programs and enterprise pentests increasingly include Android and iOS applications in scope. HexStrike currently has zero mobile testing capability. This feature adds full mobile application security testing: static analysis (decompile + scan), dynamic analysis (runtime hooks), and network traffic interception.

### Tools to Integrate
| Tool | Platform | Purpose |
|---|---|---|
| **MobSF** (Mobile Security Framework) | Android + iOS | All-in-one static and dynamic analysis — exposes via REST API for AI integration |
| **jadx** | Android | Decompile APK to readable Java/Kotlin source code |
| **apktool** | Android | Decompile + recompile APKs, extract resources and Smali code |
| **dex2jar** | Android | Convert .dex to .jar for Java decompiler analysis |
| **Frida** | Android + iOS | Dynamic instrumentation — hook functions at runtime, bypass SSL pinning, bypass root detection |
| **Objection** | Android + iOS | Runtime exploration built on Frida — UI for common bypass techniques |
| **apkleaks** | Android | Scan APK for hardcoded secrets: API keys, tokens, URLs, private keys |
| **Drozer** | Android | Android app attack framework — test exposed components (Activities, Services, Providers) |
| **adb** | Android | Device interaction: install APK, pull files, logcat, shell |
| **ssl-kill-switch2** | iOS | Cydia Substrate plugin to disable SSL pinning system-wide |

### New MCP Functions
```python
mobsf_analyze(apk_path, analysis_type)          # static/dynamic/both
apkleaks_scan(apk_path)
jadx_decompile(apk_path, output_dir)
apktool_decompile(apk_path, output_dir)
frida_hook(device_id, package, script)
objection_explore(device_id, package)
objection_bypass_ssl(device_id, package)
objection_bypass_root(device_id, package)
drozer_run(device_id, package, module)
adb_shell(device_id, command)
adb_pull(device_id, remote_path, local_path)
adb_logcat(device_id, filter, duration)
mobile_full_audit(apk_path, device_id)          # master function
```

### New AI Agent
**`MobileSecurityAgent`**
```
Step 1: Static analysis via MobSF → get report
Step 2: apkleaks → scan for hardcoded secrets
Step 3: jadx decompile → AI reads source for business logic flaws
Step 4: (Dynamic) Push APK to connected device/emulator
Step 5: Objection → bypass SSL pinning + root detection
Step 6: Frida hooks → intercept sensitive function calls
Step 7: Drozer → enumerate and abuse exposed Android components
Step 8: Combine static + dynamic findings → output report
```

### Dependencies
- Android emulator or physical device (AVD/Genymotion)
- MobSF server running (Docker recommended)
- Frida server pushed to device

### Acceptance Criteria
- [ ] MobSF REST API integration returns structured vulnerability findings
- [ ] apkleaks detects hardcoded API key in test APK
- [ ] Frida script successfully hooks and logs SSL certificates (SSL pinning bypass)
- [ ] Drozer identifies exported Activity in test vulnerable app (DIVA)

---

### F-09
## Social Engineering Toolkit
**Category:** Red Team — Initial Access
**Priority:** 🟠 High

### Description
Social engineering is a primary initial access vector in red team engagements. Phishing, pretexting, and credential harvesting via fake portals are core techniques. This feature adds phishing campaign management, credential harvesting sites, and 2FA bypass capabilities.

**⚠️ Strictly for authorized red team operations with written consent.**

### Tools to Integrate
| Tool | Purpose |
|---|---|
| **GoPhish** | Full phishing campaign platform: tracking, analytics, credential capture. REST API for AI integration. |
| **Evilginx2** | Transparent reverse proxy phishing — captures session cookies even when 2FA is enabled (bypasses TOTP/push) |
| **SET (Social Engineering Toolkit)** | Comprehensive: credential harvesting, spear-phishing, payload delivery via email |
| **Modlishka** | Alternative to Evilginx2 — reverse proxy phishing |
| **GoPhish + OSINT** | AI combines TheHarvester OSINT results → auto-build target list → craft spear-phishing email |

### New MCP Functions
```python
gophish_create_campaign(name, template, targets, landing_page, smtp)
gophish_launch_campaign(campaign_id)
gophish_get_results(campaign_id)
gophish_create_template(subject, body, from_addr)
gophish_create_landing_page(html, capture_creds, redirect_url)
evilginx2_start(phishlet, domain, redirector)
evilginx2_get_tokens(session_id)
set_attack(attack_type, options)
phishing_from_osint(domain)                     # combines TheHarvester + GoPhish
```

### New AI Agent
**`PhishingCampaignAgent`**
- Pulls OSINT data from `TheHarvester` and `LinkedIn` scraping
- Generates spear-phishing emails personalized to each target
- Creates convincing credential harvesting page (cloned from target's real login)
- Launches GoPhish campaign and monitors click/cred capture in real-time
- When 2FA is in use → switches to Evilginx2 for session cookie capture

### Dependencies
- SMTP server access (for email sending)
- Domain for phishing site (GoPhish/Evilginx2)
- `F-10` OSINT results from existing agents (TheHarvester)

### Acceptance Criteria
- [ ] GoPhish campaign created and launched via MCP function
- [ ] Credential capture working on test phishing page
- [ ] Evilginx2 captures session cookies from test 2FA-protected login
- [ ] Agent auto-generates campaign from OSINT results of a test domain

---

## CORE PLATFORM FEATURES

---

### F-10
## Automated Pentest Report Generation
**Category:** Core Platform — Reporting
**Priority:** 🔴 Critical

### Description
After a full pentest or red team engagement, HexStrike has all findings in memory but no way to produce a professional deliverable. Security teams spend 4–12 hours writing reports manually. This feature auto-generates professional pentest reports in multiple formats from the AI's collected findings.

### Report Types
| Type | Audience | Format |
|---|---|---|
| **Technical Report** | Security team / developers | Markdown → PDF/HTML, full findings with evidence, PoC steps |
| **Executive Summary** | CISO / management | PDF, risk scores, business impact, no technical jargon |
| **Bug Bounty Report** | Platform submission | Markdown, CVSS score, reproduction steps, impact, remediation |
| **Red Team Report** | SOC / Blue team | Timeline, TTPs used (MITRE ATT&CK mapped), detection opportunities |
| **Compliance Gap Report** | Compliance team | Findings mapped to PCI-DSS / HIPAA / SOC2 / CIS controls |

### Components
| Component | Technology |
|---|---|
| **Template Engine** | Jinja2 templates per report type |
| **PDF Renderer** | `weasyprint` (HTML → PDF) or `reportlab` |
| **CVSS Calculator** | Auto-calculate CVSS 3.1 score from finding metadata |
| **MITRE ATT&CK Mapper** | Map red team TTPs to ATT&CK technique IDs |
| **Evidence Bundler** | Attach screenshots, command outputs, tool results |
| **Risk Heatmap Generator** | Visual severity matrix using matplotlib/plotly |
| **DefectDojo Integration** | Push findings to vuln management platform |

### New MCP Functions
```python
report_add_finding(engagement_id, title, severity, description, evidence, cvss)
report_generate(engagement_id, report_type, output_format)
report_add_screenshot(engagement_id, finding_id, image_path, caption)
cvss_calculate(av, ac, pr, ui, s, c, i, a)
mitre_attack_map(technique_name)
report_export(engagement_id, format, output_path)   # pdf/html/markdown/docx
defectdojo_push(engagement_id, dojo_url, api_key)
```

### New AI Agent
**`ReportGenerationAgent`**
- Collects all findings from engagement session
- Deduplicates and correlates findings from multiple tools
- Auto-scores each finding with CVSS 3.1
- Maps to MITRE ATT&CK framework
- Selects appropriate templates
- Generates executive summary in plain English
- Renders final PDF/HTML report

### Dependencies
- `F-15` (Engagement Management — needs engagement context)
- `F-16` (Finding De-duplication — clean data before reporting)
- `weasyprint` or `reportlab` in requirements.txt

### Acceptance Criteria
- [ ] Report generated from 5 test findings with correct CVSS scores
- [ ] Executive summary uses plain English with no technical jargon
- [ ] PDF renders correctly with logo, headers, evidence screenshots
- [ ] MITRE ATT&CK IDs correctly assigned to 3 test TTPs
- [ ] Bug bounty format report passes HackerOne/Bugcrowd readability check

---

### F-11
## AI / LLM Security Testing
**Category:** New Vertical — AI Security
**Priority:** 🟠 High

### Description
AI-powered applications are now a standard attack surface. OWASP released the LLM Top 10. This is an emerging and underserved space in security tooling — a major differentiator for HexStrike.

### OWASP LLM Top 10 Coverage

| # | Vulnerability | Test Method |
|---|---|---|
| LLM01 | Prompt Injection | Automated injection payloads via Garak |
| LLM02 | Insecure Output Handling | Test for XSS/SQLi in LLM-generated output rendered in apps |
| LLM03 | Training Data Poisoning | Analyze model behavior for anomalies |
| LLM04 | Model Denial of Service | Token flooding, recursive prompt attacks |
| LLM05 | Supply Chain Vulnerabilities | Check model provenance, dependency scan |
| LLM06 | Sensitive Info Disclosure | Probe for training data leakage, PII extraction |
| LLM07 | Insecure Plugin Design | Test tool-calling / function-calling for injection |
| LLM08 | Excessive Agency | Test for unintended actions via prompt manipulation |
| LLM09 | Overreliance | N/A (process/governance) |
| LLM10 | Model Theft | API query analysis for model extraction |

### Tools to Integrate
| Tool | Purpose |
|---|---|
| **Garak** | Open-source LLM vulnerability scanner — 40+ probes for prompt injection, jailbreaks, data leakage |
| **PromptBench** | Benchmark adversarial robustness of LLMs |
| **LLMFuzzer** | Fuzzing LLM API endpoints |
| **Custom probe library** | HexStrike-specific prompt injection payloads for web-integrated LLMs |

### New MCP Functions
```python
llm_scan_garak(model_type, target_endpoint, api_key, probes)
llm_prompt_injection(target_url, injection_payloads)
llm_jailbreak(target_endpoint, techniques)
llm_data_leakage(target_endpoint, probe_type)
llm_plugin_test(plugin_endpoint, manipulated_inputs)
llm_dos_test(target_endpoint, method)
llm_full_audit(target_endpoint, model_type, api_key)  # master function
```

### New AI Agent
**`LLMSecurityAgent`**
- Detects if target application uses an LLM (via response pattern analysis)
- Runs Garak probe suite against discovered LLM endpoints
- Tests for each OWASP LLM Top 10 category
- Reports findings with proof-of-concept inputs and observed outputs

### Acceptance Criteria
- [ ] Garak successfully runs basic probes against a local Ollama or test API
- [ ] Prompt injection detected in a test Flask app with LangChain integration
- [ ] Jailbreak attempt logged with evidence of policy bypass

---

### F-12
## Supply Chain & Dependency Security
**Category:** New Vertical — Supply Chain
**Priority:** 🟠 High

### Description
Software supply chain attacks are now one of the top threat vectors. This feature scans target applications, containers, and source code repositories for vulnerable dependencies, exposed secrets, and malicious packages.

### Tools to Integrate
| Tool | Purpose |
|---|---|
| **Syft** | Generate SBOM (Software Bill of Materials) from container images, filesystems, or source directories |
| **Grype** | Scan SBOMs and containers for known CVEs — uses NVD, GitHub Advisory, GHSA |
| **OWASP Dependency-Check** | Scan Java, .NET, Node.js, Python project dependencies for CVEs |
| **pip-audit** | Python-specific dependency vulnerability scanner |
| **npm audit** | Node.js dependency scanner |
| **Semgrep** | Static analysis with security rules — detect insecure coding patterns across 20+ languages |
| **TruffleHog** | Already present (OSINT) — but needs repo scanning integration for supply chain |
| **Bandit** | Python-specific SAST — detect hardcoded secrets, insecure functions |

### New MCP Functions
```python
syft_generate_sbom(target, output_format)        # target = image/dir/file
grype_scan(sbom_path_or_target, severity_threshold)
dependency_check(project_path, project_type)     # java/node/python/dotnet
pip_audit(requirements_file_or_venv)
npm_audit(package_json_path, level)
semgrep_scan(target_path, ruleset)               # auto/security/owasp-top10
bandit_scan(python_path, severity, confidence)
supply_chain_full_audit(target_path, language)   # master function
```

### New AI Agent
**`SupplyChainAgent`**
- Detects tech stack from earlier TechnologyDetector agent results
- Runs language-appropriate dependency scanner
- Generates SBOM and cross-references against CVE databases
- Scans for hardcoded secrets and insecure code patterns
- Prioritizes findings by CVSS score and exploitability

### Acceptance Criteria
- [ ] SBOM generated for a test Python project and Docker image
- [ ] Known vulnerable dependency (e.g. log4j) detected by Grype/Dependency-Check
- [ ] Semgrep detects hardcoded password in test Flask app

---

### F-13
## Compliance & Hardening Framework
**Category:** New Vertical — Compliance
**Priority:** 🟡 Medium

### Description
Enterprises need to map security findings to compliance frameworks (PCI-DSS, CIS, HIPAA, NIST CSF, SOC2). This feature runs hardening checks and maps all HexStrike findings to the relevant control frameworks.

### Tools to Integrate
| Tool | Framework | Purpose |
|---|---|---|
| **Lynis** | CIS / General | Linux security auditing and hardening recommendations |
| **OpenSCAP** | CIS Benchmarks | SCAP-compliant scanning against CIS Level 1/2 benchmarks |
| **Docker Bench Security** | CIS Docker | Already present — needs compliance report output |
| **Kube-bench** | CIS Kubernetes | Already present — needs compliance mapping |
| **Inspec profiles** | CIS/PCI/HIPAA | Compliance-as-code verification tests |

### New MCP Functions
```python
lynis_audit(target_type, profile)               # system / container
openscap_scan(target, profile, benchmark)        # cis-rhel/ubuntu/debian
inspec_run(target, profile, reporter)
compliance_map_findings(engagement_id, framework) # pci-dss/hipaa/soc2/nist/cis
compliance_gap_report(engagement_id, framework)
```

### Acceptance Criteria
- [ ] Lynis runs on test Linux host and output is parsed into structured findings
- [ ] Findings from F-10 correctly mapped to PCI-DSS controls in gap report

---

### F-14
## Scope Enforcement System
**Category:** Core Platform — Safety & Legal
**Priority:** 🟠 High

### Description
Currently HexStrike will run any tool against any target. This is a legal and operational risk. A scope management system ensures tools only run against authorized targets and prevents accidental testing of out-of-scope assets.

**This is both a legal safety feature and a professional necessity for authorized engagements.**

### Feature Components
- **Scope definition file** — JSON/YAML file defining:
  - In-scope IPs, CIDR ranges, domains
  - Out-of-scope exclusions
  - Rules of engagement (active/passive only, no credentials, etc.)
- **Pre-execution validation** — every MCP function checks target against scope before running
- **Warning system** — alert AI agent if a discovered host falls outside scope
- **Automatic block** — hard block for targets explicitly excluded
- **Scope report** — at engagement end, show which targets were tested and confirmed in-scope

### New MCP Functions
```python
scope_load(scope_file_path)
scope_add(target, in_scope, notes)
scope_check(target)                              # returns: in_scope/out_of_scope/unknown
scope_list()
scope_validate_engagement(engagement_id)         # confirm all tested targets were in scope
```

### Scope File Format (JSON)
```json
{
  "engagement_name": "Client ABC Red Team",
  "in_scope": ["10.0.0.0/8", "*.example.com", "192.168.1.1"],
  "out_of_scope": ["10.0.0.100", "prod.example.com"],
  "rules_of_engagement": {
    "no_dos": true,
    "no_credentials_in_prod": true,
    "passive_only_hours": "09:00-17:00"
  }
}
```

### Acceptance Criteria
- [ ] Tool execution blocked when target matches out-of-scope list
- [ ] Warning issued when discovered subdomain is not explicitly in scope
- [ ] Scope file loaded and respected across all MCP function calls in session

---

### F-15
## Engagement / Session Management
**Category:** Core Platform — Project Management
**Priority:** 🟠 High

### Description
All scan results, findings, and agent actions currently exist only in memory and are lost when the server restarts. This feature adds persistent engagement tracking: all actions, results, and findings are stored per named engagement and can be resumed, reviewed, and reported later.

### Feature Components
- **Engagement creation** — named project with client, scope, start date
- **Persistent storage** — SQLite or JSON-based finding store per engagement
- **Resume engagement** — load a previous engagement and continue where you left off
- **Action timeline** — chronological log of every tool run and its result
- **Finding management** — add, update, delete, and query findings per engagement
- **Multi-engagement** — run multiple simultaneous engagements without data mixing

### New MCP Functions
```python
engagement_create(name, client, scope_file, notes)
engagement_list()
engagement_load(engagement_id)
engagement_close(engagement_id)
engagement_add_finding(engagement_id, finding)
engagement_get_findings(engagement_id, severity_filter)
engagement_get_timeline(engagement_id)
engagement_export(engagement_id, format)         # json/csv/markdown
```

### Acceptance Criteria
- [ ] Engagement created, server restarted, engagement reloaded with all findings intact
- [ ] Two simultaneous engagements with isolated findings
- [ ] Timeline shows ordered list of all actions with timestamps

---

### F-16
## Finding De-duplication Engine
**Category:** Core Platform — Data Quality
**Priority:** 🟡 Medium

### Description
Multiple tools often discover the same vulnerability (e.g. Nuclei, Nikto, ZAP, and Nessus all report "X-Frame-Options missing"). Without de-duplication, reports are bloated with 20+ duplicate findings. This engine merges findings from different tools into a single, high-confidence finding with evidence from all sources.

### Logic
1. Normalize findings from each tool into common schema (title, host, port, severity, CWE, evidence)
2. Group by (host + port + vulnerability type) fingerprint
3. Merge duplicate groups → single finding with all tool evidence attached
4. Calculate confidence score based on number of tools that confirmed the finding
5. Highest-severity finding wins if duplicates have different severity ratings

### New MCP Functions
```python
dedup_run(engagement_id)
dedup_preview(engagement_id)                     # show what would be merged before applying
dedup_get_stats(engagement_id)                   # how many duplicates found/removed
```

### Acceptance Criteria
- [ ] 5 duplicate "Missing Security Header" findings from Nikto + ZAP + Nuclei → merged to 1
- [ ] Confidence score increases to "High" when finding confirmed by 3+ tools
- [ ] Original raw tool output still accessible after de-duplication

---

### F-17
## Stealth Mode & Rate Limiting
**Category:** Core Platform — Operational Security
**Priority:** 🟠 High

### Description
Running all tools at full speed against a target is detectable. IDS/IPS, WAFs, and SOC teams will identify the scan and terminate the engagement or affect client systems. Stealth mode provides global throttling and tool selection preferences that minimize detection signatures.

### Feature Components

**Stealth Levels**
| Level | Behavior |
|---|---|
| **Loud** | No limits — maximum speed, all techniques (default for CTF/lab) |
| **Normal** | Reasonable delays, avoid DoS-risk operations |
| **Stealth** | High delays, passive tools preferred, no brute force, fragmented scans |
| **Ghost** | Extremely slow, only passive recon, blend into normal traffic patterns |

**Controls**
- Global requests/sec cap across all tools
- Per-tool rate limit override
- Time-of-day scheduling (run only during business hours to blend with normal traffic)
- Passive-first mode (prefer `amass`, `subfinder`, `gau` over active `nmap`, `gobuster`)
- Randomize delays between tool executions
- Rotate User-Agent strings automatically

### New MCP Functions
```python
stealth_set_level(level)                         # loud/normal/stealth/ghost
stealth_get_current()
rate_limit_set(requests_per_second, burst)
rate_limit_per_tool(tool_name, rps)
schedule_tools(time_window)                      # only run between HH:MM-HH:MM
```

### Acceptance Criteria
- [ ] In Ghost mode, Nmap runs with `-T1 -f --randomize-hosts` automatically
- [ ] Global rate limiter enforces cap across simultaneous tool executions
- [ ] Stealth mode disables all brute-force tools automatically

---

### F-18
## Notification & Alert System
**Category:** Core Platform — Monitoring
**Priority:** 🟡 Nice-to-Have

### Description
Automated penetration tests can take hours. Security teams should be notified immediately when critical vulnerabilities are discovered so they can act without waiting for a final report.

### Notification Channels
| Channel | Trigger |
|---|---|
| **Discord Webhook** | Critical/High severity finding discovered |
| **Slack Webhook** | Any configurable severity threshold |
| **Telegram Bot** | Real-time finding alerts with summary |
| **Email (SMTP)** | End-of-engagement summary report |
| **Custom Webhook** | POST JSON finding data to any URL |

### New MCP Functions
```python
notify_configure(channel, config)               # discord/slack/telegram/email/webhook
notify_send(message, severity, engagement_id)
notify_on_finding(severity_threshold)           # trigger level: critical/high/medium
notify_test(channel)
```

### Acceptance Criteria
- [ ] Discord webhook receives alert within 30 seconds of critical finding being added
- [ ] Email summary sent at engagement close with finding count by severity

---

### F-19
## Red Team Master Orchestrator Agent
**Category:** Red Team — Autonomous Orchestration
**Priority:** 🔴 Critical

### Description
This is the capstone feature — a master AI agent that autonomously executes a full red team engagement kill chain by orchestrating all other agents in the correct order, adapting based on results.

This is what separates HexStrike from a collection of tools into a true **autonomous red team platform**.

### Kill Chain Execution Flow

```
RedTeamOrchestratorAgent
│
├── Phase 1: RECONNAISSANCE
│   ├── Passive: amass, subfinder, theHarvester, shodan
│   ├── Active: nmap, autorecon, httpx
│   └── → Target Profile built
│
├── Phase 2: INITIAL ACCESS
│   ├── Web vulns: nuclei, sqlmap, dalfox (based on profile)
│   ├── Phishing: PhishingCampaignAgent (if social eng in scope)
│   └── → Shell obtained → C2OrchestratorAgent takes over
│
├── Phase 3: POST-EXPLOITATION
│   ├── EvasionAgent: detect AV/EDR → wrap tools
│   ├── PrivEscAgent: escalate to root/SYSTEM
│   └── PersistenceAgent: deploy persistence
│
├── Phase 4: LATERAL MOVEMENT
│   ├── ADRedTeamAgent: (if Windows/AD) → Domain Admin
│   ├── LateralMovementAgent: spread across network
│   └── → More hosts → repeat Phase 3
│
├── Phase 5: OBJECTIVE COMPLETION
│   ├── ExfiltrationAgent: collect and exfiltrate data
│   └── ObjectiveVerifier: confirm objectives met
│
└── Phase 6: REPORTING
    ├── ReportGenerationAgent: produce full red team report
    └── NotificationAgent: deliver to stakeholders
```

### New MCP Functions
```python
redteam_start(engagement_id, objectives, scope_file, stealth_level)
redteam_status(engagement_id)
redteam_pause(engagement_id)
redteam_resume(engagement_id)
redteam_abort(engagement_id, cleanup)
redteam_get_phase(engagement_id)
```

### Dependencies
ALL other features (F-01 through F-18)

### Acceptance Criteria
- [ ] Agent progresses through all 6 phases autonomously on a test lab (HackTheBox/TryHackMe machine)
- [ ] Agent correctly adapts when initial access vector fails (tries alternate)
- [ ] Full red team report delivered at end of autonomous engagement
- [ ] Engagement can be paused and resumed without losing state

---

## IMPLEMENTATION PRIORITY ORDER

```
Phase 1 (v7.0 Core Red Team):
  F-14 → Scope Enforcement (safety first)
  F-15 → Engagement Management (foundation for everything)
  F-03 → Privilege Escalation (LinPEAS/WinPEAS)
  F-02 → Active Directory Chain (BloodHound/Impacket/Certipy)
  F-04 → AV/EDR Evasion (Donut/Scarecrow)
  F-10 → Report Generation (immediate value)

Phase 2 (v7.0 Full Red Team):
  F-01 → C2 Integration (Sliver/Mythic)
  F-05 → Lateral Movement (Chisel/Ligolo)
  F-17 → Stealth Mode
  F-06 → Persistence
  F-08 → Mobile Security (MobSF/Frida)

Phase 3 (v7.1):
  F-07 → Exfiltration
  F-09 → Social Engineering (GoPhish/Evilginx2)
  F-11 → LLM Security Testing
  F-12 → Supply Chain Security
  F-16 → Finding De-duplication
  F-18 → Notifications
  F-13 → Compliance Framework

Phase 4 (v7.2):
  F-19 → RedTeam Master Orchestrator (requires all above)
```

---

*HexStrike AI — Where artificial intelligence meets cybersecurity excellence*

# Security Lab Architecture

Comprehensive architecture documentation for the Red vs Blue Team security testing environment.

## System Architecture

```
┌────────────────────────────────────────────────────────────────────────────┐
│                          Orchestration Layer                                │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                         n8n Workflow Engine                           │  │
│  │  • Exercise lifecycle management                                     │  │
│  │  • Attack/defense automation                                         │  │
│  │  • Real-time monitoring & alerting                                   │  │
│  │  • Scoring & reporting                                               │  │
│  └────────┬─────────────────────────────────────────────────┬───────────┘  │
└───────────┼─────────────────────────────────────────────────┼──────────────┘
            │                                                 │
            │ HTTP/Webhooks                                   │ SSH/API
            ▼                                                 ▼
┌───────────────────────────┐                    ┌───────────────────────────┐
│  Infrastructure Layer     │                    │    Detection Layer        │
│  ┌─────────────────────┐  │                    │  ┌─────────────────────┐  │
│  │ Terraform/OpenTofu  │  │◄───────────────────┤  │   Wazuh SIEM       │  │
│  │ • VM provisioning   │  │    Webhooks/API    │  │   • Alert engine   │  │
│  │ • Network config    │  │                    │  │   • Active response│  │
│  │ • State management  │  │                    │  │   • Agent mgmt     │  │
│  └─────────────────────┘  │                    │  └─────────────────────┘  │
└───────────┬───────────────┘                    └───────────┬───────────────┘
            │ Proxmox API                                    │ Agents
            │                                                │
            ▼                                                ▼
┌────────────────────────────────────────────────────────────────────────────┐
│                          Proxmox Environment                                │
│                                                                             │
│  ┌────────────────────────────────────────────────────────────────────┐   │
│  │                      Network Segmentation                           │   │
│  │  ┌──────────┬──────────┬──────────┬──────────┬──────────┐          │   │
│  │  │ Mgmt     │ Red Team │ Blue Team│ Target   │ Honeypot │          │   │
│  │  │ .0.0/24  │ .10.0/24 │ .20.0/24 │ .30.0/24 │ .50.0/24 │          │   │
│  │  └──────────┴──────────┴──────────┴──────────┴──────────┘          │   │
│  └────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ Red Team Infrastructure (10.0.10.0/24) - Offensive                  │  │
│  │  ┌──────────────┬──────────────┬──────────────┬──────────────┐     │  │
│  │  │ Kali Linux   │ Parrot OS    │ C2 Server    │ Phishing     │     │  │
│  │  │ CT 110       │ CT 111       │ CT 112       │ CT 113       │     │  │
│  │  │              │              │              │              │     │  │
│  │  │ • Nmap       │ • Alternative│ • Covenant   │ • GoPhish    │     │  │
│  │  │ • Metasploit │ • Toolset    │ • Sliver     │ • Templates  │     │  │
│  │  │ • Nuclei     │ • Backup     │ • C2 Infra   │ • Analytics  │     │  │
│  │  │ • Burp Suite │ • Research   │              │              │     │  │
│  │  └──────────────┴──────────────┴──────────────┴──────────────┘     │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ Blue Team Infrastructure (10.0.20.0/24) - Defensive                 │  │
│  │  ┌──────────────┬──────────────┬──────────────┬──────────────┐     │  │
│  │  │ SOC          │ Threat Intel │ Network Mon  │ Forensics    │     │  │
│  │  │ CT 121       │ CT 122       │ CT 123       │ CT 124       │     │  │
│  │  │              │              │              │              │     │  │
│  │  │ • Wazuh UI   │ • MISP       │ • Zeek       │ • Volatility │     │  │
│  │  │ • Kibana     │ • ThreatFox  │ • Suricata   │ • Autopsy    │     │  │
│  │  │ • IR Tools   │ • OpenCTI    │ • Wireshark  │ • Analysis   │     │  │
│  │  │ • Analytics  │ • Intel Feeds│ • IDS/IPS    │ • Reporting  │     │  │
│  │  └──────────────┴──────────────┴──────────────┴──────────────┘     │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ Target Environment (10.0.30.0/24) - Intentionally Vulnerable       │  │
│  │  ┌──────────────┬──────────────┬──────────────┬──────────────┐     │  │
│  │  │ Web Server   │ Windows AD   │ Docker Host  │ Database     │     │  │
│  │  │ CT 130       │ CT 131       │ CT 132       │ CT 133       │     │  │
│  │  │              │              │              │              │     │  │
│  │  │ • DVWA       │ • AD Domain  │ • Vulnerable │ • MySQL      │     │  │
│  │  │ • WebGoat    │ • GPOs       │ • Containers │ • PostgreSQL │     │  │
│  │  │ • Juice Shop │ • Users/Groups│ • Docker API │ • Injection  │     │  │
│  │  │ • OWASP Apps │ • Kerberos   │ • Misconfig  │ • Weak Auth  │     │  │
│  │  └──────────────┴──────────────┴──────────────┴──────────────┘     │  │
│  │  ┌──────────────┬──────────────┬──────────────┬──────────────┐     │  │
│  │  │ IoT Devices  │ Legacy Apps  │ API Server   │ File Server  │     │  │
│  │  │ CT 134       │ CT 135       │ CT 136       │ CT 137       │     │  │
│  │  └──────────────┴──────────────┴──────────────┴──────────────┘     │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ Honeypot Network (10.0.50.0/24) - Threat Detection                 │  │
│  │  ┌──────────────┬──────────────┬──────────────┬──────────────┐     │  │
│  │  │ SSH Honeypot │ Web Honeypot │ DB Honeypot  │ SMB Honeypot │     │  │
│  │  │ CT 150       │ CT 151       │ CT 152       │ CT 153       │     │  │
│  │  │              │              │              │              │     │  │
│  │  │ • Cowrie     │ • Snare      │ • Elasticpot │ • Impacket   │     │  │
│  │  │ • SSH trap   │ • Tanner     │ • MySQL trap │ • SMB trap   │     │  │
│  │  │ • Logging    │ • Web trap   │ • Log to     │ • File share │     │  │
│  │  │              │ • ModSecurity│ • Wazuh      │ • trap       │     │  │
│  │  └──────────────┴──────────────┴──────────────┴──────────────┘     │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ Purple Team Control (10.0.40.0/24) - Coordination                  │  │
│  │  ┌──────────────────────────────────────────────────────────────┐  │  │
│  │  │ Control Dashboard (CT 140)                                    │  │  │
│  │  │  • Exercise management UI                                     │  │  │
│  │  │  • Real-time scoring                                          │  │  │
│  │  │  • Team coordination                                          │  │  │
│  │  │  • Deconfliction server                                       │  │  │
│  │  │  • Reporting engine                                           │  │  │
│  │  └──────────────────────────────────────────────────────────────┘  │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────────┘
```

## Data Flow

### 1. Exercise Initiation Flow

```
User/Scheduler
    │
    │ HTTP POST
    │ /webhook/start-exercise
    ▼
n8n Orchestrator
    │
    ├─► Proxmox API ──────► Start/Verify VMs
    │
    ├─► Wazuh API ────────► Enable Detection Rules
    │
    ├─► Red Team VM ──────► SSH: start-exercise.sh
    │
    └─► Blue Team VM ─────► SSH: start-monitoring.sh
    │
    ▼
Exercise Active
```

### 2. Attack Execution Flow

```
Red Team VM (10.0.10.110)
    │
    │ Tagged Traffic
    │ User-Agent: RedTeam/EXERCISE-ID
    ▼
Target VM (10.0.30.130)
    │
    │ Wazuh Agent
    │ Logs to Manager
    ▼
Wazuh Manager
    │
    │ Rule Matching
    │ Rule 100001-100009
    ▼
Detection: "Red Team Activity"
    │
    │ Webhook
    ▼
n8n Blue Team Workflow
    │
    ├─► Slack Alert ──────► #security-exercises
    │
    ├─► Update Score ─────► Exercise State
    │
    └─► Response (optional) ──► Block/Isolate
```

### 3. Unauthorized Threat Detection Flow

```
Unknown Attacker (NOT 10.0.10.0/24)
    │
    │ Attack Traffic
    ▼
Target VM or Honeypot
    │
    │ Wazuh Agent
    │ Logs to Manager
    ▼
Wazuh Manager
    │
    │ Rule Matching
    │ Rule 100010+ (Black Hat)
    ▼
CRITICAL ALERT: Unauthorized Attack!
    │
    ├─► Slack #security-alerts ──► @security-team
    │
    ├─► Email Notification ──────► SOC Team
    │
    ├─► Active Response ──────────► Auto-block IP
    │
    ├─► n8n Workflow ─────────────► Forensics Collection
    │
    └─► Incident Response ────────► IR Playbook
```

### 4. Scoring Flow

```
Exercise Events (Attacks/Detections)
    │
    ▼
n8n Scoring Workflow
    │
    ├─► Red Team Events
    │   │
    │   ├─► Initial Access ──────► +100 pts
    │   ├─► Persistence ──────────► +200 pts
    │   ├─► Lateral Movement ─────► +300 pts
    │   ├─► Privilege Escalation ─► +400 pts
    │   ├─► Data Exfiltration ────► +500 pts
    │   └─► Detected (stealth) ───► -50 pts
    │
    ├─► Blue Team Events
    │   │
    │   ├─► Detect Recon ──────────► +100 pts
    │   ├─► Detect Exploitation ───► +200 pts
    │   ├─► Block Lateral ─────────► +300 pts
    │   ├─► Identify Compromised ──► +400 pts
    │   ├─► Full IR & Recovery ────► +500 pts
    │   └─► False Positive ────────► -50 pts
    │
    └─► Penalties
        │
        ├─► Red Out of Scope ──────► -500 pts
        └─► Missed Black Hat ───────► -1000 pts
    │
    ▼
Live Leaderboard & Reports
```

## Network Architecture

### VLAN Configuration

| VLAN ID | Network       | Purpose           | Access        |
|---------|---------------|-------------------|---------------|
| 1       | 10.0.0.0/24   | Management        | Admin only    |
| 10      | 10.0.10.0/24  | Red Team          | Monitored     |
| 20      | 10.0.20.0/24  | Blue Team         | Full access   |
| 30      | 10.0.30.0/24  | Targets           | Restricted    |
| 40      | 10.0.40.0/24  | Purple Control    | Privileged    |
| 50      | 10.0.50.0/24  | Honeypots         | Isolated      |

### Firewall Rules

```
# Allow Red Team → Targets
Source: 10.0.10.0/24
Dest: 10.0.30.0/24
Action: ALLOW (monitored)

# Block Targets → Everything else
Source: 10.0.30.0/24
Dest: !10.0.30.0/24
Action: DROP

# Allow Blue Team → Everything (read-only)
Source: 10.0.20.0/24
Dest: *
Action: ALLOW

# Purple Control → Everything
Source: 10.0.40.0/24
Dest: *
Action: ALLOW

# Honeypots → Isolated (no egress)
Source: 10.0.50.0/24
Dest: *
Action: DROP (except to Wazuh)
```

## Detection Architecture

### Wazuh Rule Hierarchy

```
All Security Events
    │
    ├─► Source IP Check
    │   │
    │   ├─► 10.0.10.0/24? ──────► RED TEAM RULES (100001-100009)
    │   │   │                      • Tag as authorized
    │   │   │                      • Alert Blue Team
    │   │   │                      • Score if detected
    │   │   │
    │   ├─► 10.0.50.0/24? ──────► HONEYPOT RULES (100020-100027)
    │   │   │                      • ANY interaction = suspicious
    │   │   │                      • Cross-check source
    │   │   │                      • If NOT Red Team = CRITICAL
    │   │   │
    │   └─► Other? ──────────────► BLACK HAT RULES (100010-100014)
    │       │                      • CRITICAL ALERT
    │       │                      • Auto-block
    │       │                      • Notify SOC immediately
    │       │                      • Trigger IR playbook
    │       │
    └─► Destination IP Check
        │
        └─► Target compromised? ──► COMPROMISE RULES (100060-100065)
            │                      • Reverse shell detection
            │                      • Privilege escalation
            │                      • Persistence mechanisms
            │                      • Data exfiltration
```

## Technology Stack

### Infrastructure
- **Hypervisor**: Proxmox VE 8.x
- **IaC**: Terraform/OpenTofu 1.6+
- **Networking**: Linux bridges, VLANs, iptables

### Orchestration
- **Workflow Engine**: n8n (self-hosted)
- **Scheduling**: n8n cron triggers
- **API Integration**: REST APIs for Proxmox, Wazuh

### Security
- **SIEM**: Wazuh 4.x
- **IDS/IPS**: Suricata
- **Network Monitoring**: Zeek (formerly Bro)
- **Threat Intelligence**: MISP

### Offensive Tools
- **OS**: Kali Linux 2024.4, Parrot OS
- **Frameworks**: Metasploit, Empire, Covenant
- **Scanners**: Nmap, Nuclei, Nikto, Burp Suite
- **Exploitation**: SQLMap, Impacket, CrackMapExec

### Defensive Tools
- **Log Analysis**: Elasticsearch, Kibana
- **Forensics**: Volatility, Autopsy
- **IR**: TheHive, Cortex (SOAR)

### Deception
- **SSH Honeypot**: Cowrie
- **Web Honeypot**: Snare/Tanner
- **Database Honeypot**: Elasticpot, MySQL-Honeypot
- **SMB Honeypot**: Impacket SMB server

## Scalability Considerations

### Horizontal Scaling

```
Current Capacity: 1-2 concurrent exercises
│
├─► Add more Red Team VMs (CT 114-119)
│   • Load balance via n8n
│   • Parallel attack scenarios
│
├─► Add more Target VMs (CT 138-149)
│   • More diverse attack surfaces
│   • Specialized environments
│
└─► Add more Blue Team analysts
    • Multiple SOC workstations
    • Split monitoring duties
```

### Vertical Scaling

```
Upgrade VM Resources:
│
├─► Kali VM: 4 cores → 8 cores, 8GB → 16GB RAM
├─► Wazuh Manager: Add more RAM for log processing
└─► Target VMs: More realistic resource allocation
```

## Security Boundaries

### Isolation Layers

1. **Network Isolation**: VLANs prevent cross-contamination
2. **Firewall Rules**: Drop by default, allow by exception
3. **Wazuh Monitoring**: All VMs monitored including Red Team
4. **Access Control**: SSH key-based authentication only
5. **Audit Logging**: All actions logged to immutable storage

### Trust Boundaries

```
HIGH TRUST: Purple Control (10.0.40.0/24)
    │
    ├─► Can control all systems
    └─► Emergency stop authority

MEDIUM TRUST: Blue Team (10.0.20.0/24)
    │
    ├─► Read access to all
    └─► Write access to defensive tools

MONITORED: Red Team (10.0.10.0/24)
    │
    ├─► Attack privileges (within scope)
    └─► All actions logged

LOW TRUST: Targets (10.0.30.0/24)
    │
    ├─► No outbound access
    └─► Isolated from production

NO TRUST: Honeypots (10.0.50.0/24)
    │
    └─► Completely isolated (except Wazuh)
```

## Disaster Recovery

### Backup Strategy

```
Daily Backups:
├─► Proxmox VM snapshots (automated)
├─► Wazuh configuration & rules
├─► n8n workflows (version controlled)
├─► Exercise results (to NAS/S3)
└─► Terraform state (remote backend)

Weekly Backups:
├─► Full VM exports
└─► Complete environment snapshot

Monthly Backups:
└─► Archive to cold storage
```

### Recovery Procedures

```
Infrastructure Failure:
1. Deploy from Terraform (< 30 minutes)
2. Restore Wazuh configuration (< 10 minutes)
3. Import n8n workflows (< 5 minutes)
4. Verify with test exercise (< 15 minutes)

Total Recovery Time Objective (RTO): < 1 hour
Recovery Point Objective (RPO): < 24 hours
```

## Monitoring & Observability

### Key Metrics

**Red Team Performance**:
- Time to initial access
- Objectives achieved
- Detection rate
- Stealth score

**Blue Team Performance**:
- Mean time to detect (MTTD)
- Mean time to respond (MTTR)
- False positive rate
- Coverage percentage

**System Health**:
- VM uptime
- Wazuh agent status
- n8n workflow success rate
- Network latency

## Future Enhancements

### Phase 2 (Optional)
- [ ] AI-powered attack generation (via Cortex)
- [ ] Machine learning for anomaly detection
- [ ] Automated vulnerability discovery
- [ ] Dynamic difficulty adjustment

### Phase 3 (Optional)
- [ ] Multi-cloud deployment (AWS, Azure, GCP)
- [ ] CTF platform integration (CTFd)
- [ ] Live streaming for training
- [ ] Certification/training program

---

**Architecture Version**: 1.0
**Last Updated**: 2025-12-09
**Maintained By**: Security Team

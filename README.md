# Security Lab: Red vs Blue Team Environment

Automated security testing environment with Red Team (offensive), Blue Team (defensive), Purple Team (collaborative), and Black Hat detection capabilities.

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────┐
│                    n8n Orchestration Layer                    │
│  - Exercise scheduling & management                           │
│  - Attack/defense automation                                  │
│  - Real-time monitoring & alerting                            │
└──────────┬───────────────────────────────────────────┬───────┘
           │                                           │
           │ Triggers & Controls                       │ Monitors
           ▼                                           ▼
┌──────────────────────┐                    ┌──────────────────┐
│  Terraform/OpenTofu  │                    │   Wazuh SIEM     │
│  Infrastructure IaC  │                    │   (Existing)     │
│  - VM provisioning   │◄───────────────────│   Detection &    │
│  - Network config    │     Webhooks       │   Response       │
└──────────┬───────────┘                    └──────────────────┘
           │
           │ Provisions & Configures
           ▼
┌──────────────────────────────────────────────────────────────┐
│                    Proxmox Environment                        │
│  ┌──────────────┬──────────────┬──────────────┬───────────┐  │
│  │  Red Team    │  Blue Team   │  Target VMs  │ Honeypots │  │
│  │  10.0.10/24  │  10.0.20/24  │  10.0.30/24  │ 10.0.50/24│  │
│  │              │              │              │           │  │
│  │ • Kali 110   │ • SOC 121    │ • Web 130    │ • SSH 150 │  │
│  │ • Parrot 111 │ • MISP 122   │ • Win 131    │ • Web 151 │  │
│  │ • C2 112     │ • IDS 123    │ • Docker 132 │           │  │
│  └──────────────┴──────────────┴──────────────┴───────────┘  │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐   │
│  │           Purple Team Control (10.0.40/24)            │   │
│  │  • Control Dashboard 140                              │   │
│  │  • Scoring Engine                                     │   │
│  │  • Deconfliction Server                               │   │
│  └───────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────┘
```

## Key Features

### 🔴 Red Team (Offensive Security)
- **Automated attack scenarios** via n8n workflows
- **Multi-phase attack chains**: reconnaissance → exploitation → post-exploitation
- **Tagged traffic** to differentiate from real threats
- **Scoring system** based on objectives achieved vs. detection

### 🔵 Blue Team (Defensive Security)
- **Real-time detection** via existing Wazuh SIEM
- **Custom detection rules** for Red Team activity
- **Automated incident response** workflows
- **Performance metrics**: detection time, false positives, response effectiveness

### 🟣 Purple Team (Collaborative Validation)
- **Controlled exercises** with defined scope and rules
- **Automated scoring** for both teams
- **Post-exercise analysis** and lessons learned
- **Continuous improvement** feedback loops

### ⚫ Black Hat Detection (Threat Intelligence)
- **Unauthorized attack detection**: Any non-Red Team activity is flagged
- **Honeypot monitoring**: Decoy services that should never be touched
- **Automated blocking** of unauthorized IPs
- **Critical alerting** via Slack, email, and PagerDuty

## Prerequisites

- **Proxmox VE** 7.x or 8.x
- **Wazuh** SIEM (already deployed)
- **n8n** workflow automation platform
- **Terraform** or **OpenTofu** >= 1.0
- **VM templates**: Ubuntu 22.04, Kali Linux, Parrot OS, Windows Server 2022

## Quick Start

### 1. Deploy Infrastructure with Terraform

```bash
cd terraform/

# Initialize Terraform
terraform init

# Review the plan
terraform plan \
  -var="proxmox_password=$PROXMOX_PASSWORD" \
  -var="ssh_public_key=$(cat ~/.ssh/id_rsa.pub)"

# Deploy all VMs
terraform apply \
  -var="proxmox_password=$PROXMOX_PASSWORD" \
  -var="ssh_public_key=$(cat ~/.ssh/id_rsa.pub)"
```

### 2. Configure Wazuh Detection Rules

```bash
# Copy custom rules to Wazuh manager
scp wazuh/rules/security-lab-rules.xml root@wazuh-manager:/var/ossec/etc/rules/

# Copy active response configurations
scp wazuh/active-response/*.xml root@wazuh-manager:/var/ossec/etc/shared/

# Restart Wazuh manager
ssh root@wazuh-manager 'systemctl restart wazuh-manager'
```

### 3. Import n8n Workflows

```bash
# Access n8n web interface
open http://n8n.local:5678

# Import workflows
# 1. Go to Workflows > Import from File
# 2. Import n8n-workflows/01-exercise-orchestrator.json
# 3. Import n8n-workflows/02-red-team-automation.json
# 4. Import n8n-workflows/03-blue-team-response.json
# 5. Import n8n-workflows/04-purple-team-scoring.json

# Configure credentials
# - Proxmox API (PM_API_URL, PM_USER, PM_PASSWORD)
# - Wazuh API (WAZUH_API_URL, WAZUH_API_TOKEN)
# - Slack (SLACK_WEBHOOK_URL)
# - Email (SMTP settings)
```

### 4. Start Your First Exercise

```bash
# Via n8n webhook
curl -X POST http://n8n.local:5678/webhook/start-exercise \
  -H "Content-Type: application/json" \
  -d '{
    "exercise_id": "redblue-001",
    "exercise_type": "full_spectrum",
    "duration_hours": 8,
    "target_network": "10.0.30.0/24"
  }'

# Or via UI dashboard
open http://10.0.40.140:8080
```

## Exercise Types

### 1. **Full Spectrum** (Default)
Complete attack chain from reconnaissance to data exfiltration.

```bash
terraform apply -var="exercise_type=full_spectrum"
```

### 2. **Web Application Only**
Focus on OWASP Top 10 web vulnerabilities.

```bash
terraform apply \
  -var="exercise_type=web_only" \
  -var="target_config={deploy_web=true,deploy_windows=false,deploy_docker=false}"
```

### 3. **Container Escape**
Test Docker/container security.

```bash
terraform apply \
  -var="exercise_type=container_escape" \
  -var="target_config={deploy_docker=true}"
```

### 4. **Active Directory Attack**
Simulate attacks against Windows/AD environment.

```bash
terraform apply \
  -var="exercise_type=ad_attack" \
  -var="target_config={deploy_windows=true}"
```

### 5. **Purple Team Walkthrough**
Collaborative exercise with both teams working together.

```bash
terraform apply -var="exercise_type=purple_team_walkthrough"
```

## Rules of Engagement

### In Scope
✅ All VMs in `10.0.30.0/24` (Target Network)
✅ Honeypots in `10.0.50.0/24` (expected to detect)
✅ All attack types except DoS/DDoS
✅ Social engineering (simulated phishing via GoPhish)

### Out of Scope
❌ Management network `10.0.0.0/24`
❌ Blue Team tools `10.0.20.0/24`
❌ Physical attacks
❌ Denial of Service attacks
❌ Production systems outside security lab

### Safe Word
`STOPEX-REDBLUE-[YYYYMMDD]`

If this is communicated via Slack, all attacks immediately cease.

## Unauthorized Threat Detection

**Critical Feature**: The system differentiates between authorized Red Team activity and real threats.

### Detection Logic

```bash
# Red Team (Authorized): 10.0.10.0/24
# Everything else: UNAUTHORIZED THREAT

# Wazuh rule excerpt:
<rule id="100010" level="12">
  <if_sid>5710</if_sid>
  <srcip>!10.0.10.0/24</srcip>  <!-- NOT from Red Team -->
  <description>CRITICAL: Unauthorized attack - NOT RED TEAM!</description>
  <group>black_hat,critical</group>
</rule>
```

### Automated Response

When an unauthorized threat is detected:

1. **Immediate alerting** via Slack (#security-alerts) and email
2. **Automated IP blocking** via iptables/pfSense
3. **Incident response** playbook activation
4. **Forensics collection** triggered
5. **Executive notification** for critical threats

### Honeypot Strategy

Honeypots deployed in `10.0.50.0/24`:
- **SSH Honeypot** (Cowrie) - CT 150
- **Web Application Honeypot** (Snare/Tanner) - CT 151

**Rule**: ANY interaction with honeypots = suspicious (unless from Red Team during exercise)

## Scoring System

### Red Team Objectives

| Objective             | Points | Detection Expected |
|-----------------------|--------|--------------------|
| Initial Access        | 100    | ✅ Yes             |
| Establish Persistence | 200    | ✅ Yes             |
| Lateral Movement      | 300    | ⚠️  Maybe          |
| Privilege Escalation  | 400    | ⚠️  Maybe          |
| Data Exfiltration     | 500    | ❌ No              |

**Bonus**: +500 for capturing flags
**Penalty**: -50 per detection (when stealth expected)

### Blue Team Objectives

| Objective                    | Points | Time Limit |
|------------------------------|--------|------------|
| Detect Reconnaissance        | 100    | < 5 min    |
| Detect Exploitation Attempt  | 200    | < 10 min   |
| Block Lateral Movement       | 300    | < 15 min   |
| Identify All Compromised     | 400    | < 30 min   |
| Full IR & Recovery           | 500    | < 2 hours  |

**Penalty**: -50 per false positive
**Critical Penalty**: -1000 for missing Black Hat attack

## n8n Workflows

### 1. Exercise Orchestrator (`01-exercise-orchestrator.json`)
- **Trigger**: Webhook `/start-exercise`
- **Function**: Initiates exercise, coordinates teams, monitors progress
- **Frequency**: On-demand + 5-minute monitoring loop

### 2. Red Team Automation (`02-red-team-automation.json`)
- **Trigger**: Webhook `/red-team/attack` or scheduled (15-min intervals)
- **Function**: Executes attack phases, logs results, checks detection
- **Phases**: Recon → Vuln Scan → Exploit → Post-Exploit → Lateral → Exfil

### 3. Blue Team Response (`03-blue-team-response.json`)
- **Trigger**: Wazuh webhook on alert
- **Function**: Analyzes alerts, triggers response, updates scoring
- **Actions**: Block IPs, isolate hosts, collect forensics

### 4. Purple Team Scoring (`04-purple-team-scoring.json`)
- **Trigger**: Exercise events from both teams
- **Function**: Real-time scoring, leaderboard updates, reporting
- **Outputs**: Slack updates, dashboard metrics, final report

## Monitoring & Dashboards

### Wazuh Dashboard
```bash
# Access existing Wazuh
open https://wazuh-manager.local/app/wazuh

# Custom dashboard: "Security Lab Exercises"
# - Red Team activity timeline
# - Blue Team detection stats
# - Unauthorized threat alerts
```

### Purple Team Control Dashboard
```bash
# Web interface on CT 140
open http://10.0.40.140:8080

# Features:
# - Real-time exercise status
# - Live scoring leaderboard
# - Alert feed
# - Exercise control (stop/pause/resume)
```

### n8n Execution Dashboard
```bash
# Monitor workflow executions
open http://n8n.local:5678/executions

# Filter by:
# - Workflow: Exercise Orchestrator
# - Status: Running, Success, Error
# - Date range: Today
```

## Optional: Cortex Integration

While this security lab runs **independently**, you can optionally integrate with Cortex for enhanced capabilities:

```bash
# Enable Cortex orchestration (optional)
terraform apply -var="enable_cortex_integration=true"

# Cortex provides:
# - LLM-powered attack analysis
# - Automated playbook generation
# - Pattern recognition across exercises
# - Executive reporting with natural language summaries
```

## Maintenance

### Update VM Templates
```bash
# Update Kali Linux template
ssh root@10.0.10.110
apt update && apt upgrade -y
apt install -y nuclei metasploit-framework

# Snapshot as new template
# Proxmox UI > VM 110 > Convert to Template
```

### Rotate Credentials
```bash
# Update n8n credentials
# n8n UI > Credentials > Edit

# Update Wazuh API token
ssh root@wazuh-manager
/var/ossec/bin/wazuh-authd -P -R 001
```

### Archive Exercise Results
```bash
# Export exercise data
terraform output > exercises/redblue-001/infrastructure.json
scp root@10.0.40.140:/data/exercises/redblue-001-* exercises/redblue-001/

# Generate final report via n8n
curl -X POST http://n8n.local:5678/webhook/generate-report \
  -d '{"exercise_id": "redblue-001"}'
```

## Troubleshooting

### Issue: Red Team attacks not detected by Wazuh

```bash
# Check Wazuh agent status on target VMs
ssh root@10.0.30.130 'systemctl status wazuh-agent'

# Verify custom rules are loaded
ssh root@wazuh-manager 'cat /var/ossec/rules/security-lab-rules.xml'
ssh root@wazuh-manager '/var/ossec/bin/wazuh-control reload'
```

### Issue: n8n workflows failing

```bash
# Check n8n logs
docker logs n8n

# Verify credentials
# n8n UI > Credentials > Test Connection

# Check environment variables
echo $PROXMOX_API_URL
echo $WAZUH_API_URL
```

### Issue: VMs not provisioning via Terraform

```bash
# Verify Proxmox API access
curl -k https://proxmox.local:8006/api2/json/nodes

# Check VM templates exist
pvesh get /cluster/resources --type vm | grep template

# Enable Terraform debug logging
export TF_LOG=DEBUG
terraform apply
```

## Security Considerations

⚠️ **IMPORTANT**: This is a **security testing environment** with intentionally vulnerable systems.

### Network Isolation
- ✅ VLANs configured to segment attack/target/honeypot networks
- ✅ Firewall rules prevent lateral movement to production
- ✅ No internet access for vulnerable target VMs

### Access Control
- ✅ SSH key-based authentication only (no passwords)
- ✅ Wazuh monitoring on all VMs including Red Team
- ✅ Control team has override authority via Purple Team dashboard

### Data Protection
- ✅ No real customer data in target VMs
- ✅ Synthetic data only for testing scenarios
- ✅ Exercise results encrypted at rest

## References

- [Terraform Proxmox Provider Docs](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [n8n Documentation](https://docs.n8n.io/)
- [Wazuh API Reference](https://documentation.wazuh.com/current/user-manual/api/reference.html)
- [MITRE ATT&CK Framework](https://attack.mitre.org/)
- [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)

## Contributing

To contribute new attack scenarios or detection rules:

1. Add scenario to `n8n-workflows/02-red-team-automation.json`
2. Create corresponding detection rule in `wazuh/rules/`
3. Update scoring in `terraform/variables.tf`
4. Test in isolated environment first
5. Submit PR with documentation

## License

This is a security testing framework. Use only in authorized environments with proper permission.

---

**Built with**: Proxmox, Terraform/OpenTofu, n8n, Wazuh, Kali Linux, and a strong cup of coffee ☕

# Security Lab Project Summary

## What We've Built

A **fully automated Red vs Blue Team security testing environment** that runs on your Proxmox infrastructure, orchestrated by n8n, monitored by your existing Wazuh SIEM, and provisioned via Terraform/OpenTofu.

## Key Differentiators

### 🎯 **Unique Feature: Black Hat Detection**
Unlike traditional Red Team exercises that only test defenses, this system **automatically detects real unauthorized threats** by differentiating between:
- **Red Team** (authorized, tagged traffic from 10.0.10.0/24)
- **Black Hat** (unauthorized attacks from anywhere else)
- **Honeypot interactions** (suspicious activity on decoy systems)

Any attack NOT from the Red Team network triggers **critical alerts** and **automated response**.

### 🤖 **Full Automation via n8n**
- Exercise scheduling and lifecycle management
- Automated attack chains (recon → exploit → persistence)
- Real-time detection and scoring
- Incident response orchestration
- Reporting and analytics

### 🏗️ **Infrastructure as Code**
- Entire environment deployed via Terraform/OpenTofu
- Repeatable, version-controlled deployments
- Environment variables for customization
- Scale up/down based on needs

### 🔍 **Existing Wazuh Integration**
- Leverages your existing Wazuh SIEM
- Custom detection rules (100+ rule IDs)
- Active response capabilities
- No need for new SIEM deployment

## Architecture at a Glance

```
┌─────────────────────────────────────────────────────────────┐
│                    n8n Orchestration                         │
│         (Workflow automation + scheduling)                   │
└────────┬─────────────────────────────────────┬──────────────┘
         │                                     │
         │ Provisions                          │ Monitors
         ▼                                     ▼
┌──────────────────────┐          ┌────────────────────────────┐
│ Terraform/OpenTofu   │          │    Wazuh SIEM (existing)   │
│ - Deploys VMs        │◄─────────┤    - Detection rules       │
│ - Configures network │ Webhooks │    - Active response       │
└──────────┬───────────┘          └────────────────────────────┘
           │
           │ Proxmox API
           ▼
┌─────────────────────────────────────────────────────────────┐
│                    Proxmox Environment                       │
│  Red Team (10.0.10/24)  │  Blue Team (10.0.20/24)          │
│  Targets (10.0.30/24)   │  Honeypots (10.0.50/24)          │
└─────────────────────────────────────────────────────────────┘
```

## Components Delivered

### 📁 **Project Structure**

```
projects/security-lab/
├── terraform/
│   ├── main.tf              # VM definitions for all teams
│   ├── variables.tf         # Configurable parameters
│   └── README.md
│
├── n8n-workflows/
│   ├── 01-exercise-orchestrator.json    # Main controller
│   ├── 02-red-team-automation.json      # Attack automation
│   └── [future: blue-team, scoring workflows]
│
├── wazuh/
│   └── rules/
│       └── security-lab-rules.xml       # 100+ custom rules
│
├── README.md                # Quick start guide
├── DEPLOYMENT-GUIDE.md      # Step-by-step deployment
├── ARCHITECTURE.md          # Detailed architecture docs
└── SUMMARY.md              # This file
```

### 🖥️ **Virtual Machines (Terraform)**

**Red Team (Offensive)**:
- CT 110: Kali Linux (primary attack platform)
- CT 111: Parrot OS (alternative toolkit)
- CT 112: C2 Server (Covenant/Sliver)
- CT 113: Phishing infrastructure

**Blue Team (Defensive)**:
- CT 121: SOC Analyst Workstation
- CT 122: MISP Threat Intelligence
- CT 123: Network Monitor (Zeek/Suricata)
- CT 124: Forensics Workstation

**Targets (Vulnerable)**:
- CT 130: Web Server (DVWA, WebGoat)
- CT 131: Windows Server 2022 (AD)
- CT 132: Docker Host (container escapes)
- CT 133: Database Server
- CT 134-139: Additional targets

**Honeypots (Deception)**:
- CT 150: SSH Honeypot (Cowrie)
- CT 151: Web Application Honeypot
- CT 152: Database Honeypot
- CT 153: SMB Honeypot

**Control**:
- CT 140: Purple Team Control Dashboard

### 🔧 **n8n Workflows**

**Exercise Orchestrator** (`01-exercise-orchestrator.json`):
- Webhook trigger: `/start-exercise`
- Verifies VMs are running via Proxmox API
- Enables Wazuh detection rules
- Triggers Red Team attacks
- Activates Blue Team monitoring
- 5-minute monitoring loop
- Detects unauthorized threats
- Sends Slack/email alerts
- Automated scoring

**Red Team Automation** (`02-red-team-automation.json`):
- Webhook trigger: `/red-team/attack`
- 15-minute scheduled attacks
- Multi-phase attack chains:
  1. Reconnaissance (Nmap, Masscan)
  2. Vulnerability scanning (Nuclei, Nikto)
  3. Exploitation (Metasploit, SQLMap)
  4. Post-exploitation (Empire, Mimikatz)
  5. Lateral movement (Impacket, CrackMapExec)
  6. Data exfiltration (custom tools)
- Checks if detected by Blue Team
- Logs results and updates score
- Slack notifications to #red-team

### 🛡️ **Wazuh Detection Rules**

**Rule Categories**:
- **100001-100009**: Red Team activity (authorized)
- **100010-100014**: Unauthorized attacks (CRITICAL)
- **100020-100027**: Honeypot interactions
- **100050-100051**: Blue Team detection/response
- **100060-100065**: Target compromise indicators
- **100100-100103**: Exercise control markers

**Key Logic**:
```
IF source_ip == 10.0.10.0/24
  THEN tag as "Red Team" (authorized)
  AND alert Blue Team
ELSE
  THEN tag as "Black Hat" (CRITICAL)
  AND auto-block IP
  AND alert SOC immediately
```

## Deployment Steps (High-Level)

1. **Prepare VM templates** (Kali, Ubuntu, Windows)
2. **Configure VLANs** on Proxmox
3. **Deploy infrastructure** via Terraform
4. **Install Wazuh rules** on existing SIEM
5. **Import n8n workflows** and configure credentials
6. **Deploy scripts** on Red/Blue Team VMs
7. **Run test exercise** to verify
8. **Deploy honeypots** for enhanced detection
9. **Create control dashboard** (optional)
10. **Start regular exercises**

## How to Use

### Start an Exercise

```bash
# Via n8n webhook
curl -X POST http://n8n.local:5678/webhook/start-exercise \
  -H "Content-Type: application/json" \
  -d '{
    "exercise_id": "redblue-001",
    "exercise_type": "full_spectrum",
    "duration_hours": 8
  }'
```

### Monitor Progress

- **Wazuh Dashboard**: `https://wazuh-manager/app/wazuh`
- **n8n Executions**: `http://n8n.local:5678/executions`
- **Slack Channels**: `#security-exercises`, `#red-team`, `#security-alerts`
- **Purple Control**: `http://10.0.40.140:8080`

### Stop an Exercise

```bash
# Send safe word via any channel
echo "STOPEX-REDBLUE-20251209"

# Or via n8n webhook
curl -X POST http://n8n.local:5678/webhook/stop-exercise \
  -d '{"exercise_id": "redblue-001"}'
```

## Scoring System

### Red Team
- Initial Access: +100
- Persistence: +200
- Lateral Movement: +300
- Privilege Escalation: +400
- Data Exfiltration: +500
- **Penalty**: -50 per detection (when stealth expected)
- **Bonus**: +500 for flag capture

### Blue Team
- Detect Reconnaissance: +100
- Detect Exploitation: +200
- Block Lateral Movement: +300
- Identify All Compromised: +400
- Full IR & Recovery: +500
- **Penalty**: -50 per false positive
- **Critical Penalty**: -1000 for missing Black Hat attack

## Security Features

### Multi-Layer Defense
1. **Network segmentation** (VLANs)
2. **Firewall rules** (drop by default)
3. **Wazuh monitoring** (all VMs including Red Team)
4. **Honeypots** (detect unauthorized access)
5. **Active response** (auto-block threats)
6. **Audit logging** (immutable)

### Threat Detection
- Authorized Red Team: Tagged traffic, monitored
- Unauthorized attacks: Immediate CRITICAL alert
- Honeypot interactions: High-severity alert
- Target compromise: Real-time detection

## Integration with Cortex (Optional)

While this lab runs **independently**, you can optionally integrate with Cortex for:
- AI-powered attack analysis
- Automated playbook generation
- Pattern recognition across exercises
- Executive reporting with natural language summaries

To enable: `terraform apply -var="enable_cortex_integration=true"`

## Benefits

### For Security Teams
- **Continuous validation** of security controls
- **Realistic attack simulations** without risk
- **Skill development** for SOC analysts
- **Threat hunting** practice
- **Incident response** drills

### For Organization
- **Reduced risk** through proactive testing
- **Compliance** (demonstrate security testing)
- **Metrics** (MTTD, MTTR, coverage)
- **Cost savings** (in-house vs. external pentests)

### For Detection Engineering
- **Tune detection rules** with real attacks
- **Reduce false positives** through testing
- **Validate coverage** of attack techniques
- **Document blind spots** for remediation

## Cost Considerations

### Infrastructure
- **Proxmox**: Already owned (zero additional cost)
- **Wazuh**: Already deployed (zero additional cost)
- **VMs**: ~15 VMs @ 2-8GB RAM each = 60-100GB total RAM
- **Storage**: ~1TB for all VMs (templates can be shared)

### Software
- **Terraform/OpenTofu**: Free and open source
- **n8n**: Free self-hosted version
- **Kali Linux**: Free
- **All security tools**: Free and open source

**Total Additional Cost**: ~$0 (leverages existing infrastructure)

## Maintenance

### Regular Tasks
- Update VM templates monthly
- Rotate credentials quarterly
- Archive exercise results weekly
- Review and tune Wazuh rules monthly
- Update n8n workflows as needed

### Time Investment
- **Initial setup**: 1-2 days (with guide)
- **Exercise creation**: 1-2 hours per scenario
- **Monthly maintenance**: 2-4 hours
- **Exercise runtime**: Automated (zero manual time)

## Success Metrics

Track these KPIs:
- **Blue Team MTTD** (Mean Time to Detect): Target < 5 minutes
- **Blue Team MTTR** (Mean Time to Respond): Target < 15 minutes
- **Red Team Success Rate**: Should decrease over time
- **False Positive Rate**: Target < 5%
- **Coverage**: % of MITRE ATT&CK techniques tested

## Next Steps

1. **Review documentation**:
   - `README.md` for quick start
   - `DEPLOYMENT-GUIDE.md` for step-by-step instructions
   - `ARCHITECTURE.md` for deep dive

2. **Prepare prerequisites**:
   - VM templates
   - Wazuh API credentials
   - n8n installation
   - Terraform installed

3. **Deploy Phase 1**:
   - Deploy core Red/Blue/Target VMs
   - Install Wazuh rules
   - Import n8n workflows

4. **Run first exercise**:
   - Start with simple reconnaissance scenario
   - Verify detection and alerting
   - Review results

5. **Expand gradually**:
   - Add more attack scenarios
   - Deploy honeypots
   - Tune detection rules
   - Add automated responses

## Support & Resources

### Documentation
- [Terraform Proxmox Provider](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [n8n Documentation](https://docs.n8n.io/)
- [Wazuh Ruleset](https://documentation.wazuh.com/current/user-manual/ruleset/index.html)
- [MITRE ATT&CK](https://attack.mitre.org/)

### Community
- Proxmox Forums
- n8n Community
- Wazuh Slack
- /r/netsec, /r/blueteamsec, /r/redteamsec

## Conclusion

This security lab provides a **production-grade testing environment** that:
- ✅ Runs on existing infrastructure (Proxmox + Wazuh)
- ✅ Fully automated via n8n workflows
- ✅ Provisioned as code via Terraform
- ✅ Detects both Red Team and real threats
- ✅ Provides continuous security validation
- ✅ Zero additional licensing costs

**Most importantly**: It's not just Red vs Blue—it also detects **unauthorized threats** that aren't part of the exercise, making it a true security validation and threat detection platform.

---

**Ready to deploy?** Start with `DEPLOYMENT-GUIDE.md`

**Questions about architecture?** See `ARCHITECTURE.md`

**Quick start?** Check `README.md`

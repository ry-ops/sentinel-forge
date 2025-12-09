# Security Lab Deployment Guide

Complete step-by-step guide to deploy the Red vs Blue Team environment on Proxmox using Terraform/OpenTofu and n8n.

## Prerequisites Checklist

Before starting, ensure you have:

- [ ] **Proxmox VE** 7.x or 8.x installed and accessible
- [ ] **Wazuh SIEM** already deployed (you mentioned this exists)
- [ ] **n8n** instance running (we'll configure this)
- [ ] **Terraform/OpenTofu** >= 1.0 installed on your workstation
- [ ] **SSH access** to Proxmox host
- [ ] **VM templates** prepared (or we'll create them)
- [ ] **Network VLANs** configured on Proxmox bridge

## Phase 1: Prepare VM Templates

### 1.1 Create Kali Linux Template

```bash
# Download Kali Linux cloud image
cd /var/lib/vz/template/iso/
wget https://cdimage.kali.org/kali-2024.4/kali-linux-2024.4-qemu-amd64.qcow2

# Create VM from image
qm create 9110 --name kali-linux-template --memory 4096 --cores 2 --net0 virtio,bridge=vmbr0

# Import disk
qm importdisk 9110 kali-linux-2024.4-qemu-amd64.qcow2 local-lvm

# Attach disk
qm set 9110 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9110-disk-0

# Set boot order
qm set 9110 --boot c --bootdisk scsi0

# Add cloud-init drive
qm set 9110 --ide2 local-lvm:cloudinit

# Enable serial console
qm set 9110 --serial0 socket --vga serial0

# Start VM and configure
qm start 9110

# SSH into VM and install tools
ssh kali@<VM-IP>
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
  nmap masscan nuclei nikto sqlmap \
  metasploit-framework burpsuite \
  impacket crackmapexec bloodhound \
  empire covenant-kbx mimikatz \
  docker.io docker-compose

# Shutdown and convert to template
qm shutdown 9110
qm template 9110
```

### 1.2 Create Ubuntu 22.04 Template

```bash
# Download Ubuntu cloud image
cd /var/lib/vz/template/iso/
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# Create template VM
qm create 9120 --name ubuntu-22-04-template --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 9120 jammy-server-cloudimg-amd64.img local-lvm
qm set 9120 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9120-disk-0
qm set 9120 --boot c --bootdisk scsi0
qm set 9120 --ide2 local-lvm:cloudinit
qm set 9120 --serial0 socket --vga serial0
qm set 9120 --agent enabled=1

# Install Wazuh agent in template
qm start 9120
ssh ubuntu@<VM-IP>

# Install Wazuh agent
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import
chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list

apt update
apt install -y wazuh-agent

# Configure Wazuh manager (use your existing Wazuh IP)
echo "WAZUH_MANAGER='<YOUR-WAZUH-MANAGER-IP>'" >> /var/ossec/etc/ossec.conf
systemctl enable wazuh-agent
systemctl stop wazuh-agent  # Will start on clone

# Shutdown and template
sudo shutdown -h now
qm template 9120
```

### 1.3 Create Parrot OS Template (Optional)

```bash
# Similar process to Kali
# Download from https://parrotsec.org/download/
```

### 1.4 Create Windows Server 2022 Template

```bash
# Download Windows Server 2022 ISO
# Upload to Proxmox via web UI: Datacenter > pve > local (pve) > ISO Images

# Create VM
qm create 9131 --name windows-server-2022-template \
  --memory 8192 --cores 4 --net0 virtio,bridge=vmbr0 \
  --ide2 local:iso/windows-server-2022.iso,media=cdrom \
  --ostype win11

# Add virtio drivers
qm set 9131 --ide0 local:iso/virtio-win.iso,media=cdrom

# Provision via UI, install Windows, install Wazuh agent
# Then convert to template
```

## Phase 2: Configure Network VLANs

### 2.1 Create VLANs on Proxmox Bridge

```bash
# SSH to Proxmox host
ssh root@proxmox.local

# Edit network configuration
nano /etc/network/interfaces

# Add VLANs (if not already configured)
auto vmbr0.10
iface vmbr0.10 inet static
    address 10.0.10.1/24
    vlan-raw-device vmbr0

auto vmbr0.20
iface vmbr0.20 inet static
    address 10.0.20.1/24
    vlan-raw-device vmbr0

auto vmbr0.30
iface vmbr0.30 inet static
    address 10.0.30.1/24
    vlan-raw-device vmbr0

auto vmbr0.40
iface vmbr0.40 inet static
    address 10.0.40.1/24
    vlan-raw-device vmbr0

auto vmbr0.50
iface vmbr0.50 inet static
    address 10.0.50.1/24
    vlan-raw-device vmbr0

# Apply changes
ifreload -a
```

### 2.2 Configure Firewall Rules (Optional)

```bash
# Create firewall rules to isolate networks
# Proxmox UI > Datacenter > Firewall > Add

# Example: Block Target -> Management
# Direction: IN
# Action: DROP
# Source: 10.0.30.0/24
# Destination: 10.0.0.0/24
```

## Phase 3: Deploy Infrastructure with Terraform

### 3.1 Install Terraform/OpenTofu

```bash
# On your workstation (macOS)
brew install opentofu

# Or install Terraform
brew install terraform
```

### 3.2 Configure Terraform Variables

```bash
cd /Users/ryandahlberg/Projects/cortex/projects/security-lab/terraform/

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
# Proxmox Configuration
proxmox_api_url      = "https://<YOUR-PROXMOX-IP>:8006/api2/json"
proxmox_user         = "root@pam"
proxmox_password     = "<YOUR-PROXMOX-PASSWORD>"
proxmox_node         = "pve"
proxmox_tls_insecure = true

# SSH Key
ssh_public_key = "$(cat ~/.ssh/id_rsa.pub)"

# Exercise Configuration
exercise_id          = "redblue-lab-prod"
exercise_type        = "full_spectrum"
enable_honeypots     = true

# Wazuh Configuration
wazuh_config = {
  manager_url  = "https://<YOUR-WAZUH-IP>"
  manager_port = 55000
  api_user     = "wazuh-api"
  api_password = "<YOUR-WAZUH-API-PASSWORD>"
}

# n8n Configuration
n8n_config = {
  url         = "http://<YOUR-N8N-IP>:5678"
  webhook_url = "http://<YOUR-N8N-IP>:5678/webhook"
  api_key     = "<YOUR-N8N-API-KEY>"
}
EOF

# Secure the file
chmod 600 terraform.tfvars
```

### 3.3 Initialize and Deploy

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan deployment (review changes)
terraform plan

# Deploy infrastructure
terraform apply

# Save output
terraform output > ../deployment-output.json
```

### 3.4 Verify VMs are Running

```bash
# Check Proxmox via CLI
ssh root@proxmox.local 'qm list'

# Should see VMs 110-153 running

# Or via Terraform
terraform show
```

## Phase 4: Configure Wazuh

### 4.1 Install Custom Detection Rules

```bash
# Copy rules to Wazuh manager
cd /Users/ryandahlberg/Projects/cortex/projects/security-lab/

scp wazuh/rules/security-lab-rules.xml \
  root@<WAZUH-MANAGER-IP>:/var/ossec/etc/rules/

# SSH to Wazuh manager
ssh root@<WAZUH-MANAGER-IP>

# Set permissions
chown root:wazuh /var/ossec/etc/rules/security-lab-rules.xml
chmod 640 /var/ossec/etc/rules/security-lab-rules.xml

# Restart Wazuh to load rules
systemctl restart wazuh-manager

# Verify rules loaded
grep -r "100001" /var/ossec/etc/rules/
```

### 4.2 Configure Active Response

```bash
# Edit ossec.conf on Wazuh manager
nano /var/ossec/etc/ossec.conf

# Add active response for unauthorized attacks
<active-response>
  <command>firewall-drop</command>
  <location>defined-agent</location>
  <rules_id>100010,100011,100012,100013,100014</rules_id>
  <timeout>3600</timeout>
</active-response>

<active-response>
  <command>firewall-drop</command>
  <location>defined-agent</location>
  <rules_id>100021,100023,100025,100027</rules_id>
  <timeout>7200</timeout>
</active-response>

# Restart
systemctl restart wazuh-manager
```

### 4.3 Create Wazuh API User for n8n

```bash
# SSH to Wazuh manager
ssh root@<WAZUH-MANAGER-IP>

# Create API user
curl -k -X POST "https://localhost:55000/security/users" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(cat /var/ossec/api/configuration/auth/user)" \
  -d '{
    "username": "n8n-automation",
    "password": "STRONG-PASSWORD-HERE"
  }'

# Generate API token
curl -k -X POST "https://localhost:55000/security/user/authenticate" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "n8n-automation",
    "password": "STRONG-PASSWORD-HERE"
  }'

# Save the token - you'll need it for n8n
```

## Phase 5: Deploy n8n Workflows

### 5.1 Install n8n (if not already installed)

```bash
# Option 1: Docker (recommended)
docker run -d \
  --name n8n \
  -p 5678:5678 \
  -v n8n_data:/home/node/.n8n \
  -e N8N_SECURE_COOKIE=false \
  n8nio/n8n

# Option 2: npm
npm install -g n8n
n8n start
```

### 5.2 Configure n8n Credentials

```bash
# Access n8n web UI
open http://<N8N-IP>:5678

# Navigate to: Credentials > Add Credential

# Add Proxmox API credential
# Type: HTTP Header Auth
# Name: Proxmox-API
# Header Name: Authorization
# Header Value: PVEAPIToken=root@pam!n8n=<YOUR-PROXMOX-TOKEN>

# Add Wazuh API credential
# Type: HTTP Header Auth
# Name: Wazuh-API
# Header Name: Authorization
# Header Value: Bearer <YOUR-WAZUH-API-TOKEN>

# Add Slack webhook (optional)
# Type: Slack
# Webhook URL: <YOUR-SLACK-WEBHOOK>
```

### 5.3 Import Workflows

```bash
# In n8n UI:
# 1. Click "Workflows" > "Import from File"
# 2. Import each workflow:

# - n8n-workflows/01-exercise-orchestrator.json
# - n8n-workflows/02-red-team-automation.json
# - n8n-workflows/03-blue-team-response.json (if created)
# - n8n-workflows/04-purple-team-scoring.json (if created)

# 3. For each workflow:
#    - Update credentials (select your configured credentials)
#    - Update environment variables
#    - Activate the workflow
```

### 5.4 Set n8n Environment Variables

```bash
# Edit n8n environment
nano ~/.n8n/.env

# Add variables
PROXMOX_API_URL=https://<PROXMOX-IP>:8006/api2/json
PROXMOX_NODE=pve
PROXMOX_TOKEN=<YOUR-TOKEN>

WAZUH_API_URL=https://<WAZUH-IP>:55000
WAZUH_API_TOKEN=<YOUR-TOKEN>

N8N_WEBHOOK_URL=http://<N8N-IP>:5678/webhook

# Restart n8n
docker restart n8n
# or
systemctl restart n8n
```

## Phase 6: Deploy Red Team Scripts

### 6.1 Install Red Team Automation Scripts

```bash
# SSH to Kali VM (CT 110)
ssh root@10.0.10.110

# Create directory structure
mkdir -p /opt/red-team/{scenarios,results,logs}

# Create main attack script
cat > /opt/red-team/start-exercise.sh <<'EOF'
#!/bin/bash
EXERCISE_ID="$1"
TARGET="${2:-10.0.30.0/24}"
LOG_DIR="/opt/red-team/logs"

mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_DIR/${EXERCISE_ID}.log")
exec 2>&1

echo "[$(date)] Starting Red Team exercise: $EXERCISE_ID"
echo "[$(date)] Target: $TARGET"

# Tag all traffic with exercise ID
export HTTP_USER_AGENT="RedTeam/${EXERCISE_ID}"
export EXERCISE_ID

# Phase 1: Reconnaissance
echo "[$(date)] Phase 1: Reconnaissance"
nmap -sV -O --script-args http.useragent="${HTTP_USER_AGENT}" \
  -oJ "/opt/red-team/results/${EXERCISE_ID}-recon.json" \
  "$TARGET"

# Phase 2: Vulnerability scanning
echo "[$(date)] Phase 2: Vulnerability Scanning"
nuclei -target "$TARGET" \
  -json -output "/opt/red-team/results/${EXERCISE_ID}-vulns.json" \
  -header "User-Agent: ${HTTP_USER_AGENT}"

echo "[$(date)] Red Team exercise $EXERCISE_ID completed"
EOF

chmod +x /opt/red-team/start-exercise.sh
```

### 6.2 Install Attack Scenario Scripts

```bash
# Create scenario-specific scripts
# /opt/red-team/scenarios/web-attack.sh
# /opt/red-team/scenarios/lateral-movement.sh
# /opt/red-team/scenarios/privilege-escalation.sh
# etc.

# See examples in project repository
```

## Phase 7: Deploy Blue Team Detection

### 7.1 Install Blue Team Scripts on SOC VM

```bash
# SSH to Blue Team SOC (CT 121)
ssh root@10.0.20.121

# Create directory
mkdir -p /opt/blue-team/{detection,response,reports}

# Create monitoring script
cat > /opt/blue-team/start-monitoring.sh <<'EOF'
#!/bin/bash
EXERCISE_ID="$1"
WAZUH_API="${WAZUH_API_URL:-https://wazuh-manager:55000}"
LOG_DIR="/opt/blue-team/logs"

mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_DIR/${EXERCISE_ID}.log")
exec 2>&1

echo "[$(date)] Starting Blue Team monitoring: $EXERCISE_ID"

# Monitor Wazuh alerts in real-time
while true; do
  curl -k -X GET "${WAZUH_API}/security/alerts" \
    -H "Authorization: Bearer ${WAZUH_API_TOKEN}" \
    -d '{"rule.groups": "red_team,unauthorized_attack,honeypot"}' \
    | jq -r '.data.affected_items[] | "\(.timestamp) | \(.rule.id) | \(.data.srcip) | \(.rule.description)"'

  sleep 30
done
EOF

chmod +x /opt/blue-team/start-monitoring.sh
```

## Phase 8: Test Deployment

### 8.1 Start First Exercise

```bash
# From your workstation, trigger via n8n webhook
curl -X POST http://<N8N-IP>:5678/webhook/start-exercise \
  -H "Content-Type: application/json" \
  -d '{
    "exercise_id": "test-001",
    "exercise_type": "reconnaissance",
    "duration_hours": 1,
    "target_network": "10.0.30.0/24"
  }'

# Should return:
# {
#   "success": true,
#   "exercise_id": "test-001",
#   "status": "started"
# }
```

### 8.2 Verify Red Team Activity

```bash
# SSH to Red Team VM
ssh root@10.0.10.110

# Check logs
tail -f /opt/red-team/logs/test-001.log

# Should see reconnaissance activity starting
```

### 8.3 Verify Blue Team Detection

```bash
# SSH to Wazuh manager
ssh root@<WAZUH-MANAGER-IP>

# Query recent alerts
curl -k -X GET "https://localhost:55000/security/alerts" \
  -H "Authorization: Bearer $(cat /var/ossec/api/configuration/auth/user)" \
  | jq '.data.affected_items[] | select(.rule.groups[] | contains("red_team"))'

# Should see alerts with rule IDs 100001-100009
```

### 8.4 Check Slack Notifications (if configured)

```bash
# Check your Slack channel #security-exercises
# Should see messages like:
# "📊 Exercise Status Update"
# "Exercise ID: test-001"
# "Status: active"
```

## Phase 9: Deploy Honeypots

### 9.1 Install SSH Honeypot (Cowrie)

```bash
# SSH to honeypot VM (CT 150)
ssh root@10.0.50.150

# Install dependencies
apt update
apt install -y python3 python3-pip git virtualenv

# Clone Cowrie
cd /opt
git clone https://github.com/cowrie/cowrie.git
cd cowrie

# Setup virtualenv
virtualenv cowrie-env
source cowrie-env/bin/activate
pip install -r requirements.txt

# Configure
cp etc/cowrie.cfg.dist etc/cowrie.cfg
nano etc/cowrie.cfg

# Start Cowrie
bin/cowrie start

# Configure to forward logs to Wazuh
# Edit /var/ossec/etc/ossec.conf to monitor /opt/cowrie/var/log/cowrie/cowrie.json
```

### 9.2 Install Web Honeypot (Snare/Tanner)

```bash
# SSH to web honeypot (CT 151)
ssh root@10.0.50.151

# Install Snare
pip3 install snare

# Run Snare
snare --host-ip 10.0.50.151 --port 80 &

# Configure Wazuh to monitor Snare logs
```

## Phase 10: Create Control Dashboard

### 10.1 Deploy Simple Web Dashboard (Optional)

```bash
# SSH to Purple Team control (CT 140)
ssh root@10.0.40.140

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Create simple dashboard
mkdir -p /opt/control-dashboard
cd /opt/control-dashboard

# Initialize npm project
npm init -y
npm install express ws body-parser

# Create server.js (see example in repo)
# Start dashboard
node server.js &
```

## Phase 11: Final Verification

### 11.1 Run Complete Exercise

```bash
# Start full spectrum exercise
curl -X POST http://<N8N-IP>:5678/webhook/start-exercise \
  -H "Content-Type: application/json" \
  -d '{
    "exercise_id": "full-test-001",
    "exercise_type": "full_spectrum",
    "duration_hours": 2,
    "target_network": "10.0.30.0/24"
  }'
```

### 11.2 Verify All Components

- [ ] Red Team VMs accessible and attacking
- [ ] Blue Team detecting Red Team activity in Wazuh
- [ ] Honeypots logging interactions
- [ ] n8n workflows executing successfully
- [ ] Slack notifications arriving (if configured)
- [ ] Scoring system tracking points
- [ ] No unauthorized alerts (unless testing Black Hat detection)

### 11.3 Test Black Hat Detection

```bash
# From OUTSIDE 10.0.10.0/24, run an attack
# Example: from your workstation

nmap -sV 10.0.30.130

# Should trigger critical alert:
# Rule 100010: "CRITICAL: Unauthorized attack from X.X.X.X - NOT RED TEAM!"

# Check Slack for critical alert
# Check if IP was auto-blocked
```

## Troubleshooting

### Issue: VMs not starting

```bash
# Check Proxmox logs
ssh root@proxmox.local 'tail -f /var/log/pve/tasks/active'

# Check specific VM
qm status 110
```

### Issue: Wazuh agents not connecting

```bash
# On agent VM
systemctl status wazuh-agent
tail -f /var/ossec/logs/ossec.log

# On manager
/var/ossec/bin/agent_control -l
```

### Issue: n8n workflows failing

```bash
# Check n8n logs
docker logs -f n8n

# Or if running as service
journalctl -u n8n -f
```

## Next Steps

1. **Schedule regular exercises** via n8n cron triggers
2. **Add more attack scenarios** in Red Team automation
3. **Tune Wazuh detection rules** based on false positives
4. **Integrate with Cortex** (optional) for AI-powered analysis
5. **Create executive dashboards** for reporting

---

**Deployment Complete!** 🎉

Your Red vs Blue Team security lab is now operational.

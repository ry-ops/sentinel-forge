# Variables for Security Lab Infrastructure

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  default     = ""
}

# Exercise-specific variables
variable "exercise_type" {
  description = "Type of exercise: full_spectrum, web_only, network_only, etc."
  type        = string
  default     = "full_spectrum"

  validation {
    condition = contains([
      "full_spectrum",
      "web_only",
      "network_only",
      "container_escape",
      "ad_attack",
      "purple_team_walkthrough"
    ], var.exercise_type)
    error_message = "Exercise type must be a valid exercise scenario."
  }
}

variable "enable_honeypots" {
  description = "Deploy honeypot infrastructure"
  type        = bool
  default     = true
}

variable "enable_blue_team_automation" {
  description = "Enable automated Blue Team responses"
  type        = bool
  default     = true
}

variable "exercise_duration_hours" {
  description = "Duration of security exercise in hours"
  type        = number
  default     = 8
}

# Red Team configuration
variable "red_team_config" {
  description = "Red Team configuration"
  type = object({
    enable_c2              = bool
    enable_phishing        = bool
    attack_intensity       = string
    stealth_level         = string
  })
  default = {
    enable_c2        = true
    enable_phishing  = false
    attack_intensity = "medium"  # low, medium, high, max
    stealth_level    = "normal"  # loud, normal, stealthy, ninja
  }
}

# Blue Team configuration
variable "blue_team_config" {
  description = "Blue Team configuration"
  type = object({
    auto_response_enabled = bool
    alert_threshold       = string
    blocking_enabled      = bool
  })
  default = {
    auto_response_enabled = true
    alert_threshold       = "medium"  # low, medium, high, critical
    blocking_enabled      = false     # Set true for aggressive blocking
  }
}

# Target environment configuration
variable "target_config" {
  description = "Target environment configuration"
  type = object({
    vulnerability_level = string
    deploy_web         = bool
    deploy_windows     = bool
    deploy_docker      = bool
    deploy_database    = bool
  })
  default = {
    vulnerability_level = "high"  # low, medium, high, critical
    deploy_web         = true
    deploy_windows     = true
    deploy_docker      = true
    deploy_database    = false
  }
}

# Wazuh integration
variable "wazuh_config" {
  description = "Wazuh SIEM configuration"
  type = object({
    manager_url    = string
    manager_port   = number
    api_user       = string
    api_password   = string
  })
  default = {
    manager_url  = "https://wazuh-manager.local"
    manager_port = 55000
    api_user     = "wazuh-api"
    api_password = ""  # Set via environment variable
  }
  sensitive = true
}

# n8n integration
variable "n8n_config" {
  description = "n8n workflow automation configuration"
  type = object({
    url          = string
    webhook_url  = string
    api_key      = string
  })
  default = {
    url         = "https://n8n.local:5678"
    webhook_url = "https://n8n.local:5678/webhook"
    api_key     = ""  # Set via environment variable
  }
  sensitive = true
}

# Scoring and metrics
variable "scoring_config" {
  description = "Exercise scoring configuration"
  type = object({
    red_team_objective_points  = map(number)
    blue_team_objective_points = map(number)
    penalties                  = map(number)
  })
  default = {
    red_team_objective_points = {
      initial_access       = 100
      persistence         = 200
      lateral_movement    = 300
      privilege_escalation = 400
      data_exfiltration   = 500
    }
    blue_team_objective_points = {
      detect_recon         = 100
      detect_exploitation  = 200
      block_lateral        = 300
      identify_compromised = 400
      full_ir_recovery     = 500
    }
    penalties = {
      red_out_of_scope     = -500
      blue_false_positive  = -50
      missed_black_hat     = -1000
    }
  }
}

# Tags for organization
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "security-lab"
    ManagedBy   = "terraform"
    Project     = "red-vs-blue"
    Owner       = "security-team"
  }
}

# Contributing to Sentinel Forge

Thank you for your interest in contributing to Sentinel Forge! This document provides guidelines for contributing to the project.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR-USERNAME/sentinel-forge.git`
3. Create a feature branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Test thoroughly
6. Commit with clear messages
7. Push to your fork
8. Open a Pull Request

## Areas for Contribution

### 1. Red Team Scenarios
Add new attack scenarios to `n8n-workflows/02-red-team-automation.json` or create standalone scripts:
- Web application attacks
- Container escape techniques
- Active Directory attacks
- API exploitation
- Social engineering simulations

### 2. Detection Rules
Enhance `wazuh/rules/security-lab-rules.xml` with:
- New attack pattern detection
- Improved false positive reduction
- Coverage for emerging threats
- MITRE ATT&CK technique mapping

### 3. Infrastructure Components
Add to `terraform/main.tf`:
- New target VM types
- Additional honeypots
- Specialized environments (IoT, cloud, etc.)
- Enhanced network configurations

### 4. n8n Workflows
Create new workflows for:
- Blue Team automated response
- Purple Team scoring and reporting
- Threat intelligence integration
- Executive dashboards

### 5. Documentation
Improve:
- Setup guides
- Troubleshooting tips
- Use case examples
- Architecture diagrams

## Code Style

### Terraform
- Use consistent naming: `resource_type_purpose_id`
- Comment complex configurations
- Use variables for reusable values
- Follow HashiCorp style guide

### n8n Workflows
- Use descriptive node names
- Add comments for complex logic
- Test all branches
- Document required credentials

### Wazuh Rules
- Follow rule ID scheme (see existing rules)
- Include clear descriptions
- Test with real attack traffic
- Document false positive scenarios

### Shell Scripts
- Use bash shebang: `#!/bin/bash`
- Set strict mode: `set -euo pipefail`
- Add function documentation
- Handle errors gracefully

## Testing Requirements

Before submitting a PR, ensure:

1. **Terraform Changes**:
   ```bash
   terraform init
   terraform validate
   terraform plan
   ```

2. **Wazuh Rules**:
   - Load rules on test Wazuh manager
   - Verify no syntax errors
   - Test with sample attack traffic
   - Verify no conflicts with existing rules

3. **n8n Workflows**:
   - Import workflow to test instance
   - Execute all branches
   - Verify error handling
   - Test webhook triggers

4. **Attack Scenarios**:
   - Run in isolated environment
   - Verify detection by Blue Team
   - Confirm scoring updates
   - Check for unintended side effects

## Security Guidelines

### Critical Rules

1. **Never commit secrets**:
   - API keys
   - Passwords
   - Private keys
   - Tokens
   - Credentials

2. **Sanitize logs and examples**:
   - Remove IP addresses
   - Redact hostnames
   - Strip sensitive data

3. **Test attack code safely**:
   - Only run in isolated lab environment
   - Never target production systems
   - Respect rules of engagement

4. **Document security implications**:
   - Note potential for misuse
   - Describe mitigation strategies
   - Reference responsible disclosure

## Pull Request Process

1. **Update documentation** if adding features
2. **Add tests** for new functionality
3. **Update CHANGELOG.md** (if one exists)
4. **Ensure all checks pass**
5. **Request review** from maintainers
6. **Address feedback** promptly
7. **Squash commits** if requested

## Commit Message Guidelines

Use conventional commit format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples**:
```
feat(red-team): Add SQL injection attack scenario

Implements automated SQLMap attacks against web targets
with detection validation and scoring.

Closes #42
```

```
fix(wazuh): Correct false positive in rule 100003

Web scanning rule was triggering on legitimate traffic.
Updated pattern matching to reduce false positives.
```

## Code of Conduct

- Be respectful and professional
- Focus on constructive feedback
- Help others learn and grow
- Report security issues privately
- Use tools responsibly and ethically

## Questions?

- Open an issue for discussion
- Check existing issues and PRs
- Review documentation thoroughly
- Test in your own environment first

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing to Sentinel Forge!** 🛡️⚔️

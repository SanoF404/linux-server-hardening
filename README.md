# Linux Server Hardening

## Overview

Linux Server Hardening is a defensive security auditing project developed with Bash. It checks selected Linux security settings and generates timestamped audit reports.

## Features

- Operating system and kernel information
- Detection of accounts with UID 0
- UFW firewall status check
- SSH service and socket status
- Permissions checks for `/etc/passwd` and `/etc/shadow`
- Overview of listening network ports
- Timestamped audit reports
- Automated tests for expected audit output

## Requirements

- Ubuntu or another Linux environment
- Bash
- Standard command-line utilities
- `sudo` access for certain checks
- ShellCheck for static analysis

## Usage

Run the audit:

```bash
bash scripts/audit.sh
```

Run the automated tests:

```bash
bash tests/test_audit.sh
```

Check the scripts:

```bash
shellcheck scripts/audit.sh tests/test_audit.sh
```

## Test Results

- Automated tests: 7/7 passed
- Bash syntax validation: passed
- ShellCheck: no warnings reported

## Security Notes

This project performs security checks without automatically changing firewall rules, SSH configuration, or system permissions.

A warning does not necessarily indicate a vulnerability. Results must be interpreted in the context of the system being audited.

The project has been tested on Ubuntu under WSL2. Results may differ on a physical Linux server or another distribution.

## Future Improvements

- Additional SSH configuration checks
- Package update status checks
- More comprehensive automated tests
- Improved audit reports and documentation

## Disclaimer

This project is intended for authorized defensive security auditing and educational purposes.
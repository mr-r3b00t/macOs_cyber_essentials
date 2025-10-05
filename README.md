# macOS Security Report Script Documentation

## Overview

This Bash script generates a comprehensive security report for macOS systems (compatible with both Intel and Apple Silicon/ARM architectures). It checks key security features including FileVault encryption, automatic software updates, telemetry (analytics) settings, firewall status, and sharing services. The script outputs the results to both the console and a timestamped text file (e.g., `security_report_YYYYMMDD_HHMMSS.txt`).

The report includes:
- **Status** of each feature.
- **Compliance** assessment based on recommended security practices:
  - FileVault: Should be **enabled**.
  - Automatic Updates: At least one setting should be **enabled**.
  - Telemetry: Should be **disabled**.
  - Firewall: Should be **enabled**.
  - Sharing Services: Should be **disabled** (none enabled).

The script requires `sudo` privileges for some checks (e.g., updates, telemetry, and sharing services). Run it with `sudo ./script.sh` for full functionality.

## Script Structure

The script is structured as follows:
1. **Header and Report Initialization**: Sets up the report file with a timestamp.
2. **Helper Function**: `add_to_report()` appends lines to the report file.
3. **Individual Checks**: Each security feature is checked in sequence.
4. **Output**: Displays the report to the console and notes the file location.

Key dependencies:
- macOS system commands: `fdesetup`, `defaults`, `launchctl`, `/usr/libexec/ApplicationFirewall/socketfilterfw`.
- No external packages required.

## Detailed Checks

### 1. FileVault Status
- **Purpose**: Verifies if full-disk encryption (FileVault) is enabled to protect data at rest.
- **Command Used**: `fdesetup status | head -n1`
- **Expected Output**: "FileVault is On." for enabled status.
- **Compliance Logic**: PASS if "FileVault is On"; otherwise FAIL.
- **Files/Settings Involved**:
  - No specific plist file; relies on the `fdesetup` tool, which queries the system's Core Storage encryption status.
- **Notes**: This check does not require sudo.

### 2. Automatic Updates
- **Purpose**: Ensures automatic checking, downloading, and installation of updates to keep the system patched against vulnerabilities.
- **Commands Used**: `sudo defaults read` on various plist keys.
- **Specific Settings Checked**:
  | Setting | Plist File | Key | Description | Compliance |
  |---------|------------|-----|-------------|------------|
  | Check for updates | `/Library/Preferences/com.apple.SoftwareUpdate.plist` | `AutomaticCheckEnabled` | Enables periodic checks for available updates. | Enabled (1) = PASS if any setting is enabled. |
  | Download updates | `/Library/Preferences/com.apple.SoftwareUpdate.plist` | `AutomaticDownload` | Automatically downloads updates when available. | Enabled (1) = PASS if any setting is enabled. |
  | Install macOS updates | `/Library/Preferences/com.apple.SoftwareUpdate.plist` | `AutomaticallyInstallMacOSUpdates` | Automatically installs macOS updates. | Enabled (1) = PASS if any setting is enabled. |
  | Install Security Responses and system files | `/Library/Preferences/com.apple.SoftwareUpdate.plist` | `ConfigDataInstall` | Automatically installs security responses and system data files. | Enabled (1) = PASS if any setting is enabled. |
  | App Store auto updates | `/Library/Preferences/com.apple.commerce.plist` | `AutoUpdate` | Enables automatic updates for App Store apps. | Enabled (1) = PASS if any setting is enabled. |
- **Compliance Logic**: PASS if at least one key is set to `1` (enabled); otherwise FAIL.
- **Notes**: Defaults to `1` (enabled) if the key is not found (assumes default macOS behavior). Requires sudo.

### 3. Telemetry (Analytics & Improvements)
- **Purpose**: Checks if data collection for analytics and crash reporting is disabled to enhance privacy.
- **Command Used**: `sudo defaults read /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory.plist AutoSubmit`
- **Specific Settings Involved**:
  | Setting | Plist File | Key | Description | Compliance |
  |---------|------------|-----|-------------|------------|
  | Auto-submit diagnostics | `/Library/Application Support/CrashReporter/DiagnosticMessagesHistory.plist` | `AutoSubmit` | Controls automatic submission of diagnostic data. | Disabled (0) = PASS. |
- **Compliance Logic**: PASS if `0` (disabled); otherwise FAIL.
- **Notes**: Defaults to `1` (enabled) if the key or file is not found. This primarily checks crash reporter telemetry; broader analytics may involve additional plists like `com.apple.analyticsd.plist` (key: `analyticsd-disabled`).

### 4. Firewall
- **Purpose**: Verifies if the built-in application firewall is active to block unauthorized network access.
- **Command Used**: `/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate`
- **Specific Settings Involved**:
  - No direct plist read; uses the `socketfilterfw` binary to query the global state.
  - Equivalent plist: `/Library/Preferences/com.apple.alf.plist` (key: `globalstate`), but the binary is more reliable.
- **Parsing Logic**: Extracts "State = 1" from output for enabled status.
- **Compliance Logic**: PASS if `1` (enabled); otherwise FAIL.
- **Notes**: Includes raw output in the report for debugging. Does not require sudo.

### 5. Sharing Services
- **Purpose**: Detects if network sharing services are enabled, which could expose the system to remote attacks.
- **Command Used**: `sudo launchctl list | grep` for specific service labels.
- **Specific Services Checked**:
  | Service | Launch Daemon/Agent Label | Description | Compliance |
  |---------|---------------------------|-------------|------------|
  | Screen Sharing | `com.apple.screensharing` | Allows remote screen control (VNC/AR D). | Disabled = PASS. |
  | Printer Sharing | `org.cups.cupsd` | Shares printers over the network. | Disabled = PASS. |
  | File Sharing (SMB) | `com.apple.smbd` | Enables SMB file sharing. | Disabled = PASS. |
  | Remote Login (SSH) | `com.openssh.sshd` | Allows SSH remote access. | Disabled = PASS. |
  | Internet Sharing | `com.apple.nat` | Shares internet connection via NAT. | Disabled = PASS. |
  | Remote Management | `com.apple.RemoteDesktop` | Allows Apple Remote Desktop access. | Disabled = PASS. |
- **Compliance Logic**: PASS if no services are running; otherwise FAIL with a list of enabled ones.
- **Notes**: Relies on `launchctl` to list active processes. Services may vary by macOS version; additional ones (e.g., AirDrop) are not checked here. Requires sudo.

## Usage Instructions

1. Save the script as `security_report.sh`.
2. Make it executable: `chmod +x security_report.sh`.
3. Run with sudo: `sudo ./security_report.sh`.
4. Review the console output or the generated `.txt` file.

## Limitations and Improvements

- **macOS Version Dependency**: Tested on recent versions (e.g., Ventura/Sonoma); older versions may have different plist keys.
- **Sudo Prompts**: Multiple sudo calls may prompt for password repeatedly; consider running in a non-interactive environment.
- **Extensibility**: Add more checks (e.g., SIP status via `csrutil status`, Gatekeeper via `spctl --status`).
- **Error Handling**: Script uses `2>/dev/null` to suppress errors; enhance with logging if needed.

For questions or contributions, refer to the script comments or contact the maintainer.

*Last Updated: October 05, 2025*

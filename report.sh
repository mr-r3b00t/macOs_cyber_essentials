#!/bin/bash

# Security Report Generator for macOS (compatible with Intel and Apple Silicon/ARM)
# This script checks the status of key security features and generates a report.

REPORT_FILE="security_report_$(date +%Y%m%d_%H%M%S).txt"
echo "macOS Security Report - $(date)" > "$REPORT_FILE"
echo "========================================" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Function to add to report
add_to_report() {
    echo "$1" >> "$REPORT_FILE"
}

# 1. FileVault Status
add_to_report "1. FileVault Status:"
FILEVAULT_STATUS=$(fdesetup status 2>/dev/null | head -n1)
add_to_report "   Status: $FILEVAULT_STATUS"
if echo "$FILEVAULT_STATUS" | grep -q "FileVault is On"; then
    add_to_report "   Compliance: PASS (FileVault should be enabled)"
else
    add_to_report "   Compliance: FAIL (FileVault should be enabled)"
fi
add_to_report ""

# 2. Automatic Updates
add_to_report "2. Automatic Updates:"
AUTO_CHECK=$(sudo defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled 2>/dev/null || echo "0")
AUTO_DOWNLOAD=$(sudo defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload 2>/dev/null || echo "0")
AUTO_APP=$(sudo defaults read /Library/Preferences/com.apple.commerce AutoUpdate 2>/dev/null || echo "0")
add_to_report "   Check for updates: $(if [ "$AUTO_CHECK" = "1" ]; then echo "Enabled"; else echo "Disabled"; fi)"
add_to_report "   Download updates: $(if [ "$AUTO_DOWNLOAD" = "1" ]; then echo "Enabled"; else echo "Disabled"; fi)"
add_to_report "   App Store auto updates: $(if [ "$AUTO_APP" = "1" ]; then echo "Enabled"; else echo "Disabled"; fi)"
if [ "$AUTO_CHECK" = "1" ] || [ "$AUTO_DOWNLOAD" = "1" ] || [ "$AUTO_APP" = "1" ]; then
    add_to_report "   Compliance: PASS (At least one automatic update setting is enabled)"
else
    add_to_report "   Compliance: FAIL (Automatic Updates should be enabled)"
fi
add_to_report ""

# 3. Telemetry (Analytics & Improvements)
add_to_report "3. Telemetry (Analytics & Improvements):"
TELEMETRY_AUTO_SUBMIT=$(sudo defaults read /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory.plist AutoSubmit 2>/dev/null || echo "1")
add_to_report "   Status: $(if [ "$TELEMETRY_AUTO_SUBMIT" = "0" ]; then echo "Disabled"; else echo "Enabled"; fi)"
if [ "$TELEMETRY_AUTO_SUBMIT" = "0" ]; then
    add_to_report "   Compliance: PASS (Telemetry should not be enabled)"
else
    add_to_report "   Compliance: FAIL (Telemetry should not be enabled)"
fi
add_to_report ""

# 4. Firewall
add_to_report "4. Firewall:"
FIREWALL_OUTPUT=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null)
add_to_report "   Raw Output: $FIREWALL_OUTPUT"
FIREWALL_STATE=$(echo "$FIREWALL_OUTPUT" | grep -o "State = [0-1]" | cut -d' ' -f3 || echo "0")
add_to_report "   Status: $(if [ "$FIREWALL_STATE" = "1" ]; then echo "Enabled"; else echo "Disabled"; fi)"
if [ "$FIREWALL_STATE" = "1" ]; then
    add_to_report "   Compliance: PASS (Firewall should be enabled)"
else
    add_to_report "   Compliance: FAIL (Firewall should be enabled)"
fi
add_to_report ""

# 5. Sharing Services (File Sharing, Screen Sharing, Printer Sharing, Remote Login, etc.)
add_to_report "5. Sharing Services:"
ENABLED_SERVICES=()

# Check Screen Sharing
if sudo launchctl list 2>/dev/null | grep -q '^ *[0-9].*com\.apple\.screensharing'; then
    ENABLED_SERVICES+=("Screen Sharing")
fi

# Check Printer Sharing (cupsd)
if sudo launchctl list 2>/dev/null | grep -q '^ *[0-9].*org\.cups\.cupsd'; then
    ENABLED_SERVICES+=("Printer Sharing")
fi

# Check File Sharing (SMB)
if sudo launchctl list 2>/dev/null | grep -q '^ *[0-9].*com\.apple\.smbd'; then
    ENABLED_SERVICES+=("File Sharing (SMB)")
fi

# Check Remote Login (SSH)
if sudo launchctl list 2>/dev/null | grep -q '^ *[0-9].*com\.openssh\.sshd'; then
    ENABLED_SERVICES+=("Remote Login (SSH)")
fi

# Check Internet Sharing (NAT)
if sudo launchctl list 2>/dev/null | grep -q '^ *[0-9].*com\.apple\.nat'; then
    ENABLED_SERVICES+=("Internet Sharing")
fi

# Check Remote Management (if applicable)
if sudo launchctl list 2>/dev/null | grep -q '^ *[0-9].*com\.apple\.RemoteDesktop'; then
    ENABLED_SERVICES+=("Remote Management")
fi

if [ ${#ENABLED_SERVICES[@]} -eq 0 ]; then
    add_to_report "   Status: None enabled"
    add_to_report "   Compliance: PASS (Sharing Services should be off)"
else
    add_to_report "   Status: ${#ENABLED_SERVICES[@]} service(s) enabled"
    add_to_report "   Enabled services:"
    for service in "${ENABLED_SERVICES[@]}"; do
        add_to_report "     - $service"
    done
    add_to_report "   Compliance: FAIL (Sharing Services should be off)"
fi
add_to_report ""

add_to_report "Report generated on: $(date)"
add_to_report "========================================"

# Output to console as well
cat "$REPORT_FILE"

echo ""
echo "Report saved to: $REPORT_FILE"

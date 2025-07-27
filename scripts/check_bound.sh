#!/usr/bin/env bash
# File: scripts/diagnose_permissions.sh
# Purpose: Enterprise-grade WSL2-aware file audit for permission and mount issues
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assignment
# Version: 2.0.1

set -euo pipefail

# CONFIGURATION
PROJECT_ROOT="${1:-$PWD}"
USER_ID=$(id -u)
GROUP_ID=$(id -g)
PROJECT_NAME=$(basename "$PROJECT_ROOT")
EXTENSIONS=("*.py" "*.sh" "*.ino" "*.j2" "*.json" "*.yaml" "*.md" "*.txt")

# HEADER
echo "────────────────────────────────────────────────────────────"
echo "PERMISSION AUDIT REPORT"
echo "Project         : $PROJECT_NAME"
echo "Directory       : $PROJECT_ROOT"
echo "User UID:GID    : $USER_ID:$GROUP_ID"
echo "Timestamp (UTC) : $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "────────────────────────────────────────────────────────────"

# COUNTERS
total_files=0
bad_permissions=0
bad_mounts=0
bad_owners=0

# ANALYSIS
find "$PROJECT_ROOT" -type f \( $(printf -- '-name "%s" -o ' "${EXTENSIONS[@]}" | sed 's/ -o $//') \) | while read -r file; do
    ((total_files++))
    rel_path="${file#$PROJECT_ROOT/}"

    stat_out=$(stat -c "%A %U %G %s %y %n" "$file")
    perm_mode=$(stat -c "%a" "$file")
    owner_uid=$(stat -c "%u" "$file")
    mount_point=$(df --output=target "$file" | tail -n1)
    writable="NO"
    executable="NO"
    filetype=$(file -b "$file")

    [[ -w "$file" ]] && writable="YES"
    [[ -x "$file" ]] && executable="YES"

    warning=""
    if [[ "$mount_point" =~ ^/mnt/ ]]; then
        warning+="Windows mount path ($mount_point). "
        ((bad_mounts++))
    fi

    if [[ "$owner_uid" -ne "$USER_ID" ]]; then
        warning+="Mismatched UID ($owner_uid). "
        ((bad_owners++))
    fi

    if [[ "$perm_mode" != 6* && "$perm_mode" != 7* ]]; then
        warning+="Unusual permissions ($perm_mode). "
        ((bad_permissions++))
    fi

    echo "FILE: $rel_path"
    echo "  Type       : $filetype"
    echo "  Perms      : $perm_mode"
    echo "  Stat       : $stat_out"
    echo "  Writable   : $writable"
    echo "  Executable : $executable"
    echo "  Mountpoint : $mount_point"
    echo "  Issues     : ${warning:-None}"
    echo
done

# SUMMARY
echo "────────────────────────────────────────────────────────────"
echo "AUDIT SUMMARY"
echo "Total Files        : $total_files"
echo "Permission Issues  : $bad_permissions"
echo "Owner UID Issues   : $bad_owners"
echo "Mounted from WinFS : $bad_mounts"
echo "────────────────────────────────────────────────────────────"

# RECOMMENDATIONS
if [[ "$bad_permissions" -gt 0 || "$bad_mounts" -gt 0 || "$bad_owners" -gt 0 ]]; then
    echo "RECOMMENDATIONS:"
    [[ "$bad_mounts" -gt 0 ]] && echo "  • Move files from /mnt/* to /home/<user>/ for WSL-safe editing."
    [[ "$bad_permissions" -gt 0 ]] && echo "  • Run: chmod -R u+rwX \"$PROJECT_ROOT\""
    [[ "$bad_owners" -gt 0 ]] && echo "  • Run: sudo chown -R $(whoami):$(id -gn) \"$PROJECT_ROOT\""
    exit 1
else
    echo "No permission or ownership anomalies detected."
    exit 0
fi

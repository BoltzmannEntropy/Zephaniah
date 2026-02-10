#!/usr/bin/env bash
# =============================================================================
# Zephaniah - Diagnostic Script
# =============================================================================
# Collects system info, checks dependencies, tests connectivity.
# Output: issues_report_<timestamp>.log
# Run: ./issues.sh
# =============================================================================

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$ROOT_DIR/issues_report_$TIMESTAMP.log"
LOG_DIR="$ROOT_DIR/.logs"
PID_DIR="$ROOT_DIR/.pids"
DATA_DIR="$ROOT_DIR/data"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "$*" | tee -a "$LOG_FILE"; }
section() {
    log ""
    log "============================================================================="
    log "  $*"
    log "============================================================================="
}
subsection() { log "\n--- $* ---"; }

run_cmd() {
    local desc="$1"; shift
    log "$ $*"
    if output=$("$@" 2>&1); then
        log "$output"
        return 0
    else
        log "$output"
        log "${RED}[FAILED]${NC} $desc (exit code: $?)"
        return $?
    fi
}

echo "" > "$LOG_FILE"
log "${CYAN}Zephaniah Diagnostic Report${NC}"
log "Generated: $(date)"
log "Working Directory: $ROOT_DIR"

# =============================================================================
# 1. System Information
# =============================================================================
section "SYSTEM INFORMATION"

subsection "OS Version"
run_cmd "OS" uname -a
run_cmd "Architecture" uname -m

if [[ "$(uname)" == "Darwin" ]]; then
    run_cmd "macOS Version" sw_vers
fi

subsection "Disk Space"
run_cmd "Disk" df -h "$ROOT_DIR"

subsection "Memory"
if [[ "$(uname)" == "Darwin" ]]; then
    run_cmd "Memory" vm_stat | head -10
fi

# =============================================================================
# 2. Development Tools
# =============================================================================
section "DEVELOPMENT TOOLS"

for tool in flutter dart git brew xcodebuild; do
    if command -v $tool &>/dev/null; then
        case $tool in
            flutter) ver=$(flutter --version 2>&1 | head -1) ;;
            dart) ver=$(dart --version 2>&1) ;;
            xcodebuild) ver=$(xcodebuild -version 2>&1 | head -1) ;;
            *) ver=$($tool --version 2>&1 | head -1) ;;
        esac
        log "${GREEN}$tool${NC}: $ver"
    else
        log "${YELLOW}$tool${NC}: NOT INSTALLED"
    fi
done

# =============================================================================
# 3. Flutter Environment
# =============================================================================
section "FLUTTER ENVIRONMENT"

subsection "Flutter Version"
run_cmd "Flutter" flutter --version

subsection "Flutter Doctor"
flutter doctor -v 2>&1 | tee -a "$LOG_FILE"

subsection "Flutter Config"
flutter config 2>&1 | tee -a "$LOG_FILE"

# =============================================================================
# 4. Project Structure
# =============================================================================
section "PROJECT STRUCTURE"

subsection "pubspec.yaml"
if [ -f "$ROOT_DIR/pubspec.yaml" ]; then
    log "${GREEN}pubspec.yaml exists${NC}"
    grep "^name:\|^version:\|^sdk:" "$ROOT_DIR/pubspec.yaml" | head -5 | tee -a "$LOG_FILE"
else
    log "${RED}pubspec.yaml NOT found${NC}"
fi

subsection "macOS Platform"
if [ -d "$ROOT_DIR/macos" ]; then
    log "${GREEN}macos directory exists${NC}"
    ls -la "$ROOT_DIR/macos" 2>&1 | head -10 | tee -a "$LOG_FILE"
else
    log "${RED}macos directory NOT found${NC}"
fi

subsection "Control Script"
if [ -f "$ROOT_DIR/bin/zephaniahctl" ]; then
    log "${GREEN}zephaniahctl exists${NC}"
else
    log "${YELLOW}zephaniahctl NOT found${NC}"
fi

# =============================================================================
# 5. Database Status
# =============================================================================
section "DATABASE STATUS"

DB_FILE="$DATA_DIR/zephaniah.db"
if [ -f "$DB_FILE" ]; then
    log "${GREEN}Database exists${NC}: $DB_FILE"
    log "Size: $(du -h "$DB_FILE" | cut -f1)"

    # Check table counts if sqlite3 available
    if command -v sqlite3 &>/dev/null; then
        subsection "Table Counts"
        for table in artifacts search_history snapshots settings; do
            count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM $table;" 2>/dev/null || echo "N/A")
            log "  $table: $count rows"
        done
    fi
else
    log "${YELLOW}Database not found${NC} (will be created on first run)"
fi

# =============================================================================
# 6. Runtime Status
# =============================================================================
section "RUNTIME STATUS"

subsection "Running Processes"
if pgrep -f "Zephaniah.app" &>/dev/null; then
    log "${GREEN}Zephaniah is running${NC}"
    pgrep -f "Zephaniah.app" | while read pid; do
        log "  PID: $pid"
    done
else
    log "${YELLOW}Zephaniah is not running${NC}"
fi

subsection "PID Files"
if [ -d "$PID_DIR" ]; then
    for pidfile in "$PID_DIR"/*.pid; do
        if [ -f "$pidfile" ]; then
            pid=$(cat "$pidfile")
            name=$(basename "$pidfile" .pid)
            if kill -0 "$pid" 2>/dev/null; then
                log "${GREEN}$name${NC}: PID $pid (running)"
            else
                log "${YELLOW}$name${NC}: PID $pid (stale)"
            fi
        fi
    done
else
    log "No PID directory found"
fi

# =============================================================================
# 7. Network Tests
# =============================================================================
section "NETWORK TESTS"

subsection "DuckDuckGo Search"
if curl -s --connect-timeout 5 "https://duckduckgo.com" > /dev/null 2>&1; then
    log "${GREEN}DuckDuckGo reachable${NC}"
else
    log "${RED}DuckDuckGo NOT reachable${NC}"
fi

subsection "Google Search"
response=$(curl -s --connect-timeout 5 -o /dev/null -w "%{http_code}" "https://www.google.com/search?q=test" 2>&1 || echo "000")
if [ "$response" = "200" ]; then
    log "${GREEN}Google Search reachable${NC} (status: $response)"
else
    log "${YELLOW}Google Search${NC} (status: $response - may require browser headers)"
fi

# =============================================================================
# 8. Runtime Logs
# =============================================================================
section "RUNTIME LOGS"

subsection "Flutter Log"
FLUTTER_LOG="$LOG_DIR/flutter.log"
if [ -f "$FLUTTER_LOG" ]; then
    log "${GREEN}Flutter log exists${NC}: $FLUTTER_LOG"
    log "Last 50 lines:"
    log "----------------------------------------"
    tail -50 "$FLUTTER_LOG" 2>/dev/null | while IFS= read -r line; do
        log "$line"
    done
    log "----------------------------------------"
else
    log "${YELLOW}Flutter log not found${NC} (app may not have been started yet)"
fi

subsection "App Log"
APP_LOG="$LOG_DIR/app.log"
if [ -f "$APP_LOG" ]; then
    log "${GREEN}App log exists${NC}: $APP_LOG"
    log "Last 50 lines:"
    log "----------------------------------------"
    tail -50 "$APP_LOG" 2>/dev/null | while IFS= read -r line; do
        log "$line"
    done
    log "----------------------------------------"
else
    log "${YELLOW}App log not found${NC}"
fi

# =============================================================================
# 9. Build Status
# =============================================================================
section "BUILD STATUS"

BUILD_DIR="$ROOT_DIR/build/macos/Build/Products"
if [ -d "$BUILD_DIR" ]; then
    log "Build directory exists"
    subsection "Debug Build"
    if [ -d "$BUILD_DIR/Debug/Zephaniah.app" ]; then
        log "${GREEN}Debug build exists${NC}"
        log "Size: $(du -sh "$BUILD_DIR/Debug/Zephaniah.app" | cut -f1)"
    else
        log "${YELLOW}No debug build${NC}"
    fi

    subsection "Release Build"
    if [ -d "$BUILD_DIR/Release/Zephaniah.app" ]; then
        log "${GREEN}Release build exists${NC}"
        log "Size: $(du -sh "$BUILD_DIR/Release/Zephaniah.app" | cut -f1)"
    else
        log "${YELLOW}No release build${NC}"
    fi
else
    log "${YELLOW}No build directory${NC} (run: flutter build macos)"
fi

# =============================================================================
# 10. Environment Variables
# =============================================================================
section "ENVIRONMENT VARIABLES"

for var in PATH FLUTTER_ROOT HOME TMPDIR; do
    val="${!var:-<not set>}"
    if [ ${#val} -gt 100 ]; then
        val="${val:0:100}..."
    fi
    log "  $var: $val"
done

# =============================================================================
# Summary
# =============================================================================
section "SUMMARY"

log "Report saved to: ${CYAN}$LOG_FILE${NC}"
log ""
log "Share this file when reporting issues on GitHub."
log ""
echo -e "${GREEN}Done!${NC} Report: $LOG_FILE"

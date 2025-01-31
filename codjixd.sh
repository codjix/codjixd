#!/bin/bash

# Configuration
CONFIG_FILE="/etc/codjixd.conf"
BASE_DIR="${BASE_DIR:-/opt/codjixd}"
LOG_DIR="${LOG_DIR:-${BASE_DIR}/logs}"
PID_DIR="${PID_DIR:-${BASE_DIR}/pids}"
SERVICES_DIR="${SERVICES_DIR:-${BASE_DIR}/services}"
VERSION="1.0.2"

# Load configuration file if it exists
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

# Check if a service is running
is_running() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            return 0
        else
            rm -f "$PID_FILE"
            return 1
        fi
    else
        return 1
    fi
}

# Rotate logs: move current logs to .old and start a new log file
rotate_logs() {
    if [ -f "$LOG_FILE.log" ]; then
        echo -e "\n=== Log session end ===\n" >> "$LOG_FILE.log"
        cat "$LOG_FILE.log" >> "${LOG_FILE}.old.log"
    fi
    echo -e "=== Log session started at $(date) ===\n" > "$LOG_FILE.log"
}

# Load dependencies if defined in the service script
load_dependencies() {
    if source "$SERVICE_SCRIPT" &> /dev/null && [ -n "${depend_on[@]}" ]; then
        for dependency in "${depend_on[@]}"; do
            echo "[o] Loading dependency: $dependency"
            # Start the dependency synchronously in a new session
            setsid "$0" start "$dependency"
        done
    fi
}

# Run a health check if defined in the service script
run_health_check() {
    if source "$SERVICE_SCRIPT" &> /dev/null && declare -f health_check > /dev/null; then
        while true; do
            sleep 5
            if health_check; then
                echo "[o] Service $SERVICE_NAME is healthy."
            else
                echo "[x] Service $SERVICE_NAME is not healthy."
            fi
        done
    fi
}

# Start a service
start_service() {
    rotate_logs
    load_dependencies
    if is_running; then
        echo "[x] Service $SERVICE_NAME is already running (PID: $(cat "$PID_FILE"))."
        return 1
    fi
    # Start the service in the background and capture its PID immediately
    if source "$SERVICE_SCRIPT" &> /dev/null && declare -f start_fn > /dev/null; then
        start_fn >> "$LOG_FILE.log" 2>&1 &
        PID=$!
        echo "$PID" > "$PID_FILE"
        echo "[o] Service $SERVICE_NAME started (PID: $PID)."
        run_health_check >> "$LOG_FILE.log" 2>&1 &
    else
        echo "[x]: Service $SERVICE_NAME requires a start function."
    fi
}

# Stop a service
stop_service() {
    if ! is_running; then
        echo "[x] Service $SERVICE_NAME is not running."
        return 1
    fi
    PID=$(cat "$PID_FILE")
    # Kill the entire process group
    PGID=$(ps -o pgid= -p "$PID" | grep -o '[0-9]*')
    kill -9 -- -"$PGID"
    rm -f "$PID_FILE"
    echo "[o] Service $SERVICE_NAME stopped."
}

# Kill a service and its dependencies
kill_service() {
    stop_service
    if source "$SERVICE_SCRIPT" &> /dev/null && [ -n "${depend_on[@]}" ]; then
        for dependency in "${depend_on[@]}"; do
            echo "[x] Killing dependency: $dependency"
            "$0" kill "$dependency"
        done
    fi
}

# Restart a service
restart_service() {
    stop_service
    sleep 2
    start_service
}

# Show the status and metrics of a service
show_status() {
    if is_running; then
        PID_NUM=$(cat "$PID_FILE")
        echo "[o] Service $SERVICE_NAME is running"
        echo "[o] Metrics (PID: $PID_NUM):"
        ps -o pid,%cpu,%mem,start_time,etime -p "$PID_NUM"
    else
        echo "[x] Service $SERVICE_NAME is not running."
    fi
}

# Tail the logs of a service
tail_logs() {
    echo "[o] Tailing logs for service: $SERVICE_NAME"
    echo '[o] Press "h" to show help, "q" to stop it'
    echo -e '[o] Press "F" for live logs, "CTRL + C" to stop it\n'
    echo "1. Current run logs"
    echo "2. Old history logs"
    echo "3. Live logs"
    echo "4. Clean up logs"
    echo "0. Cancel"
    read -p "Choose an option [1]: " option
    option="${option:-1}"
    args=""
    case "$option" in
        0) return 0 ;;
        1) option="$LOG_FILE.log" ;;
        2) option="$LOG_FILE.old.log" ;;
        3) option="$LOG_FILE.log" && args="+F" ;;
        4) rm -f $LOG_FILE.{log,old.log} > /dev/null && \
           echo "[o] Done" && exit 0 ;;
        *) echo "[x] Invalid option: $option" && return 1 ;;
    esac
    if [ ! -f "$option" ]; then
        echo "[x] No logs for $SERVICE_NAME."
        return 1
    fi
    less -M $args "$option"
}

# List all available services
list_services() {
    if [ -d "$SERVICES_DIR" ]; then
        SERVICES=$(find "$SERVICES_DIR" -name "*.sh" -exec basename {} .sh \;)
        if [ -z "$SERVICES" ]; then
            echo "[x] No services yet."
        else
            echo "[o] Available services:"
            for SERVICE in $SERVICES; do
                echo "- $SERVICE"
            done
        fi
    else
        echo "[x] No services yet."
    fi
}

# Wrapper for actions that require a service
safe_service() {
    if [ -z "$SERVICE_NAME" ]; then
        echo "[x]: Service is required."
        exit 1
    fi
    LOG_FILE="${LOG_DIR}/${SERVICE_NAME}"
    PID_FILE="${PID_DIR}/${SERVICE_NAME}.pid"
    SERVICE_SCRIPT="${SERVICES_DIR}/${SERVICE_NAME}.sh"
    if [ ! -f "$SERVICE_SCRIPT" ]; then
        echo "[x]: Service $SERVICE_NAME not found."
        exit 1
    fi
    mkdir -p "$LOG_DIR" "$PID_DIR"
    "$1"
}

# Main script logic
ACTION="$1"
SERVICE_NAME="$2"

case "$ACTION" in
    start) safe_service start_service ;;
    stop) safe_service stop_service ;;
    restart) safe_service restart_service ;;
    kill) safe_service kill_service ;;
    status) safe_service show_status ;;
    logs) safe_service tail_logs ;;
    list|ls) list_services ;;
    version|-v|--version) 
        echo "Codjixd v$VERSION"
        ;;
    help|-h|--help|"")
        echo "Usage: $0 <command> [<service>]"
        echo "Commands:"
        echo "  start <service>    Start a service"
        echo "  stop <service>     Stop a service"
        echo "  restart <service>  Restart a service"
        echo "  kill <service>     Kill a service and its dependencies"
        echo "  status <service>   Show status and metrics for a service"
        echo "  logs <service>     Tail logs for a service"
        echo "  list, ls           List all available services"
        echo "  version            Show version information"
        echo "  help               Show this help message"
        echo "Options:"
        echo "  -v, --version      Show version information"
        echo "  -h, --help         Show this help message"
        ;;
    *)
        echo "[x]: Invalid operation '$ACTION'."
        echo "Usage: $0 <command> [<service>]"
        echo "       $0 -v, --version  Show version information"
        echo "       $0 -h, --help     Show full help message"
        exit 1
        ;;
esac
#!/bin/bash
# Monitoring Stack Management Script
# Provides easy commands to manage the monitoring infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Start monitoring stack
start_monitoring() {
    print_header "Starting Monitoring Stack"

    docker-compose up -d prometheus grafana loki promtail jaeger \
        otel-collector alertmanager postgres-exporter redis-exporter \
        node-exporter cadvisor

    print_success "Monitoring stack started successfully!"
    print_info "Waiting for services to be ready..."
    sleep 10

    show_status
}

# Stop monitoring stack
stop_monitoring() {
    print_header "Stopping Monitoring Stack"

    docker-compose stop prometheus grafana loki promtail jaeger \
        otel-collector alertmanager postgres-exporter redis-exporter \
        node-exporter cadvisor

    print_success "Monitoring stack stopped successfully!"
}

# Restart monitoring stack
restart_monitoring() {
    print_header "Restarting Monitoring Stack"
    stop_monitoring
    sleep 2
    start_monitoring
}

# Show status
show_status() {
    print_header "Monitoring Stack Status"

    echo ""
    echo "Service Health:"
    echo "---------------"

    # Check Prometheus
    if curl -sf http://localhost:9090/-/healthy > /dev/null 2>&1; then
        print_success "Prometheus: Running (http://localhost:9090)"
    else
        print_error "Prometheus: Not responding"
    fi

    # Check Grafana
    if curl -sf http://localhost:3001/api/health > /dev/null 2>&1; then
        print_success "Grafana: Running (http://localhost:3001)"
    else
        print_error "Grafana: Not responding"
    fi

    # Check Loki
    if curl -sf http://localhost:3100/ready > /dev/null 2>&1; then
        print_success "Loki: Running (http://localhost:3100)"
    else
        print_error "Loki: Not responding"
    fi

    # Check Jaeger
    if curl -sf http://localhost:14269/ > /dev/null 2>&1; then
        print_success "Jaeger: Running (http://localhost:16686)"
    else
        print_error "Jaeger: Not responding"
    fi

    # Check AlertManager
    if curl -sf http://localhost:9093/-/healthy > /dev/null 2>&1; then
        print_success "AlertManager: Running (http://localhost:9093)"
    else
        print_error "AlertManager: Not responding"
    fi

    echo ""
}

# Show logs
show_logs() {
    local service=$1
    if [ -z "$service" ]; then
        print_error "Please specify a service: prometheus, grafana, loki, jaeger, etc."
        exit 1
    fi

    print_header "Logs for gemini-mail-$service"
    docker-compose logs -f --tail=100 "$service"
}

# Open dashboards
open_dashboards() {
    print_header "Opening Monitoring Dashboards"

    print_info "Opening Grafana..."
    if command -v xdg-open > /dev/null; then
        xdg-open http://localhost:3001 2>/dev/null &
    elif command -v open > /dev/null; then
        open http://localhost:3001 2>/dev/null &
    else
        print_info "Please open http://localhost:3001 in your browser"
    fi

    sleep 1

    print_info "Opening Prometheus..."
    if command -v xdg-open > /dev/null; then
        xdg-open http://localhost:9090 2>/dev/null &
    elif command -v open > /dev/null; then
        open http://localhost:9090 2>/dev/null &
    else
        print_info "Please open http://localhost:9090 in your browser"
    fi

    sleep 1

    print_info "Opening Jaeger..."
    if command -v xdg-open > /dev/null; then
        xdg-open http://localhost:16686 2>/dev/null &
    elif command -v open > /dev/null; then
        open http://localhost:16686 2>/dev/null &
    else
        print_info "Please open http://localhost:16686 in your browser"
    fi

    print_success "Dashboards opened!"
}

# Test alerts
test_alerts() {
    print_header "Testing AlertManager"

    print_info "Sending test alert to AlertManager..."

    curl -X POST http://localhost:9093/api/v1/alerts -H 'Content-Type: application/json' -d '[
      {
        "labels": {
          "alertname": "TestAlert",
          "severity": "warning",
          "component": "monitoring"
        },
        "annotations": {
          "summary": "This is a test alert",
          "description": "Testing alert routing and notifications"
        }
      }
    ]'

    echo ""
    print_success "Test alert sent! Check AlertManager UI: http://localhost:9093"
}

# Check metrics
check_metrics() {
    print_header "Checking Metrics Endpoints"

    echo ""
    print_info "Backend API Metrics:"
    curl -s http://localhost:7098/api/metrics | head -20

    echo ""
    print_info "Prometheus Targets:"
    curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | "\(.labels.job): \(.health)"'

    echo ""
}

# Cleanup old data
cleanup() {
    print_header "Cleaning Up Monitoring Data"

    print_warning "This will remove all monitoring data (metrics, logs, traces)!"
    read -p "Are you sure? (yes/no): " confirm

    if [ "$confirm" != "yes" ]; then
        print_info "Cleanup cancelled"
        exit 0
    fi

    print_info "Stopping monitoring services..."
    docker-compose stop prometheus grafana loki jaeger alertmanager

    print_info "Removing volumes..."
    docker volume rm gemini-mail_prometheus_data 2>/dev/null || true
    docker volume rm gemini-mail_grafana_data 2>/dev/null || true
    docker volume rm gemini-mail_loki_data 2>/dev/null || true
    docker volume rm gemini-mail_alertmanager_data 2>/dev/null || true

    print_success "Cleanup completed!"
    print_info "Run './scripts/monitoring-stack.sh start' to restart with fresh data"
}

# Show help
show_help() {
    cat << EOF
Gemini Mail - Monitoring Stack Management

Usage: $0 [command]

Commands:
    start           Start the monitoring stack
    stop            Stop the monitoring stack
    restart         Restart the monitoring stack
    status          Show status of all monitoring services
    logs [service]  Show logs for a specific service
    open            Open monitoring dashboards in browser
    test-alerts     Send a test alert to AlertManager
    check-metrics   Check metrics endpoints and targets
    cleanup         Remove all monitoring data (destructive!)
    help            Show this help message

Examples:
    $0 start
    $0 status
    $0 logs prometheus
    $0 open
    $0 test-alerts

Services:
    prometheus, grafana, loki, promtail, jaeger, otel-collector,
    alertmanager, postgres-exporter, redis-exporter, node-exporter, cadvisor

EOF
}

# Main script
case "${1:-help}" in
    start)
        start_monitoring
        ;;
    stop)
        stop_monitoring
        ;;
    restart)
        restart_monitoring
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    open)
        open_dashboards
        ;;
    test-alerts)
        test_alerts
        ;;
    check-metrics)
        check_metrics
        ;;
    cleanup)
        cleanup
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac

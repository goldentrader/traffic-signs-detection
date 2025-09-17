#!/bin/bash

# Traffic Sign Detection System - Monitoring Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="traffic-sign-detector"
LOG_DIR="/var/log"
APP_DIR="/opt/traffic-sign-detector"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_service_status() {
    local service_name=$1
    if systemctl is-active --quiet "$service_name"; then
        log_success "$service_name is running"
        return 0
    else
        log_error "$service_name is not running"
        return 1
    fi
}

check_port() {
    local port=$1
    local service_name=$2
    if netstat -tlnp | grep -q ":$port "; then
        log_success "$service_name is listening on port $port"
        return 0
    else
        log_error "$service_name is not listening on port $port"
        return 1
    fi
}

check_disk_space() {
    local threshold=80
    local usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ "$usage" -lt "$threshold" ]; then
        log_success "Disk usage is $usage% (below $threshold% threshold)"
        return 0
    else
        log_warning "Disk usage is $usage% (above $threshold% threshold)"
        return 1
    fi
}

check_memory_usage() {
    local threshold=80
    local usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    
    if [ "$usage" -lt "$threshold" ]; then
        log_success "Memory usage is $usage% (below $threshold% threshold)"
        return 0
    else
        log_warning "Memory usage is $usage% (above $threshold% threshold)"
        return 1
    fi
}

check_application_health() {
    log_info "Checking application health..."
    
    # Check if Django application is responding
    if curl -s -f http://localhost:8000/admin/ > /dev/null; then
        log_success "Django application is responding"
    else
        log_error "Django application is not responding"
    fi
    
    # Check if React build exists
    if [ -d "$APP_DIR/frontend/build" ]; then
        log_success "React build directory exists"
    else
        log_warning "React build directory not found"
    fi
    
    # Check if YOLO model exists
    if [ -f "$APP_DIR/yolov8-gtsrb-trained.pt" ]; then
        log_success "YOLO model file exists"
    else
        log_error "YOLO model file not found"
    fi
}

check_database_connection() {
    log_info "Checking database connection..."
    
    if [ -f "$APP_DIR/.env" ]; then
        source "$APP_DIR/.env"
        if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -d "$DATABASE_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
            log_success "Database connection successful"
        else
            log_error "Database connection failed"
        fi
    else
        log_warning "Environment file not found, skipping database check"
    fi
}

check_redis_connection() {
    log_info "Checking Redis connection..."
    
    if redis-cli ping > /dev/null 2>&1; then
        log_success "Redis connection successful"
    else
        log_error "Redis connection failed"
    fi
}

check_logs() {
    log_info "Checking application logs..."
    
    # Check for errors in Django logs
    if [ -f "$LOG_DIR/django.log" ]; then
        local error_count=$(grep -c "ERROR" "$LOG_DIR/django.log" 2>/dev/null || echo "0")
        if [ "$error_count" -eq 0 ]; then
            log_success "No errors found in Django logs"
        else
            log_warning "Found $error_count errors in Django logs"
        fi
    fi
    
    # Check for errors in application logs
    if [ -f "$LOG_DIR/traffic-sign-detector.log" ]; then
        local error_count=$(grep -c "ERROR" "$LOG_DIR/traffic-sign-detector.log" 2>/dev/null || echo "0")
        if [ "$error_count" -eq 0 ]; then
            log_success "No errors found in application logs"
        else
            log_warning "Found $error_count errors in application logs"
        fi
    fi
}

backup_database() {
    log_info "Creating database backup..."
    
    if [ -f "$APP_DIR/.env" ]; then
        source "$APP_DIR/.env"
        local backup_file="/opt/backups/db_backup_$(date +%Y%m%d_%H%M%S).sql"
        
        mkdir -p /opt/backups
        
        if PGPASSWORD="$DB_PASSWORD" pg_dump -h "$DB_HOST" -U "$DB_USER" -d "$DATABASE_NAME" > "$backup_file"; then
            log_success "Database backup created: $backup_file"
        else
            log_error "Database backup failed"
        fi
    else
        log_warning "Environment file not found, skipping database backup"
    fi
}

cleanup_logs() {
    log_info "Cleaning up old logs..."
    
    # Keep only last 7 days of logs
    find "$LOG_DIR" -name "*.log" -type f -mtime +7 -delete 2>/dev/null || true
    find /opt/backups -name "*.sql" -type f -mtime +30 -delete 2>/dev/null || true
    
    log_success "Log cleanup completed"
}

restart_services() {
    log_info "Restarting services..."
    
    sudo systemctl restart nginx
    sudo systemctl restart redis-server
    sudo supervisorctl restart traffic-sign-detector
    
    log_success "Services restarted"
}

show_system_info() {
    log_info "System Information:"
    echo "Hostname: $(hostname)"
    echo "Uptime: $(uptime -p)"
    echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
    echo "Memory: $(free -h | awk 'NR==2{printf "Used: %s/%s (%.1f%%)", $3,$2,$3*100/$2}')"
    echo "Disk: $(df -h / | awk 'NR==2{printf "Used: %s/%s (%s)", $3,$2,$5}')"
    echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')"
}

# Main monitoring function
monitor() {
    log_info "Starting system monitoring..."
    echo "=================================="
    
    show_system_info
    echo "=================================="
    
    # Check system resources
    check_disk_space
    check_memory_usage
    echo "=================================="
    
    # Check services
    check_service_status "nginx"
    check_service_status "redis-server"
    check_service_status "supervisor"
    echo "=================================="
    
    # Check ports
    check_port "80" "Nginx"
    check_port "6379" "Redis"
    check_port "8000" "Django"
    echo "=================================="
    
    # Check application health
    check_application_health
    echo "=================================="
    
    # Check external connections
    check_database_connection
    check_redis_connection
    echo "=================================="
    
    # Check logs
    check_logs
    echo "=================================="
    
    log_success "Monitoring completed"
}

# Main execution
case "${1:-monitor}" in
    "monitor")
        monitor
        ;;
    "backup")
        backup_database
        ;;
    "cleanup")
        cleanup_logs
        ;;
    "restart")
        restart_services
        ;;
    "health")
        check_application_health
        ;;
    *)
        echo "Usage: $0 {monitor|backup|cleanup|restart|health}"
        echo "  monitor  - Run full system monitoring"
        echo "  backup   - Create database backup"
        echo "  cleanup  - Clean up old logs and backups"
        echo "  restart  - Restart all services"
        echo "  health   - Check application health only"
        exit 1
        ;;
esac

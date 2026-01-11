# Gemini Mail Enterprise - Monitoring & Observability

Complete monitoring and observability stack for Gemini Mail Enterprise application.

## 📊 Overview

This project includes a comprehensive monitoring and observability stack with:

- **Metrics Collection**: Prometheus + Exporters
- **Visualization**: Grafana Dashboards
- **Log Aggregation**: Loki + Promtail
- **Distributed Tracing**: Jaeger + OpenTelemetry
- **Alerting**: AlertManager
- **Health Checks**: Detailed health endpoints

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Application Layer                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Frontend   │  │   Backend    │  │  Database    │          │
│  │   (React)    │◄─┤  (Express)   │◄─┤ (PostgreSQL) │          │
│  └──────────────┘  └──────┬───────┘  └──────────────┘          │
└─────────────────────────────┼────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
┌───────────────────▼─────┐  ┌──────────▼──────────────┐
│   METRICS (Prometheus)  │  │  TRACES (Jaeger/OTEL)  │
│                         │  │                         │
│  • Application Metrics  │  │  • Request Tracing     │
│  • Database Metrics     │  │  • Service Dependencies│
│  • Redis Metrics        │  │  • Performance Analysis│
│  • System Metrics       │  │                         │
│  • Container Metrics    │  └─────────────────────────┘
└─────────┬───────────────┘
          │
          │  ┌──────────────────────────┐
          │  │  LOGS (Loki + Promtail) │
          │  │                          │
          │  │  • Container Logs        │
          │  │  • Application Logs      │
          │  │  • System Logs           │
          └──┤  • Structured Logging    │
             └──────────────────────────┘
                         │
           ┌─────────────┴──────────────┐
           │                            │
    ┌──────▼──────┐          ┌──────────▼────────┐
    │  GRAFANA    │          │   ALERTMANAGER    │
    │  Dashboards │          │   Alert Routing   │
    └─────────────┘          └───────────────────┘
```

---

## 🚀 Quick Start

### 1. Start Monitoring Stack

```bash
# Start all services including monitoring
docker-compose up -d

# Start only monitoring services
docker-compose up -d prometheus grafana loki jaeger
```

### 2. Access Dashboards

| Service | URL | Default Credentials |
|---------|-----|---------------------|
| **Grafana** | http://localhost:3001 | admin / admin |
| **Prometheus** | http://localhost:9090 | - |
| **Jaeger** | http://localhost:16686 | - |
| **AlertManager** | http://localhost:9093 | - |

### 3. View Pre-configured Dashboards

Navigate to Grafana → Dashboards → Browse:
- **Application Overview**: HTTP metrics, response times, error rates
- **Database Monitoring**: PostgreSQL performance, connections, queries
- **System Metrics**: CPU, Memory, Disk, Network

---

## 📈 Metrics

### Available Metrics

#### Application Metrics (Backend API)

```promql
# Request metrics
http_requests_total                    # Total HTTP requests
http_request_duration_seconds         # Request duration histogram
http_request_size_bytes               # Request size
http_response_size_bytes              # Response size

# Business metrics
active_users_total                     # Active users count
emails_sent_total                      # Emails sent counter
emails_received_total                  # Emails received counter
authentication_attempts_total          # Auth attempts

# Error metrics
api_errors_total                       # API errors by type
```

#### Database Metrics (PostgreSQL)

```promql
# Connection metrics
pg_stat_database_numbackends          # Active connections
pg_settings_max_connections           # Max connections limit

# Performance metrics
pg_stat_database_xact_commit          # Committed transactions
pg_stat_database_xact_rollback        # Rolled back transactions
pg_stat_database_blks_hit             # Cache hits
pg_stat_database_blks_read            # Disk reads

# Size metrics
pg_database_size_bytes                # Database size
```

#### Redis Metrics

```promql
# Memory metrics
redis_memory_used_bytes               # Memory used
redis_memory_max_bytes                # Max memory

# Operations
redis_commands_processed_total        # Total commands processed
redis_connected_clients               # Connected clients
```

#### System Metrics (Node Exporter)

```promql
# CPU
node_cpu_seconds_total                # CPU time
node_load1                            # 1-minute load average

# Memory
node_memory_MemTotal_bytes            # Total memory
node_memory_MemAvailable_bytes        # Available memory

# Disk
node_filesystem_avail_bytes           # Available disk space
node_disk_io_time_seconds_total       # Disk I/O time
```

### Custom Metrics Usage

In your backend code:

```javascript
const { trackDatabaseQuery, trackEmailSent, updateActiveUsers } = require('./middleware/monitoring');

// Track database query
const start = Date.now();
const result = await db.query('SELECT * FROM users');
trackDatabaseQuery('SELECT', 'users', (Date.now() - start) / 1000);

// Track email sent
trackEmailSent(true); // success = true

// Update active users count
updateActiveUsers(42);
```

---

## 📝 Logging

### Log Aggregation with Loki

All logs are automatically collected by Promtail and sent to Loki:

- **Container logs**: Docker container stdout/stderr
- **Application logs**: Backend application logs
- **System logs**: System-level logs
- **Database logs**: PostgreSQL logs
- **Cache logs**: Redis logs

### Querying Logs in Grafana

Navigate to Grafana → Explore → Select "Loki" datasource:

```logql
# View all backend logs
{service="backend"}

# Filter by log level
{service="backend"} |= "ERROR"

# Search for specific patterns
{service="backend"} |= "authentication failed"

# Combine with metrics
rate({service="backend"} |= "error" [5m])
```

### Log Correlation with Traces

Logs include trace IDs for correlation:

```javascript
// Logs automatically include traceId and spanId
logger.info('User logged in', {
  userId: user.id,
  traceId: req.traceId,
  spanId: req.spanId
});
```

---

## 🔍 Distributed Tracing

### Jaeger UI

Access Jaeger at http://localhost:16686

**Features**:
- View request traces across services
- Identify performance bottlenecks
- Analyze service dependencies
- Troubleshoot errors with full context

### OpenTelemetry Integration

Automatic instrumentation for:
- HTTP requests (incoming/outgoing)
- Database queries (PostgreSQL)
- Redis operations
- Express.js routes

### Custom Spans

```javascript
const { trace } = require('@opentelemetry/api');
const { createSpan } = require('./instrumentation/tracing');

async function processEmail(email) {
  const tracer = trace.getTracer('gemini-mail-backend');
  const span = createSpan(tracer, 'processEmail', {
    'email.id': email.id,
    'email.from': email.from
  });

  try {
    // Your processing logic
    const result = await doSomething(email);
    span.setStatus({ code: 1 }); // OK
    return result;
  } catch (error) {
    span.recordException(error);
    span.setStatus({ code: 2, message: error.message }); // ERROR
    throw error;
  } finally {
    span.end();
  }
}
```

---

## 🚨 Alerting

### AlertManager Configuration

Alerts are configured in `/infrastructure/monitoring/prometheus/alerts/application_alerts.yml`

**Alert Severity Levels**:
- **Critical**: Immediate action required (service down, high error rate)
- **Warning**: Investigation needed (high resource usage, slow responses)
- **Info**: Informational only

### Alert Routes

Configured in `/infrastructure/monitoring/alertmanager/alertmanager.yml`:

- **Critical alerts**: Immediate notification via email + webhook
- **Warning alerts**: Batched notifications (1 hour interval)
- **Database alerts**: Routed to database team
- **Backend alerts**: Routed to backend team

### Example Alerts

```yaml
# Backend API Down
- alert: BackendAPIDown
  expr: up{job="backend-api"} == 0
  for: 1m
  annotations:
    summary: "Backend API is down"

# High Error Rate
- alert: HighErrorRate
  expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
  for: 5m
  annotations:
    summary: "High error rate detected"
```

### Webhook Integration

Alerts can be sent to your backend:

```javascript
// Handle alerts in your backend
app.post('/api/webhooks/alerts', (req, res) => {
  const { alerts } = req.body;
  alerts.forEach(alert => {
    console.log(`Alert: ${alert.labels.alertname}`);
    // Send to Slack, PagerDuty, etc.
  });
  res.sendStatus(200);
});
```

---

## 🏥 Health Checks

### Endpoints

| Endpoint | Purpose | Kubernetes Probe |
|----------|---------|------------------|
| `/health/live` | Liveness check | livenessProbe |
| `/health/ready` | Readiness check | readinessProbe |
| `/health/startup` | Startup check | startupProbe |
| `/health/health` | Detailed health | - |

### Example Response

```json
{
  "status": "UP",
  "timestamp": "2024-01-11T10:30:00.000Z",
  "service": "gemini-mail-backend",
  "version": "1.0.0",
  "uptime": 3600,
  "checks": {
    "database": {
      "status": "UP",
      "responseTime": 5,
      "details": {
        "type": "PostgreSQL",
        "pool": {
          "total": 10,
          "idle": 8,
          "waiting": 0
        }
      }
    },
    "redis": {
      "status": "UP",
      "responseTime": 1,
      "details": {
        "type": "Redis",
        "memoryUsed": "12.5 MB"
      }
    },
    "memory": {
      "status": "UP",
      "details": {
        "system": {
          "total": "16384 MB",
          "used": "8192 MB",
          "free": "8192 MB",
          "usagePercentage": "50%"
        }
      }
    }
  }
}
```

---

## 🔧 Configuration

### Environment Variables

Add to `.env` file:

```bash
# Grafana
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=your-secure-password

# AlertManager
ALERT_EMAIL_CRITICAL=critical@example.com
ALERT_EMAIL_WARNING=warnings@example.com
ALERT_EMAIL_DATABASE=dba@example.com
ALERT_EMAIL_BACKEND=backend-team@example.com

# SMTP for alert emails
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_FROM=alerts@example.com
SMTP_USER=your-smtp-user
SMTP_PASSWORD=your-smtp-password

# OpenTelemetry
OTEL_LOG_LEVEL=info
ENVIRONMENT=production
TRACE_SAMPLING_RATE=10  # 10% sampling in production
```

### Prometheus Retention

Default: 30 days

To change, edit `docker-compose.yml`:

```yaml
prometheus:
  command:
    - '--storage.tsdb.retention.time=90d'  # 90 days
```

### Loki Retention

Default: 30 days

To change, edit `/infrastructure/monitoring/loki/loki-config.yml`:

```yaml
table_manager:
  retention_period: 2160h  # 90 days
```

---

## 📊 Grafana Dashboards

### Pre-configured Dashboards

#### 1. Application Overview
- Request rate and latency
- Error rates by endpoint
- Active users
- Top endpoints by traffic
- Slowest endpoints

#### 2. Database Monitoring
- Connection pool status
- Query performance
- Transaction rate
- Cache hit ratio
- Deadlocks and conflicts

#### 3. System Metrics
- CPU usage
- Memory usage
- Disk I/O
- Network traffic
- Container metrics

### Creating Custom Dashboards

1. Navigate to Grafana → Dashboards → New Dashboard
2. Add Panel
3. Select datasource (Prometheus/Loki/Jaeger)
4. Write query
5. Configure visualization
6. Save dashboard

---

## 🐛 Troubleshooting

### Prometheus Not Scraping Metrics

```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets

# Check backend metrics endpoint
curl http://localhost:7098/api/metrics

# View Prometheus logs
docker logs gemini-mail-prometheus
```

### Loki Not Receiving Logs

```bash
# Check Promtail logs
docker logs gemini-mail-promtail

# Verify Loki is ready
curl http://localhost:3100/ready

# Check log ingestion
curl http://localhost:3100/metrics | grep loki_ingester
```

### Jaeger Not Showing Traces

```bash
# Check OpenTelemetry collector
docker logs gemini-mail-otel-collector

# Verify Jaeger is running
curl http://localhost:14269/

# Check backend OTEL configuration
docker exec gemini-mail-backend env | grep OTEL
```

### High Resource Usage

```bash
# Check container resource usage
docker stats

# Reduce Prometheus retention
# Edit docker-compose.yml: --storage.tsdb.retention.time=7d

# Reduce trace sampling rate
# Edit .env: TRACE_SAMPLING_RATE=1
```

---

## 📦 Ports Reference

| Service | Port | Purpose |
|---------|------|---------|
| Prometheus | 9090 | Web UI & API |
| Grafana | 3001 | Dashboard UI |
| AlertManager | 9093 | Alert Management UI |
| Loki | 3100 | Log Ingestion API |
| Jaeger | 16686 | Jaeger UI |
| Jaeger | 14268 | Trace Collector |
| OTEL Collector | 4317 | OTLP gRPC |
| OTEL Collector | 4318 | OTLP HTTP |
| PostgreSQL Exporter | 9187 | Metrics |
| Redis Exporter | 9121 | Metrics |
| Node Exporter | 9100 | System Metrics |
| cAdvisor | 8080 | Container Metrics |

---

## 🔒 Security Considerations

### Production Recommendations

1. **Change default passwords**:
   - Grafana admin password
   - AlertManager basic auth

2. **Enable HTTPS**:
   - Use reverse proxy (nginx/traefie) with SSL
   - Configure TLS for Prometheus, Grafana

3. **Network isolation**:
   - Remove port mappings for internal services
   - Use Docker networks for service communication

4. **Authentication**:
   - Enable Grafana OAuth/LDAP
   - Configure Prometheus basic auth

5. **Data retention**:
   - Set appropriate retention periods
   - Regular backup of Grafana dashboards

---

## 📚 Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Loki Documentation](https://grafana.com/docs/loki/)
- [Jaeger Documentation](https://www.jaegertracing.io/docs/)
- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)

---

## 🤝 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review service logs: `docker-compose logs <service>`
3. Check health endpoints: `curl http://localhost:7098/health/health`

---

**Last Updated**: 2024-01-11
**Version**: 1.0.0

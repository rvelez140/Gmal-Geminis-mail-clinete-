/**
 * Monitoring Middleware for Gemini Mail Backend
 * Integrates Prometheus metrics, OpenTelemetry tracing, and health checks
 */

const promClient = require('prom-client');
const { trace, context, SpanStatusCode } = require('@opentelemetry/api');

// Initialize Prometheus metrics registry
const register = new promClient.Registry();

// Add default metrics (CPU, memory, etc.)
promClient.collectDefaultMetrics({
  register,
  prefix: 'gemini_mail_',
  labels: { service: 'backend' }
});

// Custom metrics
const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'path', 'status', 'service'],
  buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1, 2, 5, 10]
});

const httpRequestTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'path', 'status', 'service']
});

const httpRequestSizeBytes = new promClient.Histogram({
  name: 'http_request_size_bytes',
  help: 'Size of HTTP requests in bytes',
  labelNames: ['method', 'path', 'service'],
  buckets: [100, 1000, 10000, 100000, 1000000]
});

const httpResponseSizeBytes = new promClient.Histogram({
  name: 'http_response_size_bytes',
  help: 'Size of HTTP responses in bytes',
  labelNames: ['method', 'path', 'status', 'service'],
  buckets: [100, 1000, 10000, 100000, 1000000]
});

const activeUsersGauge = new promClient.Gauge({
  name: 'active_users_total',
  help: 'Number of currently active users',
  labelNames: ['service']
});

const databaseQueryDuration = new promClient.Histogram({
  name: 'database_query_duration_seconds',
  help: 'Duration of database queries in seconds',
  labelNames: ['operation', 'table', 'service'],
  buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1, 2, 5]
});

const databaseConnectionPool = new promClient.Gauge({
  name: 'database_connection_pool_size',
  help: 'Current size of database connection pool',
  labelNames: ['state', 'service']
});

const redisOperationDuration = new promClient.Histogram({
  name: 'redis_operation_duration_seconds',
  help: 'Duration of Redis operations in seconds',
  labelNames: ['operation', 'service'],
  buckets: [0.0001, 0.0005, 0.001, 0.005, 0.01, 0.05, 0.1]
});

const emailsSentTotal = new promClient.Counter({
  name: 'emails_sent_total',
  help: 'Total number of emails sent',
  labelNames: ['status', 'service']
});

const emailsReceivedTotal = new promClient.Counter({
  name: 'emails_received_total',
  help: 'Total number of emails received',
  labelNames: ['service']
});

const authenticationAttempts = new promClient.Counter({
  name: 'authentication_attempts_total',
  help: 'Total number of authentication attempts',
  labelNames: ['result', 'service']
});

const apiErrorsTotal = new promClient.Counter({
  name: 'api_errors_total',
  help: 'Total number of API errors',
  labelNames: ['type', 'path', 'service']
});

// Register all custom metrics
register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestTotal);
register.registerMetric(httpRequestSizeBytes);
register.registerMetric(httpResponseSizeBytes);
register.registerMetric(activeUsersGauge);
register.registerMetric(databaseQueryDuration);
register.registerMetric(databaseConnectionPool);
register.registerMetric(redisOperationDuration);
register.registerMetric(emailsSentTotal);
register.registerMetric(emailsReceivedTotal);
register.registerMetric(authenticationAttempts);
register.registerMetric(apiErrorsTotal);

/**
 * Express middleware for request monitoring
 */
function requestMonitoring(req, res, next) {
  const start = Date.now();
  const tracer = trace.getTracer('gemini-mail-backend');

  // Start OpenTelemetry span
  const span = tracer.startSpan(`HTTP ${req.method} ${req.path}`, {
    attributes: {
      'http.method': req.method,
      'http.url': req.url,
      'http.target': req.path,
      'http.host': req.hostname,
      'http.scheme': req.protocol,
      'http.user_agent': req.get('user-agent'),
      'http.client_ip': req.ip,
    }
  });

  // Add trace context to request
  req.traceId = span.spanContext().traceId;
  req.spanId = span.spanContext().spanId;

  // Track request size
  const requestSize = parseInt(req.get('content-length')) || 0;
  if (requestSize > 0) {
    httpRequestSizeBytes.observe(
      { method: req.method, path: req.route?.path || req.path, service: 'backend' },
      requestSize
    );
  }

  // Intercept response
  const originalSend = res.send;
  res.send = function(data) {
    const duration = (Date.now() - start) / 1000;
    const status = res.statusCode.toString();
    const path = req.route?.path || req.path;

    // Record metrics
    httpRequestDuration.observe(
      { method: req.method, path, status, service: 'backend' },
      duration
    );

    httpRequestTotal.inc({
      method: req.method,
      path,
      status,
      service: 'backend'
    });

    // Track response size
    const responseSize = Buffer.byteLength(data || '');
    httpResponseSizeBytes.observe(
      { method: req.method, path, status, service: 'backend' },
      responseSize
    );

    // Update span
    span.setAttributes({
      'http.status_code': res.statusCode,
      'http.response_content_length': responseSize
    });

    if (res.statusCode >= 400) {
      span.setStatus({ code: SpanStatusCode.ERROR });
      if (res.statusCode >= 500) {
        apiErrorsTotal.inc({
          type: 'server_error',
          path,
          service: 'backend'
        });
      } else {
        apiErrorsTotal.inc({
          type: 'client_error',
          path,
          service: 'backend'
        });
      }
    } else {
      span.setStatus({ code: SpanStatusCode.OK });
    }

    span.end();

    return originalSend.call(this, data);
  };

  next();
}

/**
 * Metrics export for database operations
 */
function trackDatabaseQuery(operation, table, duration) {
  databaseQueryDuration.observe(
    { operation, table, service: 'backend' },
    duration
  );
}

/**
 * Track database connection pool
 */
function updateConnectionPool(total, idle, active) {
  databaseConnectionPool.set({ state: 'total', service: 'backend' }, total);
  databaseConnectionPool.set({ state: 'idle', service: 'backend' }, idle);
  databaseConnectionPool.set({ state: 'active', service: 'backend' }, active);
}

/**
 * Track Redis operations
 */
function trackRedisOperation(operation, duration) {
  redisOperationDuration.observe(
    { operation, service: 'backend' },
    duration
  );
}

/**
 * Track email operations
 */
function trackEmailSent(success = true) {
  emailsSentTotal.inc({
    status: success ? 'success' : 'failure',
    service: 'backend'
  });
}

function trackEmailReceived() {
  emailsReceivedTotal.inc({ service: 'backend' });
}

/**
 * Track authentication attempts
 */
function trackAuthAttempt(success = true) {
  authenticationAttempts.inc({
    result: success ? 'success' : 'failure',
    service: 'backend'
  });
}

/**
 * Update active users count
 */
function updateActiveUsers(count) {
  activeUsersGauge.set({ service: 'backend' }, count);
}

/**
 * Get metrics for Prometheus scraping
 */
async function getMetrics() {
  return register.metrics();
}

/**
 * Get metrics in JSON format
 */
async function getMetricsJSON() {
  return register.getMetricsAsJSON();
}

module.exports = {
  requestMonitoring,
  trackDatabaseQuery,
  updateConnectionPool,
  trackRedisOperation,
  trackEmailSent,
  trackEmailReceived,
  trackAuthAttempt,
  updateActiveUsers,
  getMetrics,
  getMetricsJSON,
  register
};

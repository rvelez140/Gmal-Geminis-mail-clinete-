/**
 * OpenTelemetry Instrumentation for Gemini Mail Backend
 * Distributed tracing configuration
 */

const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');
const { OTLPMetricExporter } = require('@opentelemetry/exporter-metrics-otlp-http');
const { PeriodicExportingMetricReader } = require('@opentelemetry/sdk-metrics');
const { Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');
const { JaegerExporter } = require('@opentelemetry/exporter-jaeger');
const { BatchSpanProcessor } = require('@opentelemetry/sdk-trace-base');
const { diag, DiagConsoleLogger, DiagLogLevel } = require('@opentelemetry/api');

// Enable diagnostic logging for debugging (set to Info or Error in production)
if (process.env.OTEL_LOG_LEVEL === 'debug') {
  diag.setLogger(new DiagConsoleLogger(), DiagLogLevel.DEBUG);
}

/**
 * Initialize OpenTelemetry SDK
 */
function initializeTracing() {
  const serviceName = process.env.OTEL_SERVICE_NAME || 'gemini-mail-backend';
  const environment = process.env.ENVIRONMENT || 'development';
  const serviceVersion = process.env.npm_package_version || '1.0.0';

  // Configure resource attributes
  const resource = new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: serviceName,
    [SemanticResourceAttributes.SERVICE_VERSION]: serviceVersion,
    [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]: environment,
    [SemanticResourceAttributes.SERVICE_NAMESPACE]: 'gemini-mail',
  });

  // Configure trace exporter (OTLP or Jaeger)
  const useJaeger = process.env.OTEL_EXPORTER_TYPE === 'jaeger';

  let traceExporter;
  if (useJaeger) {
    // Jaeger exporter (legacy)
    traceExporter = new JaegerExporter({
      endpoint: process.env.JAEGER_ENDPOINT || 'http://jaeger:14268/api/traces',
    });
  } else {
    // OTLP exporter (recommended)
    traceExporter = new OTLPTraceExporter({
      url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://otel-collector:4318/v1/traces',
      headers: {},
    });
  }

  // Configure metric exporter
  const metricExporter = new OTLPMetricExporter({
    url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://otel-collector:4318/v1/metrics',
    headers: {},
  });

  // Configure metric reader
  const metricReader = new PeriodicExportingMetricReader({
    exporter: metricExporter,
    exportIntervalMillis: 60000, // Export every 60 seconds
  });

  // Initialize the SDK
  const sdk = new NodeSDK({
    resource,
    traceExporter,
    metricReader,
    instrumentations: [
      // Auto-instrumentation for common libraries
      getNodeAutoInstrumentations({
        // Configure specific instrumentations
        '@opentelemetry/instrumentation-http': {
          enabled: true,
          ignoreIncomingPaths: [
            '/health/live',
            '/health/ready',
            '/api/metrics'
          ],
          requestHook: (span, request) => {
            span.setAttribute('http.client_ip', request.socket.remoteAddress);
          },
          responseHook: (span, response) => {
            span.setAttribute('http.status_code', response.statusCode);
          }
        },
        '@opentelemetry/instrumentation-express': {
          enabled: true,
          requestHook: (span, requestInfo) => {
            span.updateName(`${requestInfo.request.method} ${requestInfo.route}`);
          }
        },
        '@opentelemetry/instrumentation-pg': {
          enabled: true,
          enhancedDatabaseReporting: true,
          requestHook: (span, queryConfig) => {
            span.setAttribute('db.statement', queryConfig.text);
          }
        },
        '@opentelemetry/instrumentation-redis': {
          enabled: true,
          requestHook: (span, request) => {
            span.setAttribute('redis.command', request.command);
          }
        },
        '@opentelemetry/instrumentation-fs': {
          enabled: false // Disable file system instrumentation to reduce noise
        },
        '@opentelemetry/instrumentation-dns': {
          enabled: false // Disable DNS instrumentation to reduce noise
        }
      })
    ],
  });

  // Start the SDK
  sdk.start();

  // Graceful shutdown
  process.on('SIGTERM', () => {
    sdk.shutdown()
      .then(() => console.log('OpenTelemetry SDK shut down successfully'))
      .catch((error) => console.error('Error shutting down OpenTelemetry SDK', error))
      .finally(() => process.exit(0));
  });

  return sdk;
}

/**
 * Create a custom span for manual instrumentation
 */
function createSpan(tracer, name, attributes = {}) {
  return tracer.startSpan(name, {
    attributes: {
      'service.name': 'gemini-mail-backend',
      ...attributes
    }
  });
}

/**
 * Wrap an async function with tracing
 */
function traceAsync(tracer, spanName, fn, attributes = {}) {
  return async function(...args) {
    const span = createSpan(tracer, spanName, attributes);
    try {
      const result = await fn(...args);
      span.setStatus({ code: 1 }); // OK
      return result;
    } catch (error) {
      span.setStatus({
        code: 2, // ERROR
        message: error.message
      });
      span.recordException(error);
      throw error;
    } finally {
      span.end();
    }
  };
}

/**
 * Add custom attributes to the current span
 */
function addSpanAttributes(attributes) {
  const { trace, context } = require('@opentelemetry/api');
  const currentSpan = trace.getSpan(context.active());
  if (currentSpan) {
    Object.entries(attributes).forEach(([key, value]) => {
      currentSpan.setAttribute(key, value);
    });
  }
}

/**
 * Record an exception in the current span
 */
function recordException(error) {
  const { trace, context } = require('@opentelemetry/api');
  const currentSpan = trace.getSpan(context.active());
  if (currentSpan) {
    currentSpan.recordException(error);
    currentSpan.setStatus({ code: 2, message: error.message });
  }
}

module.exports = {
  initializeTracing,
  createSpan,
  traceAsync,
  addSpanAttributes,
  recordException
};

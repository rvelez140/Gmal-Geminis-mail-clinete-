/**
 * Health Check Endpoints for Gemini Mail Backend
 * Provides detailed health status for monitoring systems
 */

const express = require('express');
const router = express.Router();
const os = require('os');

// Import database and cache clients (these will be injected)
let dbClient = null;
let redisClient = null;

/**
 * Initialize health check with database and cache clients
 */
function initHealthCheck(db, redis) {
  dbClient = db;
  redisClient = redis;
}

/**
 * Basic liveness probe
 * Returns 200 if the application is running
 */
router.get('/live', (req, res) => {
  res.status(200).json({
    status: 'UP',
    timestamp: new Date().toISOString(),
    service: 'gemini-mail-backend'
  });
});

/**
 * Readiness probe
 * Returns 200 only if all dependencies are healthy
 */
router.get('/ready', async (req, res) => {
  const checks = {
    database: await checkDatabase(),
    redis: await checkRedis(),
    memory: checkMemory(),
    disk: checkDisk()
  };

  const isReady = Object.values(checks).every(check => check.status === 'UP');
  const statusCode = isReady ? 200 : 503;

  res.status(statusCode).json({
    status: isReady ? 'UP' : 'DOWN',
    timestamp: new Date().toISOString(),
    service: 'gemini-mail-backend',
    checks
  });
});

/**
 * Detailed health endpoint
 * Returns comprehensive health information
 */
router.get('/health', async (req, res) => {
  const startTime = Date.now();

  const checks = {
    database: await checkDatabase(),
    redis: await checkRedis(),
    memory: checkMemory(),
    disk: checkDisk(),
    cpu: checkCPU()
  };

  const isHealthy = Object.values(checks).every(check =>
    check.status === 'UP' || check.status === 'WARNING'
  );

  const response = {
    status: isHealthy ? 'UP' : 'DOWN',
    timestamp: new Date().toISOString(),
    service: 'gemini-mail-backend',
    version: process.env.npm_package_version || '1.0.0',
    uptime: process.uptime(),
    checks,
    system: {
      hostname: os.hostname(),
      platform: os.platform(),
      arch: os.arch(),
      nodeVersion: process.version,
      pid: process.pid,
      loadAverage: os.loadavg(),
      totalMemory: os.totalmem(),
      freeMemory: os.freemem()
    },
    responseTime: Date.now() - startTime
  };

  const statusCode = isHealthy ? 200 : 503;
  res.status(statusCode).json(response);
});

/**
 * Startup probe
 * Returns 200 once the application has completed initialization
 */
router.get('/startup', async (req, res) => {
  // Check if critical dependencies are available
  const dbReady = await checkDatabase();
  const redisReady = await checkRedis();

  const isStarted = dbReady.status === 'UP' && redisReady.status === 'UP';

  res.status(isStarted ? 200 : 503).json({
    status: isStarted ? 'STARTED' : 'STARTING',
    timestamp: new Date().toISOString(),
    service: 'gemini-mail-backend',
    checks: {
      database: dbReady,
      redis: redisReady
    }
  });
});

/**
 * Check database connectivity and performance
 */
async function checkDatabase() {
  if (!dbClient) {
    return {
      status: 'DOWN',
      error: 'Database client not initialized'
    };
  }

  try {
    const start = Date.now();
    await dbClient.query('SELECT 1');
    const responseTime = Date.now() - start;

    // Get connection pool stats
    const poolStats = {
      total: dbClient.pool?.totalCount || 0,
      idle: dbClient.pool?.idleCount || 0,
      waiting: dbClient.pool?.waitingCount || 0
    };

    return {
      status: responseTime < 100 ? 'UP' : 'WARNING',
      responseTime,
      details: {
        type: 'PostgreSQL',
        pool: poolStats,
        message: responseTime >= 100 ? 'Slow response time' : 'Healthy'
      }
    };
  } catch (error) {
    return {
      status: 'DOWN',
      error: error.message,
      details: {
        type: 'PostgreSQL'
      }
    };
  }
}

/**
 * Check Redis connectivity and performance
 */
async function checkRedis() {
  if (!redisClient) {
    return {
      status: 'DOWN',
      error: 'Redis client not initialized'
    };
  }

  try {
    const start = Date.now();
    await redisClient.ping();
    const responseTime = Date.now() - start;

    // Get Redis info
    const info = await redisClient.info('memory');
    const memoryUsed = info.match(/used_memory_human:(.+)/)?.[1]?.trim();

    return {
      status: responseTime < 50 ? 'UP' : 'WARNING',
      responseTime,
      details: {
        type: 'Redis',
        memoryUsed,
        message: responseTime >= 50 ? 'Slow response time' : 'Healthy'
      }
    };
  } catch (error) {
    return {
      status: 'DOWN',
      error: error.message,
      details: {
        type: 'Redis'
      }
    };
  }
}

/**
 * Check memory usage
 */
function checkMemory() {
  const totalMemory = os.totalmem();
  const freeMemory = os.freemem();
  const usedMemory = totalMemory - freeMemory;
  const usagePercentage = (usedMemory / totalMemory) * 100;

  const processMemory = process.memoryUsage();

  let status = 'UP';
  let message = 'Memory usage is healthy';

  if (usagePercentage > 90) {
    status = 'DOWN';
    message = 'Critical: Memory usage above 90%';
  } else if (usagePercentage > 80) {
    status = 'WARNING';
    message = 'Warning: Memory usage above 80%';
  }

  return {
    status,
    details: {
      system: {
        total: Math.round(totalMemory / 1024 / 1024) + ' MB',
        used: Math.round(usedMemory / 1024 / 1024) + ' MB',
        free: Math.round(freeMemory / 1024 / 1024) + ' MB',
        usagePercentage: Math.round(usagePercentage) + '%'
      },
      process: {
        rss: Math.round(processMemory.rss / 1024 / 1024) + ' MB',
        heapTotal: Math.round(processMemory.heapTotal / 1024 / 1024) + ' MB',
        heapUsed: Math.round(processMemory.heapUsed / 1024 / 1024) + ' MB',
        external: Math.round(processMemory.external / 1024 / 1024) + ' MB'
      },
      message
    }
  };
}

/**
 * Check disk usage
 */
function checkDisk() {
  // Note: Requires 'diskusage' package for accurate disk stats
  // This is a simplified version using available space estimation

  try {
    // Placeholder - in production, use a proper disk usage library
    return {
      status: 'UP',
      details: {
        message: 'Disk check requires diskusage module',
        note: 'Install with: npm install diskusage'
      }
    };
  } catch (error) {
    return {
      status: 'UNKNOWN',
      error: error.message
    };
  }
}

/**
 * Check CPU usage
 */
function checkCPU() {
  const cpus = os.cpus();
  const loadAvg = os.loadavg();

  // Calculate average CPU usage
  let totalIdle = 0;
  let totalTick = 0;

  cpus.forEach(cpu => {
    for (let type in cpu.times) {
      totalTick += cpu.times[type];
    }
    totalIdle += cpu.times.idle;
  });

  const idle = totalIdle / cpus.length;
  const total = totalTick / cpus.length;
  const usagePercentage = 100 - ~~(100 * idle / total);

  let status = 'UP';
  let message = 'CPU usage is healthy';

  if (usagePercentage > 90) {
    status = 'WARNING';
    message = 'Warning: CPU usage above 90%';
  }

  return {
    status,
    details: {
      cores: cpus.length,
      model: cpus[0].model,
      speed: cpus[0].speed + ' MHz',
      usage: usagePercentage + '%',
      loadAverage: {
        '1min': loadAvg[0].toFixed(2),
        '5min': loadAvg[1].toFixed(2),
        '15min': loadAvg[2].toFixed(2)
      },
      message
    }
  };
}

module.exports = {
  router,
  initHealthCheck
};

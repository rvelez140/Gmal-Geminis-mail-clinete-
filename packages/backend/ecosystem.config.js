// PM2 Ecosystem Configuration for Gemini Mail Backend
// This file configures PM2 to run the backend with optimal production settings

module.exports = {
  apps: [{
    name: 'gemini-backend',
    script: './src/server.js',

    // Cluster mode - runs multiple instances across CPU cores
    instances: 'max',  // Use all available CPU cores
    exec_mode: 'cluster',

    // Memory management
    max_memory_restart: '500M',  // Auto-restart if memory exceeds 500MB

    // Logging
    error_file: './logs/pm2-error.log',
    out_file: './logs/pm2-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,

    // Environment
    env: {
      NODE_ENV: 'production',
    },

    // Restart behavior
    autorestart: true,
    watch: false,  // Don't watch files in production
    max_restarts: 10,
    min_uptime: '10s',

    // Graceful shutdown/restart
    kill_timeout: 5000,
    listen_timeout: 3000,
    shutdown_with_message: true,

    // Load balancing
    instance_var: 'INSTANCE_ID',

    // Performance
    node_args: '--max-old-space-size=460',  // Limit Node heap to 460MB (leaves room for PM2)
  }]
};

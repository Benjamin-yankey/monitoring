const express = require('express');
const app = express();
const port = process.env.PORT || 5000;

const deploymentTime = new Date().toISOString();
const version = process.env.APP_VERSION || '1.0.0';

// Prometheus metrics
const metrics = {
  httpRequestsTotal: new Map(),
  httpRequestDuration: new Map(),
  httpErrorsTotal: new Map(),
  requestCount: 0,
  errorCount: 0,
  startTime: Date.now()
};

// Middleware to track metrics
app.use((req, res, next) => {
  const startTime = Date.now();
  
  res.on('finish', () => {
    const duration = Date.now() - startTime;
    const route = req.route?.path || req.path;
    const method = req.method;
    const status = res.statusCode;
    
    metrics.requestCount++;
    if (status >= 400) {
      metrics.errorCount++;
    }
    
    const key = `${method}_${route}_${status}`;
    metrics.httpRequestsTotal.set(key, (metrics.httpRequestsTotal.get(key) || 0) + 1);
    metrics.httpRequestDuration.set(key, (metrics.httpRequestDuration.get(key) || 0) + duration);
    
    if (status >= 400) {
      metrics.httpErrorsTotal.set(key, (metrics.httpErrorsTotal.get(key) || 0) + 1);
    }
  });
  
  next();
});

app.use(express.json());
app.use(express.static('public'));

app.get('/', (req, res) => {
    res.send(`
<!DOCTYPE html>
<html>
<head>
    <title>CI/CD Pipeline App</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .status { color: #28a745; font-weight: bold; }
        .info { background: #e9ecef; padding: 15px; border-radius: 5px; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 CI/CD Pipeline App</h1>
        <p class="status">Status: Running</p>
        <div class="info">
            <p><strong>Version:</strong> ${version}</p>
            <p><strong>Deployed:</strong> ${deploymentTime}</p>
        </div>
        <p>Application successfully deployed and running!</p>
    </div>
</body>
</html>
    `);
});

app.get('/api/info', (req, res) => {
    res.json({
        version,
        deploymentTime,
        status: "running"
    });
});

app.get('/health', (req, res) => {
    res.status(200).json({
        status: "healthy"
    });
});

app.get('/metrics', (req, res) => {
    const uptime = (Date.now() - metrics.startTime) / 1000;
    const errorRate = metrics.requestCount > 0 ? (metrics.errorCount / metrics.requestCount * 100).toFixed(2) : 0;
    
    let metricsOutput = `# HELP app_uptime_seconds Application uptime in seconds
# TYPE app_uptime_seconds gauge
app_uptime_seconds ${uptime}

# HELP app_requests_total Total HTTP requests
# TYPE app_requests_total counter
app_requests_total ${metrics.requestCount}

# HELP app_errors_total Total HTTP errors
# TYPE app_errors_total counter
app_errors_total ${metrics.errorCount}

# HELP app_error_rate_percent Error rate percentage
# TYPE app_error_rate_percent gauge
app_error_rate_percent ${errorRate}

# HELP app_info Application info
# TYPE app_info gauge
app_info{version="${version}",deployment_time="${deploymentTime}"} 1

`;

    // Add per-route metrics
    metrics.httpRequestsTotal.forEach((count, key) => {
        metricsOutput += `# HELP http_requests_total Total HTTP requests by route and status
# TYPE http_requests_total counter
http_requests_total{route="${key}"} ${count}\n`;
    });

    metrics.httpRequestDuration.forEach((duration, key) => {
        const avgDuration = (duration / (metrics.httpRequestsTotal.get(key) || 1)).toFixed(2);
        metricsOutput += `# HELP http_request_duration_ms Average request duration in milliseconds
# TYPE http_request_duration_ms gauge
http_request_duration_ms{route="${key}"} ${avgDuration}\n`;
    });

    res.set('Content-Type', 'text/plain; version=0.0.4');
    res.send(metricsOutput);
});

if (require.main === module) {
    app.listen(port, '0.0.0.0', () => {
        console.log(`Server running on port ${port}`);
    });
}

module.exports = app;
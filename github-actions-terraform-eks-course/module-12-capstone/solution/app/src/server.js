const http = require('http');
const url = require('url');

const PORT = process.env.PORT || 3000;
const ENVIRONMENT = process.env.ENVIRONMENT || 'dev';
const VERSION = process.env.VERSION || 'local';

function metrics() {
  const uptime = process.uptime();
  return [
    '# HELP capstone_uptime_seconds Process uptime',
    '# TYPE capstone_uptime_seconds gauge',
    `capstone_uptime_seconds ${uptime}`,
    '# HELP capstone_info Application info',
    '# TYPE capstone_info gauge',
    `capstone_info{environment="${ENVIRONMENT}",version="${VERSION}"} 1`
  ].join('\n');
}

function handler(req, res) {
  const parsed = url.parse(req.url, true);

  if (parsed.pathname === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      status: 'healthy',
      environment: ENVIRONMENT,
      version: VERSION
    }));
    return;
  }

  if (parsed.pathname === '/metrics') {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end(metrics());
    return;
  }

  if (parsed.pathname === '/') {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end(`Capstone API - ${ENVIRONMENT} - ${VERSION}\n`);
    return;
  }

  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ error: 'not found' }));
}

const server = http.createServer(handler);

if (require.main === module) {
  server.listen(PORT, () => {
    console.log(`Listening on ${PORT} env=${ENVIRONMENT} version=${VERSION}`);
  });
}

module.exports = { handler, metrics };
